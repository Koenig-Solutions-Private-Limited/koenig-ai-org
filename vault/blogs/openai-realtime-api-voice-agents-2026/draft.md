---
title: "Use OpenAI Realtime When Turn-Taking Is the Product"
slug: openai-realtime-api-voice-agents-2026
description: "OpenAI Realtime API is worth its premium when interruption handling, telephony, and live session state matter more than raw media cost. These are the production patterns that decide it."
date: 2026-05-12
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-1252
vendor_tag: openai
content_type: article
status: awaiting-g0
reading_time_min: 7
hero_image: auto:flux
tags: [openai, realtime-api, voice-agents, webrtc, sip, vad]
primary_query: "openai realtime api for voice agents production patterns 2026"
contrarian_angle: "The Realtime API is not mainly a latency trick. Its real production advantage is collapsing interruption handling, transport, telephony, and session state into one system you do not have to assemble yourself."
sources:
  - https://developers.openai.com/api/docs/guides/realtime-conversations
  - https://developers.openai.com/api/docs/guides/realtime-vad
  - https://developers.openai.com/api/docs/guides/realtime-websocket
  - https://developers.openai.com/api/docs/guides/realtime-sip
  - https://developers.openai.com/api/docs/guides/realtime-costs
  - https://developers.openai.com/api/docs/models/gpt-realtime-2
  - https://developers.openai.com/api/docs/models/gpt-4o-mini-tts
  - https://developers.openai.com/api/docs/models/gpt-4o-mini-transcribe
  - https://openai.com/index/introducing-gpt-realtime/
  - https://openai.com/index/delivering-low-latency-voice-ai-at-scale/
  - https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api/
  - https://developers.openai.com/cookbook/examples/context_summarization_with_realtime_api
references:
  - n: 1
    title: "Realtime conversations — OpenAI API docs"
    url: https://developers.openai.com/api/docs/guides/realtime-conversations
    retrieved: 2026-05-12
  - n: 2
    title: "Voice activity detection (VAD) — OpenAI API docs"
    url: https://developers.openai.com/api/docs/guides/realtime-vad
    retrieved: 2026-05-12
  - n: 3
    title: "Realtime API with WebSocket — OpenAI API docs"
    url: https://developers.openai.com/api/docs/guides/realtime-websocket
    retrieved: 2026-05-12
  - n: 4
    title: "Realtime API with SIP — OpenAI API docs"
    url: https://developers.openai.com/api/docs/guides/realtime-sip
    retrieved: 2026-05-12
  - n: 5
    title: "Managing costs — OpenAI API docs"
    url: https://developers.openai.com/api/docs/guides/realtime-costs
    retrieved: 2026-05-12
  - n: 6
    title: "GPT-Realtime-2 model page — OpenAI API docs"
    url: https://developers.openai.com/api/docs/models/gpt-realtime-2
    retrieved: 2026-05-12
  - n: 7
    title: "GPT-4o mini TTS model page — OpenAI API docs"
    url: https://developers.openai.com/api/docs/models/gpt-4o-mini-tts
    retrieved: 2026-05-12
  - n: 8
    title: "GPT-4o mini Transcribe model page — OpenAI API docs"
    url: https://developers.openai.com/api/docs/models/gpt-4o-mini-transcribe
    retrieved: 2026-05-12
  - n: 9
    title: "Introducing gpt-realtime and Realtime API updates for production voice agents — OpenAI"
    url: https://openai.com/index/introducing-gpt-realtime/
    retrieved: 2026-05-12
  - n: 10
    title: "How OpenAI delivers low-latency voice AI at scale — OpenAI Engineering"
    url: https://openai.com/index/delivering-low-latency-voice-ai-at-scale/
    retrieved: 2026-05-12
  - n: 11
    title: "Advancing voice intelligence with new models in the API — OpenAI"
    url: https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api/
    retrieved: 2026-05-12
  - n: 12
    title: "Context Summarization with Realtime API — OpenAI Cookbook"
    url: https://developers.openai.com/cookbook/examples/context_summarization_with_realtime_api
    retrieved: 2026-05-12
whats_new:
  - Realtime is the production default only when barge-in, transport choice, and session-state complexity matter more than raw media cost.
learning_objectives:
  - Decide when OpenAI Realtime is worth its higher per-minute media cost versus a Whisper plus TTS stack
  - Configure transport, VAD, and truncation so a voice agent survives real user interruptions
faq:
  - question: "When should I use OpenAI Realtime instead of Whisper plus TTS?"
    answer: "Use Realtime when natural turn-taking, interruption handling, tool calling, or telephony are product requirements. Use Whisper plus TTS when cost control and modularity matter more than speech-native interaction."
  - question: "What breaks first in production voice agents?"
    answer: "Usually not model quality. The first failures are barge-in, VAD chunking, transport choice, long-session context growth, and phone-network integration."
  - question: "Which OpenAI Realtime transport should I choose?"
    answer: "Use WebRTC for browser or mobile clients, WebSocket for backend orchestration and server-to-server control, and SIP when the entry point is a phone number or telecom trunk."
---

# Use OpenAI Realtime When Turn-Taking Is the Product

OpenAI Realtime API is OpenAI's speech-to-speech interface for apps that need one live session to listen, speak, interrupt, and call tools. If your voice agent needs natural barge-in, telephony, and session-state correctness, Realtime is usually the right default. If you mainly need cheap transcription plus spoken playback, a Whisper-plus-TTS stack is still the cheaper path.[1][5][9]

Most teams frame this as a latency contest. That misses the production tradeoff. Realtime's bigger win is operational: it collapses ASR, response generation, playback coordination, interruption handling, and transport into one system. OpenAI's own production push emphasized SIP, remote MCP tools, prompt reuse, and connection reliability, not just model quality, which is a clue about where the real engineering pain lives.[4][9][10]

## Key facts

- Realtime sessions combine audio input, audio output, and tool use over WebRTC, WebSocket, or SIP.[1][3][4][6]
- VAD and interruption handling are built into the session layer, including assistant-response truncation patterns when the user cuts in.[1][2]
- Realtime audio is materially more expensive than a modular Whisper-plus-TTS stack on raw media cost.[5][6][7][8]
- OpenAI recommends WebRTC for client apps, WebSocket for backend integrations, and SIP for telephony.[3][4][10]
- Long sessions need summarization or trimming to control context growth, latency, and cost.[5][12]

## Pick Realtime when interruption handling matters more than raw media price

Realtime sessions support audio in and audio out, plus tool use, over multiple transports.[1][3][4][6] In conversation mode, VAD can detect speech boundaries and interrupt an in-progress assistant reply, which means turn-taking is part of the API contract rather than an app-side workaround.[2]

That is the production difference from a Whisper-plus-TTS stack. In Realtime, interruption is a first-class session behavior. With supported transports, the platform provides a defined way to stop playback and reconcile the conversation state when the user barges in.[1] In a DIY pipeline, you have to coordinate ASR end-of-turn detection, TTS playback state, LLM cancellation, and history repair yourself.

That is why the right comparison is not "speech model versus speech model." It is "single session state machine versus a pile of glue code." If your agent is supposed to feel like a phone conversation instead of a push-to-talk demo, Realtime usually wins on product quality before it wins on model benchmarks.[9][10]

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I am building a customer-support voice agent for inbound phone calls. Requirements: callers interrupt often, the agent must read compliance text exactly, and it needs to call internal tools. Should I use OpenAI Realtime or a Whisper plus TTS pipeline? Answer in 5 bullets with the deciding factors."
  expectedOutput="A short recommendation that favors Realtime because interruption handling, deterministic instruction following, and tool use inside one live session matter more than minimizing media cost."
/>

## Expect Realtime to cost more, and buy back engineering surface

On raw media cost, Realtime is usually the expensive option. OpenAI's cost docs say user audio input is billed at 1 token per 100 ms and assistant audio output at 1 token per 50 ms.[5] At the current GPT-Realtime-2 pricing listed in the model docs, that implies roughly $0.096 per minute for one symmetric minute of audio conversation before you add any surrounding application cost.[5][6]

A modular stack can start much cheaper on the speech legs alone. GPT-4o mini Transcribe is listed at about $0.003 per minute and GPT-4o mini TTS at about $0.015 per minute, which makes the speech-only baseline roughly five times cheaper before text-model cost enters the picture.[7][8]

That does not make DIY better. The real comparison is whether the extra spend is cheaper than maintaining your own turn detector, playback synchronizer, telephony bridge, and context repair logic. If the interface itself is spoken conversation, Realtime often buys back enough engineering surface to justify the premium.[9][10][11]

## Run WebRTC in clients, WebSocket on servers, and SIP for phone numbers

OpenAI's transport guidance is clearer than most voice platforms. For browser and mobile clients, OpenAI recommends WebRTC because it handles the interactive media problems you would otherwise inherit yourself, including jitter buffering, echo cancellation, and resilient connection setup.[3][10] For server-to-server integrations, use WebSocket and keep the standard API credential on the backend.[3] For PSTN entry points, use SIP and let your trunking provider bridge phone traffic into OpenAI's SIP endpoint.[4]

This transport split matters because transport bugs often masquerade as model bugs. A voice agent that sounds flaky under packet loss, half-duplex playback, or phone-network jitter does not need a smarter model first; it needs the right media path. OpenAI's engineering writeup framed the real challenge as fast connection setup plus low, stable media round-trip time, which is why client-side WebRTC is the default recommendation.[10]

Use `WebRTC` for web and app clients, `WebSocket` for backend workers and supervisory control, and `SIP` for telephony entry points. Treat that as architecture, not as an implementation detail.[3][4][10]

## Treat VAD, truncation, and context trimming as product features

The production gotchas in Realtime are mostly session-management gotchas. OpenAI's `server_vad` mode exposes `threshold`, `prefix_padding_ms`, and `silence_duration_ms`, while `semantic_vad` can end turns based on utterance meaning rather than silence alone.[2] Those settings determine whether your agent feels crisp, hesitant, or rude.

Truncation is the other major one. In WebSocket mode, the client owns playback, so on interruption it must stop audio and send `conversation.item.truncate` so the model does not remember words the user never actually heard.[1][3] Skip that step and your conversation state drifts away from the user's experience.

Long sessions also need explicit trimming. OpenAI's cost guidance notes that each response sees prior conversation state, and the cookbook pattern shows why summarization becomes operationally important once turns accumulate.[5][12] The practical decision tree is simple: choose Realtime when users interrupt often, when you need one live session that can speak and call tools, when telephony is on the roadmap, and when engineering time is more expensive than raw audio tokens. Choose Whisper plus TTS when vendor modularity, cost control, and simpler component isolation matter more than speech-native interaction.

<KnowledgeCheck
  question="A team replaces Whisper plus TTS with Realtime and keeps the same frontend, but forgets to send truncation events after user interruptions in WebSocket mode. What breaks first?"
  options={[
    "The model's RPM tier drops because interruptions count as duplicate requests",
    "The assistant keeps conversation history for words the user never heard, so follow-up turns become incoherent",
    "SIP registration fails because truncation is required for phone calls",
    "Audio tokens stop being cached after the first minute"
  ]}
  correctIdx={1}
  explanation="In WebSocket mode the client owns playback. If it does not truncate the unplayed assistant tail after a barge-in, the conversation state drifts away from the user's actual experience."
/>

The short version is this: use Realtime when speech itself is the interface, not just the input format. If you want the cheaper modular path, stay honest about the transport and interruption logic you are choosing to own. For the full build path from session design through tool calling and deployment tradeoffs, start with [[course/openai-agents-sdk-mastery]].

## References

[1] Realtime conversations — OpenAI API docs — https://developers.openai.com/api/docs/guides/realtime-conversations · retrieved 2026-05-12

[2] Voice activity detection (VAD) — OpenAI API docs — https://developers.openai.com/api/docs/guides/realtime-vad · retrieved 2026-05-12

[3] Realtime API with WebSocket — OpenAI API docs — https://developers.openai.com/api/docs/guides/realtime-websocket · retrieved 2026-05-12

[4] Realtime API with SIP — OpenAI API docs — https://developers.openai.com/api/docs/guides/realtime-sip · retrieved 2026-05-12

[5] Managing costs — OpenAI API docs — https://developers.openai.com/api/docs/guides/realtime-costs · retrieved 2026-05-12

[6] GPT-Realtime-2 model page — OpenAI API docs — https://developers.openai.com/api/docs/models/gpt-realtime-2 · retrieved 2026-05-12

[7] GPT-4o mini TTS model page — OpenAI API docs — https://developers.openai.com/api/docs/models/gpt-4o-mini-tts · retrieved 2026-05-12

[8] GPT-4o mini Transcribe model page — OpenAI API docs — https://developers.openai.com/api/docs/models/gpt-4o-mini-transcribe · retrieved 2026-05-12

[9] Introducing gpt-realtime and Realtime API updates for production voice agents — OpenAI — https://openai.com/index/introducing-gpt-realtime/ · retrieved 2026-05-12

[10] How OpenAI delivers low-latency voice AI at scale — OpenAI Engineering — https://openai.com/index/delivering-low-latency-voice-ai-at-scale/ · retrieved 2026-05-12

[11] Advancing voice intelligence with new models in the API — OpenAI — https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api/ · retrieved 2026-05-12

[12] Context Summarization with Realtime API — OpenAI Cookbook — https://developers.openai.com/cookbook/examples/context_summarization_with_realtime_api · retrieved 2026-05-12
