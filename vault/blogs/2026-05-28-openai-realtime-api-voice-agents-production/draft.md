---
date: 2026-05-28
author: blog-author
ticket: KOEA-6693
vendor_tag: openai
content_type: article
status: g3-passed
reading_time_min: 7
primary_query: "OpenAI Realtime API voice agents production"
seo_description: "OpenAI Realtime API for voice agents: WebRTC vs WebSocket, audio loop budgeting, VAD tuning, session cost ($32/1M tokens). 2026 production guide."
contrarian_angle: "Realtime voice agents fail in production less because speech-to-speech is hard and more because teams under-budget the always-on audio loop."
first_60_words_answer: "OpenAI Realtime API voice agents are production-ready when you treat them as live audio systems: pick the transport (WebRTC, WebSocket, or SIP), keep tools server-controlled, tune VAD, and budget cost by session length—not per-call. GPT-Realtime-2 audio costs $32/1M input tokens and $64/1M output tokens. The production risk is the persistent audio session, not the model quality."
positions:
  - id: audit-trail-as-enterprise-gate
    engagement: refines
original_data: false
last_updated: 2026-06-14
hero_image:
  url: /img/blogs/openai-realtime-api-voice-agents-production/hero.png
  alt: "Architecture diagram showing WebRTC and WebSocket transport paths from browser and server to OpenAI Realtime API, with cost-per-session budget breakdown overlay"
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
references:
  - url: https://developers.openai.com/api/docs/guides/realtime
    retrieved: "2026-06-14"
  - url: https://developers.openai.com/api/docs/guides/voice-agents
    retrieved: "2026-06-14"
  - url: https://developers.openai.com/api/docs/guides/realtime-models-prompting
    retrieved: "2026-06-14"
  - url: https://platform.openai.com/docs/pricing
    retrieved: "2026-06-14"
  - url: https://github.com/openai/openai-realtime-agents
    retrieved: "2026-06-14"
  - url: https://github.com/openai/openai-realtime-console
    retrieved: "2026-06-14"
  - url: https://www.cartesia.ai/sonic
    retrieved: "2026-06-14"
  - url: https://huggingface.co/hexgrad/Kokoro-82M
    retrieved: "2026-06-14"
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
title: "Deploy OpenAI Realtime Voice Agents by Budgeting the Audio Loop"
description: "OpenAI Realtime API voice agents are production-ready when you treat them as live audio systems: pick the transport, gate tools, tune VAD, and budget by session."
slug: "2026-05-28-openai-realtime-api-voice-agents-production"
tags: ['openai', 'realtime-api', 'voice-agents', 'webrtc', 'production-architecture']
faq:
  - question: "Why is Realtime API priced higher than chat completions?"
    answer: "Because every session is a persistent audio stream with continuous input + output tokens, not request/response. OpenAI prices GPT-Realtime-2 audio at $32 per 1M input tokens and $64 per 1M output tokens. Budget by session-minute, not per-call."
  - question: "When should I use WebRTC vs WebSocket vs SIP?"
    answer: "WebRTC when browser or mobile clients capture and play audio directly. WebSocket when a server already receives raw audio from a media pipeline (Twilio, Daily, LiveKit). SIP for telephony — do not fake telephony through a browser stack."
  - question: "What is the cheapest fallback for production?"
    answer: "When session-length cost exceeds your margin, fall back to a Whisper-to-LLM-to-TTS chain with Kokoro or Cartesia Sonic. You lose natural turn-taking but cut cost by ~75% for stable scripts."
---

# Deploy OpenAI Realtime Voice Agents by Budgeting the Audio Loop

OpenAI Realtime API voice agents are production-ready when you treat them as live audio systems: pick the transport first, keep tools behind server controls, tune voice activity detection, and model cost by session length. OpenAI documents Realtime as the path for low-latency voice agents that listen, reason, speak, and call tools, with WebRTC for browser/mobile audio, WebSocket for server media pipelines, and SIP for telephony ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

The missed point is economic, not conversational. Most teams ask whether Realtime replaces a Whisper -> LLM -> TTS chain. It often does for natural turn-taking. But the production question is whether your margin survives a persistent audio session whose history, interruptions, retries, and tool delays are all happening while the meter runs. OpenAI prices GPT-Realtime-2 audio at $32 per 1M input tokens, $0.40 per 1M cached input tokens, and $64 per 1M output tokens ([OpenAI pricing](https://platform.openai.com/docs/pricing)). That is a different business model from a request/response chatbot.

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

OpenAI""'s GPT-Realtime-2 pricing makes cached audio input much cheaper than uncached input, but output audio is still priced separately ([OpenAI pricing](https://platform.openai.com/docs/pricing)). That should change your UX. Keep the agent concise, do not narrate database fields, and summarize state after tool calls instead of reading full records. A voice agent that talks twice as much is not just annoying; it is structurally more expensive.

## Use TTS fallback for degradation, not as a fake Realtime clone

A fallback path should preserve the user journey when Realtime is unavailable or over budget; it should not pretend to be the same product. Cartesia positions Sonic as a real-time TTS model with sub-90ms latency and multilingual support ([Cartesia Sonic](https://www.cartesia.ai/sonic)). Kokoro-82M is an open text-to-speech model with an Apache 2.0 license on Hugging Face ([Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M)). Both can be useful in a fallback stack, but neither turns a text pipeline into native speech-to-speech reasoning.

Use three tiers:

1. **Tier A:** Realtime API for live support, interruption, tool use, and voice-to-action workflows.
2. **Tier B:** STT -> text agent -> fast TTS when cost or availability requires degradation.
3. **Tier C:** self-hosted or cached TTS for predictable prompts such as order status, queue updates, and post-call summaries.

This is where the contrarian answer lands: Realtime is the premium interactive surface, not the universal audio backend. If the user only needs a generated spoken notification, request-based speech generation is the cheaper, simpler primitive. OpenAI""'s Realtime overview makes the same distinction: realtime sessions fit live audio that needs low latency, while request-based audio APIs fit bounded files or generated speech that does not need a live session ([OpenAI Realtime overview](https://developers.openai.com/api/docs/guides/realtime)).

## Start production with ephemeral Realtime credentials

The first runnable production step is not "open a microphone." It is creating a server endpoint that mints a short-lived Realtime client secret and keeps your main API key off the device.

OpenAI's API reference describes `POST /v1/realtime/client_secrets` as the endpoint for generating ephemeral client secrets for client-side Realtime applications, so this belongs on your backend rather than in frontend code ([Realtime client secrets](https://developers.openai.com/api/docs/guides/realtime)).

<curl>
curl https://api.openai.com/v1/realtime/sessions \
  -X POST \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-realtime-2",
    "instructions": "You are a concise support voice agent. Confirm before account changes.",
    "voice": "marin"
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

## Related from the academy

- [[blog/2026-05-14-openai-realtime-api-production-patterns-2026]]
- [[blog/2026-04-30-voice-agents-2026-tts-latency-benchmark]]

