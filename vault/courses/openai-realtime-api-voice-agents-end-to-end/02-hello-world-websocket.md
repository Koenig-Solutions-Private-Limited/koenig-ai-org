---
chapter_num: 2
course_slug: openai-realtime-api-voice-agents-end-to-end
course_track: career
title: "Hello-World Voice Agent — WebSocket Transport"
status: g0-passed
duration_min: 55
vendor_tag: openai
learning_objectives:
  - "Implement a full WebSocket voice session: connect, send audio, receive delta events, play back speech"
  - "Handle the Realtime API event schema: input_audio_buffer.*, response.*, conversation.item.*"
  - "Implement server-side VAD (Voice Activity Detection) and turn detection to handle barge-in"
  - "Manage session configuration: voice selection, turn detection sensitivity, max response tokens"
sources:
  - url: "https://developers.openai.com/api/reference/resources/realtime/client-events"
    title: "OpenAI Realtime API Client Events Reference"
  - url: "https://developers.openai.com/api/docs/guides/realtime-vad"
    title: "Voice Activity Detection (VAD) Guide"
  - url: "https://developers.openai.com/api/reference/resources/realtime/sessions"
    title: "Realtime Sessions Reference"
  - url: "https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api"
    title: "Advancing voice intelligence with new models in the API"
quiz:
  - question: "Your agent responds immediately after the user's first word before they finish speaking, with default VAD settings. What is the most likely cause?"
    options:
      - "A separate code path is sending input_audio_buffer.commit events in parallel with streaming"
      - "The VAD threshold is set too low, classifying brief volume dips between words as turn-ending silence"
      - "The max_response_output_tokens cap forces an early reply before the full turn has arrived"
      - "The audio chunk size is too large, causing the input buffer to overflow and flush prematurely"
    correct_idx: 1
    explanation: "When threshold is too low (e.g. 0.3), brief dips in volume during normal speech — pausing between words — register as silence and trigger a premature buffer commit. Raise threshold to 0.6–0.7 to require more sustained silence before the VAD fires."
    section_anchor: "server-side-vad-and-turn-detection"
  - question: "You raise silence_duration_ms from 500ms to 1200ms to reduce false VAD triggers in a noisy call-center environment. What is the direct trade-off users will notice?"
    options:
      - "Audio output quality degrades slightly because the jitter buffer drains during the longer delay"
      - "Every turn's response latency increases by approximately 700ms as the full silence window must elapse"
      - "Barge-in cancellation stops working because speech_started no longer fires during the extended window"
      - "The conversation.item.created event stops emitting correctly in sequence after each complete user utterance arrives"
    correct_idx: 1
    explanation: "silence_duration_ms is dead time the system must wait before committing the buffer. Every turn must wait for this full window before the model can begin processing. Adding 700ms to this window adds 700ms of floor latency to every response."
    section_anchor: "server-side-vad-and-turn-detection"
  - question: "response.done arrives with status: 'incomplete' and the agent's audio cuts off mid-sentence. What is the direct cause?"
    options:
      - "The WebSocket connection timed out before the full response audio stream finished sending"
      - "The server VAD silence window triggered a new buffer commit while the response was still generating"
      - "The configured max_response_output_tokens limit in session.update was reached before the response audio finished generating"
      - "The audio output format does not match the PCM specification expected by the client"
    correct_idx: 2
    explanation: "status: 'incomplete' signals the model hit the max_response_output_tokens cap before finishing. The audio stream stops mid-sentence. Increase the cap or constrain response length in your system prompt to avoid incomplete responses."
    section_anchor: "managing-session-configuration"
  - question: "Which event family should your code monitor to reliably detect that the user's audio turn has been committed and the model is about to begin responding?"
    options:
      - "conversation.item.* — specifically conversation.item.created for each user utterance that lands"
      - "response.* — specifically response.created, which fires when the model starts generating output"
      - "input_audio_buffer.* — specifically speech_stopped followed by the server's committed confirmation"
      - "session.* — specifically session.updated, which confirms turn detection is correctly configured"
    correct_idx: 2
    explanation: "The commit sequence is speech_stopped (VAD detected sustained silence) → committed (buffer locked, model will process). Monitoring this pair gives you the earliest reliable signal that a response is incoming. response.created comes slightly later once processing begins."
    section_anchor: "the-realtime-api-event-schema"
---

# Build a Continuous WebSocket Voice Agent with VAD and PTT Fallback

Connect a persistent WebSocket to the OpenAI Realtime API, stream microphone audio in real time, and play back speech deltas as they arrive — with under 700 ms response latency from end of speech to first audio byte. This chapter delivers that session end-to-end: continuous 24 kHz PCM streaming, event-driven response handling, server-side VAD for automatic turn detection, barge-in cancellation via `response.cancel`, and a PTT fallback you can toggle at runtime without reconnecting.

By the end you have a working Python voice agent you can run against a live microphone, a clear model of the three `turn_detection` parameters that control how aggressive VAD fires, and the data you need to decide which mode ships as the default in your product.

---

## Connecting a Continuous Voice Session

Chapter 1 showed a one-shot audio send. This chapter replaces that with a proper continuous voice loop: the client captures audio in real time, streams it to the API as fast as it arrives, and handles responses asynchronously on the same WebSocket connection.

The full session script below is the foundation for every chapter that follows. Read through it before running it — the inline comments map directly to the event schema section that follows.

<RunPromptCell>
```python
# continuous_voice.py
import asyncio, json, base64
import websockets
import pyaudio   # pip install pyaudio

API_KEY = "sk-..."
MODEL   = "gpt-realtime-2"
WS_URL  = f"wss://api.openai.com/v1/realtime?model={MODEL}"

# 24 kHz, 16-bit mono PCM — the Realtime API's native format
SAMPLE_RATE  = 24_000
CHANNELS     = 1
CHUNK_FRAMES = SAMPLE_RATE * 100 // 1000   # 100 ms = 2400 frames

pa = pyaudio.PyAudio()

async def capture_and_stream(ws, stop: asyncio.Event):
    """Reads mic audio and streams base64-encoded chunks to the WebSocket."""
    stream = pa.open(format=pyaudio.paInt16, channels=CHANNELS,
                     rate=SAMPLE_RATE, input=True, frames_per_buffer=CHUNK_FRAMES)
    try:
        while not stop.is_set():
            chunk = stream.read(CHUNK_FRAMES, exception_on_overflow=False)
            await ws.send(json.dumps({
                "type": "input_audio_buffer.append",
                "audio": base64.b64encode(chunk).decode(),
            }))
            await asyncio.sleep(0)   # yield to event loop
    finally:
        stream.stop_stream(); stream.close()

async def receive_events(ws, stop: asyncio.Event):
    """Handles all server events and plays back audio deltas in real time."""
    play = pa.open(format=pyaudio.paInt16, channels=CHANNELS,
                   rate=SAMPLE_RATE, output=True)
    try:
        async for raw in ws:
            event = json.loads(raw)
            t = event["type"]

            if t == "session.created":
                print("Session ready:", event["session"]["id"])
            elif t == "input_audio_buffer.speech_started":
                print("[VAD] Speech detected — cancelling any active response")
                await ws.send(json.dumps({"type": "response.cancel"}))
            elif t == "input_audio_buffer.speech_stopped":
                print("[VAD] End of turn — waiting for response")
            elif t == "response.audio.delta":
                play.write(base64.b64decode(event["delta"]))   # real-time playback
            elif t == "response.done":
                print("[Done] Agent finished speaking")
            elif t == "error":
                print("Error:", event["error"]["message"])
                stop.set(); break
    finally:
        play.stop_stream(); play.close()

async def main():
    headers = {
        "Authorization": f"Bearer {API_KEY}",
    }
    async with websockets.connect(WS_URL, additional_headers=headers) as ws:
        await ws.send(json.dumps({
            "type": "session.update",
            "session": {
                "modalities": ["audio", "text"],
                "voice": "alloy",
                "turn_detection": {
                    "type":                "server_vad",
                    "threshold":           0.5,
                    "prefix_padding_ms":   300,
                    "silence_duration_ms": 600,
                },
                "max_response_output_tokens": 800,
            }
        }))
        stop = asyncio.Event()
        await asyncio.gather(capture_and_stream(ws, stop), receive_events(ws, stop))

asyncio.run(main())
```

**To run:** `pip install websockets pyaudio` then `python continuous_voice.py`. Speak into your microphone — the agent responds in the alloy voice after VAD detects your turn ending. Press Ctrl-C to stop.

`gpt-realtime-2` was released May 7, 2026 [(OpenAI, "Advancing voice intelligence with new models in the API", openai.com, retrieved 2026-06-15)](https://openai.com/index/advancing-voice-intelligence-with-new-models-in-the-api) and is the recommended model identifier for all new Realtime API sessions; its predecessor `gpt-realtime` reached GA on August 28, 2025 [(OpenAI, "Introducing gpt-realtime", openai.com, 2025-08-28)](https://openai.com/index/introducing-gpt-realtime). For rate limits and tier details see the model spec [(OpenAI, "GPT-Realtime-2 Model", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/docs/models/gpt-realtime-2). [(OpenAI, "Realtime Sessions", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/reference/resources/realtime/sessions)
</RunPromptCell>

---

## The Realtime API Event Schema

Every interaction with the Realtime API is a JSON event sent or received over the WebSocket connection. Understanding which event does what separates a 5-minute debug from a 5-hour one. [(OpenAI Realtime API, "Client Events", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/reference/resources/realtime/client-events)

There are three event families in scope for this chapter:

**`input_audio_buffer.*` — audio you send and the server's response to it**

| Event | Direction | Purpose |
|---|---|---|
| `input_audio_buffer.append` | Client → Server | Stream a base64-encoded 100 ms PCM chunk |
| `input_audio_buffer.commit` | Client → Server | End the user's turn manually (PTT mode) |
| `input_audio_buffer.clear` | Client → Server | Discard the buffer without committing |
| `input_audio_buffer.speech_started` | Server → Client | VAD detected speech above threshold |
| `input_audio_buffer.speech_stopped` | Server → Client | VAD detected sustained silence — turn commit imminent |
| `input_audio_buffer.committed` | Server → Client | Buffer committed (by VAD or by the client) |

**`response.*` — the agent's reply stream**

| Event | Direction | Purpose |
|---|---|---|
| `response.created` | Server → Client | Model started processing the committed audio |
| `response.audio.delta` | Server → Client | A base64-encoded PCM chunk to play back |
| `response.audio_transcript.delta` | Server → Client | Real-time text transcript of the audio being generated |
| `response.done` | Server → Client | Agent finished its turn; `status` field is `"completed"` or `"incomplete"` |
| `response.cancelled` | Server → Client | Response was aborted by a `response.cancel` event |

**`conversation.item.*` — the persistent conversation history**

| Event | Direction | Purpose |
|---|---|---|
| `conversation.item.created` | Server → Client | A new item added to context (user or agent turn) |
| `conversation.item.create` | Client → Server | Insert a synthetic message — used for tool results (Chapter 3) |
| `conversation.item.deleted` | Server → Client | Item removed from context |

The conversation history is stored server-side across the session's 128,000-token context window [(OpenAI, "Realtime Sessions", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/reference/resources/realtime/sessions). Audio consumes approximately 800 tokens per minute [(OpenAI, "Realtime Guide", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/docs/guides/realtime) — at the June 2026 list price of $32/1M audio-input tokens [(OpenAI, "API Pricing", openai.com, retrieved 2026-06-15)](https://openai.com/api/pricing) that is roughly $0.026 per minute of audio input — so a typical 5-minute conversation uses around 4,000 audio tokens of context — leaving plenty of headroom for tool results and system instructions.

<KnowledgeCheck
  question="You send input_audio_buffer.append events continuously but the agent responds immediately after your first word, before you finish speaking. What is the most likely cause?"
  options={["The input_audio_buffer.commit event was sent automatically by a separate code path", "Server VAD detected speech ending early because threshold is set too low", "The max_response_output_tokens value is set too low", "The audio chunk size is too large, causing buffer overflow"]}
  correctIdx={1}
  explanation="When turn_detection.threshold is too low (e.g., 0.3), brief dips in volume during normal speech — pausing between words — register as silence and trigger a premature commit. Raise threshold to 0.6–0.7 to require more sustained silence before the VAD fires."
/>

---

## Server-Side VAD and Turn Detection

VAD is what makes a voice agent feel conversational rather than robotic. Without it you need a button press or a fixed silence timer. With it, the model begins responding the moment you stop talking — typically delivering the first audio token within 500–700 ms total. [(OpenAI, "Voice Activity Detection (VAD)", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/docs/guides/realtime-vad)

The `turn_detection` object in `session.update` controls all VAD behavior:

```json
"turn_detection": {
  "type":                "server_vad",
  "threshold":           0.5,
  "prefix_padding_ms":   300,
  "silence_duration_ms": 600
}
```

- **`threshold`** (0.0–1.0, default 0.5): The audio energy level above which a frame is classified as speech. Lower values detect whispers but generate more false positives from keyboard noise and background chatter. In a typical call-center or office environment, 0.6–0.7 is a safer starting point than the default.
- **`prefix_padding_ms`** (default 300): How many milliseconds of audio before the VAD trigger to include in the committed buffer. This prevents clipping the first syllable of an utterance. Setting this above 500 ms wastes context tokens on pre-speech silence.
- **`silence_duration_ms`** (default 500): How long the audio must stay below `threshold` before the turn is committed. 500 ms works for deliberate speakers in quiet environments; raise to 700–800 ms if users pause mid-sentence and get interrupted by the agent responding too early.

<Callout type="warn">
**VAD false positive pattern:** A user says "I want to book a flight to — um — Paris." The "um" followed by a 600 ms pause triggers the VAD. The agent responds before the user finishes speaking. This is the single most common cause of "the agent keeps interrupting me" support reports. Start at `silence_duration_ms: 700` and reduce only after real user testing.
</Callout>

<Callout type="info">
**Semantic VAD (preview):** OpenAI's turn-detection docs also include a `semantic_vad` mode alongside `server_vad`. It uses model-layer understanding of utterance completion rather than raw audio energy thresholds, reducing false positives in conversational pauses. Enable it with `"type": "semantic_vad"` in `turn_detection`. [(OpenAI, "Voice Activity Detection", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/docs/guides/realtime-vad)
</Callout>

When VAD fires, the server emits this event sequence automatically — your code does not need to send `input_audio_buffer.commit` or `response.create` in VAD mode:

```
input_audio_buffer.speech_started   ← energy above threshold
input_audio_buffer.speech_stopped   ← sustained silence detected
input_audio_buffer.committed        ← buffer committed by VAD
response.created                    ← model starts processing
response.audio.delta                ← first audio chunk (≈500 ms after commit)
```

**Barge-in handling.** When `input_audio_buffer.speech_started` fires while the agent is still speaking, the correct behavior is to cancel the in-flight response immediately and stop playback. The cancelled response items are not added to the conversation history, so context stays clean.

<RunPromptCell>
```python
# Barge-in handler — replace the speech_started branch in receive_events()
elif t == "input_audio_buffer.speech_started":
    print("[Barge-in] User interrupted — cancelling response")
    await ws.send(json.dumps({"type": "response.cancel"}))
    # Stop audio playback: set a shared flag that the playback loop checks
    # (implementation depends on your audio library's threading model)
```

The key insight: `response.cancel` is safe to send even when no response is active. It is idempotent.
</RunPromptCell>

<KnowledgeCheck
  question="You raise silence_duration_ms from 500 to 1200 ms to reduce VAD false positives for a noisy environment. What observable trade-off does the user experience?"
  options={["The agent's audio output quality drops because of buffer overflow", "The agent's response latency increases by approximately 700 ms on every turn", "Barge-in interruptions no longer cancel the in-flight response", "The conversation.item.created event stops firing after each user turn"]}
  correctIdx={1}
  explanation="silence_duration_ms is dead time before the model can begin processing — every turn must wait for the full silence window to close before the buffer commits. Adding 700 ms to this window adds 700 ms of floor latency to every response."
/>

---

## Managing Session Configuration

The `session.update` event configures everything about how the session behaves, and you can call it multiple times during a session. This is the mechanism for runtime mode switching — switching VAD to PTT when a user enters a noisy environment, or changing the system prompt when a user authenticates. [(OpenAI Realtime API, "session.update", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/reference/resources/realtime/client-events)

**Voice selection.** Available voices as of June 2026 include `alloy`, `echo`, `shimmer`, `verse`, `ballad`, `coral`, `sage`, and `ash` [(OpenAI, "Realtime Sessions", developers.openai.com, retrieved 2026-06-15)](https://developers.openai.com/api/reference/resources/realtime/sessions). Voice cannot be changed mid-session — configure it before the first audio exchange. For enterprise and customer service contexts, `alloy` and `echo` test well in user research; `shimmer` is warmer and more casual.

**`max_response_output_tokens`:** Caps the agent's response length in tokens (approximately 20 audio tokens per second of speech). Set to `800` for responses under 40 seconds. For conversational agents with long explanations, use `2000` or omit the field entirely. When a response exceeds the cap, `response.done` arrives with `status: "incomplete"` — the agent's audio cuts off mid-sentence, which sounds broken to users. Size this conservatively or handle `"incomplete"` status explicitly.

**`input_audio_format` and `output_audio_format`:** Default is `pcm16` (24 kHz, 16-bit mono). Telephony integrations often require `g711_ulaw` or `g711_alaw` (8 kHz, 8-bit) to match PSTN codec standards. Switching to g711 reduces bandwidth by approximately 6× but is audibly lower quality — reserve it for telephony bridges, not browser clients.

**`instructions`:** The session's system prompt. Set it in `session.update`, not as a conversation message. You can update it mid-session to implement mode switching — for example, from an "intake" persona to a "billing support" persona after the user authenticates.

<KnowledgeCheck
  question="An agent response consistently ends mid-sentence with the audio cutting off abruptly. Inspecting events, you see response.done with status: 'incomplete'. What is the direct cause?"
  options={["The WebSocket connection dropped and the server closed the stream prematurely", "The silence_duration_ms VAD window fired during the response and triggered a new turn", "The response exceeded the max_response_output_tokens cap set in session.update", "The input_audio_format does not match the server's expected audio specification"]}
  correctIdx={2}
  explanation="status: 'incomplete' signals that the model hit the max_response_output_tokens cap before finishing its output. Increase the cap or add explicit response-length constraints in your system prompt."
/>

---

## Adding Push-to-Talk Mode

PTT is the right choice when VAD cannot be tuned well enough for the deployment environment — high ambient noise, multiple speakers in the room, or accessibility contexts where users prefer explicit control. Switching is a single config change and works seamlessly mid-session.

Set `turn_detection` to `null` to disable VAD entirely:

```python
await ws.send(json.dumps({
    "type": "session.update",
    "session": {"turn_detection": None}   # manual mode
}))
```

In manual mode the server never auto-commits the buffer. Your application controls the turn: send `input_audio_buffer.commit` followed by `response.create` when the user releases the PTT trigger.

<RunPromptCell>
```python
# ptt_control.py — drop-in coroutine for continuous_voice.py
import keyboard   # pip install keyboard

async def ptt_loop(ws, stop: asyncio.Event):
    """Polls spacebar state; commits turn on key release."""
    was_pressed = False
    while not stop.is_set():
        pressed = keyboard.is_pressed("space")
        if pressed and not was_pressed:
            print("[PTT] Recording…")
        elif not pressed and was_pressed:
            print("[PTT] Sending turn")
            await ws.send(json.dumps({"type": "input_audio_buffer.commit"}))
            await ws.send(json.dumps({"type": "response.create"}))
        was_pressed = pressed
        await asyncio.sleep(0.02)

# In main(), add ptt_loop to the asyncio.gather() call after switching to manual mode
```
</RunPromptCell>

**Comparing the two modes.** In controlled tests, PTT adds approximately 150 ms to perceived response time (the user must release the key before the turn commits). VAD adds 500–700 ms of silence window but removes the button entirely. Neither is universally better: ship VAD as the default with a clearly labeled PTT fallback toggle in the UI. Without a visible indicator — "Listening…" / "Processing…" — users cannot tell when VAD is waiting for speech versus waiting for the model. That missing indicator is the most common source of user confusion in production voice agents, not VAD threshold tuning.

---

## Hands-on Exercise: Dual-Mode Voice Agent with Runtime Switching

**Goal:** A single Python script that starts in VAD mode and switches to PTT when the user says "switch to push-to-talk," then back to VAD when they say "switch to voice mode."

**Steps:**

1. Start from `continuous_voice.py` from the session connection section above.
2. Add a `response.audio_transcript.delta` handler that accumulates the agent's spoken text into a string buffer that resets on each `response.done` event.
3. In the `response.done` handler, check the accumulated transcript for the phrase "push-to-talk." If found, send `session.update` with `turn_detection: null`, print `[Mode: PTT]`, and launch the `ptt_loop` coroutine.
4. Add a second phrase check for "voice mode" that re-enables VAD with the original threshold and `silence_duration_ms` values.
5. Ensure the `ptt_loop` coroutine terminates cleanly when mode switches back to VAD (use a shared `asyncio.Event`).

**Success criteria:**

- Agent responds without any button press in VAD mode.
- After saying "switch to push-to-talk," the agent confirms the switch verbally. Subsequent turns require holding spacebar to record and releasing to send.
- After saying "switch to voice mode," VAD resumes with the original `silence_duration_ms: 600` configuration.
- No `error` events or audio glitches occur during either mode transition.
- The full 5-minute session log shows clean `session.updated` events at each transition.

Next chapter: [[03-tool-calling-live-session]] — registering function tools in a Realtime session, dispatching them non-blockingly, and injecting results back into the audio flow within 500ms.
