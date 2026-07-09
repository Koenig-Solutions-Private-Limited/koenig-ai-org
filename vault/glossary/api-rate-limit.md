---
term: "API Rate Limit"
definition: "A constraint enforced by an API provider that caps the number or volume of requests a client can make within a time window, returning a 429 error and requiring the client to throttle or back off when the limit is exceeded."
seo_description: "API rate limit: how provider-enforced request caps affect AI agents and why exponential backoff and budget guards are essential for reliable agentic systems."
category: "Infrastructure"
related_terms: [rate-limiting, latency, inference, ai-gateway, agent-budget, agent-loop]
related_courses: [production-agents-claude-agent-sdk-mcp-connector, mcp-from-first-principles-to-production]
---

An **API rate limit** is a guardrail that prevents any single client from monopolizing a shared service. Model providers express rate limits in multiple dimensions simultaneously: requests per minute (RPM), tokens per minute (TPM), and sometimes requests per day. Exceeding any dimension returns HTTP 429. The provider's response typically includes a `Retry-After` header indicating when the client can try again. For agents that make many sequential or parallel tool calls, hitting rate limits is one of the most common causes of workflow failures in production.

The naive fix—retrying immediately on 429—makes the problem worse because all retries hit the limit at the same moment. The standard pattern is exponential backoff with jitter: wait 1 second, then 2, then 4, with a small random offset to prevent a "thundering herd" of simultaneous retries from different agent instances. Beyond retry logic, well-designed agentic systems implement proactive rate management: tracking token consumption within the [[agent-loop]], spreading parallel calls across time using queuing, and routing lower-priority agent tasks to off-peak windows using the [[ai-gateway]].

A common misconception is that rate limits only matter for heavy workloads. They matter whenever an agent runs multiple tool calls per user request—even a modest agent that makes 5 tool calls per query can hit per-minute limits quickly if multiple users run it simultaneously. Another misconception is that rate limits are fixed: providers offer higher-tier limits on request, and enterprise contracts often include dedicated capacity that removes per-minute caps entirely. The [[agent-budget]] pattern complements rate limit handling: instead of only reacting to 429 responses, an agent tracks its own token spend and voluntarily slows down before hitting limits, preventing visible user-facing failures. See [[production-agents-claude-agent-sdk-mcp-connector]] for production-grade rate limit patterns.

## Related Terms

- [[glossary/rate-limiting|Rate Limiting]] — the policy of capping request throughput to protect service reliability
- [[glossary/latency|Latency]] — the elapsed time from request submission to first token or full response received
- [[glossary/inference|Inference]] — the process of running a trained model forward to generate output
- [[glossary/ai-gateway|AI Gateway]] — the proxy layer that centralises auth, rate-limiting, logging, and model routing
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
