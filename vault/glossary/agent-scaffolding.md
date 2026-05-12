---
term: "Agent Scaffolding"
definition: "The non-model infrastructure that surrounds an LLM to make it act as an agent: tool definitions, loop control, memory management, state persistence, error handling, and observability hooks."
seo_description: "Agent scaffolding: the infrastructure surrounding an LLM—tools, loop control, memory, error handling—that enables autonomous agent behavior."
category: "Agentic AI concepts"
related_terms: [agent-loop, tool-use, agent-memory, agent-harness, claude-agent-sdk, langchain]
---

An LLM by itself is a stateless text completion engine. Scaffolding transforms it into a stateful agent. The scaffold is responsible for: constructing the prompt at each step (injecting tool results, memory, system prompt), dispatching tool calls, persisting state between turns, enforcing budget limits, and emitting telemetry.

Good scaffolding is transparent to the model—the agent's prompt should feel like natural context, not a JSON dump of framework internals. It should also be resilient: tool failures, malformed JSON outputs, and network errors are routine, not exceptional, and the scaffold must handle them gracefully without breaking the loop.

Frameworks like LangGraph, the Claude Agent SDK, and Paperclip each make different tradeoffs between flexibility and opinions. LangGraph is maximally flexible; Paperclip adds strong governance opinions (lane discipline, budget guards, heartbeats); the Claude Agent SDK prioritizes simplicity and tight integration with Anthropic's models and tool-use protocol.
