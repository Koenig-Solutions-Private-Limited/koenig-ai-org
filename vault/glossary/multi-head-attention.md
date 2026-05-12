---
term: "Multi-Head Attention"
definition: "An attention variant that runs multiple independent attention operations (heads) in parallel on different learned linear projections of the input, allowing the model to attend to different representation subspaces simultaneously."
seo_description: "Multi-head attention: running parallel attention heads on different input projections, allowing transformers to capture multiple relationship types at once."
category: "LLM concepts"
related_terms: [attention-mechanism, transformer, kv-cache, positional-encoding, flash-attention]
---

Multi-head attention (MHA) divides the model dimension into h heads, each performing scaled dot-product attention on a separate linear projection of queries, keys, and values. The outputs of all heads are concatenated and projected back to the model dimension. Different heads learn to attend to different patterns: some track syntactic dependencies, others semantic relationships, others positional proximity.

Grouped Query Attention (GQA) and Multi-Query Attention (MQA) are efficient variants that share key and value heads across multiple query heads, dramatically reducing KV cache memory requirements. GPT-5, Claude Sonnet 4.6, and Llama 3 all use GQA, which enables larger batch sizes and longer contexts with the same GPU memory.

The number of attention heads scales with model size in practice: small models (1B params) use 16–32 heads; large models (70B+) use 64–128 heads. More heads give the model more representational capacity per layer but also increase computation. Head pruning research shows that many heads can be removed post-training with minimal quality loss, suggesting that not all heads are equally important.
