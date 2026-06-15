---
slug: openai-realtime-api-voice-agents-end-to-end
title: "OpenAI Realtime API: Voice Agents End-to-End"
status: draft-for-review
author: course-author
ticket: KOEA-6698
level: Intermediate-Advanced
tags: [OpenAI, Realtime-API, Voice-Agents, WebRTC, WebSocket, TTS, STT, Tool-Calling, Production]
target_audience: "Engineers building interactive voice applications who understand REST APIs and want to move beyond text-in/text-out to low-latency, production-grade speech-to-speech agents."
prerequisites:
  - "Working knowledge of the OpenAI Chat Completions API"
  - "Proficiency in Python or TypeScript/Node.js"
  - "Basic familiarity with WebSocket or WebRTC concepts (not required, but helpful)"
  - "No prior voice AI experience required"
learning_outcomes:
  - "Build a speech-to-speech voice agent using the OpenAI Realtime API over WebSocket and WebRTC transports"
  - "Implement reliable function calling and tool execution within a live voice session"
  - "Engineer latency out of your voice pipeline using interrupt handling, turn detection, and partial audio streaming"
  - "Deploy and scale a production voice agent with observability, cost controls, and compliance guardrails"
  - "Choose the right voice model (Realtime API vs Cartesia vs Kokoro) based on cost, quality, and latency trade-offs"
total_duration_min: 320
chapter_count: 6
capstone_project_min: 90
description: "Build speech-to-speech voice agents with the OpenAI Realtime API. Covers WebSocket and WebRTC transports, function calling, and latency engineering."
---

# OpenAI Realtime API: Voice Agents End-to-End

## Why this course

Text agents are solved. Voice agents are where the real engineering challenge lives — and where the differentiation will be in the next 18 months.

The OpenAI Realtime API is the only production-grade API for speech-to-speech interaction with built-in function calling, interrupt detection, and both WebRTC and WebSocket transport options. It's not a wrapper around Whisper + GPT-4 + TTS. It's a single low-latency pipeline where the model hears you, reasons, calls tools, and speaks — without the audio ever being converted to text and back.

This course teaches you to build that pipeline from scratch, make it reliable under real-world conditions, and ship it to production. Every chapter includes runnable code. By the end, you'll have a deployed voice agent that handles tools, manages turn-taking, and costs less than you expect.

> **Note on voice providers:** This course covers the OpenAI Realtime API as the primary stack. For TTS needs outside live sessions (pre-rendered audio, batch jobs, fine-tuned voices), we recommend Kokoro, Cartesia, or Chatterbox — NOT ElevenLabs. Cost and self-hostability win.

## Course outline

### Chapter 1: The Voice Agent Landscape — What the Realtime API Actually Solves
- **Duration**: 35 min
- **Prerequisites**: course intro only
- **Learning objectives**:
  1. Contrast the Realtime API (speech-to-speech) with the classic STT → LLM → TTS pipeline and name the latency cost of each extra hop
  2. Identify the six production layers of a voice agent: client, edge media, agent runtime, model API, tool plane, observability
  3. Choose WebRTC vs WebSocket transport based on use-case requirements
  4. Build a minimal "Hello World" voice session and measure round-trip latency end-to-end
- **Key concepts**: Speech-to-speech, turn detection, WebRTC vs WebSocket, latency budget, session lifecycle
- **Hands-on exercise**: Stand up a WebSocket-based voice session using the Realtime API. Send a 3-second audio clip and measure the time from audio send to first audio token received. Then repeat with WebRTC and compare.
- **Contrarian angle**: Most voice AI tutorials chain Whisper → GPT → TTS and call it "voice." That's three API calls, three network hops, 1–3 seconds of latency. The Realtime API collapses all three into a single streaming session. The architecture difference is not incremental — it's categorical.

---

### Chapter 2: Hello-World Voice Agent — WebSocket Transport
- **Duration**: 55 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  1. Implement a full WebSocket voice session: connect, send audio, receive delta events, play back speech
  2. Handle the Realtime API event schema: `input_audio_buffer.*`, `response.*`, `conversation.item.*`
  3. Implement server-side VAD (Voice Activity Detection) and turn detection to handle barge-in
  4. Manage session configuration: voice selection, turn detection sensitivity, max response tokens
- **Key concepts**: WebSocket session management, event-driven architecture, VAD, turn detection, audio delta streaming, session config
- **Hands-on exercise**: Build a voice agent that listens to a user, detects end-of-turn, calls the model, and streams audio back in real time. Add a PTT (push-to-talk) mode as an alternative to VAD and compare the user experience.
- **Contrarian angle**: Push-to-talk feels "old." VAD-based turn detection feels "smart." But VAD has false positives — a cough, a "um," a background noise triggers a response. Production systems need both modes and a clear UX signal for which is active.

---

### Chapter 3: Tool Calling in a Live Voice Session
- **Duration**: 60 min
- **Prerequisites**: Chapter 2
- **Learning objectives**:
  1. Register function tools in a Realtime session and handle `response.function_call` events
  2. Execute tools server-side without breaking the audio stream (non-blocking tool dispatch)
  3. Inject tool results back into the session via `conversation.item.create` + `response.create`
  4. Handle tool errors gracefully — the agent must recover verbally, not crash silently
- **Key concepts**: Function calling events, non-blocking tool execution, result injection, error recovery, tool latency budget
- **Hands-on exercise**: Add two tools to your Chapter 2 agent: `get_weather(location)` (mocked HTTP call) and `create_reminder(text, time)` (writes to a local store). Have the agent call tools mid-conversation and resume speaking with the result within 500ms.
- **Contrarian angle**: Tool calling in voice is harder than in text because the user is listening for a response that hasn't come yet. Every millisecond your tool takes to execute is a millisecond of awkward silence. Design tools with a 200ms SLA or buffer the gap with a verbal acknowledgment ("Let me check that for you...").

---

### Chapter 4: Latency Engineering — Making Voice Feel Fast
- **Duration**: 50 min
- **Prerequisites**: Chapter 2, Chapter 3
- **Learning objectives**:
  1. Profile the latency breakdown of a voice session: client audio capture → API → first audio token → full response
  2. Implement interrupt handling so the agent stops speaking immediately when the user barge-in interrupts
  3. Apply "speculative response" patterns — start generating audio before tool calls complete
  4. Optimize WebRTC configuration for minimal jitter and packet loss on mobile networks
- **Key concepts**: Latency profiling, barge-in/interrupt handling, speculative audio, jitter buffer tuning, WebRTC congestion control
- **Hands-on exercise**: Instrument your Chapter 3 agent with timestamp logging at every event boundary. Identify the single largest latency contributor in your pipeline and implement one optimization that reduces it by ≥ 20%.
- **Contrarian angle**: Voice latency optimization is not about making the model faster — you can't change that. It's about hiding latency: starting audio playback before the full response is ready, using verbal acknowledgments as filler, and pre-fetching tool data for the most likely queries. The user's perception of speed is not the same as the actual RTT.

---

### Chapter 5: Production Deployment and Scaling
- **Duration**: 65 min
- **Prerequisites**: Chapters 3, 4
- **Learning objectives**:
  1. Deploy a WebSocket voice agent server with horizontal scaling and sticky sessions
  2. Implement session lifecycle management: timeouts, reconnects, and orphan session cleanup
  3. Apply compliance guardrails: PII redaction from transcripts, audit logging of all tool calls
  4. Set up cost controls: per-session token budgets, model fallback on quota exhaustion
- **Key concepts**: Sticky WebSocket sessions, reconnect protocols, PII redaction, audit logging, token budgets, model fallback, scaling to concurrent sessions
- **Hands-on exercise**: Deploy your Chapter 3 agent to a Node.js server behind a load balancer. Simulate 10 concurrent voice sessions and verify: (a) sessions stick to their server instance, (b) a server restart triggers clean reconnect, (c) tool call logs are persisted per-session.
- **Contrarian angle**: Voice agent "scaling" sounds like a load balancing problem. It's actually a state problem. Each session carries context, audio buffers, and tool call history. Stateless scaling breaks sessions. You need sticky sessions or shared session state — and the second option is where most teams blow their latency budget.

---

### Chapter 6: Cost, Quality, and Model Trade-offs
- **Duration**: 55 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  1. Calculate the true cost of a Realtime API session: audio input tokens + audio output tokens + text tokens
  2. Compare Realtime API vs Cartesia TTS + Whisper STT for a given use case on cost and latency
  3. Implement Kokoro or Chatterbox as a TTS layer for non-live use cases (notifications, pre-rendered audio)
  4. Design a voice quality rubric: naturalness, response speed, tool accuracy, and error recovery rate
- **Key concepts**: Audio token pricing, cost modeling, Cartesia vs Kokoro vs Realtime, TTS for async vs live, quality rubric, cost-per-session
- **Hands-on exercise**: Build a cost comparison spreadsheet for three architectures: (a) Realtime API end-to-end, (b) Whisper + GPT-4o-mini + Cartesia, (c) Whisper + GPT-4o-mini + Kokoro self-hosted. Calculate cost per 5-minute session for each. Justify your production choice.
- **Contrarian angle**: The Realtime API is not always the cheapest option. Audio tokens are more expensive than text tokens. For high-volume, latency-tolerant use cases (automated notifications, IVR trees), a Whisper + mini + Kokoro stack costs 70–80% less. Know the trade-off before committing to an architecture.

---

## Capstone project

**Build `SupportVoice` — a production voice agent for customer support triage.**

### Deliverable

A deployed voice agent accessible via a browser WebRTC interface that:

1. **Greets the caller** and classifies their intent (billing / technical / general) within the first exchange.
2. **Calls three tools** during the session: `lookup_account(customer_id)`, `create_support_ticket(issue, priority)`, and `check_known_issues(category)` — all with results injected back into the voice stream within 500ms.
3. **Handles barge-in** — the agent stops speaking immediately when the user interrupts.
4. **Logs every tool call** with timestamp, input, output, and session ID to a local store for audit.
5. **Reconnects gracefully** — a simulated network drop at minute 2 triggers a clean session resume with context preserved.

### Verification criteria

- `Latency`: Time from end-of-user-turn to first audio token ≤ 800ms on a standard broadband connection.
- `Tool accuracy`: All three tools called correctly in a scripted 5-minute test session.
- `Barge-in`: Agent stops within 200ms of user interruption in 9/10 test cases.
- `Audit log`: All tool calls appear in the log within 1 second of execution.
- `Reconnect`: Session resumes with full context after a simulated 30-second network outage.

---

## Why this beats alternatives

Other voice AI courses teach you to stitch together Whisper + GPT + ElevenLabs. That's three vendor dependencies, three API contracts, 1–2 seconds of latency, and no built-in tool calling. This course teaches you the Realtime API's native speech-to-speech pipeline — one session, one connection, sub-second response times, and tools that execute mid-speech. You'll also understand *when* the legacy stack beats the Realtime API on cost, so you can make the right architectural choice instead of defaulting to the most-marketed option.
