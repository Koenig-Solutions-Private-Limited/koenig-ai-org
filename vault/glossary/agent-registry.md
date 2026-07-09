---
term: "Agent Registry"
definition: "A central directory or metadata store where AI agents register their identities, capabilities, tools, and resource requirements, allowing orchestrators and other agents to discover and route work to the right agent dynamically."
seo_description: "Agent registry: the directory service that lets AI orchestrators discover, route to, and version-manage the agents in a multi-agent system."
category: "agent-architecture"
related_terms: [agent-scaffolding, agent-orchestration, mcp, orchestrator, multi-agent-system, agent-harness]
related_courses: [gemini-enterprise-agents, production-agents-claude-agent-sdk-mcp-connector]
---

An **agent registry** is the lookup service that makes [[multi-agent-system]] architectures dynamic rather than hard-coded. Instead of the [[orchestrator]] having a static list of agent addresses compiled into its code, it queries the registry at runtime: "which agent handles CI test execution?" or "which agent has read access to the payment service?" The registry returns metadata—endpoint, tool list, authentication requirements, health status, version—and the orchestrator routes accordingly.

This matters most when the agent fleet is large or changes frequently. Adding a new specialized agent, upgrading an existing one, or decommissioning a deprecated agent is a registry operation rather than an orchestrator code change. Well-implemented registries also carry capability schemas that let the orchestrator know what inputs each agent expects and what outputs it produces, enabling automatic composition of multi-step workflows. [[mcp]] servers surface their available tools through a similar discovery mechanism, and an agent registry often wraps or extends that pattern to cover agent-to-agent routing, not just tool availability.

Production registries typically add health checks, capacity signals, and [[rbac]] enforcement so that an agent cannot be routed tasks it lacks permission to execute. A common misconception is that a registry is only needed at large scale—in practice, even two-agent systems benefit from a registry because it makes adding a third agent a configuration change rather than a code change. Another misconception is conflating the registry with the [[orchestrator]] itself: the orchestrator decides what to do; the registry tells it which agent can do it. See [[gemini-enterprise-agents]] for how Google's enterprise agent platform handles multi-agent discovery and routing.

## Related Terms

- [[glossary/agent-scaffolding|Agent Scaffolding]] — the non-model infrastructure that surrounds the LLM to enable agent behaviour
- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that routes and schedules work across multiple agents
- [[glossary/mcp|Model Context Protocol (MCP)]] — the protocol layer that standardises how agents discover and call tools
- [[glossary/orchestrator|Orchestrator]] — the component that owns the task graph and decides which agent handles each step
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
