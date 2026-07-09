---
term: "Agent Loop"
definition: "The continuous perceive-think-act cycle an AI agent executes: it reads observations from its environment, selects an action (often a tool call), executes it, receives the result, and iterates until a termination condition is met."
seo_description: "Agent loop: the core perceive-think-act cycle that drives autonomous AI agents through multi-step task execution."
category: "Agentic AI concepts"
related_terms: [agentic-loop, tool-use, agent-orchestration, agent-heartbeat, orchestrator, human-in-the-loop, agent-budget]
related_courses: [claude-tool-use-from-zero, gemini-enterprise-agents, production-agents-claude-agent-sdk-mcp-connector]
---

The **agent loop** is the fundamental execution pattern underlying all autonomous AI systems. At each iteration the agent receives a context window containing its history, available tools, and current observations, then generates a completion that may include one or more tool calls. Results are appended to the context and the loop repeats. This architecture is why agents can accomplish multi-step tasks that no single LLM call could complete—each iteration can read outputs, update a plan, and decide what to do next.

Termination conditions define when the loop stops: task completion signals from the model, budget exhaustion enforced by the [[agent-budget]] guard, error thresholds that trigger escalation, or explicit [[human-in-the-loop]] interruption. Without at least one of these, an agent can loop indefinitely—spinning up tool calls and consuming tokens until the account is drained. Well-designed loops include an [[agent-heartbeat]] mechanism so the [[orchestrator]] can detect stalls, a maximum-iterations ceiling, and a cost circuit breaker.

Modern frameworks like the Claude Agent SDK and LangGraph implement the loop as a directed graph rather than raw recursion, making it easier to add branching logic, parallel sub-tasks, and recovery paths without tangling control flow inside the model's prompt. The distinction between an agent loop and an [[agentic-loop]] is mainly one of granularity: the agent loop describes the single agent's cycle; the agentic loop may describe a broader workflow spanning multiple agents.

A common misconception is that the agent loop is always a tight inner cycle with no human involvement. In practice, production systems insert human-approval steps for high-stakes actions, run multiple agents in parallel branches, and may pause the loop for hours awaiting an external event. The loop is the execution unit, but the surrounding harness—permissions, observability, recovery paths—determines whether it is production-safe. See [[claude-tool-use-from-zero]] for a hands-on walkthrough of building and instrumenting a working agent loop.

## Related Terms

- [[glossary/agent-orchestration|Agent Orchestration]] — the coordination layer that governs when and how agent loops are started, monitored, and terminated
- [[glossary/tool-use|Tool use]] — the primary mechanism by which an agent loop takes action on each iteration
- [[glossary/agent-heartbeat|Agent Heartbeat]] — the periodic signal emitted during a loop so the orchestrator can detect stalls or crashes
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — learn agent orchestration, loops, and budgets in a production context
