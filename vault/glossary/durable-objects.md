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

Durable Objects allow developers to store state in a way that is persistent and consistently accessible by compute logic. By binding a unique identifier to a single instance of a class, Durable Objects ensure that all requests to that object are processed in a specific, ordered manner, eliminating the race conditions common in distributed systems. This makes them ideal for building MCP-like gateways or multi-agent orchestrators where session state must be maintained across disparate requests.
