---
date: 2026-05-28
author: blog-author
ticket: KOEA-6693
vendor_tag: openai
content_type: article
status: draft-for-review
reading_time_min: 7
primary_query: "OpenAI Realtime API voice agents production"
contrarian_angle: "Realtime voice agents fail in production less because speech-to-speech is hard and more because teams under-budget the always-on audio loop."
sources:
  - https://developers.openai.com/api/docs/guides/realtime
  - https://developers.openai.com/api/docs/guides/voice-agents
  - https://developers.openai.com/api/docs/guides/realtime-models-prompting
  - https://platform.openai.com/docs/api-reference/realtime-sessions
  - https://openai.com/api/pricing/
  - https://github.com/openai/openai-realtime-agents
  - https://github.com/openai/openai-realtime-console
  - https://www.cartesia.ai/sonic
  - https://huggingface.co/hexgrad/Kokoro-82M
whats_new:
  - OpenAI Realtime voice agents should be budgeted as persistent audio sessions with tools, not as cheaper TTS wrappers around a chat app.
learning_objectives:
  - Choose WebRTC, WebSocket, or SIP based on where audio is captured and terminated.
  - Estimate the cost and fallback path for a production Realtime voice agent before launch.
schema:
  "@context": "https://schema.org"
  "@type": "Article"
  headline: "Deploy OpenAI Realtime Voice Agents by Budgeting the Audio Loop"
  author:
    "@type": "Person"
    name: "blog-author"
  datePublished: "2026-05-28"
  about:
    - "OpenAI Realtime API"
    - "Voice agents"
    - "Production AI systems"
---

# Deploy OpenAI Realtime Voice Agents by Budgeting the Audio Loop

OpenAI Realtime API voice agents are production-ready when you treat them as live audio systems: pick the transport first, keep tools behind server controls, tune voice activity detection, and model cost by session length. OpenAI documents Realtime as the path for low-latency voice agents that listen, reason, speak, and call tools, with WebRTC for browser/mobile audio, WebSocket for server media pipelines, and SIP for telephony ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

The missed point is economic, not conversational. Most teams ask whether Realtime replaces a Whisper -> LLM -> TTS chain. It often does for natural turn-taking. But the production question is whether your margin survives a persistent audio session whose history, interruptions, retries, and tool delays are all happening while the meter runs. OpenAI prices GPT-Realtime-2 audio at $32 per 1M input tokens, $0.40 per 1M cached input tokens, and $64 per 1M output tokens ([OpenAI pricing](https://openai.com/api/pricing/)). That is a different business model from a request/response chatbot.

## Choose WebRTC for apps, WebSocket for media backends, and SIP for phones

The connection method decides your latency budget before the model sees a token. OpenAI""'s own Realtime guide says to use WebRTC when browser or mobile clients capture and play audio directly, WebSocket when a server already receives raw audio from a media pipeline, and SIP for telephony voice agents ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

That split matters because """voice agent""" is not one architecture. A sales demo in a browser wants WebRTC so the client can handle real-time media behavior. A contact-center integration that already receives RTP or another backend audio stream may want WebSocket from the server side. A phone agent should not fake telephony through a browser stack when OpenAI exposes SIP as a connection method.

The practical deployment shape is a thin client plus a server authority. OpenAI""'s Realtime console is a React app for inspecting, building, and debugging Realtime sessions, and its repository points developers toward a separate Realtime Agents demo for more advanced patterns ([openai-realtime-console](https://github.com/openai/openai-realtime-console)). Do not ship a browser that owns the main API key. Mint short-lived session credentials from your backend, bind tools to server-side policy, and log every tool result as a business event.

## Keep tool calls server-controlled, even when speech is instant

Realtime voice does not make agent design disappear; it makes bad agent design audible. OpenAI""'s voice-agents guide says the voice surface changes transport and audio loop, while the core workflow decisions still use tools, running agents, orchestration, guardrails, human review, integrations, and observability ([OpenAI voice agents](https://developers.openai.com/api/docs/guides/voice-agents)).

That is the right mental model: choose the audio architecture first, then design the agent as if it were text. Read-only tools can execute immediately. Mutating tools should confirm aloud, especially for money movement, booking, cancellation, medical intake, or account changes. For long-running calls, the voice agent should use short preambles such as """I""'m checking that now""" rather than dead air; OpenAI""'s Realtime prompting guide explicitly covers preambles, tool behavior, entity capture, and a `wait_for_user` tool for silence, background noise, hold music, or side conversations ([Realtime prompting guide](https://developers.openai.com/api/docs/guides/realtime-models-prompting)).

OpenAI""'s Realtime Agents demo shows why specialization matters: the sequential handoff pattern transfers a user between specialized realtime agents, with handoffs coordinated through tool calls and `session.update` events that swap instructions and tools ([openai-realtime-agents](https://github.com/openai/openai-realtime-agents)). That is not just cleaner code. It keeps the active instruction and tool surface smaller, which matters in voice because long prompts and tool catalogs compete with latency and context budget.

## Model cost by session, not by answer

The cheapest voice-agent mistake is pricing only the first response. A Realtime session stays open while the app sends audio, receives events, and updates state; OpenAI describes voice-agent sessions as the standard conversation lifecycle on `/v1/realtime`, where the client sends audio or text and listens for responses, tool calls, and session events ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

Build a spreadsheet with five columns before you write code: average call length, user-talk percentage, assistant-talk percentage, tool delay seconds, and abandonment/retry rate. Then separate three budgets:

1. **Transport latency:** microphone capture, network, relay, playback.
2. **Reasoning latency:** model effort, prompt size, tool choice, guardrail pass.
3. **Recovery latency:** interruptions, barge-in, retries, escalation.

OpenAI""'s GPT-Realtime-2 pricing makes cached audio input much cheaper than uncached input, but output audio is still priced separately ([OpenAI pricing](https://openai.com/api/pricing/)). That should change your UX. Keep the agent concise, do not narrate database fields, and summarize state after tool calls instead of reading full records. A voice agent that talks twice as much is not just annoying; it is structurally more expensive.

## Use TTS fallback for degradation, not as a fake Realtime clone

A fallback path should preserve the user journey when Realtime is unavailable or over budget; it should not pretend to be the same product. Cartesia positions Sonic as a real-time TTS model with sub-90ms latency and multilingual support ([Cartesia Sonic](https://www.cartesia.ai/sonic)). Kokoro-82M is an open text-to-speech model with an Apache 2.0 license on Hugging Face ([Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M)). Both can be useful in a fallback stack, but neither turns a text pipeline into native speech-to-speech reasoning.

Use three tiers:

1. **Tier A:** Realtime API for live support, interruption, tool use, and voice-to-action workflows.
2. **Tier B:** STT -> text agent -> fast TTS when cost or availability requires degradation.
3. **Tier C:** self-hosted or cached TTS for predictable prompts such as order status, queue updates, and post-call summaries.

This is where the contrarian answer lands: Realtime is the premium interactive surface, not the universal audio backend. If the user only needs a generated spoken notification, request-based speech generation is the cheaper, simpler primitive. OpenAI""'s Realtime overview makes the same distinction: realtime sessions fit live audio that needs low latency, while request-based audio APIs fit bounded files or generated speech that does not need a live session ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

## Start production with ephemeral Realtime credentials

The first runnable production step is not "open a microphone." It is creating a server endpoint that mints a short-lived Realtime client secret and keeps your main API key off the device.

OpenAI's API reference describes `POST /v1/realtime/client_secrets` as the endpoint for generating ephemeral client secrets for client-side Realtime applications, so this belongs on your backend rather than in frontend code ([Realtime client secrets](https://platform.openai.com/docs/api-reference/realtime-sessions)).

<curl>
curl https://api.openai.com/v1/realtime/client_secrets \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "session": {
      "type": "realtime",
      "model": "gpt-realtime-2",
      "instructions": "You are a concise support voice agent. Confirm before account changes.",
      "audio": {
        "output": { "voice": "marin" }
      }
    }
  }'
</curl>

Expected output shape:

```json
{
  "value": "ek_...",
  "expires_at": 1770000000,
  "session": {
    "type": "realtime",
    "model": "gpt-realtime-2"
  }
}
```

Put this behind your own `/realtime/session` endpoint, attach the user ID, allowed tool list, budget bucket, and call purpose, then let the browser connect with the ephemeral key. That one boundary gives you key hygiene, per-call policy, and the place to enforce fallbacks before a bad session becomes an expensive session.

## KnowledgeCheck

Question: A browser-based support agent needs live interruption, account lookups, and occasional cancellation requests. Which production decision should come first?

Answer: Choose the audio transport and authority boundary first: WebRTC from browser/mobile audio to a server-controlled Realtime session, with read-only tools allowed immediately and cancellation tools confirmed before execution. The model prompt comes after that boundary is clear.

If you are building this for real, the next skill is not prompt polishing; it is designing tools, handoffs, guardrails, and observability around a voice loop. That is the production layer covered in [[course/openai-agents-sdk-mastery]].
