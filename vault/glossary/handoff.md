---
term: "Handoff"
definition: "The structured transfer of a task from one agent to another, including all necessary context, inputs, and instructions, ensuring the receiving agent can continue work without information loss."
seo_description: "Handoff: a structured transfer of a task between AI agents, passing all necessary context so the receiving agent can continue without gaps."
category: "Agentic AI concepts"
related_terms: [sub-agent, orchestrator, agent-orchestration, escalation, multi-agent-system, definition-of-done]
---

A handoff marks the boundary between agents in a pipeline or hierarchy. The sending agent packages its output—a document, a code diff, a data structure, an action plan—along with metadata: what was done, what remains, any blockers, and the expected output format. The receiving agent reads this package and continues without needing the full conversation history of the sender.

Good handoff design minimizes information loss. A code review handoff from a coder agent to a reviewer agent should include the diff, the original requirements, and the test results—not just the diff. Missing context forces the receiver to ask clarifying questions, which either blocks the pipeline or causes the receiver to make assumptions.

In Paperclip, handoffs are implemented as task state transitions. When a content author marks a task DONE, the system transitions it to REVIEW and assigns it to the reviewer agent, passing the authored content as the task payload. This explicit state machine prevents both dropped handoffs (task forgotten) and double-processing (two agents working simultaneously on the same task).

## Related Terms

- [[glossary/orchestrator|Orchestrator]] — the component that routes handoff payloads to the correct receiving agent
- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that formalizes handoff protocols across a pipeline
- [[glossary/escalation|Escalation]] — the alternative path when the receiving agent cannot accept the handoff or the task exceeds its scope
- [[glossary/sub-agent|Sub-Agent]] — a common handoff target; receives delegated sub-tasks from a parent or orchestrator
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — learn agent orchestration, loops, and budgets in a production context
