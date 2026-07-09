---
term: "Orchestrator"
definition: "The top-level component in a multi-agent system responsible for receiving goals, decomposing them into tasks, assigning tasks to appropriate agents, monitoring progress, and handling failures and escalations."
seo_description: "Orchestrator: the top-level multi-agent component that decomposes goals, assigns tasks to agents, monitors progress, and handles failures."
category: "Agentic AI concepts"
related_terms: [agent-orchestration, hierarchical-agents, planning-agent, sub-agent, handoff, agent-budget]
---

The orchestrator is the conductor of the multi-agent orchestra. It maintains a global view of the task graph—which tasks are pending, in progress, blocked, or complete—while individual agents have only a local view of their current assignment. This separation of concerns enables the orchestrator to re-route tasks around failures without agents needing awareness of each other.

Orchestrators can be implemented as a dedicated agent (typically a strong model like Opus 4.7 running a planning + routing loop), as a deterministic state machine (for well-defined pipelines), or as a hybrid (a state machine for normal flow, an agent for exception handling). Pure state machine orchestrators are cheaper and more reliable for known-good pipelines; agent orchestrators are more flexible for novel task types.

In Paperclip, the CEO agent acts as the primary orchestrator: it receives company-level goals, translates them into projects and tasks, assigns them to chiefs, and monitors status via Langfuse dashboards. Chiefs act as sub-orchestrators within their domains, delegating to worker agents and aggregating results.

## Related Terms

- [[glossary/agent-orchestration|Agent Orchestration]] — the process and patterns the orchestrator implements to coordinate agent work
- [[glossary/hierarchical-agents|Hierarchical Agents]] — the layered architecture in which orchestrators and sub-orchestrators nest within each other
- [[glossary/sub-agent|Sub-Agent]] — an agent spawned and managed by the orchestrator to handle delegated sub-tasks
- [[glossary/handoff|Handoff]] — the task transfer the orchestrator mediates between agents in the pipeline
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — learn agent orchestration, loops, and budgets in a production context
