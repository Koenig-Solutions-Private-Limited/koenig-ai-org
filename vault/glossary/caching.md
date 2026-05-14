---
term: "Caching"
definition: "The practice of storing computed results or reusable data so later requests can be served faster or more cheaply."
seo_description: "Caching: storing computed results or reusable data so later requests can be served faster or at lower cost."
category: "Infrastructure"
related_terms: [prompt-caching, kv-cache, inference, latency, rate-limiting]
---

Caching reduces repeated work. In AI systems, caches may store retrieved documents, embeddings, prompt prefixes, model responses, tool results, or compiled assets used by an agent workflow.

The tradeoff is freshness. A cache can return stale data after source documents, permissions, or business rules change. Reliable systems define cache keys carefully, set expiration policies, and invalidate cached entries when the underlying facts or access rights change.
