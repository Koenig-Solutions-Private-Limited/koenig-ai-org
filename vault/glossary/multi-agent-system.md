---
term: "Multi-Agent System"
definition: "An architecture in which multiple AI agents, each with distinct roles and capabilities, collaborate or compete to accomplish tasks that exceed what any single agent could do within one context window."
seo_description: "Multi-agent system: an architecture where multiple AI agents with distinct roles collaborate to solve complex tasks beyond a single agent's scope."
category: "Agentic AI concepts"
related_terms: [agent-orchestration, orchestrator, sub-agent, hierarchical-agents, handoff, parallel-tool-calls]
---

Multi-agent systems decompose complex work along two dimensions: specialization (a research agent, a code agent, a reviewer agent each optimized for one domain) and parallelism (multiple agents working simultaneously on independent sub-tasks). This mirrors how human organizations are structured, and the same coordination challenges apply.

Communication between agents happens through shared message queues, structured handoff payloads, or a shared workspace (like an Obsidian vault or a database). Governance requires clear ownership—each task has exactly one responsible agent at any moment—to prevent both deadlock and duplicate work.

As of 2026, frameworks like Paperclip, LangGraph, and the Claude Agent SDK provide primitives for spawning sub-agents, routing messages, and enforcing budget limits across an entire fleet. Key open problems include trust between agents (can agent A trust agent B's tool results?) and emergent behavior in large swarms.

## Related Terms

- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that manages task flow and agent lifecycles across the system
- [[glossary/orchestrator|Orchestrator]] — the top-level component that holds the global view of all agents and tasks
- [[glossary/sub-agent|Sub-Agent]] — the worker units that a multi-agent system spawns to handle specialized sub-tasks
- [[glossary/handoff|Handoff]] — the structured transfer mechanism that connects agents within the system
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — learn agent orchestration, loops, and budgets in a production context
