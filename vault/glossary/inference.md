---
term: "Inference"
definition: "The runtime process of using a trained model to produce outputs from inputs, such as generating text, classifications, tool calls, or embeddings."
seo_description: "Inference: the runtime process of using a trained model to produce outputs such as text, classifications, tool calls, or embeddings."
category: "Infrastructure"
related_terms: [latency, caching, kv-cache, inference-time-compute, sampling-parameters]
related_courses: [gemini-enterprise-agents]
---

Inference is where model capability becomes product behavior. The system receives an input, prepares the prompt or request, runs the model, applies decoding settings, and returns an output or tool action.

Production inference has practical constraints: [[latency]], throughput, cost, reliability, privacy, and observability. A technically stronger model may be the wrong choice if it misses the serving budget or fails under peak traffic.

**The inference pipeline** has two distinct computational phases. The prefill phase processes all input tokens simultaneously — this is parallelizable across the full [[context-window]] and is relatively fast relative to its token count. The decode phase generates output tokens one at a time in an autoregressive loop: each new token depends on all previous tokens, so this phase cannot be parallelized and dominates [[latency]] for long outputs. Understanding this distinction matters because optimizing for long-input tasks (prefill-heavy) requires different strategies than optimizing for long-output tasks (decode-heavy).

**The [[kv-cache]] role.** During the prefill phase, the model computes key and value tensors for every layer of the [[transformer]] for every input token. These tensors are stored in a key-value cache so that when the model generates the next token, it does not recompute attention over already-processed tokens. [[prompt-caching]] extends this idea across requests: a long, stable system prompt that appears at the start of many requests can have its KV state cached on the server, so subsequent requests skip the prefill cost for that prefix entirely. This is one of the highest-leverage optimizations available for [[agent-loop]] workloads that reuse the same instructions across many turns.

**Batching tradeoffs.** Serving systems batch multiple requests together to improve hardware utilization and throughput. Batching reduces cost per request but increases [[latency]] for individual requests that must wait to form or complete a batch. Interactive products typically configure small batches or continuous batching (adding new requests to an in-flight batch as slots open); background processing pipelines prefer larger batches for efficiency.

**Inference-time compute.** Some [[reasoning-model]] architectures spend more compute at inference — generating internal chain-of-thought traces, sampling multiple candidate answers, or running verifiers — to improve accuracy without changing model weights. This trades additional [[latency]] and cost for higher reliability on hard tasks.

**Self-hosting vs. inference providers.** Managed inference APIs (OpenAI, Anthropic, Google Vertex AI) handle serving infrastructure and hide complexity. Self-hosting gives control over [[data-residency]], [[kv-cache]] configuration, and cost at scale, but requires significant operational investment. See [[gemini-enterprise-agents]] for how managed and self-hosted inference decisions interact with enterprise security requirements.

## Related Terms

- [[glossary/latency|Latency]] — the elapsed time from request submission to first token or full response received
- [[glossary/caching|Caching]] — storing computed results for reuse to reduce latency and cost on repeated inputs
- [[glossary/kv-cache|KV Cache]] — the cached key-value pairs that eliminate redundant attention computation across turns
- [[glossary/inference-time-compute|Inference-Time Compute]] — additional computation at inference time (e.g. chain-of-thought, search) that improves output quality
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
