---
term: "Agent Budget"
definition: "A predefined limit on the resources—tokens, API calls, wall-clock time, or monetary cost—that an agent is permitted to consume on a single task or within a time period, enforced by the orchestrator or a watchdog process."
seo_description: "Agent budget: predefined resource limits (tokens, cost, time) for an AI agent per task or period, enforced to prevent runaway consumption."
category: "Agentic AI concepts"
related_terms: [agent-orchestration, agent-heartbeat, escalation, autonomous-agent, watchdog]
---

Agent budgets are the primary lever for controlling cost in autonomous AI systems. Without explicit limits, agents can enter infinite loops, spawn excessive sub-agents, or make thousands of API calls on a single task. Budget enforcement prevents these failure modes while still allowing legitimate complex tasks to consume appropriate resources.

Budget dimensions to track include: input tokens, output tokens, tool calls (especially to expensive external APIs), total monetary cost, and elapsed time. Different task types warrant different budgets—a deep research task legitimately requires more tokens than a simple classification task. Budgets are typically set per-task type in the agent's config.json and can be overridden by the orchestrator for specific tasks.

When a budget is approached, the agent should detect this and proactively summarize and conclude rather than abruptly stopping. A budget-aware agent monitors its remaining allowance each loop iteration and shifts to a "wrap up" mode at, say, 80% consumption, prioritizing a useful partial answer over silence.
