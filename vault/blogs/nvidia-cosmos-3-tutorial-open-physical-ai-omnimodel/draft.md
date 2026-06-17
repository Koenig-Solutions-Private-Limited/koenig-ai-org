---
date: 2026-06-17
author: blog-author
ticket: KOEA-8796
vendor_tag: community
content_type: article
status: draft-for-review
reading_time_min: 6-8
primary_query: "how to run NVIDIA Cosmos 3 open physical AI model"
contrarian_angle: "Cosmos 3 is not a chatbot — comparing it to GPT or Claude is a fundamental category error. The right comparison class is Stable Diffusion and robotics simulators."
first_60_words_answer: "NVIDIA Cosmos 3 is an open-weight physical AI world model — not a language model — released May 31, 2026. Weights for Nano (16B) and Super (64B) are live on HuggingFace. The fastest run path is Diffusers' Cosmos3OmniPipeline. Nano requires at least 96GB VRAM (RTX PRO 6000 class or multi-GPU); Super needs H100/H200/B200 datacenter hardware."
positions:
  - id: benchmark-theater-vs-agent-trace-evaluation
    engagement: refines
faq:
  - question: "What hardware do I need to run Cosmos 3 Nano locally?"
    answer: "Cosmos 3 Nano (16B parameters, BF16 only) requires a minimum of 96GB VRAM for full local inference — practical floor is an RTX PRO 6000 or a multi-GPU setup with equivalent VRAM. Consumer GPUs below that threshold cannot run Nano. Super (64B) requires H100, H200, or B200 datacenter-class hardware."
  - question: "Can I run Cosmos 3 with Ollama?"
    answer: "No — as of June 2026, NVIDIA has not released an official Ollama integration for Cosmos 3. The three supported run paths are: Diffusers Cosmos3OmniPipeline (easiest, recommended for prototyping), vLLM-Omni (production API server), and SGLang. Avoid third-party Ollama forks not endorsed by NVIDIA for a model this new."
  - question: "What license does Cosmos 3 use?"
    answer: "Cosmos 3 weights are released under the OpenMDW 1.1 license — open weights, but with use restrictions on certain commercial and safety-critical applications. Review the full license at the HuggingFace model card before deploying in production or commercial contexts."
  - question: "What is the difference between Cosmos 3 Nano and Super?"
    answer: "Cosmos 3 Nano (16B parameters) targets fast inference and real-time robotics applications, running on Ampere/Hopper/Blackwell GPUs with 96GB+ VRAM. Cosmos 3 Super (64B parameters) targets highest-quality generation for synthetic data pipelines and world-model research, requiring H100/H200/B200 datacenter hardware. Both are open-weight on HuggingFace."
original_data: false
last_updated: 2026-06-17
hero_image:
  url: /img/blogs/nvidia-cosmos-3-tutorial/hero.png
  alt: "NVIDIA Cosmos 3 architecture diagram showing Reasoner and Generator towers with robot arm training output"
sources:
  - https://nvidianews.nvidia.com/news/nvidia-launches-cosmos-3-the-open-frontier-foundation-model-for-physical-ai
  - https://developer.nvidia.com/blog/develop-physical-ai-reasoning-world-and-action-models-with-nvidia-cosmos-3/
  - https://huggingface.co/nvidia/Cosmos3-Nano
  - https://huggingface.co/nvidia/Cosmos3-Super
  - https://github.com/NVIDIA/cosmos
  - https://huggingface.co/collections/nvidia/cosmos3
  - https://www.axios.com/2026/06/01/nvidia-ai-push-cosmos-3-world-model
  - https://www.latent.space/p/ainews-nvidia-cosmos-3-nemotron-3
  - https://www.hpcwire.com/aiwire/2026/06/01/nvidia-launches-cosmos-3-the-open-frontier-foundation-model-for-physical-ai/
whats_new:
  - "NVIDIA Cosmos 3 open-weights physical AI world model is live — here's how to run Nano on 96GB hardware today"
learning_objectives:
  - "Understand the Mixture-of-Transformers architecture behind Cosmos 3 and why it is not a language model"
  - "Choose between Nano and Super based on your hardware and use case"
  - "Run Cosmos 3 Nano using Diffusers, vLLM-Omni, or SGLang"
  - "Evaluate Cosmos 3's synthetic robot training capabilities against its documented limitations"
---

# Get Started With NVIDIA Cosmos 3: The Open Physical AI World Model (2026)

NVIDIA Cosmos 3 is an open-weight physical AI world model — not a language model — released May 31, 2026. Weights for Nano (16B) and Super (64B) are [live on HuggingFace](https://huggingface.co/collections/nvidia/cosmos3) under the OpenMDW 1.1 license. The fastest run path is the Diffusers `Cosmos3OmniPipeline`. Nano requires at least 96GB VRAM (RTX PRO 6000 class or equivalent multi-GPU); Super requires H100/H200/B200 datacenter hardware.

The most important thing to understand before you install anything: **Cosmos 3 is not a chatbot.** If you are expecting a smarter GPT, you are looking at the wrong model. The right mental model is Stable Diffusion meets a robotics simulator — a system that generates physically plausible video frames and robot action trajectories, not answers to questions. Treat it like that and it is genuinely powerful. Treat it like Claude and you will be disappointed.

![NVIDIA Cosmos 3 architecture showing Reasoner Tower (VLM) and Generator Tower (diffusion) working in sequence to produce robot training trajectories](https://cosmos.nvidia.com/assets/cosmos3-architecture.png)
_Architecture overview: Reasoner Tower interprets inputs; Generator Tower produces video frames and action sequences._

## What Cosmos 3 Actually Is

Cosmos 3 uses a **Mixture-of-Transformers (MoT)** architecture with two specialized towers operating in tandem, [per NVIDIA's technical blog](https://developer.nvidia.com/blog/develop-physical-ai-reasoning-world-and-action-models-with-nvidia-cosmos-3/):

- **Reasoner Tower** — an autoregressive vision-language model that interprets multimodal inputs and builds a physical-world understanding
- **Generator Tower** — a diffusion-based system that produces future video frames and robot action sequences conditioned on the Reasoner's output

Together they create a model that can natively handle five modalities: text, images, video, ambient sound, and robot action trajectories. The [NVIDIA press release](https://nvidianews.nvidia.com/news/nvidia-launches-cosmos-3-the-open-frontier-foundation-model-for-physical-ai) describes it as "a vision language model, world model, and world action model backbone" — three jobs in one.

This was released alongside Nemotron 3 Ultra as part of NVIDIA's "open-source week," including weights, code, datasets, and fine-tuning recipes — [per HPC Wire](https://www.hpcwire.com/aiwire/2026/06/01/nvidia-launches-cosmos-3-the-open-frontier-foundation-model-for-physical-ai/).

## Nano vs Super: Which Can You Actually Run?

| | Cosmos 3 Nano | Cosmos 3 Super |
|---|---|---|
| Parameters | 16B | 64B |
| HuggingFace | [nvidia/Cosmos3-Nano](https://huggingface.co/nvidia/Cosmos3-Nano) | [nvidia/Cosmos3-Super](https://huggingface.co/nvidia/Cosmos3-Super) |
| Precision | BF16 only | BF16 only |
| GPU Architecture | Ampere, Hopper, Blackwell | Hopper, Blackwell only |
| Practical hardware floor | RTX PRO 6000 (96GB VRAM) | H100 / H200 / B200 |
| Use case | Fast inference, real-time robotics | Highest-quality synthetic data |

The Nano's "Ampere support" framing in the official docs is technically true but practically optimistic for consumer hardware. 96GB VRAM means an RTX PRO 6000 workstation GPU or a multi-GPU setup — not a gaming card. Super is a datacenter-only model.

The [HuggingFace collection](https://huggingface.co/collections/nvidia/cosmos3) also includes specialty variants: `Cosmos3-Super-Text2Image`, `Cosmos3-Super-Image2Video`, and `Cosmos3-Nano-Policy-DROID` (a pre-finetuned robot manipulation policy on the DROID dataset). A Cosmos 3 Edge variant for real-time inference is listed as coming soon.

## Running Cosmos 3: The Three Official Paths

The [NVIDIA Cosmos GitHub repo](https://github.com/NVIDIA/cosmos) documents three supported inference paths. There is no official Ollama integration as of June 2026 — skip any third-party Ollama forks for a model this new.

### Path 1 — Diffusers (Recommended for Prototyping)

The easiest on-ramp. Install with `uv` for clean Python 3.13 isolation:

```bash
uv venv --python 3.13 --seed --managed-python
uv pip install --torch-backend=auto diffusers accelerate torch torchvision transformers
uvx hf@latest auth login
```

Then run Nano:

```python
import torch
from diffusers import Cosmos3OmniPipeline

pipe = Cosmos3OmniPipeline.from_pretrained(
    "nvidia/Cosmos3-Nano",
    torch_dtype=torch.bfloat16,
    device_map="cuda",
    enable_safety_checker=True,
)

result = pipe(
    prompt="Robot arm picks up red cube from table",
    num_frames=189,
    height=720,
    width=1280,
    num_inference_steps=35,
    guidance_scale=6.0,
)
result.frames[0].save("cosmos_output.mp4")
```

**Expected output:** An MP4 video showing a physically plausible simulation of the described scene, 189 frames at 24fps (~7.9 seconds). Generation time on an H100 is approximately 2-4 minutes for this configuration.

### Path 2 — vLLM-Omni (Production API Server)

Exposes an OpenAI-compatible endpoint — useful for integrating Cosmos 3 into existing pipelines:

```bash
docker pull vllm/vllm-omni:cosmos3

vllm serve nvidia/Cosmos3-Nano \
  --omni \
  --host 0.0.0.0 \
  --port 8000 \
  --init-timeout 1800
```

The `--init-timeout 1800` flag is required — Cosmos 3 checkpoints exceed the default server init timeout. The API is available at `localhost:8000/v1/videos/sync`.

### Path 3 — SGLang

Minimal setup for inference serving:

```bash
sglang serve --model-path nvidia/Cosmos3-Nano
```

SGLang is a good option if you are already using it for other models and want consistent tooling across your stack.

## Synthetic Robot Training: The Real Use Case

The "months to days" claim in [Axios's Cosmos 3 coverage](https://www.axios.com/2026/06/01/nvidia-ai-push-cosmos-3-world-model) is NVIDIA-sourced, not independently benchmarked. Treat it as directional, not a guaranteed reduction.

That said, the mechanism is legitimate. Cosmos 3 generates synthetic robot training data — video frames plus action trajectories — that can substitute for expensive real-world data collection. It supports four distinct task types:

- **Forward dynamics:** Given video context + action, predict the next state
- **Inverse dynamics:** Given before/after video, infer what action was taken
- **Policy generation:** Given video + goal, output robot action trajectories as JSON
- **Synthetic dataset creation:** NVIDIA released six datasets covering embodied robots, physical interactions, warehouse operations, and autonomous driving — all on HuggingFace

The training corpus for Cosmos 3 itself comprises 1.3B data points across 393 datasets from 2024–2026, including public sources (Coyo700M, OpenImage, YouTube) and private robotics and AV data.

Artificial Analysis independently confirmed Cosmos 3 achieved #1 among open-weight models on text-to-image and image-to-video leaderboards — [per the Latent Space AI News roundup](https://www.latent.space/p/ainews-nvidia-cosmos-3-nemotron-3). On physical AI benchmarks (Physics-IQ, PAI-Bench, RoboArena, VANTAGE-Bench), the claims come from NVIDIA's own technical blog. Independent replication of those physical AI benchmarks is still early.

## The Cosmos Coalition

Six companies are founding members of the Cosmos Coalition — an open physical AI ecosystem built around the Cosmos platform:

- **Agile Robots** — humanoid robotics
- **Black Forest Labs** — image generation (FLUX models)
- **Generalist** — embodied AI
- **LTX** — video generation
- **Runway** — video AI (notable given they also compete in this space)
- **Skild AI** — robot foundation models

Broader launch partners include Doosan Robotics, LG Electronics, Samsung Electronics, Li Auto (autonomous vehicles), and several vision AI companies. The Coalition framing mirrors what HuggingFace did for language models — a shared infrastructure layer owned by no single vendor.

## Honest Caveats

The Cosmos 3 model card documents these limitations directly:

- **Temporal inconsistencies:** motion can be unstable; object and camera jitter is documented
- **Physics gaps:** no explicit physics simulation — objects may disappear, morph, or collide unrealistically despite the "physical AI" branding
- **Long-horizon degradation:** quality degrades with longer video outputs
- **Hallucinations on spatial geometry:** can misinterpret causal relationships and depth
- **Not certified for safety-critical use:** autonomous systems and robotics control require additional validation beyond Cosmos 3 outputs

The bottom line: Cosmos 3 is a world model for *training data generation*, not for direct deployment in a production robot. Use it to create diverse synthetic scenarios that you then validate with real-world data before any safety-critical application.

---

**KnowledgeCheck:** You want to fine-tune a manipulation policy using synthetic data from Cosmos 3 Nano, but you only have a consumer RTX 4090 (24GB VRAM). What should you do?

A) Download Nano and run with `--quantize int4` to fit in 24GB  
B) Use the hosted API at build.nvidia.com instead of local inference  
C) Switch to Cosmos 3 Super, which has lower VRAM requirements  
D) Use the `--cpu-offload` flag to spill to system RAM  

**Answer: B.** Cosmos 3 Nano requires ~96GB VRAM for BF16 inference — a 24GB consumer GPU cannot run it regardless of quantization (officially only BF16 is supported). The hosted API at build.nvidia.com gives you access without local hardware. Option A is tempting but not supported by official documentation; Option C is wrong (Super needs more, not less VRAM); Option D is not documented in official sources.

---

Ready to build production-grade AI agent pipelines that integrate world models and physical AI into real systems? The [[course/claude-agent-sdk-zero-to-production]] course covers multi-modal tool use, agentic workflows, and production deployment — the infrastructure layer that makes models like Cosmos 3 usable in real pipelines.
