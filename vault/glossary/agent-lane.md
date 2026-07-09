---
term: "Agent Lane"
definition: "The defined scope of actions, tools, and decisions an agent is authorized to take, preventing scope creep and ensuring each agent in a multi-agent system stays within its designated responsibility boundary."
seo_description: "Agent lane: the defined scope of actions and decisions an agent is authorized to take, preventing scope creep in multi-agent systems."
category: "Agentic AI concepts"
related_terms: [agent-soul, definition-of-done, escalation, agent-orchestration, hierarchical-agents]
---

Lane discipline is the agentic equivalent of separation of concerns in software engineering. Each agent has a lane: the set of tools it may call, the types of tasks it may accept, and the decisions it may make unilaterally. Staying in lane means the agent does not attempt to perform work that belongs to another agent, even if it believes it could.

Lane boundaries are enforced at multiple levels: the SOUL document instructs the agent to stay in lane, the tool list in config.json restricts which tools are physically available, and the orchestrator routes tasks only to agents whose lane matches the task type. Belt-and-suspenders enforcement is important because LLMs can sometimes be prompted to ignore their instructions.

The value of lane discipline scales with system complexity. In a two-agent system, lane violations are merely inefficient. In a twenty-agent system, an agent drifting out of its lane can create cascading failures: it produces output that the downstream agent cannot handle, or it takes actions that conflict with another agent currently working on related state.

## Related Terms

- [[glossary/agent-soul|Agent SOUL]] — the identity document that constrains the agent's lane and definition-of-done
- [[glossary/definition-of-done|Definition of Done]] — the explicit completion criteria that tell the agent when to stop and report
- [[glossary/escalation|Escalation]] — the mechanism for passing an issue up the chain of command when the agent is blocked
- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that routes and schedules work across multiple agents
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
