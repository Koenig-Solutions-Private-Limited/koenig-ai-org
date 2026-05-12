---
term: "Sub-Agent"
definition: "An AI agent spawned by an orchestrator or parent agent to handle a specific sub-task, operating within a delegated scope and budget, and returning results to the parent upon completion."
seo_description: "Sub-agent: an AI agent spawned by a parent orchestrator to handle a specific delegated sub-task within a bounded scope and budget."
category: "Agentic AI concepts"
related_terms: [orchestrator, hierarchical-agents, agent-orchestration, handoff, multi-agent-system, agent-budget]
---

Sub-agents implement the decomposition step of hierarchical planning. When a planning agent determines that a sub-task requires specialized capabilities or would exceed its own context budget, it spawns a sub-agent with a focused mandate: "research this topic and return a 500-word summary with citations." The sub-agent operates independently within its assigned scope.

Sub-agent boundaries enforce good software engineering principles at the agent level: separation of concerns, clear interfaces (the sub-agent receives a typed input and returns a typed output), and independent testability. A sub-agent for code review can be tested separately from the planning agent that decides when to invoke it.

Trust between parent and sub-agent is a nuanced issue. The parent should validate sub-agent outputs before acting on them, especially in security-sensitive contexts where a compromised or misbehaving sub-agent could inject malicious instructions. Defense-in-depth means the orchestrator applies its own safety checks even on outputs from trusted sub-agents.
