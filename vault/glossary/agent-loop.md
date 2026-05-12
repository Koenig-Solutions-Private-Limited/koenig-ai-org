---
term: "Agent Loop"
definition: "The continuous perceive-think-act cycle an AI agent executes: it reads observations from its environment, selects an action (often a tool call), executes it, receives the result, and iterates until a termination condition is met."
seo_description: "Agent loop: the core perceive-think-act cycle that drives autonomous AI agents through multi-step task execution."
category: "Agentic AI concepts"
related_terms: [agentic-loop, tool-use, agent-orchestration, agent-heartbeat, orchestrator]
---

The agent loop is the fundamental execution pattern underlying all autonomous AI systems. At each step the agent receives a context window containing its history, available tools, and current observations, then generates a completion that may include one or more tool calls. Results are appended to the context and the loop repeats.

Termination conditions include task completion signals, budget exhaustion, error thresholds, or explicit human interruption. Well-designed loops include a heartbeat mechanism so the orchestrator can detect stalls, and a budget guard to prevent runaway inference costs.

Modern frameworks like the Claude Agent SDK and LangGraph implement the loop as a directed graph, making it easier to add branching logic, parallel sub-tasks, and recovery paths without tangling control flow inside the model's prompt.
