---
date: 2026-05-12
author: blog-author
ticket: KOEA-1252
vendor_tag: openai
content_type: article
status: draft-for-review
reading_time_min: 7
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
  - Realtime is now the production-default only when barge-in, transport choice, and session-state complexity matter more than raw media cost.
learning_objectives:
  - Decide when OpenAI Realtime is worth its higher per-minute media cost versus a Whisper plus TTS stack
  - Configure transport, VAD, and truncation so a voice agent survives real user interruptions
faq:
  - question: "When should I use OpenAI Realtime instead of Whisper plus TTS?"
    answer: "Use Realtime when natural turn-taking, interruption handling, tool calling, or telephony are product requirements. Use Whisper plus TTS when cost control and modularity matter more than speech-native interaction."
  - question: "What breaks first in production voice agents?"
    answer: "Usually not model quality. The first failures are barge-in, VAD chunking, transport choice, long-session context growth, and phone-network integration."
---

# Use OpenAI Realtime When Turn-Taking Is the Product

If you are building a voice agent in 2026, OpenAI Realtime is the right default when you need natural interruption handling, telephony, and one session model that owns speech input, speech output, and tool calls. If you mainly need cheap transcription plus spoken playback, a self-assembled Whisper-plus-TTS stack is still the more economical choice.[^1][^5][^9]

What most teams miss is that Realtime is not just "faster voice." The bigger win is operational: it removes the handoff bugs between ASR, LLM, TTS, playback, and call transport. OpenAI's own GA push emphasized SIP, remote MCP tools, reusable prompts, and transport reliability, not just model quality.[^9][^10]

## Pick Realtime when interruption handling matters more than raw media price

Realtime sessions support audio in and audio out, plus tool use, over WebRTC, WebSocket, or SIP.[^6][^9] In conversation mode, VAD can detect speech boundaries and interrupt an in-progress assistant reply.[^2]

This is the production difference from a Whisper-plus-TTS stack. In Realtime, interruption is a first-class session behavior. With WebRTC and SIP, the server can automatically truncate the unplayed tail of the assistant response when the user cuts in.[^1] With a DIY pipeline, you have to coordinate ASR end-of-turn detection, TTS playback state, LLM cancellation, and conversation history repair yourself.

That is why the best comparison baseline is not "speech model versus speech model." It is "single session state machine versus a pile of glue code." For the TTS baseline, Cartesia Sonic 3 is still the most useful paid comparison point in [[voice-agents-2026-tts-latency-benchmark]], but that post reaches the same conclusion: raw time-to-first-audio is not the whole product.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I am building a customer-support voice agent for inbound phone calls. Requirements: callers interrupt often, the agent must read compliance text exactly, and it needs to call internal tools. Should I use OpenAI Realtime or a Whisper plus TTS pipeline? Answer in 5 bullets with the deciding factors."
  expectedOutput="A short recommendation that favors Realtime because interruption handling, deterministic instruction following, and tool use inside one live session matter more than minimizing media cost."
/>

## Expect Realtime to cost more than Whisper plus TTS, and buy back engineering surface

On raw media cost, Realtime is usually the expensive option. OpenAI's cost docs say user audio input is billed at 1 token per 100 ms and assistant audio output at 1 token per 50 ms.[^5] At current GPT-Realtime-2 prices, that implies a symmetric minute of conversation costs about $0.096 per minute in audio alone.[^6] That arithmetic is an inference from the pricing and tokenization docs, not a quoted OpenAI example.

By contrast, a modular stack can start much cheaper on media alone. GPT-4o mini Transcribe is listed at about $0.003 per minute and GPT-4o mini TTS at about $0.015 per minute, so the DIY stack can be roughly 5x cheaper on the speech legs before text-model cost.[^7][^8]

That does not mean DIY is better. The real question is whether the extra spend is cheaper than maintaining your own turn detector, playback synchronizer, telephony bridge, and context repair logic. If your agent is supposed to feel like a phone conversation, Realtime usually earns its keep.[^9][^10]

## Run WebRTC in clients, WebSocket on servers, and SIP for phone numbers

OpenAI's transport guidance is unusually clear. For browser and mobile clients, OpenAI recommends WebRTC because it handles the hard parts of interactive media like jitter buffering, echo cancellation, and connection robustness.[^3][^10] For server-to-server integrations, use WebSocket and keep the standard API key on the backend.[^3] For phone numbers, use SIP and let your trunking provider bridge PSTN traffic into OpenAI's SIP endpoint.[^4]

Use `WebRTC` for web and app clients, `WebSocket` for backend workers and session control, and `SIP` for telephony entry points. Transport bugs often masquerade as model bugs, and OpenAI's May 4 engineering writeup framed the real problem as fast connection setup plus low, stable media round-trip time.[^10]

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="Given this stack: React web app, iPhone client later, and a future Twilio phone number, choose the right OpenAI Realtime transport for each surface and explain why in one sentence each."
  expectedOutput="WebRTC for the React and iPhone clients, SIP for the phone number, and optional WebSocket only for backend orchestration or server-side supervision."
/>

## Treat VAD, truncation, and context trimming as product features

The production gotchas are mostly session-management gotchas. Realtime's default `server_vad` mode can be tuned with `threshold`, `prefix_padding_ms`, and `silence_duration_ms`; `semantic_vad` can instead decide turn endings based on the meaning of the utterance rather than silence alone.[^2] Those settings control whether your agent feels crisp or rude.

Truncation is the other big one. In WebSocket mode, the client must stop playback on interruption and then send `conversation.item.truncate` so the model does not retain words the user never actually heard.[^1] Skip that step and your assistant will behave as if it finished a sentence that it never finished aloud.

Long sessions also get expensive because every response sees the conversation state that came before it.[^5] OpenAI's cookbook example is worth treating as a production pattern: transcript retrieval arrives about 100-300 ms after audio completion, audio deltas stream every 20-60 ms during playback, and old turns get trimmed before context bloat hurts latency and quality.[^12]

## Use this decision tree instead of defaulting to speech-to-speech

Choose OpenAI Realtime if most answers below are "yes":

- Do users interrupt often?
- Do you need one live session that can speak, listen, and call tools?
- Will you add phone support through SIP?
- Is engineering time more expensive than raw audio tokens?

Choose Whisper plus TTS if most answers below are "yes":

- Do you want interchangeable ASR, LLM, and TTS vendors?
- Is media cost the primary constraint?
- Do you need simpler failure isolation per component?
- Can users tolerate push-to-talk or strict turn-taking?

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

The short version is this: use Realtime when speech itself is the interface, not just the input format. When you want the cheaper modular path, borrow the latency lessons from [[voice-agents-2026-tts-latency-benchmark]] and the vendor context in [[research/openai/2026-05-12]], but keep your architecture honest about what you are re-implementing. For a full build path from session design through tool calling and deployment tradeoffs, start with [[course/openai-agents-sdk-mastery]].
