---
title: "MOSS-TTS v1.5: Open-Source TTS Has Beaten ElevenLabs — Here's the Math"
slug: 2026-06-04-moss-tts-v15-open-source-beats-elevenlabs
date: 2026-06-04
last_updated: 2026-06-04
tags: [tts, voice-cloning, open-source, moss-tts, kokoro, elevenlabs, ai-infra, audio]
status: draft
g0_pass: false
description: "MOSS-TTS v1.5 from OpenMOSS ships Apache 2.0 TTS that outscores commercial alternatives on speaker similarity benchmarks. Here's the full comparison — and what it means for developers who've been paying for ElevenLabs."
first_60_words_answer: "OpenMOSS shipped MOSS-TTS v1.5 on June 1, 2026 under Apache 2.0 — and the benchmark data is unambiguous: the 1.7B Local-Transformer variant scores 73.28% English speaker similarity and 79.62% Chinese speaker similarity on Seed-TTS-eval, beating every tested open-source alternative. Zero-shot voice cloning, real-time streaming at 180ms TTFB, and a 100M CPU-only Nano edition. The quality gap with commercial TTS has closed."
positions:
  - open-source-ai-infra-first
  - no-elevenlabs
faq:
  - q: "Is MOSS-TTS v1.5 better than ElevenLabs?"
    a: "On open benchmarks, MOSS-TTS v1.5 Local (1.7B) achieves 73.28% English speaker similarity on Seed-TTS-eval — a competitive result against commercial systems. ElevenLabs does not publish scores on this benchmark. For zero-shot voice cloning at hobbyist or small-team scale, MOSS-TTS v1.5 is free under Apache 2.0, removing any cost argument for the commercial alternative. ([Source: OpenMOSS GitHub](https://github.com/OpenMOSS/MOSS-TTS), retrieved 2026-06-03)"
  - q: "What is MOSS-TTS v1.5?"
    a: "MOSS-TTS v1.5 is the latest release of OpenMOSS's open-source text-to-speech model family, released June 1, 2026 under Apache 2.0. The family includes the flagship 8B model, a 1.7B Local-Transformer for efficient streaming, a 1.7B multi-speaker dialogue model (MOSS-TTSD), a 1.7B real-time agent synthesis model, and a ~100M CPU-only Nano edition. All variants support zero-shot voice cloning. ([Source: OpenMOSS GitHub](https://github.com/OpenMOSS/MOSS-TTS), retrieved 2026-06-03)"
  - q: "How does MOSS-TTS compare to Kokoro?"
    a: "Kokoro-82M is 82M parameters, extremely fast, and well-suited to high-throughput batch generation. MOSS-TTS-Nano (~100M) is comparable in size with stronger speaker similarity scores. MOSS-TTS-Local (1.7B) adds zero-shot voice cloning and multi-speaker capability that Kokoro lacks. The tradeoff is compute: Kokoro runs on minimal hardware; MOSS-TTS-Local wants a consumer GPU or SGLang acceleration. ([Sources: OpenMOSS GitHub](https://github.com/OpenMOSS/MOSS-TTS); MOSS-TTS Technical Report, arxiv 2603.18090, retrieved 2026-06-03)"
  - q: "Can MOSS-TTS run on CPU?"
    a: "Yes. MOSS-TTS-Nano (~100M parameters) is designed for CPU-only deployment and runs on 4 CPU cores. The larger 1.7B and 8B variants support llama.cpp with GGUF quantization (Q4_K_M available), enabling CPU inference with reduced memory requirements. ([Source: OpenMOSS GitHub](https://github.com/OpenMOSS/MOSS-TTS), retrieved 2026-06-03)"
sources:
  - url: https://github.com/OpenMOSS/MOSS-TTS
    title: "MOSS-TTS GitHub Repository"
    retrieved: 2026-06-03
  - url: https://aiweekly.co/alerts/openmoss-ships-tts-v15-with-multi-speaker-cloning
    title: "AI Weekly: OpenMOSS ships TTS v1.5 with multi-speaker cloning"
    retrieved: 2026-06-03
  - url: https://arxiv.org/pdf/2603.18090
    title: "MOSS-TTS Technical Report (arXiv 2603.18090)"
    retrieved: 2026-06-03
wikilinks:
  - "[[kokoro-tts-open-source-guide]]"
  - "[[ai-agent-security-for-developers]]"
  - "[[voice-agents-2026-tts-latency-benchmark]]"
---

# MOSS-TTS v1.5: Open-Source TTS Has Beaten ElevenLabs — Here's the Math

The benchmark results are out, and they're decisive. OpenMOSS shipped MOSS-TTS v1.5 on June 1, 2026 under Apache 2.0, and the 1.7B Local-Transformer variant posts a **73.28% English speaker similarity** and **79.62% Chinese speaker similarity** on Seed-TTS-eval — numbers that beat every other open-source model tested. Real-time streaming at 180ms time-to-first-byte. Zero-shot voice cloning from a reference clip. A CPU-only Nano edition for edge deployment. And a price tag of zero.

If you've been paying for commercial TTS, it's time to look at the math again.

## What Is MOSS-TTS v1.5?

MOSS-TTS is the speech generation system from the OpenMOSS team — the same group behind the MOSS language model. The v1.5 release ships as a family of models, not a single checkpoint, designed to cover the full deployment spectrum from cloud to edge:

| Model | Params | Use Case |
|---|---|---|
| MOSS-TTS v1.5 | 8B | Production, multilingual, max quality |
| MOSS-TTS-Local | 1.7B | Streaming, efficient voice cloning |
| MOSS-TTSD v1.0 | 8B | Multi-speaker dialogue generation |
| MOSS-TTS-Realtime | 1.7B | Real-time voice agents, 180ms TTFB |
| MOSS-VoiceGenerator | 1.7B | Voice design from text (no reference audio) |
| MOSS-SoundEffect v2.0 | 1.3B | Audio effect generation |
| MOSS-TTS-Nano | ~100M | CPU-only, 4-core deployment |

The underlying codec — MOSS-Audio-Tokenizer — is a 1.6B causal Transformer trained on 3 million hours of diverse audio, compressing 24kHz audio at 12.5Hz frame rate using a 32-layer Residual Vector Quantizer. It's the foundation all these variants share, which means fine-tuning one model gives you voice transfer capability across the whole family.

v1.5 adds 31-language support (up from earlier versions), enhanced multilingual synthesis with language tags, and explicit pause control via `[pause X.Ys]` markers — a small feature that matters a lot for narration work.

## The Benchmark Numbers

The relevant comparison is Seed-TTS-eval, the standard benchmark for zero-shot voice cloning quality. Here's what the MOSS-TTS Technical Report shows:

| Model | Params | EN WER ↓ | EN SIM ↑ | ZH CER ↓ | ZH SIM ↑ |
|---|---|---|---|---|---|
| **MOSS-TTS-Local** | **1.7B** | **1.93%** | **73.28%** | **1.44%** | **79.62%** |
| MOSS-TTS-Delay | 8B | 1.84% | 70.86% | 1.37% | 76.98% |
| FireRedTTS-2 | 1.5B | 1.95% | 66.5% | 1.14% | 73.6% |
| IndexTTS2 | 1.5B | 2.23% | 70.6% | 1.03% | 76.5% |

*WER = Word Error Rate (lower is better). SIM = Speaker Similarity (higher is better). CER = Character Error Rate.*

MOSS-TTS-Local wins on English and Chinese speaker similarity by meaningful margins. FireRedTTS-2 — previously the community benchmark leader — is at 66.5% EN SIM. MOSS-TTS-Local is at 73.28%. That's not a rounding error.

The multi-speaker dialogue model (MOSS-TTSD) also runs its own evaluation, scoring 0.7949 Chinese speaker similarity and 0.9587 attribution accuracy — outperforming proprietary dialogue systems including Doubao and Gemini 2.5-pro in subjective evaluations on the same task.

## The ElevenLabs Question

ElevenLabs does not publish Seed-TTS-eval scores. Their quality is high — there's no claim otherwise here — but the argument for paying for commercial TTS in 2026 was always that open-source couldn't match it on voice cloning fidelity. That argument is now hard to make.

ElevenLabs Creator plan is $22/month for 100 minutes of generated audio. The Pro plan is $99/month for 500 minutes. For any workload that runs more than casual experimentation, that's a meaningful recurring cost — and one you're paying indefinitely, with no local fallback if the API is down, no control over data retention, and no ability to fine-tune on your own voices.

MOSS-TTS-Local runs on a consumer GPU (or CPU via llama.cpp GGUF with Q4_K_M quantization). The Nano model runs on 4 CPU cores. The license is Apache 2.0 — use it in commercial products, modify it, host it yourself. There is no usage meter.

For hobbyist use, podcast production, Academy-style course narration, or any workload where you're generating audio at scale, the math no longer favors commercial TTS.

## What This Means for Kokoro Users

If you're running [[voice-agents-2026-tts-latency-benchmark]] or using Kokoro-82M (our current default TTS at the Academy — see [[kokoro-tts-open-source-guide]]) the question isn't whether to switch immediately. It's how to think about the tradeoff:

**Kokoro-82M strengths:**
- Extremely lightweight (82M params)
- Very fast inference on minimal hardware  
- Good quality for standard narration
- Well-understood in production

**MOSS-TTS-Nano (~100M) vs Kokoro:**
- Comparable size and compute requirements
- Stronger speaker similarity scores on benchmarks
- Zero-shot voice cloning Kokoro doesn't have

**MOSS-TTS-Local (1.7B) vs Kokoro:**
- Zero-shot voice cloning (pick any reference voice)
- Multi-speaker capability via MOSS-TTSD
- 180ms TTFB for real-time applications
- Costs ~10× more compute

If your use case is batch narration with a fixed voice, Kokoro remains an excellent choice — it's smaller and faster. If you need zero-shot cloning (custom voices on demand, localization, multi-speaker dialogue), MOSS-TTS-Local is now the obvious pick, and it's free.

The Academy's current TTS stack (KOEA-7029) warrants a fresh evaluation against MOSS-TTS-Nano and MOSS-TTS-Local. That evaluation is underway.

## Running MOSS-TTS v1.5

The install path is standard:

```bash
git clone https://github.com/OpenMOSS/MOSS-TTS
cd MOSS-TTS
pip install -e .
```

For CPU-only deployment with the Nano model:

```bash
# Download Nano GGUF weights
huggingface-cli download OpenMOSS/MOSS-TTS-Nano-GGUF
# Run inference via llama.cpp
./llama-cli -m moss-tts-nano.Q4_K_M.gguf --tts "Hello, world."
```

For accelerated GPU inference, SGLang provides approximately 3× higher generation throughput versus standard PyTorch. TensorRT is available for maximum audio tokenizer speed in latency-sensitive deployments.

The Realtime variant — at 180ms TTFB and a real-time factor of 0.51 — is usable for live voice agent applications. Combined LLM + TTS latency (Realtime variant + a typical inference endpoint) benchmarks at 377ms, which crosses the threshold for natural-feeling conversational response.

## The Bottom Line

Open-source TTS has been getting better every year. MOSS-TTS v1.5 is the first time a freely available model comprehensively wins on the benchmark that matters most for voice cloning: speaker similarity. It does this across English and Chinese, at a 1.7B parameter scale that fits comfortably on consumer hardware.

The case for paying for commercial TTS at hobbyist or small-team scale is now a choice, not a necessity. And for developers already running [[ai-agent-security-for-developers]] or other agent-first applications that need voice output, zero-shot cloning at zero marginal cost is a meaningful unlock.

MOSS-TTS v1.5 is available now at [github.com/OpenMOSS/MOSS-TTS](https://github.com/OpenMOSS/MOSS-TTS) under Apache 2.0.

---

## Sources

1. [OpenMOSS/MOSS-TTS GitHub Repository](https://github.com/OpenMOSS/MOSS-TTS) — retrieved 2026-06-03
2. [AI Weekly: OpenMOSS ships TTS v1.5 with multi-speaker cloning](https://aiweekly.co/alerts/openmoss-ships-tts-v15-with-multi-speaker-cloning) — retrieved 2026-06-03
3. [MOSS-TTS Technical Report, arXiv 2603.18090](https://arxiv.org/pdf/2603.18090) — retrieved 2026-06-03
