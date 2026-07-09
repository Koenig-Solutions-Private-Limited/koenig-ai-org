---
term: "Rate Limiting"
definition: "Rate limiting is the practice of restricting the number of API requests a user or agent can make within a specific time period to maintain service stability and prevent abuse."
seo_description: "Rate limiting explained: protecting AI services from abuse."
category: "infrastructure"
related_terms: [ai-gateway, rbac, audit-trail]
related_courses: [mcp-from-first-principles-to-production]
---

Rate limiting governs how frequently a client can interact with an API endpoint within a rolling time window. For LLM providers, two separate dimensions are usually enforced simultaneously: requests per minute (RPM) and tokens per minute (TPM). An agent can hit either ceiling independently — a low-request, high-context workflow can exhaust TPM while barely touching RPM, while a tool-calling agent firing dozens of short classification requests can saturate RPM with minimal token spend.

**The 429 error and backoff.** When a client exceeds its limit, the server returns HTTP 429 Too Many Requests. The correct response is exponential backoff with jitter — doubling the wait on each retry and adding a random offset to prevent synchronized retry storms when multiple agents hit the limit simultaneously. Blindly retrying at fixed intervals is the fastest path to a permanent ban.

**Burst headroom vs. sustained limits.** Most providers distinguish between burst allowance (a short-term spike above the sustained rate, consumed from a token bucket) and the sustained baseline. An agent that fires ten parallel tool calls instantly may burn its burst budget in seconds and then stall for the rest of the minute. Designing around sustained limits rather than burst headroom makes agents more predictable in production.

**Why agents are especially vulnerable.** The [[agent-loop]] amplifies limit exhaustion in ways that single-turn applications do not. An agent running an inner planning loop, spawning parallel sub-agents, or iterating on a [[tool-use]] result can generate tens of requests per second without any explicit batching. Without an [[agent-budget]] ceiling that terminates runaway loops, a single misconfigured agent can exhaust a team's entire TPM allocation and degrade every other service sharing the same API key.

**Gateway vs. provider enforcement.** Provider-side limits are a safety net, not a design target. A well-architected [[mcp]] deployment enforces rate limits at the gateway tier — before requests reach the model — using tools like token-bucket middleware. Gateway enforcement allows per-tenant or per-agent limits, detailed [[audit-trail]] logging, and graceful queuing rather than hard 429 failures.

**Design pattern.** Before starting a long multi-step task, check current quota utilization via the provider's rate-limit headers (`x-ratelimit-remaining-tokens`, etc.) and size the task accordingly. If remaining headroom is below the estimated task budget, queue or defer rather than start and fail midway.

See [[mcp-from-first-principles-to-production]] for a practical gateway implementation that wires per-agent rate limits into an MCP server deployment.

## Related Terms

- [[glossary/ai-gateway|AI Gateway]] — the proxy layer that centralises auth, rate-limiting, logging, and model routing
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
