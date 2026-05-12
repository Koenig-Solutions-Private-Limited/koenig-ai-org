---
term: "Escalation"
definition: "The automatic or triggered transfer of a task to a higher-authority agent or human reviewer when the current agent lacks the capability, confidence, or permission to proceed safely and correctly."
seo_description: "Escalation: transferring a task to a higher-authority agent or human when the current agent lacks capability, confidence, or permission to proceed."
category: "Agentic AI concepts"
related_terms: [human-in-the-loop, handoff, agent-budget, corrigibility, definition-of-done, agent-orchestration]
---

Escalation is a safety mechanism that prevents agents from proceeding through uncertainty by taking potentially harmful actions. Escalation triggers include: confidence below a threshold, a requested action outside the agent's defined lane, budget nearly exhausted, repeated failures on a sub-task, or detection of a potential security issue.

Escalation paths form a directed graph: a worker agent escalates to its chief, who escalates to the CEO agent, who escalates to a human. Each level should be able to resolve most issues surfaced from below; human escalation should be rare (for genuinely novel or high-stakes decisions) rather than routine.

Implementing escalation requires clear criteria for when to escalate vs. when to attempt recovery. Over-escalation paralyzes the system; under-escalation allows errors to compound. The optimal threshold depends on the cost of a wrong action vs. the cost of interrupting a human—for irreversible actions, escalation bias is appropriate; for low-stakes reversible actions, agents should attempt recovery independently.
