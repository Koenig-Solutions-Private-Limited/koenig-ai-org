---
term: "AI Gateway"
definition: "A proxy layer sitting between AI applications and model or tool providers that centralizes rate limiting, logging, authentication, RBAC, cost tracking, and model routing for agentic systems."
seo_description: "AI gateway: the infrastructure layer that enforces security, observability, and routing policy between AI applications and model providers."
category: "infrastructure"
related_terms: [api-rate-limit, rbac, audit-trail, rate-limiting, observability, structured-logging, mcp]
related_courses: [mcp-from-first-principles-to-production, gemini-enterprise-agents]
---

An **AI gateway** is the hardened perimeter for agentic systems. Without one, each application component calls model providers directly—which means API keys scattered across services, no central visibility into which agent is calling what, no consistent enforcement of spend limits, and no single place to enforce security policy. A gateway consolidates those concerns: every inference request and tool call passes through it, and the gateway applies authentication, [[rbac]], [[rate-limiting]], cost accounting, and logging before forwarding the request.

Beyond security, gateways enable model agility. If a team wants to upgrade from one model to another, or route different agent roles to different models based on cost or capability, the gateway handles that routing centrally without changing application code. Gateways also provide the foundation for A/B testing model changes: a percentage of traffic can be routed to a new model while the rest continues to the existing one, with [[observability]] metrics tracking which performs better on task completion, latency, and cost.

A common misconception is that an AI gateway is a luxury for large enterprises. Teams of any size benefit from centralized [[audit-trail]] logging (for debugging and compliance), unified spend dashboards (to catch runaway agent costs early), and a single credential rotation point (instead of updating API keys in every microservice). Another misconception is that a gateway adds significant latency—most gateways add fewer than 5ms when running close to the application, which is negligible against typical model generation times. See [[mcp-from-first-principles-to-production]] for how gateways combine with [[mcp]] servers to build secure, observable agent infrastructure.

## Related Terms

- [[glossary/api-rate-limit|API Rate Limit]] — the server-enforced cap on how many requests a client can make per time window
- [[glossary/rbac|RBAC (Role-Based Access Control)]] — the access-control model that grants permissions based on role rather than individual identity
- [[glossary/audit-trail|Audit Trail]] — the immutable chronological record of every action taken, enabling forensic review
- [[glossary/rate-limiting|Rate Limiting]] — the policy of capping request throughput to protect service reliability
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
