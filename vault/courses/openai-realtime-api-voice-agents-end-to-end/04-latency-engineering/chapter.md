---
date: 2026-06-15
author: chapter-author-2
vendor_tag: openai
content_type: course-chapter
course_slug: openai-realtime-api-voice-agents-end-to-end
chapter_num: 4
title: "Latency Engineering: Making Voice Feel Fast"
status: g0-passed
last_updated: 2026-06-15
reading_time_min: 50
learning_objectives:
  - "Profile the latency breakdown of a voice session: client audio capture → API → first audio token → full response"
  - "Implement interrupt handling so the agent stops speaking immediately when the user barge-in interrupts"
  - "Apply speculative response patterns — start generating audio before tool calls complete"
  - "Optimize WebRTC configuration for minimal jitter and packet loss on mobile networks"
whats_new:
  - "Timestamp instrumentation harness for end-to-end latency profiling"
  - "Interrupt handling with synchronous audio flush on barge-in"
  - "Speculative verbal acknowledgment as latency filler before tool results arrive"
  - "WebRTC jitter buffer tuning via RTCRtpReceiver.jitterBufferDelayHint and Opus SDP rewrite"
prerequisites:
  - chapter: 2
    title: "Hello-World Voice Agent — WebSocket Transport"
  - chapter: 3
    title: "Tool Calling in a Live Voice Session"
positions: []
first_60_words_answer: "The model's inference speed is not yours to optimize. You cannot make the Realtime API think faster, and chasing that goal wastes engineering time you could spend on levers you actually control. What you can control — entirely — is what happens on every side of that inference window: how fast you commit audio into the session, whether you start"
faq:
  - question: "What is time-to-first-audio-token (TTFAT) and can it be reduced?"
    answer: >
      Time-to-first-audio-token (TTFAT) is the delay between submitting audio input and receiving the first audio token in the API response — typically 200–600ms depending on model load and session state. It is entirely controlled by the API provider and cannot be reduced through application code. Developers should instead focus on client playback startup delay and speculative acknowledgment patterns, which are fully within application control. See the [OpenAI Realtime API guide](https://developers.openai.com/api/docs/guides/realtime) for the full latency architecture breakdown.
  - question: "How does the speculative acknowledgment pattern reduce perceived tool-call latency?"
    answer: >
      The speculative acknowledgment pattern injects a short verbal filler — such as "Let me check that for you…" — into the conversation immediately when a tool call begins, before the result is available. The model streams audio for this phrase while the tool executes in parallel, converting 300–800ms of mandatory silence into audible speech. This trade is worthwhile for any tool that takes more than approximately 150ms to complete. See the [Realtime API reference](https://developers.openai.com/api/docs/api-reference/realtime) for `conversation.item.create` event details.
  - question: "When should jitterBufferDelayHint be reduced for WebRTC voice agents?"
    answer: >
      The `jitterBufferDelayHint` hint on `RTCRtpReceiver` should be lowered when voice agent startup latency is consistently high on well-connected networks with low natural packet jitter. Setting a value around 0.03 seconds (30ms vs the browser default of ~100ms) can recover 50–70ms of audio startup delay. However, on lossy mobile connections, values below 20ms risk more audible glitches than the latency saved. Always measure baseline jitter in `chrome://webrtc-internals` before shipping any tuning. See the [W3C WebRTC specification](https://w3c.github.io/webrtc-pc/) for the full jitter buffer API.
---

# Voice Latency Is a Perception Problem — And You Can Win It Without Touching the Model

The model's inference speed is not yours to optimize. You cannot make the Realtime API think faster, and chasing that goal wastes engineering time you could spend on levers you actually control. What you can control — entirely — is what happens on every side of that inference window: how fast you commit audio into the session, whether you start audio playback on the first token or the last, how instantly the agent goes silent when the user interrupts, and how much of the tool-call gap you fill with something useful. A 500ms model response that starts playing at token one feels faster than a 300ms response that sits in a client buffer for 250ms before the first speaker sample.

This chapter is about the four levers that move perceived latency without touching inference: a profiling harness that makes the breakdown visible, interrupt handling that stops audio within a single event loop tick, speculative verbal acknowledgments that fill tool-call silence, and WebRTC jitter buffer configuration that keeps audio smooth when the network isn't.

## The Latency Budget: Where Every Millisecond Goes

A full voice round-trip has five measurable segments with very different ownership profiles:

| Segment | Typical range | You own it? |
|---|---|---|
| Microphone capture + VAD processing | 20–100 ms | Partially (VAD sensitivity) |
| Network: client → API endpoint | 30–150 ms | Partially (region proximity) |
| Model time-to-first-audio-token (TTFAT) | 200–600 ms | No |
| Audio chunk streaming: API → client | ~10–20 ms per 20ms chunk | No |
| Client playback queue startup | 0–200 ms | Yes, fully |

The model TTFAT column dominates the total and is completely fixed. That 200–600ms window is model scheduling, KV-cache state, and token sampling — none of which you influence through application code. Focus instead on the two rows you own: VAD sensitivity (reducing false turn-ends that trigger premature responses) and the playback queue startup delay, which many implementations silently leave at 150–200ms by waiting for `response.done` before starting playback. Start on `response.audio.delta`, not `response.done`, and you typically recover 100–180ms for free.

Network latency to the OpenAI API is the one structural lever you partially control: deploying your relay server in the same AWS region as the API endpoint (currently us-east-1 for `api.openai.com`) cuts your RTT contribution roughly in half compared to a client calling from Europe. See the [OpenAI Realtime API guide](https://developers.openai.com/api/docs/guides/realtime) for transport architecture recommendations.

A practical way to think about the budget: anything above 250ms total perceived latency from end-of-user-speech to first audible agent token registers as a noticeable pause in conversation. Anything above 800ms breaks the conversational flow entirely — users start to wonder if the system heard them and often speak again, triggering a barge-in. Your goal is to stay under 500ms total across all segments you control, leaving the model's TTFAT as the one uncontrolled variable inside that envelope.

<KnowledgeCheck question="Which segment of the voice round-trip offers the most developer leverage for reducing perceived latency?" options={["Model TTFAT — choosing a smaller model cuts inference time", "Network RTT — WebRTC routes packets faster than WebSocket", "Client playback startup and speculative response timing — both are fully application-controlled", "VAD sensitivity — a lower threshold fires speech_stopped faster"]} correctIdx={2} explanation="Model TTFAT is fixed for a given model. Network RTT depends on geography, not transport type. VAD sensitivity is a small lever with tradeoffs. Playback startup delay and when you issue response.create are pure application decisions worth 100–300ms each." />

## Instrumentation First: Seeing the Pipeline

Measure before you optimize. Add a lightweight profiler that records `performance.now()` at each event boundary; run five back-to-back turns; compare. Any segment averaging more than 30ms beyond its baseline is your first target.

```typescript
// latency-profiler.ts
export interface Checkpoint { label: string; ts: number; }

export class LatencyProfiler {
  private checkpoints: Checkpoint[] = [];
  constructor(private sessionId: string) {}

  mark(label: string) {
    this.checkpoints.push({ label, ts: performance.now() });
  }

  report(): void {
    if (this.checkpoints.length < 2) return;
    console.log(`\n[Latency — ${this.sessionId}]`);
    for (let i = 1; i < this.checkpoints.length; i++) {
      const delta = this.checkpoints[i].ts - this.checkpoints[i - 1].ts;
      console.log(`  ${this.checkpoints[i - 1].label} → ${this.checkpoints[i].label}: ${delta.toFixed(1)} ms`);
    }
    const total = this.checkpoints.at(-1)!.ts - this.checkpoints[0].ts;
    console.log(`  TOTAL: ${total.toFixed(1)} ms\n`);
    this.checkpoints = [];
  }
}
```

Wire it into your Chapter 3 WebSocket event loop:

```typescript
const profiler = new LatencyProfiler(sessionId);
let firstAudioDeltaSeen = false;

ws.on('message', (raw: string) => {
  const event = JSON.parse(raw);
  switch (event.type) {
    case 'input_audio_buffer.speech_started':
      profiler.mark('VAD_speech_started'); break;
    case 'input_audio_buffer.speech_stopped':
      profiler.mark('VAD_speech_stopped'); break;
    case 'input_audio_buffer.committed':
      profiler.mark('buffer_committed'); break;
    case 'response.created':
      profiler.mark('response_created'); break;
    case 'response.audio.delta':
      if (!firstAudioDeltaSeen) {
        profiler.mark('first_audio_token');
        firstAudioDeltaSeen = true;
        startAudioPlayback(); // ← start here, not on response.done
      }
      break;
    case 'response.done':
      profiler.mark('response_done');
      profiler.report();
      firstAudioDeltaSeen = false;
      break;
  }
});
```

After instrumentation, most implementations surface the same top two offenders: a 100–200ms `first_audio_token → playback start` gap caused by buffering on `response.done`, and a 200ms–2s gap in `response_created → response_done` whenever a tool call is in flight. The first is fixed in one line. The second requires the speculative pattern in the next section.

## Interrupt Handling: Stop on a Dime

When the user talks over the agent, they must hear silence within the same event loop tick — not after the current audio chunk finishes, not after a 200ms drainage cycle. Any perceptible overlap of old agent speech and new user speech signals that the system is not listening, which destroys trust faster than any latency metric.

The [Realtime API fires `input_audio_buffer.speech_started`](https://developers.openai.com/api/docs/api-reference/realtime) the instant server-side VAD detects voice onset. Your handler has two mandatory obligations: cancel the in-flight model response and flush the local speaker buffer synchronously.

```typescript
let responseInFlight = false;

ws.on('message', (raw: string) => {
  const event = JSON.parse(raw);

  switch (event.type) {
    case 'response.created':
      responseInFlight = true; break;

    case 'response.done':
    case 'response.cancelled':
      responseInFlight = false; break;

    case 'input_audio_buffer.speech_started':
      if (responseInFlight) {
        // Cancel server-side generation immediately
        ws.send(JSON.stringify({ type: 'response.cancel' }));

        // Flush client-side speaker buffer synchronously
        audioPlayer.flush(); // must be synchronous — schedule = audible bleed
      }
      break;
  }
});
```

Two failure modes to guard against:

**Asynchronous flush.** If `audioPlayer.flush()` posts a task to the event queue instead of draining inline, the old audio continues for one or two frames. Use `AudioContext.close()` followed by constructing a fresh context, or `sourceNode.stop(0)` with offset zero and a new `BufferSourceNode` for the next response. The `0` offset is the critical difference: `stop()` without an offset stops at the next render quantum (one frame delay); `stop(0)` stops at the earliest safe boundary.

**Double-cancel.** Short sounds — background noise, a breath, a click — may fire `speech_started` followed immediately by `speech_stopped` with no real barge-in intent. The `responseInFlight` guard prevents cancelling a response that has already finished or was never started.

<KnowledgeCheck question="Why must the client-side audio buffer flush be synchronous when handling speech_started?" options={["The API rejects the response.cancel if the client is still playing audio", "Asynchronous draining allows old agent speech to overlap new user input, destroying the barge-in illusion", "WebSocket message ordering requires the flush before response.cancel is sent", "Synchronous flush reduces the WebRTC jitter buffer's target delay"]} correctIdx={1} explanation="The API cancels cleanly regardless of client audio state. The synchronous flush is required on the client side: if you schedule the drain, the old audio bleeds for one render quantum and the user hears the agent's voice overlap their own — the precise experience you're trying to eliminate." />

## Speculative Response: Audio Before the Tool Completes

Every tool call introduces a mandatory silence: the model requests a result, your server fetches it, you inject it, then you request a continuation response. At 300ms per tool that gap is noticeable; at 800ms it sounds broken. The fix is to send a verbal acknowledgment to the conversation before the tool finishes, letting the model generate a natural filler phrase while execution runs in parallel.

The [Realtime API conversation model](https://developers.openai.com/api/docs/api-reference/realtime) accepts `conversation.item.create` events out of band. Inject a short assistant message immediately on `response.function_call_arguments.done`, then issue `response.create` for that message. While the model streams audio for "Let me check that for you…", your tool is executing in parallel.

```typescript
ws.on('message', async (raw: string) => {
  const event = JSON.parse(raw);

  if (event.type === 'response.function_call_arguments.done') {
    const { call_id, name, arguments: argsJson } = event;
    const args = JSON.parse(argsJson);

    // 1. Inject acknowledgment text immediately
    ws.send(JSON.stringify({
      type: 'conversation.item.create',
      item: {
        type: 'message',
        role: 'assistant',
        content: [{ type: 'text', text: getAcknowledgment(name) }],
      }
    }));
    ws.send(JSON.stringify({ type: 'response.create', response: { modalities: ['audio', 'text'] } }));

    // 2. Execute tool in parallel
    const result = await executeTool(name, args);

    // 3. Inject result and request continuation
    ws.send(JSON.stringify({
      type: 'conversation.item.create',
      item: { type: 'function_call_output', call_id, output: JSON.stringify(result) }
    }));
    ws.send(JSON.stringify({ type: 'response.create' }));
  }
});

function getAcknowledgment(toolName: string): string {
  const map: Record<string, string> = {
    get_weather:     'Let me check the current conditions…',
    create_reminder: 'Setting that up now…',
    lookup_account:  'Pulling up your account…',
  };
  return map[toolName] ?? 'One moment…';
}
```

This trades a single-response turn for a two-turn structure. The cost is minimal — a short text token sequence for the filler. The benefit is that 300–800ms of tool latency becomes inaudible because the agent is speaking through it. For tools that take less than ~150ms (local lookups, in-memory caches), skip the acknowledgment — the added turn introduces more overhead than the silence it would hide.

For deeper tool architecture patterns including caching frequently-called results and pre-fetching likely queries, see the [[claude-mcp-mastery|Claude MCP Mastery]] course, which covers client-server tool contracts and low-latency dispatch strategies that transfer directly to Realtime API tool design.

<KnowledgeCheck question="When is the speculative acknowledgment pattern worth its overhead cost?" options={["Always — verbal filler is always better than silence", "Only when tool latency exceeds ~150ms; below that the added turn costs more than it saves", "Only when using WebRTC transport, not WebSocket", "When the model TTFAT is above 400ms"]} correctIdx={1} explanation="Each injected conversation item adds a small but real processing cycle. For sub-150ms tools, the overhead exceeds the silence it covers. The pattern pays off when tool latency is long enough that the user would consciously notice the gap — roughly 150ms and above." />

## WebRTC Jitter Buffer Tuning

WebRTC transport (recommended for browser clients in production) introduces one additional latency variable: the jitter buffer, which the browser uses to smooth out packet reordering on congested or mobile networks. The default target delay is conservative — browsers typically buffer 80–120ms of audio to absorb packet jitter — and this default adds constant startup latency to every response.

The [W3C WebRTC specification](https://w3c.github.io/webrtc-pc/) exposes `RTCRtpReceiver.jitterBufferDelayHint` as a hint to the browser's jitter buffer algorithm. Setting a smaller value tells the browser to trade smoothness for lower startup delay:

```typescript
pc.ontrack = (event) => {
  const receiver = event.receiver;

  // Hint a 30ms target (vs browser default ~100ms). Advisory — browser may override on poor links.
  if ('jitterBufferDelayHint' in receiver) {
    (receiver as any).jitterBufferDelayHint = 0.03; // seconds
  }

  const stream = new MediaStream([event.track]);
  audioElement.srcObject = stream;
};
```

For mobile networks where packet loss is the primary problem rather than jitter, the better lever is codec configuration. The Realtime API uses Opus over WebRTC, and you can influence its parameters during SDP negotiation. A lower bitrate with in-band FEC enabled tolerates packet loss better than a higher-bitrate stream:

```typescript
async function applyLatencyBiasedSDP(
  pc: RTCPeerConnection,
  offer: RTCSessionDescriptionInit
): Promise<RTCSessionDescriptionInit> {
  await pc.setRemoteDescription(offer);
  const answer = await pc.createAnswer();

  // Set Opus to voice-optimized 24kbps mono with forward error correction
  answer.sdp = answer.sdp!.replace(
    /a=fmtp:(\d+) (.+useinbandfec.+)/g,
    (_m, pt, params) => `a=fmtp:${pt} ${params};maxaveragebitrate=24000;stereo=0`
  );

  await pc.setLocalDescription(answer);
  return answer;
}
```

On very flaky mobile connections, also consider setting `iceTransportPolicy: 'relay'` on your `RTCPeerConnection` configuration to force TURN relay. Direct ICE paths through mobile NAT often add 30–80ms of unpredictable variance; a good TURN server in the same region as your server is more consistent. See the [MDN WebRTC API documentation](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API) for full ICE configuration options and when relay is and isn't worth the extra hop.

<KnowledgeCheck question="What does a lower jitterBufferDelayHint value trade off?" options={["Higher Opus bitrate in exchange for lower startup latency", "Shorter buffer depth — lower startup latency at the cost of less tolerance for late-arriving packets", "Forced TURN relay instead of direct ICE path", "Reduced VAD sensitivity on the server side"]} correctIdx={1} explanation="The jitter buffer absorbs late packets by buffering ahead. A smaller hint shrinks that buffer, so audio starts sooner but individual late packets are more likely to cause a glitch. This is the right trade on good connections; on very lossy links, enable FEC instead and let the hint stay closer to default." />

## Optimization Priority Stack

After instrumentation, virtually every Realtime API implementation surfaces the same top three offenders in roughly this order:

**First: Playback startup delay (50–200ms).** Fixed by calling `startAudioPlayback()` on the first `response.audio.delta` event, not on `response.done`. One line change, immediate improvement.

**Second: Tool execution silence (200ms–2s).** Fixed with the speculative acknowledgment pattern. The agent speaking through the tool call gap costs one additional conversation turn — a worthwhile trade for any tool taking more than 150ms.

**Third: Client jitter buffering (20–100ms).** Fixed with `jitterBufferDelayHint` and Opus SDP tuning. The payoff is largest on mobile connections where the default buffer is deepest.

One pattern that pays dividends across all three: pre-fetch tool data for the queries most likely to arrive in a session before the user asks. If your voice agent handles weather queries and 60% of sessions ask about the same city the user previously queried, pre-fetching that city's conditions during the greeting exchange converts a 400ms tool call into a synchronous map lookup. This is the aggressive end of the "hide latency" philosophy — not faster execution, but execution that already completed before the user formed the intent. Tool pre-fetching is worth implementing for any tool whose inputs can be predicted from session context.

Model TTFAT and cross-continental network RTT are structural: you address them by choosing a relay server near the API endpoint, not through application code. If you need to route different query types to different models inside a live session — for example, falling back to a smaller model when cost-per-session thresholds are hit — see the [[gemini-enterprise-agents|Gemini Enterprise Agents]] course for multi-model routing patterns that adapt to runtime load without re-architecting the session layer. For infrastructure-level optimizations — sticky WebSocket sessions, reconnect protocols that preserve context, and horizontal scaling under concurrent voice load — see [[05-production-deployment-scaling/chapter.md|Chapter 5: Production Deployment and Scaling]]. For cost implications of the speculative pattern's extra response tokens, see [[06-cost-quality-model-tradeoffs/chapter.md|Chapter 6: Cost, Quality, and Model Trade-offs]].

<Callout type="warning">
Do not optimize WebRTC jitter buffer settings on production before measuring baseline jitter on your target network profiles. On well-connected broadband the hint has negligible effect. On mobile, an overly aggressive hint (< 20ms) can cause more audible glitches than the latency it saves. Measure first with Chrome's `chrome://webrtc-internals` or a TURN server analytics dashboard before shipping the tuning.
</Callout>

---

## Hands-On Exercise

**Goal:** Measure your Chapter 3 agent's latency profile and reduce your single largest bottleneck by ≥ 20%.

**Setup:** Start from your working Chapter 3 agent (WebSocket transport, two tool calls wired). Add the `LatencyProfiler` class above and instrument every event handler as shown.

**Steps:**

1. Run five back-to-back voice turns. After each turn, capture the profiler console output. Compute the average delta for each segment across the five runs.

2. Identify the single segment with the highest average. Implement the matching optimization:
   - `first_audio_token → playback start` averaging > 100ms → start playback on `response.audio.delta` instead of `response.done`.
   - `response_created → response_done` averaging > 300ms during tool calls → implement the speculative acknowledgment pattern for your `get_weather` tool.
   - Barge-in response delay > 100ms → implement `response.cancel` + synchronous audio flush on `speech_started`.

3. Run five more turns after your change. Compare the before and after averages for the targeted segment.

**Success criteria:** The targeted segment's average drops by ≥ 20%. Paste the before and after profiler output as your submission.

**Stretch goal:** Throttle your browser to "Slow 3G" in DevTools Network panel, then apply the `jitterBufferDelayHint` and Opus SDP rewrite. Observe the difference in `chrome://webrtc-internals` under the `inboundRtp` jitter metric before and after.

---

Next chapter: [[05-production-deployment-scaling/chapter.md|Chapter 5: Production Deployment and Scaling]] — sticky sessions, horizontal scaling under concurrent voice load, PII redaction, and session reconnect protocols for when the network drops mid-call.
