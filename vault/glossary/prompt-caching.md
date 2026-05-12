---
term: "Prompt Caching"
definition: "Prompt caching is a technique that stores the results of intermediate processing of prompt tokens to avoid re-computing them, significantly reducing inference latency and costs for frequently reused context."
seo_description: "Prompt caching explained: how to reduce LLM costs and latency by caching long-context components."
category: "optimization"
related_terms: [context-window, inference-time-compute, tokenization]
related_courses: [gemini-enterprise-agents]
---

By caching the prefix or frequently used instructions of a prompt, models can bypass redundant computation. This is especially effective in agentic coding scenarios where large system prompts or codebase schemas are repeated across many consecutive turns, effectively turning O(N) context costs into near O(1) costs after the initial cache write.
