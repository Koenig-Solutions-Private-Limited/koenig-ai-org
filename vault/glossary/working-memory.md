---
term: "Working Memory"
definition: "In AI agents, the content currently held in the active context window—the task instructions, prior conversation turns, tool results, and injected memories available to the LLM at each reasoning step."
seo_description: "Working memory: the content in an AI agent's active context window—instructions, history, and tool results available at each reasoning step."
category: "Agentic AI concepts"
related_terms: [agent-memory, episodic-memory, semantic-memory, context-window, context-injection, kv-cache]
---

Working memory is bounded by the model's context window size—from 128K tokens in Claude Sonnet 4.6 to over 1M tokens in Gemini 2.5 Pro. Everything outside the context window is inaccessible to the model unless explicitly retrieved and injected. This fundamental constraint shapes all agent memory design decisions.

Content management within working memory is critical. At the start of a long agentic session, the system prompt, tool definitions, and initial task may consume 20–30% of the context. As the session progresses, tool results accumulate and old turns scroll out of the effective attention window (due to the recency bias of attention). Summarization and compaction strategies periodically compress old turns into dense summaries to reclaim context budget.

KV caching (key-value caching) allows the scaffolding to reuse previously computed attention states for stable prefixes (system prompt, tools list), dramatically reducing the cost and latency of each turn in a long agentic session.
