---
term: "Caching"
definition: "The practice of storing computed results or reusable data so later requests can be served faster or more cheaply."
seo_description: "Caching: storing computed results or reusable data so later requests can be served faster or at lower cost."
category: "Infrastructure"
related_terms: [prompt-caching, kv-cache, inference, latency, rate-limiting]
related_courses: [gemini-enterprise-agents]
---

Caching stores the result of an expensive computation so the next request that needs it can skip the work. In AI systems this applies at several layers simultaneously, each with its own cost/freshness tradeoff.

**Types of caches in AI systems.** [[prompt-caching]] and [[kv-cache]] operate inside the model serving layer: when the same prompt prefix is reused, the transformer's key-value attention state is cached and re-served, cutting [[inference]] cost and [[latency]] dramatically for long-context or repeated-system-prompt workloads. [[retrieval]] result caches store the top-k document chunks returned for a query, avoiding a round-trip to the vector database for repeated questions. Embedding caches store the dense vector representation of a text passage, so the same document does not need to be re-encoded each time. Tool result caches store the output of external API calls (search, database lookups) for a defined window. Response caches store the final model output for a query, serving it verbatim to identical future requests.

**Cache key design.** A cache key must include every input that would change the output. For a prompt cache, the key typically covers the model ID, the system prompt, and the user message prefix. For a retrieval cache, the key is the query embedding or the raw query string. A missing dimension in the key causes cache poisoning: the system returns a stale or wrong result because it cannot distinguish between two requests that appear identical but should not be.

**TTL vs. event-based invalidation.** Time-to-live (TTL) expiry is simple and predictable but imprecise. A cached retrieval result from a document that was updated one minute after caching remains valid for the full TTL window. Event-based invalidation — purging cache entries when the underlying document, permission, or business rule changes — is more correct but requires a signal path from the data source to the cache layer.

**Semantic caching.** A more advanced pattern stores model responses indexed by the embedding of the query rather than the exact string. A near-duplicate question then hits the cache even if the wording differs. This can slash costs for FAQ-style workloads, but it requires tuning a similarity threshold carefully: too loose and unrelated queries get wrong cached answers.

**Common misconception.** Caching model responses is not always safe. If the underlying [[retrieval]] corpus has changed, the model's behaviour has updated (via fine-tuning or system prompt), or access permissions have been modified, a cached response may be incorrect or reveal content the requester is no longer authorised to see. See [[gemini-enterprise-agents]] for how enterprise deployments handle cache invalidation alongside access control.

## Related Terms

- [[glossary/prompt-caching|Prompt Caching]] — the mechanism that reuses cached key-value state for repeated long prefixes
- [[glossary/kv-cache|KV Cache]] — the cached key-value pairs that eliminate redundant attention computation across turns
- [[glossary/inference|Inference]] — the process of running a trained model forward to generate output
- [[glossary/latency|Latency]] — the elapsed time from request submission to first token or full response received
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
