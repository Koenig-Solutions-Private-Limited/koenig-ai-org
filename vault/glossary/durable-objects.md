---
term: "Durable Objects"
definition: "Durable Objects are stateful serverless primitives provided by Cloudflare that provide strongly consistent state storage coupled with compute, designed to solve problems like session management, collaborative editing, and real-time multiplayer coordination."
seo_description: "Durable Objects explained: strongly consistent stateful serverless compute from Cloudflare for real-time applications."
category: "infrastructure"
related_terms: [agent-memory, memory-agent, orchestrator]
related_courses: [gemini-enterprise-agents]
sameAs:
  - https://developers.cloudflare.com/durable-objects/
---

A Durable Object is a single-instance actor with its own private storage and compute. When you create a Durable Object by ID, every request that references that ID is routed to the same instance — no matter where it originates in the world. This makes it fundamentally different from stateless serverless functions, where any instance can handle any request and shared state must live in an external database with all the coordination overhead that implies.

**Why strong consistency matters for agents.** An [[agent-loop]] typically executes a sequence of tool calls, accumulates intermediate results, and maintains a view of what has happened so far within a session. If that session state is distributed across multiple compute instances without coordination, you can get split-brain situations: one instance believes tool A succeeded, another has not seen that update yet, and a subsequent decision is made on a stale snapshot. Durable Objects eliminate this class of bug by making the session state the exclusive property of a single instance that processes requests one at a time.

**Storage model.** Each Durable Object has a private transactional key-value store. Reads and writes within a single request are atomic. The storage persists across requests and is replicated for durability. This makes Durable Objects suitable as the persistence layer for [[agent-memory]] — the object can read its stored state at the start of a turn and commit updates at the end.

**WebSocket support.** Durable Objects can hold persistent WebSocket connections open for their entire lifetime. This is important for streaming agent workflows: the object manages the [[http-sse]] or WebSocket connection to the client while also orchestrating upstream tool calls and [[mcp]] server interactions. The connection lives as long as the object is active, removing the per-request timeout limitation of standard serverless functions.

**How this differs from Redis or shared state stores.** Redis provides fast key-value access but requires all compute instances to coordinate through it, introducing network round-trips and potential race conditions under concurrent writes. A Durable Object is the database and the compute in the same place: there is no round-trip to an external store for state that belongs to a single session.

**[[mcp]] hosting use case.** A common pattern in stateful MCP deployments is to run one Durable Object per active session. The object manages the full [[mcp]] server lifecycle for that session, ensuring that tool invocations are sequenced correctly and that session context is not lost between turns.

**Limitation.** The single-instance model means a single-region execution by default. Globally distributed, read-heavy workloads that do not require strong per-session consistency are better served by Cloudflare KV or a distributed cache. Durable Objects are the right primitive when correctness of session state matters more than global read throughput. See [[gemini-enterprise-agents]] for architecture patterns that combine Durable Objects with [[orchestrator]] design.

## Related Terms

- [[glossary/agent-memory|Agent Memory]] — the persistence layer (working, episodic, semantic) that maintains agent continuity
- [[glossary/memory-agent|Memory Agent]] — a specialized agent that manages long-term knowledge retrieval and storage
- [[glossary/orchestrator|Orchestrator]] — the component that owns the task graph and decides which agent handles each step
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
