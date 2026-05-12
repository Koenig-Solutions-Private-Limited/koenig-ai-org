---
term: "Agentic Loop"
definition: "A synonym for the agent loop, emphasizing the iterative nature of autonomous AI execution: the model repeatedly perceives its context, selects an action, observes the result, and continues until a stopping condition is reached."
seo_description: "Agentic loop: the iterative perceive-act-observe cycle that defines autonomous AI agent execution, repeated until a goal is achieved."
category: "Agentic AI concepts"
related_terms: [agent-loop, tool-use, agent-scaffolding, agent-heartbeat, orchestrator, autonomous-agent]
---

The agentic loop is the runtime instantiation of an agent's cognitive architecture. Each iteration consists of: (1) assembling the current context from memory and prior observations, (2) calling the LLM to generate a response or tool call, (3) executing any tool calls, and (4) appending results back to context. The loop terminates when the agent emits a final answer, a stop token is detected, or an external condition (budget, timeout, error count) halts it.

Well-engineered agentic loops are resilient to partial failures. If a tool returns an error, the loop should catch it, inject the error message as an observation, and let the model retry or choose an alternative. Unhandled exceptions that crash the loop lose all accumulated context and must restart from scratch.

The distinction between "agentic loop" and "agent loop" is purely stylistic. "Agentic loop" is the term more commonly used in Anthropic's and LangChain's documentation to describe the loop that occurs during an agentic session, contrasting with a simple single-turn LLM call.
