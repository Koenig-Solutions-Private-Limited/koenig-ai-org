---
date: 2026-06-15
author: content-author
vendor_tag: openai
content_type: course-chapter
course_slug: openai-realtime-api-voice-agents-end-to-end
chapter_number: 1
chapter_slug: voice-agent-landscape
title: "The Voice Agent Landscape — What the Realtime API Actually Solves"
description: "Learn how the OpenAI Realtime API eliminates the classic STT→LLM→TTS pipeline, map the six layers of a production voice agent, and build your first WebSocket voice session."
slug: openai-realtime-api-voice-agents-ch01-voice-agent-landscape
learning_objectives:
  - "Contrast the Realtime API (speech-to-speech) with the classic STT → LLM → TTS pipeline and name the latency cost of each extra hop"
  - "Identify the six production layers of a voice agent: client, edge media, agent runtime, model API, tool plane, observability"
  - "Choose WebRTC vs WebSocket transport based on use-case requirements"
  - "Build a minimal Hello World voice session and measure round-trip latency end-to-end"
whats_new: "Covers gpt-realtime-2 (released May 2026, GPT-5-class reasoning) and its predecessor gpt-realtime (GA August 2025), WebRTC GA endpoint, and current audio token pricing as of June 2026"
status: g3-passed
last_updated: 2026-06-15
reading_time_min: 10
duration_min: 35
prerequisites:
  - "Working knowledge of the OpenAI Chat Completions API"
  - "Python 3.10+ or Node.js 20+"
tags: [openai, realtime-api, voice-agents, WebRTC, WebSocket, latency, speech-to-speech]
positions: [] # no active stances directly addressed
faq:
  - question: "How does the OpenAI Realtime API differ from a Whisper + GPT + TTS pipeline?"
    answer: "The classic pipeline chains three independent services — Whisper for transcription, a chat model for reasoning, and a TTS service for synthesis — into three sequential API calls, each adding latency. The minimum floor is 800–1,800 ms per turn before network overhead. The Realtime API replaces all three with a single stateful WebSocket or WebRTC session: audio tokens enter, the model reasons directly over them, and audio tokens stream out, cutting time-to-first-audio to roughly 500 ms from US datacenters. [(OpenAI, 'Advancing voice intelligence with new models in the API')](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api) (retrieved 2026-06-15)"
  - question: "When should I use WebRTC instead of WebSocket for the Realtime API?"
    answer: "Choose WebRTC for browser and mobile clients on variable networks. WebRTC's UDP-based congestion control drops late packets rather than stalling — on poor LTE, a TCP retransmission freeze in a WebSocket can introduce 200–500 ms gaps that break conversational flow. WebRTC also handles firewall traversal automatically via ICE negotiation. Choose WebSocket for server-to-server scenarios such as telephony bridges or backend pipelines that pre-process audio, where reliable delivery and frame-level control matter more than network adaptability. Both transports share the same event schema. [(OpenAI, 'Realtime conversations guide')](https://developers.openai.com/api/docs/guides/realtime-conversations) (retrieved 2026-06-15)"
  - question: "How much does a 10-minute Realtime API voice session cost?"
    answer: "At gpt-realtime-2's rates of $32 per 1M audio input tokens and $64 per 1M audio output tokens, a 10-minute session where both parties speak generates roughly $0.77 in audio tokens — approximately 800 tokens per minute per channel, totaling ~8,000 input and ~8,000 output tokens. Enabling prompt caching drops cached input to $0.40 per 1M tokens, a meaningful saving for long sessions with large system instructions. At 1,000 daily 10-minute calls, audio costs run approximately $770/day before caching. [(OpenAI, 'API Pricing')](https://openai.com/api/pricing) (retrieved 2026-06-15)"
---

# The Classic STT → LLM → TTS Pipeline Costs You 1–3 Seconds Every Turn

Most voice AI tutorials teach the same architecture: record audio → transcribe with Whisper → send text to GPT → synthesize with a TTS service → play back audio. The pipeline feels logical because each component is familiar. The problem is latency: three API calls, three network hops, three serialization steps — and a minimum floor of around 1,000 ms even on a fast connection.

The OpenAI Realtime API is a categorical break from that pattern. It runs a single speech-to-speech session where audio goes in, reasoning happens, tools fire, and audio comes out — without ever converting your voice to text and back. The result is a time-to-first-audio of around 500 ms from US datacenters under good conditions. [(Latent.Space, "Realtime API: The Missing Manual")](https://www.latent.space/p/realtime-api) (retrieved 2026-06-15)

This chapter maps the architecture difference, introduces the six layers every production voice agent needs, and walks you through building your first working session.

---

## Why the Three-Hop Pipeline Always Loses on Latency

To see the problem concretely, time each stage of a classic pipeline:

| Stage | Median latency |
|---|---|
| Audio capture → Whisper STT | 300–600 ms |
| Text → GPT-4o Chat Completions (TTFT) | 300–700 ms |
| Text → TTS (first audio frame) | 200–500 ms |
| **Total floor** | **800 ms–1,800 ms** |

[(Latent.Space, "Realtime API: The Missing Manual")](https://www.latent.space/p/realtime-api) (retrieved 2026-06-15)

Each stage has its own queue, connection, and tokenization cost. The stages also can't overlap: you can't start TTS until GPT finishes, and GPT can't start until Whisper returns. The pipeline is sequential by design.

The Realtime API collapses all three stages into one stateful connection. The model receives audio tokens directly, reasons over them with full context, and emits audio tokens that begin playing within ~500 ms of your speech ending. [(Skywork, "OpenAI Realtime API vs WebRTC 2025")](https://skywork.ai/blog/openai-realtime-api-vs-webrtc-2025-which-to-choose) (retrieved 2026-06-15) No re-serialization. No queue handoffs.

<Callout type="warn">
The 500 ms TTFB is a target, not a guarantee. Tail latency on public internet can reach 800–1,200 ms. Production systems need latency budgets (Chapter 4) and verbal acknowledgment patterns ("Let me check that…") to fill gaps without dead air.
</Callout>

<KnowledgeCheck>
**Q1:** A classic pipeline runs Whisper (400 ms) → GPT-4o (500 ms) → Cartesia TTS (300 ms) sequentially. What is the minimum total latency before the user hears the first word?

a) 400 ms  
b) 900 ms  
c) 1,200 ms ✓  
d) It depends on the model

**Why:** All three stages run sequentially — they cannot overlap. 400 + 500 + 300 = 1,200 ms minimum, before any network overhead.

**Q2:** Which characteristic of the Realtime API primarily accounts for its latency advantage?

a) Faster GPT inference  
b) Compressed audio formats  
c) A single stateful session that eliminates inter-stage handoffs ✓  
d) WebRTC's UDP transport
</KnowledgeCheck>

---

## The Six Layers of a Production Voice Agent

A "voice agent" is not one component — it is a stack. Understanding all six layers is what separates a demo from a deployment.

```
┌──────────────────────────────────────┐
│  1. Client                           │  Browser / mobile / SIP phone
│  2. Edge media                       │  WebRTC or WebSocket transport
│  3. Agent runtime                    │  Your server: session mgmt, tools
│  4. Model API                        │  OpenAI Realtime API (gpt-realtime-2)
│  5. Tool plane                       │  Functions, databases, third-party APIs
│  6. Observability                    │  Latency tracing, cost metering, audit logs
└──────────────────────────────────────┘
```

**Layer 1 — Client.** The microphone and speaker. In a browser this is the Web Audio API; in a mobile app it is the platform audio stack; in telephony it is a SIP bridge. The client is responsible for audio capture quality (sample rate, noise suppression) and playback buffering. Bad audio in means bad understanding out, regardless of model quality.

**Layer 2 — Edge media.** How audio travels between the client and your server (and onward to the model API). The two options — WebRTC and WebSocket — are the first major architectural decision you will make, and the next section covers the trade-off.

**Layer 3 — Agent runtime.** Your server code. It manages the session lifecycle (connect, authenticate, configure), dispatches tool calls without blocking the audio stream, and handles reconnects. This is where most production bugs live.

**Layer 4 — Model API.** The OpenAI Realtime API. As of June 2026, the recommended model is `gpt-realtime-2` — released May 7, 2026 with GPT-5-class reasoning and a 128,000-token context window. [(OpenAI, "Advancing voice intelligence with new models in the API")](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api) (retrieved 2026-06-15) Its predecessor, `gpt-realtime`, reached general availability on August 28, 2025. [(OpenAI, "Introducing gpt-realtime")](https://openai.com/index/introducing-gpt-realtime) (retrieved 2026-06-15) Both support audio input, audio output, text, images, and function calling within a single session. [(OpenAI, "Realtime conversations guide")](https://developers.openai.com/api/docs/guides/realtime-conversations) (retrieved 2026-06-15)

**Layer 5 — Tool plane.** The functions your agent can call: database lookups, CRM reads, calendar writes. Tool latency directly affects perceived response time — the agent cannot speak its answer until the tool returns. For MCP-based tool orchestration patterns that apply here, see [[Claude MCP Mastery]] — the dispatch model transfers directly. Chapter 3 covers non-blocking tool dispatch in Realtime API sessions specifically.

**Layer 6 — Observability.** Timestamp logging at every event boundary, per-session cost metering, and audit logs of all tool calls. Without this layer you cannot diagnose latency regressions or catch runaway costs. Audio tokens are priced at approximately $32 per 1M input tokens and $64 per 1M output tokens for `gpt-realtime-2` [(OpenAI, "API Pricing")](https://openai.com/api/pricing) (retrieved 2026-06-15), with audio consuming roughly 800 tokens per minute per channel. A 10-minute session without any caching runs about $0.77 in audio tokens alone — multiply by concurrent sessions and observability becomes financial hygiene. Chapter 5 builds this out.

<KnowledgeCheck>
**Q:** Which layer is responsible for ensuring the agent recovers after a network drop without losing conversation context?

a) Layer 1 (Client)  
b) Layer 3 (Agent runtime) ✓  
c) Layer 4 (Model API)  
d) Layer 6 (Observability)

**Why:** Session lifecycle management — including reconnect logic and context preservation — lives in the agent runtime. The model API itself is stateless between connections.
</KnowledgeCheck>

---

## WebRTC vs WebSocket: One Decision, Many Consequences

The Realtime API supports both WebRTC and WebSocket as first-class transports with the same event schema. Your application-layer event handling code looks nearly identical — but the underlying behavior is very different.

| | WebRTC | WebSocket |
|---|---|---|
| **Transport** | UDP (DTLS/SRTP) | TCP |
| **Packet loss behavior** | Drops late packets; never stalls | Retransmits; can stall the stream |
| **Network adaptability** | Auto-adjusts bitrate and quality | Fixed bitrate |
| **Firewall traversal** | ICE/STUN/TURN handles it | Usually straightforward |
| **Latency vs reliability** | Favors latency | Favors reliability |
| **Best for** | Browser and mobile clients | Server-to-server, telephony bridges |

**Choose WebRTC** when your client is a browser or mobile app on variable network conditions — home WiFi, LTE, 5G. WebRTC's congestion control automatically degrades audio quality to maintain low latency rather than stalling. A dropped audio packet in a conversational stream is less harmful than a 200 ms TCP retransmission freeze. WebRTC also handles firewall traversal through ICE negotiation without you configuring anything.

**Choose WebSocket** when you are running server-to-server: a telephony bridge (SIP to Realtime API), a backend pipeline that post-processes audio before sending, or any scenario where you want fine-grained control over every frame. WebSocket is also the simpler transport for getting started — no ICE negotiation, no SDP offer/answer, just a connection and a message loop.

<Callout type="info">
Both transports use the same event schema. If you build on WebSocket first (as this chapter does) and later need WebRTC for a browser client, your event-handling code is unchanged. Only the connection setup differs.
</Callout>

<KnowledgeCheck>
**Q:** A customer service voice agent will run in a browser for consumers on inconsistent LTE connections. Which transport and why?

_Free response — model answer:_ WebRTC. UDP-based congestion control drops late packets rather than stalling. On poor LTE, TCP retransmission in a WebSocket can introduce 200–500 ms freezes that make the conversation feel broken. WebRTC degrades audio quality gracefully instead of blocking.
</KnowledgeCheck>

---

## Hello World: Your First Voice Session

Before any architecture, you need a working session. The script below connects to the Realtime API over WebSocket, streams a 3-second audio clip, and timestamps the first `response.output_audio.delta` event. That timestamp is your baseline RTT — you will optimize it in Chapter 4.

**Prerequisites:**
- OpenAI API key with Realtime API access (check [platform.openai.com](https://platform.openai.com) — Realtime is in the API dashboard)
- Python 3.10+ with `websockets` installed (`pip install 'websockets>=12.0'`) — `additional_headers` requires v12+
- A 3-second mono 24 kHz PCM16 audio clip saved as `hello.pcm` (raw bytes, no WAV header). Generate with: `ffmpeg -i any_audio.wav -f s16le -ar 24000 -ac 1 hello.pcm`

<RunPromptCell>
```python
# hello_realtime.py
import asyncio, json, os, time, base64, websockets

API_KEY = os.environ["OPENAI_API_KEY"]  # never hardcode keys; add `import os` at top
MODEL   = "gpt-realtime-2"
WS_URL  = f"wss://api.openai.com/v1/realtime?model={MODEL}"

async def main():
    headers = {
        "Authorization": f"Bearer {API_KEY}",
    }

    async with websockets.connect(WS_URL, additional_headers=headers) as ws:
        # 1. Configure session: audio in + audio out, manual turn detection
        await ws.send(json.dumps({
            "type": "session.update",
            "session": {
                "modalities": ["audio", "text"],
                "voice": "alloy",
                "turn_detection": None,   # we commit manually
            }
        }))

        # 2. Stream the PCM clip in 100 ms chunks (4800 bytes @ 24kHz 16-bit mono)
        with open("hello.pcm", "rb") as f:
            pcm = f.read()

        for i in range(0, len(pcm), 4800):
            chunk_b64 = base64.b64encode(pcm[i : i + 4800]).decode()
            await ws.send(json.dumps({
                "type": "input_audio_buffer.append",
                "audio": chunk_b64,
            }))

        # 3. Commit audio and request a response — start the clock here
        await ws.send(json.dumps({"type": "input_audio_buffer.commit"}))
        t0 = time.monotonic()
        await ws.send(json.dumps({"type": "response.create"}))
        print(f"[{t0:.3f}] Committed audio, waiting…")

        # 4. Wait for the first audio delta — that is the TTFA
        async for raw in ws:
            event = json.loads(raw)
            if event["type"] == "response.output_audio.delta":
                t1 = time.monotonic()
                print(f"[{t1:.3f}] First audio delta received")
                print(f"Time to first audio: {(t1 - t0) * 1000:.0f} ms")
                break

asyncio.run(main())
```

**Expected output (US datacenter, good broadband):**
```
[1718444400.123] Committed audio, waiting…
[1718444400.623] First audio delta received
Time to first audio: 500 ms
```
</RunPromptCell>

Write down your result. If you see 400–600 ms, your setup is healthy. Above 1,000 ms suggests a regional routing issue or an oversized audio chunk stalling the first parse — reduce your chunk size from 4800 to 2400 bytes and retry.

<Callout type="hot">
**Common error:** `{"type": "error", "error": {"message": "audio buffer empty"}}` — this means the base64 payload arrived malformed or the PCM file was a WAV file (with a 44-byte header). Strip the WAV header before encoding: `pcm = f.read()[44:]`.
</Callout>

---

## Session Lifecycle: What Happens Under the Hood

Every Realtime API session goes through the same lifecycle. Knowing this prevents the most common bugs.

1. **Connect** — WebSocket handshake to `wss://api.openai.com/v1/realtime?model=gpt-realtime-2`. Authenticate via `Authorization: Bearer <key>`.
2. **`session.created`** — Server confirms the session with default settings (voice, VAD threshold, modalities).
3. **`session.update`** — You configure the session before any audio: voice, VAD sensitivity, system instructions, tool definitions.
4. **`input_audio_buffer.append`** — Stream audio chunks continuously.
5. **Turn commit** — Either `input_audio_buffer.commit` (manual mode) or the server's VAD fires automatically.
6. **`response.create`** — Model starts generating. First `response.output_audio.delta` arrives in ~500 ms.
7. **`response.output_audio.delta` stream** — Base64-encoded PCM chunks. Decode and queue for playback.
8. **`response.done`** — Model finished its turn. Session stays open — continue the conversation.
9. **Close** — Either party closes the WebSocket. Maximum session duration: 60 minutes. [(OpenAI, "Realtime conversations guide")](https://developers.openai.com/api/docs/guides/realtime-conversations) (retrieved 2026-06-15)

Sessions carry a 128,000-token context window and consume approximately 800 audio tokens per minute per channel of speech. A 10-minute conversation with both parties active occupies roughly 16,000 audio tokens (8,000 input + 8,000 output) — comfortable within the context window, but track it if you are mixing audio with long tool results. [(OpenAI, "Advancing voice intelligence with new models in the API")](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api) (retrieved 2026-06-15)

<RunPromptCell>
```python
# Snippet: parse every event type and print the lifecycle sequence
async for raw in ws:
    event = json.loads(raw)
    print(f"{event['type']}")
```

**Expected event sequence for a single turn:**
```
session.created
session.updated
conversation.item.created
response.created
rate_limits.updated
response.output_item.added
conversation.item.created
response.content_part.added
response.audio_transcript.delta
response.output_audio.delta        ← first audio here, ~500 ms after response.create
response.output_audio.delta
…
response.output_audio.done
response.done
```
</RunPromptCell>

---

## What's Next

You have seen why the Realtime API beats the three-hop pipeline on latency, mapped all six production layers, and measured your first round-trip time. Chapter 2 builds on this: continuous audio capture, server-side VAD for automatic turn detection, and real-time audio playback.

If you want to understand agentic tool dispatch before reaching Chapter 3, see [[Claude Tool Use From Zero]] — the mental model for non-blocking tool execution is the same across all voice and text agent stacks. For a broader landscape of multi-modal AI runtimes to compare, [[Gemini Enterprise Agents]] covers Google's Live API architecture and where it diverges from the OpenAI approach.

Chapter 6 runs the cost comparison between Realtime API end-to-end, Whisper + GPT-4o-mini + Cartesia, and a self-hosted Kokoro stack. If you are still deciding on architecture before investing time in Chapters 2–5, read that chapter first.

---

## Chapter Summary

| Concept | Key takeaway |
|---|---|
| Classic pipeline | STT → LLM → TTS = 3 sequential hops, 800 ms–1,800 ms floor |
| Realtime API | Single stateful session, ~500 ms TTFA |
| Six layers | Client → Edge → Runtime → Model → Tools → Observability |
| WebRTC | UDP, browser/mobile, auto-adapts to variable networks |
| WebSocket | TCP, server-side and telephony, simpler to get started |
| Session lifecycle | connect → update → stream → commit → response → done |
| Context limits | 128K tokens, ~800 tokens/min/channel of audio, 60 min max session |
| Pricing ballpark | gpt-realtime-2: $32/1M audio input tokens, $64/1M audio output tokens |
