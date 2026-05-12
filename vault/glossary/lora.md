---
term: "LoRA"
definition: "Low-Rank Adaptation — a parameter-efficient fine-tuning method that trains only small, low-rank decomposition matrices injected into the model's weight matrices, reducing trainable parameters by 100–10,000× while matching full fine-tuning quality."
seo_description: "LoRA: a parameter-efficient fine-tuning method that trains small low-rank matrices instead of full model weights, enabling affordable LLM adaptation."
category: "LLM concepts"
related_terms: [qlora, supervised-fine-tuning, fine-tuning, quantization, lora]
---

LoRA (Hu et al., 2021) represents the weight update ΔW as a product of two low-rank matrices: ΔW = BA, where B ∈ R^(d×r) and A ∈ R^(r×k), with rank r << min(d,k). During training, only A and B are updated; the original weights W are frozen. At inference, BA is merged with W, adding no latency overhead.

The rank r controls the expressivity-efficiency tradeoff. r=4 works well for style adaptation; r=64 approaches full fine-tuning expressivity for domain specialization. For a 7B model, r=8 LoRA adapters contain ~10M trainable parameters vs. ~7B for full fine-tuning—a 700× reduction. This makes fine-tuning feasible on a single GPU.

LoRA adapters are composable and swappable. A base model can have many task-specific adapters (coding, medical, legal) that are swapped at inference time, enabling a single model deployment to serve multiple specialized behaviors. Libraries like PEFT (HuggingFace) and Unsloth make LoRA fine-tuning accessible with minimal code.
