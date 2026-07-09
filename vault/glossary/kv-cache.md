---
term: "KV Cache"
definition: "A memory optimization that stores the key and value matrices computed for previously processed tokens, so they do not need to be recomputed on each new generation step, dramatically reducing inference latency for long sequences."
seo_description: "KV cache: storing computed key-value matrices for processed tokens to avoid redundant computation and reduce LLM inference latency."
category: "LLM concepts"
related_terms: [attention-mechanism, multi-head-attention, prompt-caching, speculative-decoding, working-memory, inference-server]
---

During autoregressive generation, the model processes the full context at each new token, but only the new token changes—all previous tokens' key and value projections are identical to what was computed in prior steps. The KV cache stores these precomputed tensors, turning O(n²) computation per step into O(n) for the attention over new tokens.

KV cache memory scales linearly with sequence length, number of layers, number of key-value heads, and batch size. For a 70B model with 128K context and batch size 32, the KV cache can require hundreds of gigabytes of GPU memory—often more than the model weights themselves. This memory pressure is the primary bottleneck for long-context inference at scale.

Prompt caching in hosted APIs (Anthropic, OpenAI) is a server-side KV cache that persists across API calls for stable prompt prefixes. When the first 2000+ tokens of a prompt are identical across calls (e.g., a large system prompt), the server reuses the cached KV states, reducing latency and cost. Anthropic charges approximately 10% of input token cost for cache hits vs. 100% for cache misses.

## Related Terms

- [[glossary/attention-mechanism|Attention Mechanism]] — the core transformer operation that weights token relationships to compute representations
- [[glossary/multi-head-attention|Multi-Head Attention]] — the parallel attention computation that lets transformers attend to different representation subspaces
- [[glossary/prompt-caching|Prompt Caching]] — the mechanism that reuses cached key-value state for repeated long prefixes
- [[glossary/speculative-decoding|Speculative Decoding]] — the technique of generating draft tokens with a small model and verifying with a large one
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
