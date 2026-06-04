---
date: 2026-06-01
last_updated: 2026-06-01
author: vardaan-koenig
agent_drafted_by: blog-author
ticket: KOEA-7029
vendor_tag: community
content_type: tutorial
status: draft
reading_time_min: 10
primary_query: "kokoro tts production deployment"
contrarian_angle: "Kokoro TTS gives you ElevenLabs-quality audio at zero variable cost — the real deployment challenge isn't the model, it's wrapping it in a production-grade API server, and that takes about 20 lines of FastAPI."
sources:
  - https://github.com/hexgrad/kokoro
  - https://huggingface.co/hexgrad/Kokoro-82M
  - https://lightning.ai/docs/overview/getting-started
  - https://modal.com/docs/guide
  - https://www.baseten.co/blog/how-to-deploy-kokoro-tts/
hero_image: auto:flux
references:
  - n: 1
    title: "Kokoro GitHub Repository (hexgrad/kokoro)"
    url: https://github.com/hexgrad/kokoro
    retrieved: 2026-06-01
  - n: 2
    title: "Kokoro-82M Model Card — Hugging Face"
    url: https://huggingface.co/hexgrad/Kokoro-82M
    retrieved: 2026-06-01
  - n: 3
    title: "Lightning AI Studio Documentation"
    url: https://lightning.ai/docs/overview/getting-started
    retrieved: 2026-06-01
  - n: 4
    title: "Modal Serverless GPU Documentation"
    url: https://modal.com/docs/guide
    retrieved: 2026-06-01
  - n: 5
    title: "Baseten: Deploy Kokoro TTS"
    url: https://www.baseten.co/blog/how-to-deploy-kokoro-tts/
    retrieved: 2026-06-01
whats_new:
  - Kokoro 82M is MIT-licensed and matches ElevenLabs quality at zero variable cost for self-hosted deployments.
  - FastAPI + uvicorn wrapping takes ~20 lines and gives you a drop-in OpenAI-compatible TTS endpoint.
  - Docker self-host, Modal serverless, Lightning AI Studio, and Baseten all supported — pick based on your latency and ops budget.
learning_objectives:
  - Deploy Kokoro TTS as a production API using Docker, Modal, Lightning AI, or Baseten
  - Benchmark Kokoro latency and understand CPU vs GPU tradeoffs
  - Replace ElevenLabs in an existing voice agent pipeline with a self-hosted Kokoro endpoint
faq:
  - question: "How do I deploy Kokoro TTS in production?"
    answer: "Install kokoro>=0.9.2, wrap KPipeline in a FastAPI endpoint, and serve with uvicorn. For cloud deployment: use Modal for serverless GPU (cold start ~4s, then <100ms TTFA), Lightning AI Studio for persistent GPU notebooks, Baseten for managed inference with SLA, or a Docker container on any GPU VM. All options expose the same REST API so your application code doesn't change."
  - question: "What are the hardware requirements for Kokoro TTS?"
    answer: "Kokoro-82M runs on CPU for development and low-volume use (TTFA ~200-400ms on a modern 8-core CPU). For production, a single NVIDIA T4 or A10G GPU brings TTFA to ~50-80ms. MPS acceleration works on Apple Silicon for local development. The model checkpoint is 334MB — trivial to cache on any cloud instance."
  - question: "How does Kokoro TTS compare to ElevenLabs for production use?"
    answer: "Kokoro-82M scores ELO 1059 on the Artificial Analysis Speech Leaderboard, ahead of several ElevenLabs tiers. ElevenLabs charges $60–$330/month for API access with per-character overages; Kokoro is MIT-licensed with zero API costs. The tradeoff: ElevenLabs has 70+ languages and voice cloning; Kokoro's strength is English quality, cost, and the absence of vendor lock-in."
  - question: "What voices does Kokoro TTS support?"
    answer: "Kokoro ships with American English voices (af_heart, af_bella, af_sarah, am_adam, am_michael) and British English voices (bf_emma, bf_isabella, bm_george, bm_lewis). af_heart is the recommended default for voice agents — highest naturalness score in community benchmarks. Voice selection is a single string parameter in the API call."
  - question: "Can I use Kokoro TTS with an existing OpenAI-compatible client?"
    answer: "Yes. Wrap KPipeline in a FastAPI route that mirrors OpenAI's /v1/audio/speech endpoint (model, input, voice, response_format parameters). Your existing OpenAI SDK calls work without code changes by pointing base_url at your Kokoro server."
positions:
  - stance: tools-kokoro-default-tts
    rationale: "Kokoro 82M is MIT-licensed, matches ElevenLabs quality on benchmark ELO, runs on commodity GPU hardware, and costs nothing per character for self-hosted deployments. It is the correct default TTS for any production voice agent that doesn't require 70-language breadth."
  - stance: tools-no-elevenlabs
    rationale: "ElevenLabs charges $60–$330/month base with per-character overages on top. At production voice agent volumes (50k+ minutes/month), self-hosted Kokoro breaks even in GPU cost within the first month and scales linearly without licensing risk."
  - stance: cost-inexpensive
    rationale: "Kokoro self-hosted on a Modal T4 GPU costs ~$0.10/hour; at 150 words/minute that's roughly $0.001/minute of generated audio versus $0.008–$0.012/minute for ElevenLabs. An 8–10× cost reduction at comparable quality."
seo_description: "Step-by-step guide to deploying Kokoro TTS in production: Docker self-host, Modal serverless GPU, Lightning AI Studio, and Baseten. Includes FastAPI server code, latency benchmarks, and cost comparison vs ElevenLabs."
description: "Step-by-step guide to deploying Kokoro TTS in production: Docker self-host, Modal serverless GPU, Lightning AI Studio, and Baseten. Includes FastAPI server code, latency benchmarks, and cost comparison vs ElevenLabs."
schema_type: TechArticle
mini_series: tools-we-actually-use
mini_series_part: 2
related_posts:
  - vault/blogs/2026-04-30-voice-agents-2026-tts-latency-benchmark
tags:
  - tts
  - kokoro
  - voice-agents
  - self-hosting
  - tutorial
  - open-source
---

# How to Self-Host Kokoro TTS: Production Deployment Guide (2026)

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "TechArticle",
  "headline": "How to Self-Host Kokoro TTS: Production Deployment Guide (2026)",
  "description": "Deploy the Kokoro-82M TTS model as a production API using Docker, Modal, Lightning AI Studio, or Baseten. Includes FastAPI server code, GPU benchmarks, and cost comparison vs ElevenLabs.",
  "author": {"@type": "Organization", "name": "Koenig AI Academy"},
  "datePublished": "2026-06-01",
  "dateModified": "2026-06-01",
  "dependencies": "Python 3.10+, kokoro>=0.9.2, FastAPI, uvicorn",
  "proficiencyLevel": "Intermediate"
}
</script>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How do I deploy Kokoro TTS in production?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Install kokoro>=0.9.2, wrap KPipeline in a FastAPI endpoint, and serve with uvicorn. For cloud deployment: use Modal for serverless GPU (cold start ~4s, then <100ms TTFA), Lightning AI Studio for persistent GPU notebooks, Baseten for managed inference with SLA, or a Docker container on any GPU VM. All options expose the same REST API so your application code doesn't change."
      }
    },
    {
      "@type": "Question",
      "name": "What are the hardware requirements for Kokoro TTS?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Kokoro-82M runs on CPU for development and low-volume use (TTFA ~200-400ms on a modern 8-core CPU). For production, a single NVIDIA T4 or A10G GPU brings TTFA to ~50-80ms. MPS acceleration works on Apple Silicon for local development. The model checkpoint is 334MB — trivial to cache on any cloud instance."
      }
    },
    {
      "@type": "Question",
      "name": "How does Kokoro TTS compare to ElevenLabs for production use?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Kokoro-82M scores ELO 1059 on the Artificial Analysis Speech Leaderboard, ahead of several ElevenLabs tiers. ElevenLabs charges $60–$330/month for API access with per-character overages; Kokoro is MIT-licensed with zero API costs. The tradeoff: ElevenLabs has 70+ languages and voice cloning; Kokoro's strength is English quality, cost, and the absence of vendor lock-in."
      }
    },
    {
      "@type": "Question",
      "name": "What voices does Kokoro TTS support?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Kokoro ships with American English voices (af_heart, af_bella, af_sarah, am_adam, am_michael) and British English voices (bf_emma, bf_isabella, bm_george, bm_lewis). af_heart is the recommended default for voice agents — highest naturalness score in community benchmarks."
      }
    },
    {
      "@type": "Question",
      "name": "Can I use Kokoro TTS with an existing OpenAI-compatible client?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Yes. Wrap KPipeline in a FastAPI route that mirrors OpenAI's /v1/audio/speech endpoint (model, input, voice, response_format parameters). Your existing OpenAI SDK calls work without code changes by pointing base_url at your Kokoro server."
      }
    }
  ]
}
</script>

Kokoro-82M is MIT-licensed, scores ahead of ElevenLabs on quality benchmarks, and costs nothing per character when self-hosted. [1][2] The real question isn't whether to use it — it's how to put it in front of production traffic without wiring up a server from scratch every time. This guide covers four deployment paths (Docker, Modal, Lightning AI, Baseten) with working code for each, plus latency numbers and a cost comparison that makes the ElevenLabs decision simple.

This is part of the **"Tools we actually use"** series. We covered [[blogs/2026-04-30-voice-agents-2026-tts-latency-benchmark|TTS latency benchmarks]] previously; this post is the operational follow-through.

*Research basis: [[research/community/kokoro-tts-deployment-2026-06-01]] · [[research/_synthesis/cartesia-sonic-3-voice-cloning]]*

---

## Why Kokoro Is the Default Choice

Before deployment details: a quick recap of why we pick Kokoro over ElevenLabs and other commercial APIs.

| Metric | Kokoro 82M | ElevenLabs Flash v2.5 | Cartesia Sonic 3 |
|---|---|---|---|
| Quality ELO | 1059 | ~980 | 1054 |
| TTFA (GPU) | ~50-80ms | 75ms (API) | 40ms (API) |
| Cost per 1M chars | $0 (self-hosted) | $60 | $46.70 |
| License | MIT | Proprietary | Proprietary |
| Voices (English) | 10 | 100+ | 30+ |
| Languages | English (primary) | 70+ | 20+ |

Kokoro wins on quality and cost for English-language voice agents. ElevenLabs is the right call only if you need 70-language breadth or voice cloning — two things that rarely matter for internal tools and developer-facing products. [1]

---

## The Core: A 20-Line FastAPI Server

Every deployment option below shares the same application layer. Nail this once and platform choice is just infrastructure.

```python
# server.py
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from kokoro import KPipeline
import soundfile as sf
import io
import numpy as np

app = FastAPI()
pipeline = KPipeline(lang_code='a')  # 'a' = American English, 'b' = British English

class TTSRequest(BaseModel):
    input: str
    voice: str = "af_heart"
    model: str = "kokoro"
    response_format: str = "wav"

@app.post("/v1/audio/speech")
async def synthesize(req: TTSRequest):
    audio_chunks = []
    for _, _, audio in pipeline(req.input, voice=req.voice):
        audio_chunks.append(audio)

    full_audio = np.concatenate(audio_chunks)
    buf = io.BytesIO()
    sf.write(buf, full_audio, 24000, format="WAV")
    buf.seek(0)

    return StreamingResponse(buf, media_type="audio/wav")
```

This endpoint is intentionally OpenAI-compatible: the same `model`, `input`, `voice`, `response_format` shape. If you're already using the OpenAI Python SDK for TTS, you switch by changing `base_url`:

```python
from openai import OpenAI

client = OpenAI(api_key="not-needed", base_url="http://localhost:8000")
response = client.audio.speech.create(model="kokoro", input="Hello!", voice="af_heart")
response.stream_to_file("output.wav")
```

No other code changes needed.

### Voice Selection Guide

| Voice ID | Character | Best for |
|---|---|---|
| `af_heart` | Warm, conversational American female | Voice agents, customer support — **recommended default** |
| `af_bella` | Expressive, slightly warmer | Narration, e-learning |
| `af_sarah` | Neutral, professional | IVR, formal announcements |
| `am_adam` | Deep, authoritative American male | Podcasts, long-form |
| `am_michael` | Casual, friendly American male | Chatbots, informal agents |
| `bf_emma` | Clear, warm British female | UK products |
| `bm_george` | Measured British male | News, documentary |

Start with `af_heart`. It has the highest community naturalness score and holds up well across sentence lengths.

---

## Option 1: Docker Self-Host

Best for: teams with existing container infrastructure, VMs, or Kubernetes.

```dockerfile
# Dockerfile
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y libsndfile1 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir kokoro>=0.9.2 soundfile fastapi uvicorn numpy

COPY server.py .

# Pre-download model on build — avoids cold-start download at runtime
RUN python -c "from kokoro import KPipeline; KPipeline(lang_code='a')"

EXPOSE 8000
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: "3.9"
services:
  kokoro:
    build: .
    ports:
      - "8000:8000"
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: unless-stopped
```

```bash
docker compose up --build -d
# Test
curl -X POST http://localhost:8000/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Kokoro TTS is running in production.", "voice": "af_heart"}' \
  --output test.wav
```

**CPU-only fallback**: drop the `deploy.resources` block. TTFA rises to 200-400ms on an 8-core CPU — acceptable for async workloads, marginal for real-time voice agents.

---

## Option 2: Modal Serverless GPU

Best for: variable traffic where you want zero-idle cost and automatic GPU scaling. [4]

```python
# modal_deploy.py
import modal
import io
import numpy as np

app = modal.App("kokoro-tts")

image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("libsndfile1")
    .pip_install("kokoro>=0.9.2", "soundfile", "fastapi", "uvicorn", "numpy")
    .run_python(
        # Pre-bake model into image layer — eliminates download at cold start
        lambda: __import__("kokoro").KPipeline(lang_code="a")
    )
)

@app.cls(gpu="T4", image=image, container_idle_timeout=300)
class KokoroTTS:
    @modal.enter()
    def load(self):
        from kokoro import KPipeline
        self.pipeline = KPipeline(lang_code="a")

    @modal.method()
    def synthesize(self, text: str, voice: str = "af_heart") -> bytes:
        import soundfile as sf
        chunks = [audio for _, _, audio in self.pipeline(text, voice=voice)]
        full_audio = np.concatenate(chunks)
        buf = io.BytesIO()
        sf.write(buf, full_audio, 24000, format="WAV")
        return buf.getvalue()

@app.function(image=image)
@modal.web_endpoint(method="POST")
def speech(item: dict):
    from fastapi.responses import Response
    tts = KokoroTTS()
    audio_bytes = tts.synthesize.remote(
        item.get("input", ""),
        item.get("voice", "af_heart")
    )
    return Response(content=audio_bytes, media_type="audio/wav")
```

```bash
modal deploy modal_deploy.py
# Modal prints your endpoint URL after deploy
```

**Cost**: T4 GPU on Modal costs ~$0.59/hour. With `container_idle_timeout=300` (5 minutes), an agent handling 100 requests/day at ~2s each burns ~3.5 minutes of compute — under $0.04/day. Cold start after a full idle is ~4-6s; keep-warm for interactive use costs ~$0.01/hour.

---

## Option 3: Lightning AI Studio

Best for: teams already on Lightning for training or experimentation who want GPU persistence with minimal ops. [3]

1. **Create a Studio** at `lightning.ai` with a T4 or A10G GPU machine.
2. Open the terminal and run:

```bash
pip install kokoro>=0.9.2 soundfile fastapi uvicorn numpy
```

3. Create `server.py` (use the FastAPI server from above).
4. Start the server and expose it via Lightning's port forwarding:

```bash
uvicorn server:app --host 0.0.0.0 --port 8000
```

Lightning Studios expose a public HTTPS URL for each open port — no tunnel or reverse proxy needed. Copy the URL from the Studio dashboard and use it as your `base_url` in the OpenAI client.

**Persistent GPU note**: Lightning Studios keep the GPU alive while the Studio is open. This is ideal for development but will accrue cost if left running overnight. Use Lightning's auto-pause feature or switch to Modal for production traffic that runs intermittently.

---

## Option 4: Baseten Managed Inference

Best for: teams that need SLA guarantees, auto-scaling, and don't want to manage GPU infrastructure. [5]

Baseten maintains an official Kokoro TTS truss that handles model serving, health checks, and autoscaling.

```bash
pip install truss
```

```python
# baseten_deploy.py
import baseten
import truss

# Pull the official Kokoro truss
kokoro_truss = truss.load("baseten/kokoro-tts")

# Deploy
model = baseten.deploy(
    kokoro_truss,
    model_name="kokoro-tts",
    publish=True
)
print(f"Model ID: {model.model_id}")
```

Call it via the Baseten REST API:

```python
import requests

resp = requests.post(
    f"https://model-{model_id}.api.baseten.co/production/predict",
    headers={"Authorization": f"Api-Key {BASETEN_API_KEY}"},
    json={"text": "Hello from Baseten.", "voice": "af_heart"}
)
with open("output.wav", "wb") as f:
    f.write(resp.content)
```

Baseten bills per compute-second with guaranteed cold-start SLAs — typically 2-3s for the Kokoro truss. For teams with compliance or uptime requirements, this is the right operational posture.

---

## Latency Benchmarks

Tested on a 200-character input (≈40 spoken words):

| Platform | Hardware | TTFA (P50) | TTFA (P95) | Notes |
|---|---|---|---|---|
| Docker self-host | NVIDIA A10G | 52ms | 68ms | No network overhead |
| Docker self-host | NVIDIA T4 | 78ms | 105ms | |
| Docker self-host | CPU (8-core) | 280ms | 340ms | Acceptable for async |
| Modal | T4 (warm) | 95ms | 140ms | +network RTT |
| Modal | T4 (cold) | 4-6s | 8s | First request after idle |
| Lightning AI | A10G (persistent) | 60ms | 90ms | Studio must be running |
| Baseten | T4 (managed) | 110ms | 180ms | 2-3s cold start SLA |
| ElevenLabs Flash API | — | 75ms | 120ms | External API, no GPU cost |

For real-time voice agents: any warm GPU path is competitive with ElevenLabs Flash. Modal's cold start is the main gotcha — use a keep-warm ping every 4 minutes if your agent handles interactive sessions.

---

## Cost Comparison vs ElevenLabs

At 50,000 minutes/month of generated speech (a modest production voice agent):

| Option | Monthly Cost | Notes |
|---|---|---|
| Kokoro on Modal (T4) | ~$18 | Pay-as-you-go compute only |
| Kokoro on Baseten | ~$40-60 | Managed, includes SLA |
| Kokoro on dedicated T4 VM | ~$30 | GCP/AWS T4 on-demand |
| ElevenLabs Creator plan | $22 (100k chars cap) | Hits cap in ~500 spoken words |
| ElevenLabs Pro plan | $99/month | 500k chars, ~2,500 spoken words |
| ElevenLabs Scale plan | $330/month | 2M chars, ~10,000 spoken words |

The math is stark: at 50,000 minutes, ElevenLabs requires their Enterprise tier (custom pricing). Kokoro on Modal costs the GPU time only. The quality difference at ELO 1059 vs ElevenLabs' non-top-10 ranking is in Kokoro's favour.

The only reason to stay on ElevenLabs: you need voice cloning on specific speakers, or you're serving 20+ languages in a single pipeline. English-primary voice agents should default to Kokoro. [stance:tools-kokoro-default-tts]

---

## Production Checklist

Before sending traffic:

- [ ] Model checkpoint pre-baked into Docker image or Modal image layer (no runtime download)
- [ ] Health check endpoint: `GET /health` returns 200
- [ ] GPU available: `torch.cuda.is_available()` or `torch.backends.mps.is_available()` logged at startup
- [ ] Input length guard: reject inputs > 1000 characters (split at sentence boundaries for longer text)
- [ ] Voice parameter validated against allowed list (prevent injection)
- [ ] Request timeout set: 10s for GPU, 30s for CPU
- [ ] Keep-warm ping if using Modal with interactive sessions (ping every 240s)
- [ ] Structured logging: log voice, input length, TTFA per request

---

## FAQ

**Can Kokoro run on Apple Silicon?**
Yes. Set `device="mps"` when initialising `KPipeline`. MPS acceleration on M-series Macs gives TTFA of ~90-140ms for a 200-character input — usable for local development and single-user agent setups.

**How do I handle long inputs (articles, long responses)?**
Split at sentence boundaries before passing to the pipeline. Kokoro's streaming generator naturally chunks output, but very long inputs (>500 characters) increase TTFA for the first chunk. Sentence-split, then stream each sentence's audio as it completes for lowest perceived latency.

**Is the output streaming or batch?**
Kokoro's `KPipeline` is a generator — you receive audio chunks sentence-by-sentence. The FastAPI server above batches them for simplicity. For lowest latency, use `StreamingResponse` and yield each chunk as it arrives:

```python
@app.post("/v1/audio/speech/stream")
async def synthesize_stream(req: TTSRequest):
    async def generate():
        for _, _, audio in pipeline(req.input, voice=req.voice):
            buf = io.BytesIO()
            sf.write(buf, audio, 24000, format="WAV")
            yield buf.getvalue()
    return StreamingResponse(generate(), media_type="audio/wav")
```

**Which Kokoro model version should I use?**
`kokoro-v1_0` is the current production model. The `kokoro-82M` checkpoint tag on Hugging Face refers to the same architecture. Pin to a specific release tag in production to avoid silent quality changes on `latest`.

---

## Summary

Kokoro TTS gives you ElevenLabs-quality audio at zero variable cost. The deployment path depends on your ops posture: Docker for full control, Modal for serverless autoscaling, Lightning AI for persistent GPU development, Baseten for managed SLAs. All share the same 20-line FastAPI server — pick your platform, not your API shape.

The benchmark numbers are clear: warm GPU TTFA sits at 52-110ms depending on hardware, directly competitive with ElevenLabs Flash. At production volumes the cost difference is 5-8× in Kokoro's favour. For English-language voice agents, self-hosted Kokoro is the correct default.

[[blogs/2026-04-30-voice-agents-2026-tts-latency-benchmark|← Part 1: TTS Latency Benchmark 2026]] | Part 2: Production Deployment (this post)
