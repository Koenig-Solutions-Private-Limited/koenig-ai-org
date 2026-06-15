---
chapter_num: 6
course_slug: openai-realtime-api-voice-agents-end-to-end
title: "Cost, Quality, and Model Trade-offs"
status: g3-passed
duration_min: 55
vendor_tag: openai
learning_objectives:
  - "Calculate the true cost of a Realtime API session: audio input tokens + audio output tokens + text tokens"
  - "Compare Realtime API vs Cartesia TTS + Whisper STT for a given use case on cost and latency"
  - "Implement Kokoro or Chatterbox as a TTS layer for non-live use cases (notifications, pre-rendered audio)"
  - "Design a voice quality rubric: naturalness, response speed, tool accuracy, and error recovery rate"
whats_new: "Cost comparison across gpt-realtime-2, Whisper-1 + GPT-4o-mini + Cartesia, and Kokoro self-hosted as of June 2026; Chatterbox MIT release (Resemble AI, April 2025)"
sources:
  - url: "https://openai.com/api/pricing"
    title: "OpenAI API Pricing"
  - url: "https://platform.openai.com/docs/guides/speech-to-text"
    title: "OpenAI Speech-to-Text (Whisper) Documentation"
  - url: "https://huggingface.co/hexgrad/Kokoro-82M"
    title: "Kokoro-82M on HuggingFace"
  - url: "https://docs.cartesia.ai"
    title: "Cartesia API Documentation"
  - url: "https://github.com/resemble-ai/chatterbox"
    title: "Chatterbox TTS by Resemble AI"
owns:
  - "audio token pricing and cost calculation"
  - "Realtime API vs Whisper+TTS pipeline cost comparison"
  - "Kokoro self-hosted TTS integration"
  - "Cartesia TTS integration"
  - "Chatterbox TTS for self-hosted use cases"
  - "voice quality rubric design"
  - "cost-per-session modeling for three architectures"
  - "TTS for async vs live use cases"
defers_to:
  - "WebSocket/WebRTC implementation → ch02"
  - "tool calling mechanics → ch03"
  - "latency optimization techniques → ch04"
  - "deployment and scaling infrastructure → ch05"
quiz_topics:
  - "audio input vs output token pricing mechanics"
  - "cost difference between Realtime API and Whisper+GPT-4o-mini+Kokoro for a 5-min session"
  - "when to choose Kokoro self-hosted vs Realtime API"
  - "four dimensions of the voice quality rubric"
notebooklm_source_focus:
  - "OpenAI Realtime API pricing documentation"
  - "Kokoro TTS documentation and benchmarks"
  - "Cartesia API documentation and pricing"
  - "Whisper API pricing page"
word_budget: { min: 1500, max: 2500 }
quiz:
  - question: "The Realtime API charges $32/1M tokens for audio input and $64/1M tokens for audio output. In a balanced 5-minute session where both parties speak equally, what fraction of the total audio bill comes from output tokens?"
    options:
      - "One quarter of the audio bill"
      - "One third of the audio bill"
      - "One half of the audio bill"
      - "Two thirds of the audio bill"
    correct_idx: 3
    explanation: "With equal speaking time, input and output token counts are equal. But output costs 2× input. So output bill = 2× input bill, and output / (input + output) = 2/3 ≈ 67%. Two thirds of your audio bill comes from the agent speaking — not the user."
    section_anchor: "audio-token-pricing-how-the-realtime-api-bills"
  - question: "A 5-minute balanced Realtime API session costs ~$0.39. The same session via Whisper + GPT-4o-mini + Kokoro self-hosted costs ~$0.031 in API fees. What is the primary driver of the cost gap?"
    options:
      - "Whisper STT and audio input tokens cost the same, so the transcription stage is price-equivalent"
      - "The Realtime API bills STT, reasoning, and TTS as audio tokens; Kokoro self-hosted eliminates the TTS cost"
      - "GPT-4o-mini processes audio tokens natively, so it avoids Whisper fees and matches Realtime API voice quality"
      - "The Realtime API charges for idle session time even when no audio is actively being transmitted"
    correct_idx: 1
    explanation: "The Realtime API charges audio-native STT + reasoning + TTS at $32–64/1M audio tokens. The pipeline pays Whisper's $0.006/min STT rate (text pricing), GPT-4o-mini's low text-token rates, and zero for self-hosted Kokoro. Removing the audio output cost removes the single most expensive line item."
    section_anchor: "cost-per-session-modeling-three-architectures"
  - question: "You are building an automated outbound notification system sending 50,000 voice messages per day, each 20 seconds long. No user responds — the system speaks and disconnects. Which architecture is correct?"
    options:
      - "Realtime API, because it provides native voice quality and built-in barge-in interruption handling"
      - "Kokoro or Chatterbox self-hosted, because the workload is async with no live-latency requirement"
      - "Cartesia managed API, because streaming TTS quality always exceeds any open-source self-hosted alternative"
      - "Whisper plus Realtime API in hybrid, because Whisper enables quality monitoring of outbound audio"
    correct_idx: 1
    explanation: "The Realtime API's premium buys you sub-500ms interactive latency and VAD-based turn detection — neither matters for one-way notifications. At 50,000 × $0.039/session, the Realtime API costs $1,950/day. Kokoro self-hosted on a single A10G instance brings that to under $50/day in GPU costs with zero per-call API fee."
    section_anchor: "kokoro-and-chatterbox-self-hosted-tts-for-async-workloads"
  - question: "Which four dimensions make up the voice quality rubric described in this chapter?"
    options:
      - "Audio bitrate, transcription accuracy, first-audio latency, and system uptime"
      - "NPS score, session duration, user retention rate, and CSAT"
      - "Naturalness, response speed, tool accuracy, and error recovery rate"
      - "Concurrent sessions, throughput, network jitter, and packet loss rate"
    correct_idx: 2
    explanation: "The rubric covers user perception (naturalness), operational performance (response speed, tool accuracy), and resilience (error recovery rate). Infrastructure metrics like bitrate and uptime are inputs to those outcomes, not rubric dimensions themselves."
    section_anchor: "building-a-voice-quality-rubric"
---

# The Realtime API Is 6–12× More Expensive per Session — Know When That Premium Pays Off

The OpenAI Realtime API is the fastest path from user speech to agent response. It is not always the cheapest. Audio tokens are priced at a significant premium over text tokens, and for high-volume or latency-tolerant use cases — automated notifications, IVR trees, batch audio generation — a Whisper + LLM + self-hosted TTS stack costs 70–90% less per session. This chapter gives you the math to choose correctly, the code to implement the alternatives, and a rubric to evaluate voice quality across all three architectures so you can defend any architecture decision with numbers.

## Audio Token Pricing: How the Realtime API Bills

Every second of audio in a Realtime API session is tokenized at approximately 800 tokens per minute of natural speech. Both sides of the conversation are metered independently: audio input tokens (what the user says) and audio output tokens (what the agent says) are billed at different rates, with output priced at 2× input. [(OpenAI, "API Pricing")](https://openai.com/api/pricing)

| Token type | gpt-realtime-2 rate | 5-min session tokens | 5-min session cost |
|---|---|---|---|
| Audio input | $32 / 1M tokens | ~4,000 | $0.128 |
| Audio output | $64 / 1M tokens | ~4,000 | $0.256 |
| Text (system prompt, tool calls) | $3 / 1M tokens | ~2,000 | $0.006 |
| **Total** | | | **~$0.39** |

The 2:1 output-to-input ratio matters in practice because agents often speak more than users. In a customer support session where the agent delivers multi-sentence responses, output tokens frequently outpace input by 1.5–2×, pushing the effective cost per session above the symmetric estimate in the table above.

Text tokens — your system prompt, tool schemas, and tool call results — are priced far below audio. A 1,500-token system prompt and 500 tokens of tool I/O costs about $0.006 per session at gpt-realtime-2 rates, roughly 1.5% of the audio bill. Input caching reduces cached text input to $0.40/1M tokens, which helps if your system prompt is large and stable across sessions, but audio tokens dominate and cannot be cached.

You can measure your actual token consumption in real time by reading the `usage` field on each `response.done` event the server emits. The object includes `input_token_details` and `output_token_details`, both broken down into `audio_tokens` and `text_tokens` sub-fields. Log this per session from the start — it is the only reliable way to know whether your actual costs match the per-session estimate.

<Callout type="info">
800 audio tokens per minute is a baseline for natural conversational English at standard sample rates. Fast-talking users, noisy environments requiring longer audio windows, or high-sample-rate captures consume tokens faster. Instrument real sessions before committing this estimate to a budget model.
</Callout>

<KnowledgeCheck question="The Realtime API charges $32/1M for audio input and $64/1M for audio output. In a balanced 5-minute session where both parties speak equally, what fraction of the total audio bill comes from output tokens?" options={["One quarter", "One third", "One half", "Two thirds"]} correctIdx={3} explanation="Equal speaking time means equal input and output token counts, but output costs 2× input. So output bill = 2× input bill, and output / (input + output) = 2/3 ≈ 67%. Two thirds of your audio bill comes from the agent speaking." />

## Cost-Per-Session Modeling: Three Architectures

To choose an architecture, you need comparable numbers across options. The following models a 5-minute session with roughly equal user and agent speaking time:

| Architecture | STT | Reasoning | TTS | 5-min session cost |
|---|---|---|---|---|
| **A: Realtime API** | (built-in) | gpt-realtime-2 | (built-in) | **~$0.39** |
| **B: Whisper + 4o-mini + Cartesia** | Whisper-1 | GPT-4o-mini | Cartesia Sonic | **~$0.04–0.06** |
| **C: Whisper + 4o-mini + Kokoro** | Whisper-1 | GPT-4o-mini | Kokoro (self-hosted) | **~$0.031 API cost** |

Architecture B line-item breakdown: [(OpenAI, "Speech to Text")](https://platform.openai.com/docs/guides/speech-to-text)

- Whisper-1 transcription (5 min × $0.006/min): **$0.030**
- GPT-4o-mini text reasoning (~2,000 input + ~1,000 output tokens): **<$0.001**
- Cartesia Sonic TTS (~2.5 min of agent speech): **~$0.01–0.03**
- Total: **~$0.041–0.061**

Architecture C replaces Cartesia with Kokoro running on your own GPU. The only variable API costs are Whisper and the text LLM. At 1,000 sessions per day, a single A10G GPU instance handles the TTS load with throughput to spare, bringing the effective TTS cost to under $0.001 per session when amortized. The total is approximately $0.031 in API fees plus a small infrastructure share — call it $0.031–0.035 all-in at moderate volume.

The Realtime API costs roughly $0.39 for the same session. Architecture B saves approximately 85%; Architecture C saves 90–92% in API fees alone. The spec figure of "70–80% less" is a conservative floor that accounts for the infrastructure costs of self-hosting.

The Realtime API earns its premium in three ways you cannot easily replicate in a pipeline: (1) sub-500ms round-trip latency without complex streaming orchestration across three services, (2) built-in Voice Activity Detection and barge-in handling so the agent stops speaking the instant the user interrupts, and (3) a single stateful audio session that eliminates multi-hop state management between separate STT, LLM, and TTS services. When any of those directly improve your user experience, the premium is justified. When they don't — batch notifications, IVR trees, async pre-rendering — you are paying for latency no one will ever notice.

<KnowledgeCheck question="You need 5,000 outbound notification calls per day, each 30 seconds long, with no live user on the other end. The Realtime API costs ~$0.039 per call. A Kokoro self-hosted instance on an A10G GPU at $1.20/hr handles 40 calls/minute at full utilization. What is the approximate Kokoro cost per call?" options={["$0.0005", "$0.005", "$0.05", "$0.50"]} correctIdx={0} explanation="$1.20/hr ÷ (40 calls/min × 60 min/hr) = $1.20 ÷ 2,400 = $0.0005 per call. That is 78× cheaper than the Realtime API for a workload where interactive latency has no value." />

## Kokoro and Chatterbox: Self-Hosted TTS for Async Workloads

[Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) is an 82-million-parameter open-source TTS model released under the Apache License 2.0. At its size it runs on a single consumer GPU or CPU (more slowly), and on an A10G it generates audio significantly faster than real time — meaning you can batch-render a 30-second audio clip in under 5 seconds. It covers American and British English across multiple voices, and achieves naturalness scores competitive with mid-tier commercial alternatives for standard speech content.

For async workloads — outbound notifications, pre-rendered IVR prompts, batch audio generation — Kokoro is the correct default. The integration is straightforward:

```python
# pip install kokoro soundfile numpy
from kokoro import KPipeline
import soundfile as sf
import numpy as np

pipeline = KPipeline(lang_code='a')  # 'a' = American English

def synthesize(text: str, output_path: str, voice: str = 'af_heart') -> None:
    chunks = []
    for _, _, audio in pipeline(text, voice=voice, speed=1.0, split_pattern=r'\n+'):
        chunks.append(audio)
    sf.write(output_path, np.concatenate(chunks), samplerate=24000)

synthesize(
    "Your appointment is confirmed for 3 PM tomorrow.",
    "notification.wav"
)
```

[Chatterbox](https://github.com/resemble-ai/chatterbox), released by Resemble AI under the MIT License, extends the self-hosted option with explicit controls for emotional expressiveness. The `exaggeration` parameter lets you tune warmth from flat and neutral to noticeably personal — useful for notifications that should feel human rather than robotic:

```python
# pip install chatterbox-tts torchaudio
import torchaudio
from chatterbox.tts import ChatterboxTTS

model = ChatterboxTTS.from_pretrained(device="cuda")

def synthesize_expressive(text: str, output_path: str, exaggeration: float = 0.5) -> None:
    wav = model.generate(text, cfg_weight=0.3, exaggeration=exaggeration)
    torchaudio.save(output_path, wav, model.sr)

synthesize_expressive(
    "Great news — your order has shipped and arrives tomorrow.",
    "shipping_alert.wav",
    exaggeration=0.6
)
```

Deploy either model on any GPU instance: Vast.ai, Lambda Labs, or HuggingFace Inference Endpoints all work for variable load. For sustained volume above 5,000 sessions per day, provision a dedicated instance and wrap the pipeline function above in a FastAPI handler that accepts text payloads and returns audio bytes. The wrapper adds roughly 100 lines of code and turns your TTS layer into a private HTTP service you can version and monitor independently.

<Callout type="hot">
Kokoro and Chatterbox do not support real-time streaming audio output — they generate a complete audio file before returning. Do not use them in live interactive sessions where the user is waiting for a response. Use them only for batch or async workloads where audio is pre-rendered, or for outbound calls where no user interruption is expected.
</Callout>

## Cartesia: Managed Streaming TTS for Production Pipelines

[Cartesia](https://docs.cartesia.ai) provides a managed TTS API with low-latency streaming output — audio begins arriving within 50–80ms of the request. This makes it viable for live pipeline architectures where you need streaming TTS but want independent observability on each stage (transcription quality, LLM reasoning accuracy, and TTS naturalness all measured and logged separately).

The streaming integration pattern: feed GPT-4o-mini output to Cartesia's `/tts/bytes` endpoint sentence by sentence as the LLM generates, and Cartesia returns audio frames you forward to the client as they arrive. This brings total pipeline latency (Whisper → LLM → Cartesia → client) into the 700–1,200ms range under good conditions — slower than the Realtime API's 500ms target but competitive enough for many production use cases that do not require barge-in interruption. The techniques for pushing that latency lower — response chunking, VAD tuning, and connection pre-warming — are covered in [[latency-engineering|Chapter 4: Latency Engineering]].

Cartesia also supports voice cloning and style transfer, which matters when your product requires a branded voice persona. Self-hosted Kokoro and Chatterbox have fixed voice libraries and limited fine-tuning support as of mid-2026. If a custom trained voice is a product requirement, Cartesia or a similar managed API is the practical choice today. The separation of concerns is also a benefit for compliance teams: Cartesia's logging surfaces exactly what your TTS service synthesized, independent of the audio session log from your LLM provider.

## Building a Voice Quality Rubric

Cost tells you what you pay; quality tells you what you deliver. A voice agent needs a rubric that makes quality trade-offs visible and measurable across any architecture. Four dimensions cover the essential surface:

| Dimension | What it measures | Target | How to measure |
|---|---|---|---|
| **Naturalness** | Does the voice sound human and appropriate to context? | MOS ≥ 4.0 on a 1–5 scale | Weekly internal listener panel with a standardized 10-utterance script |
| **Response speed** | Time from end of user turn to first agent audio | Median TTFA ≤ 800ms | Automated logging of `response.audio.delta` event timestamps |
| **Tool accuracy** | Do tool calls return correct, complete results? | ≥ 95% pass rate on scripted scenarios | Nightly scripted session suite against staging environment |
| **Error recovery rate** | When a tool fails, does the agent recover verbally? | ≥ 90% of errors produce a valid verbal fallback | Fault injection testing — force tool timeouts and log agent behavior |

Naturalness is the only dimension that resists full automation. Internal MOS panels catch obvious regressions quickly, and session abandonment rate gives you a complementary signal from real traffic: when users hang up early in the first exchange, naturalness is usually the first thing to examine.

Response speed is fully automatable and the easiest to improve. Every Realtime API event carries a server-assigned timestamp. Log `input_audio_buffer.speech_stopped` and the first `response.audio.delta`, compute the delta, and track P50 and P95 across sessions. P95 matters more than P50 — a 95th-percentile TTFA above 1,500ms means roughly 1 in 20 users experiences a conversation-breaking pause.

Tool accuracy and error recovery require scripted test harnesses. Maintain a library of test conversations that exercise each tool your agent supports, run them nightly, and track regression. Error recovery requires deliberate fault injection: configure staging tool endpoints to return errors on command and verify the agent's verbal fallback triggers correctly rather than silently failing or repeating the question.

<KnowledgeCheck question="Which four dimensions make up the voice quality rubric described in this chapter?" options={["Audio bitrate, transcription accuracy, first-audio latency, and system uptime", "NPS score, session duration, user retention rate, and CSAT", "Naturalness, response speed, tool accuracy, and error recovery rate", "Concurrent sessions, throughput, network jitter, and packet loss rate"]} correctIdx={2} explanation="The rubric covers user perception (naturalness), operational performance (response speed and tool accuracy), and resilience (error recovery rate). Infrastructure metrics like bitrate and uptime are inputs to those outcomes, not rubric dimensions themselves." />

## Choosing Your Architecture: A Decision Framework

The right architecture depends on three variables: required latency, daily session volume, and whether the interaction is live or async.

| Signal | Architecture |
|---|---|
| Sub-second interactive latency required | Realtime API |
| Live session, cost-sensitive, latency ≤ 1,200ms acceptable | Whisper + LLM + Cartesia |
| High-volume async (notifications, IVR prompts, batch audio) | Whisper + LLM + Kokoro or Chatterbox self-hosted |
| Branded voice or fine-tuned voice persona | Cartesia (managed voice cloning) |
| Compliance: no third-party audio processing permitted | Kokoro or Chatterbox fully self-hosted |
| Hybrid product (live chat + async notifications) | Realtime API for live; Kokoro for async in the same codebase |

Many production deployments end up hybrid: the Realtime API handles live customer-facing sessions where latency and barge-in detection are visible to the user, while Kokoro handles batch rendering of thousands of personalized audio notifications overnight. The cost of each architecture matches its use case, and the two stacks coexist without conflict. Making the decision explicit — writing the table above for your specific use case — is more durable than defaulting to the most visible option.

<KnowledgeCheck question="Your product sends 50,000 personalized audio notifications per night with no live user interaction. Which architecture best minimizes cost?" options={["OpenAI Realtime API — lowest latency, simplest integration", "Whisper + GPT-4o-mini + Cartesia — managed TTS with competitive pricing", "Whisper + GPT-4o-mini + Kokoro self-hosted — lowest per-session cost at scale for async workloads", "Realtime API with a Kokoro fallback for overflow traffic"]} correctIdx={2} explanation="Async batch audio has no need for sub-second latency or barge-in detection. A self-hosted Kokoro instance on a GPU handles thousands of renders per hour at a fraction of the Realtime API audio token cost. For 50,000 nightly notifications, the cost difference is 70–80% versus the Realtime API." />

---

## Hands-On Exercise: Build a Three-Architecture Cost Comparison

**Goal:** Calculate the real cost-per-session for all three architectures using your own usage data.

**Steps:**

1. **Instrument a Realtime API session.** Run a 5-minute test call and log the `usage` field on each `response.done` event. Sum audio input tokens, audio output tokens, and text tokens. Multiply by current rates from [openai.com/api/pricing](https://openai.com/api/pricing).

2. **Model Pipeline B (Whisper + 4o-mini + Cartesia).** Estimate Whisper STT cost from your user speech duration. Add GPT-4o-mini text token cost from a comparable Chat Completions session on the same topic. Add Cartesia TTS cost for your agent's speech duration from current rates at [docs.cartesia.ai](https://docs.cartesia.ai).

3. **Model Pipeline C (Whisper + 4o-mini + Kokoro self-hosted).** Use the same Whisper and LLM numbers from Pipeline B. Estimate Kokoro GPU cost: pick an instance type, estimate concurrent session throughput, and calculate cost-per-session at your expected daily volume.

4. **Build the comparison table.** Three rows: architecture, 5-min session cost, monthly cost at your expected volume, and one capability you give up by choosing it.

**Success criteria:**
- You have real token counts from a live Realtime API session, not estimates.
- Your Pipeline B and C costs land within 20% of the formulas in this chapter.
- You have a written one-sentence justification for which architecture you would choose for your next production voice deployment.

---

Apply everything built across this course — sessions, tools, latency engineering, production deployment, and the cost framework from this chapter — in the **Build SupportVoice Capstone Project** (see the course capstone overview).
