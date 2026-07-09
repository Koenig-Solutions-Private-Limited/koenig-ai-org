---
term: "Memory Agent"
definition: "An AI agent component or dedicated sub-agent responsible for storing, indexing, and retrieving information across sessions, maintaining continuity beyond a single context window."
seo_description: "Memory agent: an AI component that stores and retrieves information across sessions, extending an agent's memory beyond its context window."
category: "Agentic AI concepts"
related_terms: [agent-memory, episodic-memory, semantic-memory, working-memory, context-injection, rag]
---

Because LLMs have a finite context window, long-running agents need an external memory layer. A memory agent manages three stores: episodic (what happened in past sessions), semantic (facts, summaries, world knowledge), and working (current session scratchpad). It decides what to write, when to consolidate, and what to recall for each incoming task.

Write policies matter: naive agents write everything, which leads to noisy recall. Sophisticated memory agents use importance scoring, deduplication, and periodic summarization to keep the store compact and relevant. Tools like LangGraph's MemorySaver, and Paperclip's vault-first memory pattern, are practical implementations.

Retrieval uses dense embedding search or BM25 keyword search, often re-ranked with a cross-encoder. The retrieved snippets are injected into the live context window, giving the agent apparent long-term memory without any modification to the underlying model weights.

## Related Terms

- [[glossary/agent-memory|Agent Memory]] — the persistence layer (working, episodic, semantic) that maintains agent continuity
- [[glossary/episodic-memory|Episodic Memory]] — the long-term store of past interactions retrieved to inform future decisions
- [[glossary/semantic-memory|Semantic Memory]] — the persistent factual knowledge base the agent queries during tasks
- [[glossary/working-memory|Working Memory]] — the in-context short-term store for the current task's intermediate results
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
