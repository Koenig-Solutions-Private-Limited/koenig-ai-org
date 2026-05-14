---
date: 2026-05-14
author: content-author
vendor_tag: openai
content_type: blog
status: draft-for-review
reading_time_min: 9
learning_objectives:
  - "Choose between Realtime API and a Whisper+TTS pipeline using concrete latency and cost numbers"
  - "Architect a WebRTC proxy for production Realtime sessions"
  - "Handle interrupts, the 15-min session cap, and the 16k instruction limit correctly"
  - "Estimate per-minute cost at tier 1 and plan tier upgrades for scale"
whats_new: "gpt-realtime-2 GA (Feb 2026) with 128k context, reasoning.effort param, and SIP/DTMF telephony support"
---

# How to ship OpenAI Realtime API voice agents to production: rate limits, sessions, and cost control

OpenAI's Realtime API hit general availability in February 2026 with `gpt-realtime-1.5`, and the follow-on `gpt-realtime-2` landed with 128k context, configurable `reasoning.effort`, and SIP/DTMF telephony. <CitationFootnote source="https://platform.openai.com/docs/changelog">OpenAI Changelog — Realtime GA Feb 2026</CitationFootnote> If you're building a production voice agent today, you need to know exactly where the API saves you latency, where it costs you money, and which session limits will bite you at 2 AM.

This post covers the five production concerns that trip up most teams: pipeline selection, WebSocket vs. WebRTC architecture, session management, interrupt handling, and the rate-limit tier ladder.

---

## 1. Realtime API vs. Whisper + TTS pipelines: pick the right tool

The traditional voice stack chains Whisper (STT) → GPT-4o (LLM) → TTS-1, yielding 2–3 seconds of end-to-end latency, robotic prosody, and awkward interrupts. <CitationFootnote source="https://www.eesel.ai/blog/realtime-api-vs-whisper-vs-tts-api">Eesel.ai — Realtime vs Whisper vs TTS, 2026</CitationFootnote> The Realtime API collapses that chain into one WebSocket endpoint (`wss://api.openai.com/v1/realtime?model=gpt-realtime-2`), with native audio I/O, server-side VAD, and tool calls mid-stream. The result is 500 ms TTFB (US) and 643 ms median E2E on `gpt-realtime-1.5` benchmarks. <CitationFootnote source="https://www.latent.space/p/realtime-api">Latent Space — Realtime API benchmarks, 2026</CitationFootnote>

**Use Realtime when:**
- You need sub-800ms voice-to-voice (support bots, live translation, phone IVR)
- Natural interrupts matter (callers don't wait for the AI to finish)
- You need tool calls or reasoning inside the voice turn

**Stick to pipelines when:**
- Cost is the primary constraint — pipelines run ~$0.01–0.05/min vs. Realtime's $0.11–0.50+/min depending on session length
- You need accented-language STT or custom TTS voices not in OpenAI's catalog
- The task is batch transcription with no latency requirement

<Callout type="hot">
Realtime API obsoletes the Whisper+TTS stack for agentic voice. The latency gap (500ms vs. 2-3s) is large enough that pipelines are no longer competitive for user-facing conversation.
</Callout>

---

## 2. Architecture: WebRTC proxy beats raw WebSocket for most teams

The Realtime API speaks WebSocket, but WebSocket runs over TCP — which means head-of-line blocking at 800ms+ round trips. For production, most teams run a **WebRTC proxy**: your server holds the WebSocket to OpenAI and speaks WebRTC (UDP) to the client. UDP packet loss is graceful for audio; TCP stalls are not.

Typical proxy arch:
```
Browser ──(WebRTC/UDP)──▶ Your server ──(WebSocket/TLS)──▶ OpenAI Realtime
```

Audio format: 24kHz PCM16, base64-encoded, sent as `input_audio_buffer.append` events. Output arrives as `response.audio.delta` chunks. For telephony, use G.711 (8kHz µ-law) — the API supports both. <CitationFootnote source="https://platform.openai.com/docs/guides/realtime-models-prompting">OpenAI — Realtime prompting guide</CitationFootnote>

Additional tips:
- Mute the microphone while the AI is speaking to avoid echo feedback
- Bluetooth headsets add 200–300ms hardware latency — wire-only for production kiosks

<RunPromptCell>
prompt: |
  # WebRTC proxy: start a Realtime session
  # Replace with your OpenAI API key and connect to the Realtime WS endpoint

  import asyncio, websockets, json

  async def realtime_session():
      url = "wss://api.openai.com/v1/realtime?model=gpt-realtime-2"
      headers = {"Authorization": "Bearer YOUR_API_KEY", "OpenAI-Beta": "realtime=v1"}
      async with websockets.connect(url, extra_headers=headers) as ws:
          # Configure session
          await ws.send(json.dumps({
              "type": "session.update",
              "session": {
                  "modalities": ["audio", "text"],
                  "voice": "alloy",
                  "input_audio_format": "pcm16",
                  "output_audio_format": "pcm16",
                  "turn_detection": {"type": "server_vad", "silence_duration_ms": 800},
                  "instructions": "You are a concise voice assistant. Answer in 2 sentences max.",
                  "reasoning": {"effort": "low"}
              }
          }))
          print("Session configured — ready for audio input")

  asyncio.run(realtime_session())

expected_output: |
  Session configured — ready for audio input
<!-- TODO: verify with QA -->
</RunPromptCell>

---

## 3. Session management: the two limits that will catch you

**15-minute session cap.** Each WebSocket connection has a hard 15-minute limit. For support bots with longer calls, you must gracefully reconnect: flush the current conversation state to your DB, open a new session, and replay a condensed context window. Design for this from day one.

**16k instruction token limit.** The system prompt + tool schemas must fit in 16,384 tokens. For agents with many tools, this gets tight fast. <CitationFootnote source="https://community.openai.com/t/realtime-api-instruction-limit-16-384-tokens-is-too-low-for-production-voice-agents-with-tool-calling/1378932">OpenAI Community — 16k instruction limit, 2026</CitationFootnote> Workarounds:
- Use `session.update` mid-conversation to swap tool schemas in and out dynamically
- Compress tool descriptions ruthlessly (3 words > 30 for the model)
- Separate "fast tools" (always loaded) from "slow tools" (loaded on demand)

**Interrupt handling.** When a user talks over the AI, you receive `conversation.interrupted`. You must immediately call `conversation.item.truncate` to revert the model's context to the last user turn. Then sync your audio playback promise to stop playing buffered chunks. <CitationFootnote source="https://docs.workadventu.re/blog/realtime-api-interrupting-the-model/">WorkAdventure — Interrupt handling in Realtime API</CitationFootnote>

```js
// On interrupt event
ws.on('message', (raw) => {
  const event = JSON.parse(raw);
  if (event.type === 'conversation.interrupted') {
    // 1. Stop playing buffered audio
    audioPlayer.flush();
    // 2. Revert model context
    ws.send(JSON.stringify({
      type: 'conversation.item.truncate',
      item_id: event.item_id,
      content_index: 0,
      audio_end_ms: event.audio_end_ms
    }));
  }
});
```

---

## 4. Cost model: the exponential that surprises everyone

Audio tokens are expensive, and history grows fast. OpenAI prices Realtime at **$32/1M input audio tokens** (80% discount for cached audio) and **$64/1M output audio**. At 70% AI talk time: <CitationFootnote source="https://www.latent.space/p/realtime-api">Latent Space — Realtime cost breakdown, 2026</CitationFootnote>

| Session length | Estimated cost |
|---|---|
| 1 min | $0.11 |
| 5 min | $0.92 |
| 15 min | $5.28 |

The 15-min cost is 48× the 1-min cost — not 15× — because the conversation history (context window) grows with every turn. Keep sessions short and use `conversation.item.delete` to prune old turns when sessions run long.

For comparison: Cartesia Sonic-3 costs $0.03/min flat for TTS-only agents with no reasoning. <CitationFootnote source="https://cartesia.ai/vs/cartesia-vs-openai-tts">Cartesia — Sonic-3 vs OpenAI TTS benchmark</CitationFootnote> If your agent needs ultra-low TTFA (40ms Turbo vs. OpenAI's 199ms) and doesn't need reasoning or tool calls, Cartesia may be the better fit. For comparison of both stacks in detail, see the Academy course [[picking-a-frontier-model-2026-q2]].

<Callout type="warn">
The 15-minute session cost ($5.28) is 12× the OpenAI $0.40/min Realtime TTS benchmark you'll see quoted in vendor comparisons — those benchmarks measure TTFA, not total session cost with growing context history.
</Callout>

---

## 5. Rate limits: tier ladder and observability

Rate limits apply at the organization and project level, measured in RPM (requests/min), TPM (tokens/min), and RPD/TPD (per day). <CitationFootnote source="https://platform.openai.com/docs/guides/rate-limits">OpenAI — Rate limits guide</CitationFootnote>

| Tier | Requirement | Typical TPM |
|---|---|---|
| Tier 1 | $5 paid, $100/mo | ~1M–4M |
| Tier 3 | $250 paid | ~40M |
| Tier 5 | $200k/mo | Negotiated |

For production voice agents, target **Tier 3** at minimum before launch. Each Realtime session consumes tokens continuously — a 15-minute session at 70% AI speech burns ~300k tokens on output alone.

Monitor these response headers on every WebSocket upgrade:
- `x-ratelimit-remaining-requests`
- `x-ratelimit-reset-tokens`

Implement exponential backoff on `429` errors and use OpenAI Projects to isolate prod from dev limits.

<KnowledgeCheck>
questions:
  - type: mcq
    prompt: "You're billing users per call. A 10-minute Realtime session costs approximately how much at 70% AI talk time?"
    options:
      - "A. $0.11"
      - "B. $2.50"
      - "C. $5.28"
      - "D. $0.40"
    correct: B
    explanation: "The cost is non-linear: 1min=$0.11, 5min=$0.92, 15min=$5.28. A 10-min session lands around $2.50 due to history growth."
  - type: free_form
    prompt: "Your production voice agent hits a 15-minute session limit mid-call. Describe the two steps you need to take to reconnect without losing conversation context."
    grading_rubric: "Should mention: (1) save conversation state/history to external store before 15min; (2) open new WebSocket session and replay condensed context or summary."
</KnowledgeCheck>

---

## Summary

OpenAI Realtime API (`gpt-realtime-2`) is the right default for agentic voice in 2026: 500ms TTFB, native interrupts, tool calls, and 128k context. The main production concerns are:

1. **Architecture** — run a WebRTC proxy (UDP) in front of the WebSocket (TCP) for client-facing latency
2. **Session limits** — plan for 15-min reconnects and keep instructions under 16k tokens
3. **Interrupts** — always `conversation.item.truncate` on `conversation.interrupted`, then sync your audio buffer
4. **Cost** — budget $0.11–$5.28/session depending on length; cache audio when possible; use `conversation.item.delete` to prune history
5. **Rate limits** — hit Tier 3 before launch; instrument `x-ratelimit-*` headers

For a deeper look at how Realtime fits into a multi-agent production system, see the Academy course [[production-agents-claude-agent-sdk-mcp-connector]]. For model selection decisions (Realtime vs Cartesia vs Gemini Live), see [[picking-a-frontier-model-2026-q2]].
