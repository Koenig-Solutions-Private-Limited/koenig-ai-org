---
term: "Claude Agent SDK"
definition: "Anthropic's official SDK for building autonomous and multi-agent systems on top of Claude models, providing primitives for tool use, sub-agent spawning, memory, and structured agent communication."
seo_description: "Claude Agent SDK: Anthropic's SDK for building autonomous agents on Claude, with primitives for tools, sub-agents, memory, and structured communication."
category: "Agentic AI concepts"
related_terms: [anthropic-agent-sdk, agent-scaffolding, agent-loop, tool-use, multi-agent-system, claude]
---

Anthropic released the Claude Agent SDK as part of its push toward production agentic systems. It wraps the core Messages API with higher-level abstractions: typed tool definitions, automatic tool-call dispatch, conversation threading, and hooks for injecting memory. The SDK is designed to make the 80% case easy while remaining composable for advanced use cases.

Key features include built-in support for parallel tool calls, structured output via JSON schema validation, and first-class support for the Model Context Protocol (MCP) for standardized tool integration. The SDK handles the bookkeeping of multi-turn conversations so developers focus on task logic rather than loop management.

The SDK is currently available in Python and TypeScript. It integrates with Anthropic's prompt caching API, which substantially reduces costs in long agentic sessions where the system prompt and tools list are stable across many turns.

## Related Terms

- [[glossary/anthropic-agent-sdk|Anthropic Agent SDK]] — the broader Anthropic toolkit for evaluation, prompt management, and deployment
- [[glossary/agent-scaffolding|Agent Scaffolding]] — the non-model infrastructure that surrounds the LLM to enable agent behaviour
- [[glossary/agent-loop|Agent Loop]] — the iterative perceive-act-observe cycle the harness executes
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
