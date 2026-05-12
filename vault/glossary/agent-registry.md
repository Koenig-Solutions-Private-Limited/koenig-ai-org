---
term: "Agent Registry"
definition: "An agent registry is a central directory or metadata store where AI agents and their capabilities (tools, resources, prompts) are registered, allowing for discovery, version management, and orchestration by the host."
seo_description: "Agent registry explained: directory for AI agents and their tools."
category: "agent-architecture"
related_terms: [agent-scaffolding, agent-orchestration, mcp]
related_courses: [gemini-enterprise-agents]
---

In complex multi-agent systems, agents need to find each other dynamically. A registry provides the lookup service: an orchestrator queries the registry to find the correct agent to handle a specific task (e.g., "find the agent capable of CI test execution"). Registries often include health status, tool descriptions, and auth requirements.
