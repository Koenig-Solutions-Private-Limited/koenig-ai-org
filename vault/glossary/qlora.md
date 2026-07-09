---
term: "QLoRA"
definition: "Quantized Low-Rank Adaptation — a fine-tuning technique that combines 4-bit quantization of the frozen base model with LoRA adapters trained in higher precision, enabling fine-tuning of large models on consumer-grade GPUs."
seo_description: "QLoRA: combining 4-bit quantized base models with LoRA adapters to fine-tune large LLMs on consumer hardware with minimal quality loss."
category: "LLM concepts"
related_terms: [lora, quantization, supervised-fine-tuning, fine-tuning, gpu-cluster]
---

QLoRA (Dettmers et al., 2023) made fine-tuning 65B+ models practical on a single 48GB GPU—previously requiring multi-GPU clusters. The key innovation is NF4 (NormalFloat4), a 4-bit quantization format optimized for normally distributed weights, combined with double quantization (quantizing the quantization constants themselves) and paged optimizers that use CPU RAM as an overflow buffer for GPU memory spikes.

The quality gap between QLoRA and full fine-tuning is surprisingly small—often within 1–2% on downstream tasks—because LoRA adapters are trained in BFloat16 and compensate for quantization noise. This makes QLoRA the go-to method for researchers and practitioners who want to fine-tune large models without access to A100/H100 clusters.

Practical QLoRA recipes use rank 16–64 adapters, learning rate 2e-4, and the Alpaca or ShareGPT instruction format. Libraries like Axolotl, Unsloth, and LLaMA-Factory wrap QLoRA in user-friendly training interfaces. As of 2026, the open-source fine-tuning ecosystem is almost entirely built on LoRA/QLoRA variants.

## Related Terms

- [[glossary/lora|LoRA]] — a parameter-efficient fine-tuning method that trains low-rank weight adaptors instead of full weights
- [[glossary/quantization|Quantization]] — the process of reducing model weight precision to decrease memory and speed up inference
- [[glossary/supervised-fine-tuning|Supervised Fine-Tuning]] — the weight-update process that adapts a pre-trained model to a target task using labeled data
- [[glossary/fine-tuning|Fine-tuning]] — the weight-update process that adapts a pre-trained base model for downstream tasks
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
