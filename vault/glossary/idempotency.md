---
term: "Idempotency"
definition: "An operation is idempotent if it can be applied multiple times without changing the result beyond the initial application."
seo_description: "Idempotency explained: critical for reliable agent operations."
category: "architecture"
related_terms: [agent-orchestration]
related_courses: [production-agents-claude-agent-sdk-mcp-connector]
---

Agentic systems must be resilient to retries. If an agent tries to call a "charge payment" tool, the network times out, and the agent retries, it must *not* charge the user twice. Building idempotent tools—often by including a client-generated unique `idempotency-key`—is a mandatory best practice for any MCP server dealing with side-effecting operations.
