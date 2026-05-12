---
term: "Quantization"
definition: "A model compression technique that reduces the numerical precision of model weights and/or activations from 32-bit or 16-bit floating point to 8-bit integers or lower, reducing memory footprint and accelerating inference at modest quality cost."
seo_description: "Quantization: compressing LLM weights to lower bit precision to reduce memory and speed up inference with minimal quality loss."
category: "LLM concepts"
related_terms: [lora, qlora, inference-server, gpu-cluster, tpu, vllm]
---

Modern LLMs are trained in BFloat16 or Float16 precision. Quantization converts weights to INT8, INT4, or even INT2, reducing memory by 2×, 4×, or 8× respectively. The quality tradeoff depends on the quantization method: naive rounding loses significant quality; calibrated methods like GPTQ, AWQ, and GGUF preserve most performance even at 4-bit precision.

Post-training quantization (PTQ) applies after training using a small calibration dataset, requiring no gradient computation. Quantization-aware training (QAT) simulates quantization noise during training, producing models that are more robust to precision reduction. PTQ is practical and widely used; QAT produces better results but requires retraining.

The practical impact is substantial: a 70B model requires ~140GB in BFloat16 but only ~35GB in INT4, fitting on two consumer-grade 24GB GPUs. GGUF format (used by llama.cpp) enables running quantized LLMs on CPU with no GPU required, making local model deployment accessible without dedicated ML hardware. AWQ and GPTQ are the dominant GPU quantization formats as of 2026.
