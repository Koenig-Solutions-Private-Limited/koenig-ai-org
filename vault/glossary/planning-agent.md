---
term: "Planning Agent"
definition: "An AI agent specialized in decomposing high-level goals into ordered, executable sub-tasks, selecting tools and sub-agents, and maintaining a plan that adapts as new information arrives during execution."
seo_description: "Planning agent: an AI agent that decomposes goals into executable sub-tasks and coordinates execution across tools and sub-agents."
category: "Agentic AI concepts"
related_terms: [agent-loop, hierarchical-agents, sub-agent, orchestrator, agent-orchestration]
---

Planning agents operate at the top of the agentic hierarchy. Given a natural-language objective, a planning agent produces a structured task graph—a sequence or DAG of steps—then either executes them directly or delegates to specialized sub-agents. Common planning strategies include tree-of-thought search, ReAct-style planning, and divide-and-conquer decomposition.

Good planning agents are also re-planning agents: when a step fails or produces unexpected output, they revise the remaining plan rather than aborting. This requires tight integration with an episodic memory that records what has already been tried.

In systems like Paperclip, the planning role is distinct from the execution role, enforcing the principle that a single agent should not both design and execute work without review. The planner produces a plan artifact that a human or senior agent can inspect before execution begins.
