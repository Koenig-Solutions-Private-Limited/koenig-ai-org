---
title: "Use OpenAI Realtime API when voice agents need interruptions, tools, and sub-second turns"
slug: openai-realtime-api-voice-agents-2026
description: "A production guide to OpenAI Realtime API voice agents in 2026: latency, cost, PCM16 and G.711 audio formats, interruption handling, rate limits, the 15-minute session cap, and when to choose Realtime over a Whisper plus TTS pipeline."
hero_image: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1600&q=80"
tags: [openai, voice-agents, realtime-api, production]
author: koenig-ai-academy
status: draft
date: 2026-05-14
ticket: KOEA-1252
vendor_tag: openai
content_type: article
reading_time_min: 11
primary_query: "openai realtime api voice agents production patterns 2026"
contrarian_angle: "Realtime API is not mainly a faster TTS endpoint. Its production advantage is collapsing turn detection, interruption repair, telephony audio formats, tool calls, and session state into one speech-native loop."
learning_objectives:
  - "Choose between OpenAI Realtime API and a self-assembled Whisper plus TTS pipeline using latency, cost, and product requirements."
  - "Identify the production gotchas that break voice agents: PCM16 and G.711 audio chunks, interruption truncation, rate limits, and 15-minute sessions."
  - "Estimate Realtime API session cost and compare it with Cartesia Sonic 3 and lower-cost STT plus TTS pipelines."
whats_new:
  - "OpenAI Realtime is now a production voice-agent platform, not just a speech demo: the decision turns on barge-in, tools, telephony, and context cost."
references:
  - url: https://platform.openai.com/docs/guides/rate-limits
    title: "OpenAI rate limits guide"
  - url: https://platform.openai.com/docs/guides/realtime-models-prompting
    title: "OpenAI Realtime models prompting guide"
  - url: https://platform.openai.com/docs/changelog
    title: "OpenAI platform changelog"
  - url: https://www.latent.space/p/realtime-api
    title: "Latent Space: Realtime API latency and production notes"
  - url: https://cartesia.ai/vs/cartesia-vs-openai-tts
    title: "Cartesia Sonic 3 vs OpenAI TTS benchmark"
  - url: https://www.eesel.ai/blog/realtime-api-vs-whisper-vs-tts-api
    title: "Eesel: Realtime API vs Whisper vs TTS API"
  - url: https://cartesia.ai/sonic
    title: "Cartesia Sonic product page"
  - url: https://inworld.ai/resources/best-voice-ai-tts-apis-for-real-time-voice-agents-2026-benchmarks
    title: "Inworld voice AI and TTS APIs 2026 benchmark"
  - url: https://docs.workadventu.re/blog/realtime-api-interrupting-the-model/
    title: "WorkAdventure: Interrupting the OpenAI Realtime model"
  - url: https://community.openai.com/t/realtime-api-instruction-limit-16-384-tokens-is-too-low-for-production-voice-agents-with-tool-calling/1378932
    title: "OpenAI Community: Realtime instruction limit discussion"
faq:
  - question: "Is OpenAI Realtime API better than Whisper plus TTS for voice agents?"
    answer: "It is better for live agents that need sub-second turns, barge-in, prosody, tools, and telephony. Whisper plus TTS remains better for cheaper batch, push-to-talk, or modular voice workflows."
  - question: "How fast is OpenAI Realtime API compared with a traditional voice pipeline?"
    answer: "The synthesis cites roughly 500ms TTFB and an 800ms target for Realtime, compared with roughly 2-3 seconds for STT to LLM to TTS pipelines."
  - question: "What production limit should teams plan around first?"
    answer: "Plan around the 15-minute session limit and interruption truncation first. Both affect real calls before model quality becomes the limiting factor."
---

# Use OpenAI Realtime API when voice agents need interruptions, tools, and sub-second turns

OpenAI Realtime API is the better production choice for voice agents when the user experience depends on natural interruptions, speech-to-speech latency around 500-800ms, live tool calls, and phone or browser audio transport. A self-assembled Whisper plus LLM plus TTS pipeline is still cheaper and more modular, but it usually lands closer to 2-3 seconds end to end and makes your team own turn detection, playback sync, and conversation repair.[1][4][6]

The contrarian point is that Realtime is not primarily a faster TTS product. Cartesia Sonic 3 can beat OpenAI on pure time-to-first-audio, with the synthesis citing 40ms Turbo and 90ms Sonic latency against OpenAI TTS around 199ms.[5][7] Realtime wins a different contest: it turns voice into one stateful session where audio input, model reasoning, speech output, tool calls, interruption handling, and telephony formats can move together.

## Choose Realtime for live conversation; choose pipelines for cheap modular speech

The old voice-agent stack has three obvious boxes: speech-to-text, reasoning, and text-to-speech. A user speaks, Whisper or another STT engine transcribes the utterance, an LLM decides what to do, and a TTS engine speaks the response. That architecture is understandable, debuggable, and vendor-flexible. It is also why many early voice agents felt like voice wrappers around chatbots rather than conversations.

The synthesis summarizes the practical gap: traditional STT to LLM to TTS chains tend to produce 2-3 seconds of end-to-end latency, lose prosody and emotion between transcription and response, and handle interruptions poorly.[6] Once speech has been flattened into text, the model no longer knows whether the user sounded confused, amused, urgent, or halfway through a sentence. You can reconstruct some of that with metadata, confidence scores, or custom prompts, but then you are rebuilding a speech-native interaction loop out of separate services.

Realtime API changes the integration boundary. The synthesis describes a single Realtime endpoint for `gpt-realtime-2`, native audio I/O, server VAD and endpointing, and tool calls mid-stream.[2][4] Instead of treating audio as a preprocessing step, Realtime treats speech as part of the model session. That matters for live support, tutoring, translation, scheduling, IVR, sales intake, and any agent that must respond before the user feels the turn has died.

This does not make Whisper plus TTS obsolete. It narrows where it belongs. Use a pipeline when the job is batch transcription, voicemail summarization, narrated report generation, asynchronous coaching feedback, or a push-to-talk workflow where users expect a pause. Use Realtime when the product promise is "talk to this agent" rather than "submit audio and receive a spoken answer."

<RunPromptCell
  model="gpt-5.5"
  prompt="Given a voice product with these requirements: inbound phone calls, callers interrupt frequently, the agent must call CRM tools, and calls average 6 minutes. Recommend OpenAI Realtime API or a Whisper plus TTS pipeline. Include latency, cost, and operational risk in the answer."
  expectedOutput="A recommendation favoring Realtime for the live phone-agent case, while explicitly warning that cost rises with session length and that long calls need summarization or handoff design."
/>

## Measure round-trip TTFB, not just TTS TTFA

The most common benchmark mistake is comparing only TTS time-to-first-audio. TTFA is useful when you are buying a TTS engine, but it is incomplete for a voice agent. A real user waits through capture, endpointing, model reasoning, audio generation, playback buffering, and sometimes network jitter. The metric you need is round-trip time to first meaningful response.

The synthesis gives the headline numbers: Realtime around 500ms TTFB in US conditions, with an 800ms target for end-to-end conversational quality.[4] It contrasts that with a traditional pipeline around 2-3 seconds, typically composed of STT latency, LLM latency, and TTS latency.[6] The exact numbers will move with region, model, device, transport, and utterance length, but the architectural difference is stable: a chained pipeline has serial stages, while Realtime can behave like a speech-native session.

Cartesia Sonic 3 is still the baseline worth respecting. The Cartesia comparison in the synthesis cites 40ms Turbo and 90ms Sonic latency, while Cartesia's Sonic page positions it for streaming TTS with emotes, laughter, 40+ languages, and a roughly $0.03/min TTS-only price.[5][7] Our earlier latency article, [[voice-agents-2026-tts-latency-benchmark]], makes the same product-level point: Cartesia can be the fastest paid TTS choice, but the voice-agent bottleneck is often the full turn, not the final audio renderer.

That means you should instrument four timestamps in production:

| Measurement | What it tells you | Typical fix |
|---|---|---|
| User speech end to model response start | Endpointing and reasoning latency | Tune VAD, lower `reasoning.effort`, shorten prompts |
| First audio delta to playback start | Client buffering and audio output latency | Reduce buffer size, avoid TCP stalls on client audio |
| User interruption to assistant stop | Barge-in quality | Wire interruption events to playback cancellation |
| Full turn round trip | What the user actually feels | Optimize transport, prompts, and session state together |

Bluetooth headsets can add another 200-300ms in real deployments according to the synthesis. That sounds mundane, but it can erase much of the advantage you thought you bought with a faster model. For kiosks, call centers, or benchmark labs, test with the hardware you will ship.

<KnowledgeCheck
  question="Why is Cartesia Sonic 3's 40-90ms TTFA not enough to prove a Cartesia pipeline will feel faster than OpenAI Realtime?"
  options={[
    "Because Cartesia cannot generate any audio chunks.",
    "Because TTFA measures only the TTS stage, while a voice agent also pays STT, LLM, endpointing, buffering, and interruption costs.",
    "Because Realtime does not use audio tokens.",
    "Because Whisper transcription is always slower than 3 seconds."
  ]}
  correctIdx={1}
  explanation="TTFA is a TTS metric. For a voice agent, the user feels the full round trip from finished speech to useful response, plus how quickly the system handles interruptions."
/>

## Budget for session cost, not only per-minute audio

Realtime's cost model is the part teams underestimate. The synthesis cites Realtime input audio at $32 per 1M input audio tokens, cached input at $0.40 per 1M, and output audio at $64 per 1M.[4] It also summarizes estimated conversational costs around $0.11 for 1 minute, $0.92 for 5 minutes, and $5.28 for 15 minutes because history growth compounds over longer sessions.[4]

Those estimates are not the same as pricing a single TTS response. In a live agent, each new response sees conversation state that came before it. If you let a call run for 15 minutes while keeping every turn, every tool result, and every verbose instruction in context, your marginal response cost grows. The cost curve is why production Realtime agents need summarization, truncation, and routing logic, not just a billing alert.

A self-assembled pipeline can be far cheaper. The synthesis estimates pipeline cost around $0.01-0.05/min, combining STT, cheaper text-model inference, and TTS.[4] Cartesia Sonic 3 is cited at $0.03/min for TTS-only use.[7] If you are generating spoken summaries, audio lessons, or scripted outbound reminders, those economics are hard to ignore.

The practical calculation is not "Realtime is expensive" versus "pipeline is cheap." It is this:

| Scenario | Better default | Why |
|---|---|---|
| 30-second support triage with tool lookup | Realtime | Latency and interruption quality matter more than raw media cost |
| 8-minute customer-service call | Realtime with summarization | Live turn-taking matters, but context cost must be controlled |
| Batch transcription and spoken summary | Whisper plus TTS | No live turn-taking requirement |
| Pure ultra-low-latency speech playback | Cartesia Sonic 3 | TTS speed matters; no reasoning loop needed |
| Custom voice, language, or on-device speech | Pipeline | Vendor control and deployment flexibility matter |

At scale, add rate limits to the model. OpenAI rate limits are measured in requests per minute, tokens per minute, requests per day, and tokens per day, with tiers based on spend.[1] The synthesis specifically calls out headers such as `x-ratelimit-remaining-requests` and `x-ratelimit-reset-tokens`.[1] For a normal text API, you can often retry a failed request. For a live call, a rate-limit failure is a product failure unless you route around it.

Your production cost plan should therefore include four controls: short default sessions, explicit summaries before context gets large, per-project rate-limit isolation between development and production, and a non-Realtime path for work that does not need live speech.

## Build for PCM16, G.711, VAD, and interruption repair from day one

The production gotchas are not glamorous. They are audio format, session duration, prompt size, and what happens when someone interrupts the model.

The synthesis names the audio formats directly: 24kHz PCM16 base64 chunks for standard Realtime audio, and G.711 for telephony.[4] If you are coming from web development, the base64 event stream can look like an implementation detail. It is not. Chunk size, buffering, resampling, and transport choice shape perceived latency. In the synthesis, input arrives through events like `input_audio_buffer.append`; output arrives as `response.audio.delta` chunks.[4]

For browser and mobile clients, the architecture pattern is a WebRTC path for user media and a controlled backend path to OpenAI. The synthesis notes the WebRTC proxy architecture and the reason: WebRTC over UDP handles interactive audio better than raw client WebSocket paths that can suffer TCP head-of-line blocking.[4] For phone systems, use G.711 and SIP-oriented designs rather than forcing PSTN audio through a web-media mental model.[3][4]

VAD is the second failure point. If silence detection is too aggressive, the model starts speaking while the user is still thinking. If it is too slow, every turn feels delayed. The synthesis flags `silence_duration_ms=800-1000ms` as a practical tuning range and calls out `reasoning.effort=minimal/low` as a latency optimization.[2][4] The right setting depends on the product. A medical intake agent should wait longer than a drive-through ordering assistant.

Interruption handling is where demo code usually breaks. The synthesis cites the WorkAdventure implementation note: when the user interrupts, revert the model conversation with `conversation.item.truncate` and sync the audio playback promise so you do not keep context for words the user never heard.[9] If the assistant says, "Your appointment is at four..." and the user interrupts after "Your appointment," your conversation state must not pretend the user heard the rest.

Session limits are the third thing to design around. The synthesis cites a 15-minute session limit and a production complaint about a 16,384-token instruction limit for Realtime agents with tool calling.[4][10] Whether or not your calls usually last 15 minutes, you need a reconnection strategy before launch: summarize the call, store tool state outside the session, open a fresh session, and replay only what the next turn needs.

<RunPromptCell
  model="gpt-5.5"
  prompt="Write a production checklist for an OpenAI Realtime voice agent that uses browser audio and later adds telephony. Include audio format, transport, VAD tuning, interruption handling, session limit, and rate-limit monitoring."
  expectedOutput="A checklist that mentions PCM16 for web/app audio, G.711 for telephony, WebRTC for client audio, VAD tuning, conversation.item.truncate on interruption, 15-minute session rollover, and x-ratelimit monitoring."
/>

## Use a decision tree before you commit to Realtime

The simplest decision tree is also the most useful:

1. Does the user need to interrupt the agent naturally?
2. Does the agent need to call tools inside the spoken turn?
3. Does the product need sub-second conversational feel?
4. Will the agent run on phone calls, live translation, support, coaching, or tutoring?
5. Is engineering time more expensive than the extra Realtime media cost?

If most answers are yes, start with Realtime. If most answers are no, start with a pipeline.

Now run the reverse test:

1. Is the workload batch, asynchronous, or push-to-talk?
2. Is per-minute cost the primary constraint?
3. Do you need a custom TTS vendor such as Cartesia Sonic 3?
4. Do you need specialized STT for accents, noise, or domain vocabulary?
5. Would losing a live session be acceptable because each step can be retried?

If most answers are yes, a Whisper plus TTS pipeline is probably the better architecture.

This comparison also keeps vendor claims in the right lane. Cartesia Sonic 3 is an excellent TTS benchmark and should be in your test set, especially if pure speech playback latency is the job.[5][7] Realtime should be judged on speech-native agency: tool calls, prosody, endpointing, interruptions, session control, and total turn latency. Whisper plus TTS should be judged on modularity, cost, and operational transparency.

<KnowledgeCheck
  question="A team is building a weekly voice-summary generator. Users upload recordings, receive a written summary, and optionally listen to a narrated version later. Which architecture is the better default?"
  options={[
    "OpenAI Realtime API, because all audio products need sub-second turn-taking.",
    "Whisper plus LLM plus TTS, because the workflow is asynchronous and does not need live interruption handling.",
    "Cartesia Sonic 3 only, because no transcription is needed.",
    "A SIP Realtime session, because uploaded recordings are phone calls."
  ]}
  correctIdx={1}
  explanation="The workload is batch-like. A pipeline keeps cost lower and lets each stage be retried without paying for a live speech session."
/>

## Ship the first production version with observability and fallbacks

The minimum viable production voice agent is not just a Realtime session that works once. It is a system that can tell you why a call felt slow, why a user interrupted twice, why rate limits spiked, and when a session needs to be rolled over.

Log at least these events: session start, transport type, audio format, VAD settings, first user audio chunk, detected end of user turn, first model response event, first audio delta, playback start, interruption event, truncate event, tool call start and end, rate-limit headers, summary creation, and session close. These are the timestamps that let you distinguish model latency from media latency.

The synthesis also points to prompting patterns that are easy to miss: use lower `reasoning.effort` for latency-sensitive turns, use preambles to mask tool latency, read entities such as account numbers digit by digit, and use a no-op `wait_for_user` tool when the model needs to stop speaking and wait.[2] Voice prompting is not chat prompting read aloud. The prompt has to manage timing, turn boundaries, and what the user actually hears.

Finally, keep a pipeline fallback. If rate limits are tight, if a user uploads a long recording, or if a call becomes asynchronous, route that work through STT plus text plus TTS. Realtime is the premium live path. It should not become the only audio path in your system.

The practical takeaway: use OpenAI Realtime when speech is the interface. Use Whisper plus TTS when speech is just an input or output format. Use Cartesia Sonic 3 when TTS latency is the whole problem. For implementation practice that connects these choices to tool calling and agent orchestration, continue with [[course/openai-agents-sdk-mastery]] and keep [[voice-agents-2026-tts-latency-benchmark]] nearby as the TTS comparison baseline.

## Further reading

[1] OpenAI rate limits guide: https://platform.openai.com/docs/guides/rate-limits

[2] OpenAI Realtime models prompting guide: https://platform.openai.com/docs/guides/realtime-models-prompting

[3] OpenAI platform changelog: https://platform.openai.com/docs/changelog

[4] Latent Space Realtime API production notes: https://www.latent.space/p/realtime-api

[5] Cartesia Sonic 3 vs OpenAI TTS benchmark: https://cartesia.ai/vs/cartesia-vs-openai-tts

[6] Eesel Realtime API vs Whisper vs TTS API: https://www.eesel.ai/blog/realtime-api-vs-whisper-vs-tts-api

[7] Cartesia Sonic product page: https://cartesia.ai/sonic

[8] Inworld voice AI and TTS APIs 2026 benchmark: https://inworld.ai/resources/best-voice-ai-tts-apis-for-real-time-voice-agents-2026-benchmarks

[9] WorkAdventure interrupt handling in Realtime API: https://docs.workadventu.re/blog/realtime-api-interrupting-the-model/

[10] OpenAI Community Realtime instruction limit discussion: https://community.openai.com/t/realtime-api-instruction-limit-16-384-tokens-is-too-low-for-production-voice-agents-with-tool-calling/1378932
