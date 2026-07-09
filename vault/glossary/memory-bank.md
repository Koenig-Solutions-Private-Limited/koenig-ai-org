---
term: "Memory Bank"
definition: "A Memory Bank is a persistent, structured storage pattern used by AI agents to maintain state, user preferences, and project context across multiple sessions and disparate conversations."
seo_description: "Memory Bank pattern explained: how AI agents maintain long-term persistent context across sessions."
category: "agent-architecture"
related_terms: [agent-memory, episodic-memory, semantic-memory]
related_courses: [gemini-enterprise-agents]
sameAs: []
---

A Memory Bank separates the short-lived context of a single conversation from the durable, accumulated knowledge of the agent's work over time. When a session ends, the in-context window is discarded; what the agent wrote to its memory bank persists and is available on next invocation. This is what allows an agent to behave like a continuant — one that remembers decisions made last week, user preferences set last month, and project milestones completed yesterday — rather than starting from zero every time.

**What a Memory Bank stores vs. a vector database.** A [[vector-database]] holds raw document embeddings optimised for semantic similarity search across a large corpus. A Memory Bank holds structured, agent-authored state: current project status, user preferences, key decisions and their rationale, configuration choices, and known constraints. The Memory Bank is typically small, high-signal, and human-readable; the vector DB is large, approximate, and machine-indexed.

**Three types of agent memory.** [[Episodic-memory]] records events in sequence — what happened, when, and in what order. [[Semantic-memory]] stores facts and concepts independent of when they were learned — "the user prefers concise responses" or "the deployment target is Cloudflare Workers." Procedural memory stores skills and action patterns. A Memory Bank typically holds all three in structured form, often as categorised markdown files or a lightweight JSON document.

**Read and write patterns.** At the start of each session, the agent reads its memory bank to reconstruct context. At the end — or at significant checkpoints during a long task — it writes updates: new decisions, changed preferences, completed milestones, discovered constraints. Some systems write in real-time on each significant event. The write step is as important as the read step; agents that forget to update their memory bank accumulate stale beliefs.

**Persistence layer.** Memory banks are commonly stored as files, in a relational database, in a key-value store, or as a dedicated table in the application database. The choice depends on access patterns: files work well for single-agent systems with low write concurrency; databases scale better for multi-agent systems where several agents may update shared memory.

**The freshness challenge.** Stale memory causes agents to act on outdated beliefs — continuing a project that was cancelled, applying a user preference that was revoked, or treating a completed task as pending. Memory banks require explicit invalidation and update discipline. Agents should mark memories with the date they were written and treat old entries with appropriate scepticism.

**Memory compression.** Memory banks grow over long projects. Agents must periodically summarise older entries to prevent the bank from exceeding a useful size. This is analogous to how [[rag]] systems use [[chunking]] to manage document size. The summarisation step itself can be a model call — the agent compresses its own episodic log into a higher-level narrative.

**Common misconception.** A large [[context-window]] does not eliminate the need for persistent memory. Context is cleared between sessions; the memory bank persists deliberately. The two mechanisms are complementary: within a session, context holds everything; across sessions, the memory bank bridges the gap. See [[agent-loop]] and [[gemini-enterprise-agents]] for practical patterns.

## Related Terms

- [[glossary/agent-memory|Agent Memory]] — the persistence layer (working, episodic, semantic) that maintains agent continuity
- [[glossary/episodic-memory|Episodic Memory]] — the long-term store of past interactions retrieved to inform future decisions
- [[glossary/semantic-memory|Semantic Memory]] — the persistent factual knowledge base the agent queries during tasks
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
