---
term: "Rate Limiting"
definition: "Rate limiting is the practice of restricting the number of API requests a user or agent can make within a specific time period to maintain service stability and prevent abuse."
seo_description: "Rate limiting explained: protecting AI services from abuse."
category: "infrastructure"
related_terms: [ai-gateway, rbac, audit-trail]
related_courses: [mcp-from-first-principles-to-production]
---

Rate limiting prevents a single runaway agent or malicious actor from exhausting resources. For MCP architectures, rate limiting is usually enforced at the gateway tier, ensuring that even if an agent tries to burst thousands of requests per second, the upstream tools and models are protected from starvation or catastrophic cost overruns.
