---
term: "Human-in-the-Loop"
definition: "An AI system design pattern in which human judgment is incorporated at designated checkpoints to approve, correct, or redirect agent actions before they become irreversible or cross a policy boundary."
seo_description: "Human-in-the-loop: an AI design pattern where humans approve or correct agent actions at key checkpoints to ensure safety and alignment."
category: "Agentic AI concepts"
related_terms: [autonomous-agent, escalation, agent-budget, corrigibility, definition-of-done, agent-evaluation]
---

Human-in-the-loop (HITL) is not a single mechanism but a spectrum of interventions. At the lightest end, a human reviews agent outputs after the fact (asynchronous review). In the middle, a human approves each plan before execution begins but lets execution run autonomously. At the heaviest end, every tool call requires explicit human confirmation—appropriate only for high-stakes, low-volume workflows.

Designing effective HITL requires identifying the right intervention points: not so frequent that humans become a bottleneck, not so sparse that errors propagate too far before detection. Common trigger conditions include: spending above a threshold, accessing sensitive resources, taking irreversible actions, or reaching low-confidence states.

In Paperclip's G0–G4 approval model, G4 is the human approval gate. Three channels surface the approval request (email magic-link, Slack/Teams button, Paperclip UI queue) to maximize the chance of a timely human response without requiring the human to monitor any single interface.

## Related Terms

- [[glossary/autonomous-agent|Autonomous Agent]] — an agent that completes tasks independently without step-by-step human approval
- [[glossary/escalation|Escalation]] — the mechanism for passing an issue up the chain of command when the agent is blocked
- [[glossary/agent-budget|Agent Budget]] — the resource and spend limits enforced to prevent runaway agent consumption
- [[glossary/definition-of-done|Definition of Done]] — the explicit completion criteria that tell the agent when to stop and report
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
