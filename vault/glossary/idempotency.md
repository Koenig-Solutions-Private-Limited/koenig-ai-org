---
term: "Idempotency"
definition: "A property of an operation that guarantees identical results when applied once or multiple times to the same input—critical for agent tool design because agents must be able to safely retry operations after network failures or timeouts."
seo_description: "Idempotency in AI agents: why tools must be designed to handle retries safely, and how idempotency keys prevent double-charges, duplicate records, and data corruption."
category: "architecture"
related_terms: [agent-orchestration, agent-loop, tool-use, sandboxing, audit-trail, rate-limiting]
related_courses: [production-agents-claude-agent-sdk-mcp-connector, mcp-from-first-principles-to-production]
---

**Idempotency** guarantees that repeating an operation produces the same outcome as running it once. The classic example: an HTTP GET request is idempotent because fetching the same URL twice returns the same (or equivalent) data and does not change server state. An HTTP POST that creates a new record is not idempotent by default—posting twice creates two records.

For agentic systems, idempotency is a mandatory property for any tool that has side effects. Agents operate over networks with transient failures. A tool call that triggers a payment, sends a notification, or creates a database record may execute successfully on the server but have its response lost in transit. The agent's retry logic—which is essential for reliability—will then fire the same tool call again. Without idempotency, that retry creates a duplicate charge, duplicate notification, or duplicate record. The standard solution is an **idempotency key**: the client generates a unique identifier per logical operation (not per retry), includes it in the tool call arguments, and the server uses that key to detect and deduplicate repeated requests. Payment APIs, messaging APIs, and most enterprise APIs that accept writes support this pattern.

A common misconception is that idempotency only matters for payment flows. Any agent that can modify data—creating files, updating records, sending messages, triggering workflows—should expose idempotent tool interfaces. Another misconception is that making a tool idempotent requires complex deduplication infrastructure. For many operations, a simple check-then-write pattern works: "if a record with this ID already exists, return it rather than creating a duplicate." The [[audit-trail]] pattern complements idempotency: when every tool call is logged with its idempotency key, it is easy to verify during incident review whether a retry actually executed twice or was deduplicated correctly. See [[production-agents-claude-agent-sdk-mcp-connector]] for idempotent tool design patterns in production Claude agent workflows.

## Related Terms

- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that routes and schedules work across multiple agents
- [[glossary/agent-loop|Agent Loop]] — the iterative perceive-act-observe cycle the harness executes
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/sandboxing|Sandboxing]] — the isolation mechanism that prevents agent code execution from affecting the host system
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
