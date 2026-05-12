---
term: "API Rate Limit"
definition: "A constraint imposed by an API service provider on the number of requests a user or client can make within a specified timeframe (e.g., requests per minute)."
seo_description: "API rate limit: resource control constraint capping the number of requests to a service provider's API over a set duration."
category: "Infrastructure"
related_terms: [latency, inference]
---

## Definition
An API rate limit is a security and performance mechanism designed to prevent abuse of a service and to ensure stability by capping the volume of incoming requests. When a client exceeds the limit, the API typically responds with a 429 (Too Many Requests) error, signaling that further requests should be throttled or delayed. For AI agents, managing API rate limits is critical, especially when the agent performs many sub-tasks or tool calls. Proper handling involves implementing exponential backoff or scheduling requests to avoid hitting these thresholds.
