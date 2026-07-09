---
term: "Prompt Caching"
definition: "Prompt caching is a technique that stores the results of intermediate processing of prompt tokens to avoid re-computing them, significantly reducing inference latency and costs for frequently reused context."
seo_description: "Prompt caching explained: how to reduce LLM costs and latency by caching long-context components."
category: "optimization"
related_terms: [context-window, inference-time-compute, tokenization]
related_courses: [gemini-enterprise-agents]
---

Prompt caching works by storing the computed [[kv-cache]] — the key-value representations of attention layers — for a prefix of the prompt. When the same prefix appears in subsequent requests, the model skips recomputing those attention states and reads them from cache instead. The result is dramatically lower [[inference]] cost and reduced [[latency]] for anything that reuses a stable context block.

**What gets cached.** The cache stores intermediate transformer activations (not the raw text, not the final response). A "cache write" happens the first time a prefix is processed; every subsequent request that shares that prefix triggers a cheaper "cache read." On Anthropic's API, cache reads are priced at roughly 10% of a normal input token write, while cache writes cost about 25% more than standard input tokens — so the break-even point is usually hit after two or three cache reads.

**TTL and invalidation.** Caches are not permanent. Providers set a time-to-live (typically five minutes on Anthropic, longer with explicit cache-control headers). If a deployment idles for too long between requests, the cache expires and must be rewritten. This means batch workloads with long gaps between calls get less benefit than continuously active agent loops.

**When it helps most.** The gains are largest when a long, stable block sits at the front of every request: a multi-thousand-token [[system-prompt]] containing tool schemas, a large retrieved document corpus used for [[rag]], or a full codebase loaded for every turn of an agentic coding session. In these patterns, the effective cost of the reused context drops to near zero after the first call.

**When it does not help.** Highly dynamic prompts — where each turn prepends new user-specific data before the stable instructions — defeat caching because the prefix changes with every request. The cache key is the literal byte sequence of the prefix, so even minor variation invalidates the hit.

**Common misconception.** Many developers assume prompt caching stores model outputs (i.e., the response is cached and replayed). It does not. Caching stores intermediate compute state, not answers. Two requests sharing the same prefix can still produce different outputs because sampling is applied to the un-cached suffix and the generation step.

For a practical walkthrough of caching in production agent pipelines, see [[gemini-enterprise-agents]] and [[claude-tool-use-from-zero]].

## Related Terms

- [[glossary/context-window|Context window]] — the token buffer the model reads at each step of the loop
- [[glossary/inference-time-compute|Inference-Time Compute]] — additional computation at inference time (e.g. chain-of-thought, search) that improves output quality
- [[glossary/tokenization|Tokenization]] — related concept that intersects with this term in agent workflows
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
