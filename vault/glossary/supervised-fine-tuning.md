---
term: "Supervised Fine-Tuning"
definition: "The process of continuing gradient-descent training on a pre-trained model using a curated labeled dataset, adapting it to a specific task, style, or domain by updating model weights through standard cross-entropy loss."
seo_description: "Supervised fine-tuning: adapting a pre-trained LLM to a specific task or domain by continuing training on a curated labeled dataset."
category: "LLM concepts"
related_terms: [instruction-tuning, fine-tuning, pre-training, direct-preference-optimization, rlhf, lora]
---

Supervised fine-tuning (SFT) is the first step in the post-training pipeline for most production LLMs. After pre-training on internet-scale text, the model undergoes SFT on a smaller, high-quality dataset of (input, ideal output) pairs curated by human annotators. This teaches the model the desired response format, level of detail, and domain expertise.

The practical tradeoff between SFT and in-context learning (few-shot prompting) has shifted as models have grown more capable. For general tasks, strong frontier models often match SFT performance with well-crafted prompts. For specialized tasks (medical terminology, legal drafting, proprietary domain knowledge) or efficiency requirements (reducing prompt length), SFT still provides a significant edge.

Parameter-efficient fine-tuning methods—LoRA, QLoRA—make SFT practical on consumer-grade hardware by updating only a small fraction of model parameters. A 7B model can be fine-tuned on a single consumer GPU with LoRA; a 70B model on a 4-GPU workstation with QLoRA. This democratization has enabled a thriving open-source fine-tuning ecosystem around Llama 3 and Mistral 7B.
