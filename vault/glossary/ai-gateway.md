---
term: "AI Gateway"
definition: "An AI gateway is a proxy layer between the AI application and the model/service provider that handles common cross-cutting concerns like rate limiting, logging, auditing, RBAC, and model routing."
seo_description: "AI gateway explained: the proxy layer for model orchestration and management."
category: "infrastructure"
related_terms: [api-rate-limit, rbac, audit-trail]
related_courses: [mcp-from-first-principles-to-production]
---

An AI gateway acts as the hardened perimeter for agentic systems. Without a gateway, agents interact directly with vendors, which creates security risks. A gateway centralizes observability (logging every request) and security (enforcing API keys or RBAC). It also enables model agility, allowing developers to switch between model providers without changing application-level integration code.
