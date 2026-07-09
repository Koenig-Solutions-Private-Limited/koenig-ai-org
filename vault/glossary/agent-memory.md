---
term: "Agent Memory"
definition: "The collective set of information-persistence mechanisms available to an AI agent—spanning in-context working memory, episodic long-term memory, and semantic knowledge stores—that maintain continuity across turns and sessions."
seo_description: "Agent memory: the persistence mechanisms—working, episodic, and semantic—that let AI agents maintain continuity across turns and sessions."
category: "Agentic AI concepts"
related_terms: [working-memory, episodic-memory, semantic-memory, memory-agent, context-injection, rag]
---

Agent memory is typically stratified into three layers. Working memory is the current context window—fast, fully accessible, but strictly bounded. Episodic memory stores past interactions and task histories in an external database, retrievable by time or semantic similarity. Semantic memory stores factual knowledge, embeddings of documents, and summarized insights, searchable by content.

Write policies determine what gets stored and when. Naively writing everything leads to noisy retrieval; writing nothing loses important context. Effective agents use importance scoring, event triggers (task completion, error occurrence, novel information), and periodic summarization to maintain a compact, high-signal memory store.

Read policies determine what gets recalled and injected into context for each new task. Hybrid retrieval (dense semantic search + BM25 keyword) with cross-encoder re-ranking achieves good precision. The amount recalled is constrained by available context budget—agents should prioritize recent, highly relevant memories and discard low-relevance background.

## Related Terms

- [[glossary/working-memory|Working Memory]] — the in-context short-term store for the current task's intermediate results
- [[glossary/episodic-memory|Episodic Memory]] — the long-term store of past interactions retrieved to inform future decisions
- [[glossary/semantic-memory|Semantic Memory]] — the persistent factual knowledge base the agent queries during tasks
- [[glossary/memory-agent|Memory Agent]] — a specialized agent that manages long-term knowledge retrieval and storage
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
