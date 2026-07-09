---
term: "Anthropic Agent SDK"
definition: "The umbrella SDK from Anthropic for building, testing, and deploying agentic applications on Claude models, encompassing the Claude Agent SDK and related tooling for evaluation, observability, and deployment."
seo_description: "Anthropic Agent SDK: Anthropic's umbrella toolkit for building, evaluating, and deploying agentic applications on Claude models."
category: "Agentic AI concepts"
related_terms: [claude-agent-sdk, claude, agent-scaffolding, agent-evaluation, tool-use, mcp]
---

The Anthropic Agent SDK is the broader product category that includes the Claude Agent SDK plus ancillary tools for evaluation, prompt management, and deployment. Anthropic designed it to lower the barrier to production-grade agentic systems by packaging best practices—prompt caching, tool definitions, structured output, multi-turn threading—into an opinionated but extensible API.

The SDK follows Anthropic's Constitutional AI principles at the infrastructure level: built-in rate limiting prevents runaway agents, structured output schemas reduce hallucination surface area, and the evaluation harness makes it straightforward to test safety properties alongside task performance.

As of 2026, the SDK supports both direct API access and integration with hosted orchestration via Claude.ai's API tier. Community adapters extend it to work with LangGraph, LlamaIndex, and Paperclip, making it a de facto standard for Claude-centric agentic development.

## Related Terms

- [[glossary/claude-agent-sdk|Claude Agent SDK]] — Anthropic's SDK that wraps the API with agent loop, tool, and multi-turn patterns
- [[glossary/claude|Claude]] — Anthropic's model family that the SDK and harnesses are built around
- [[glossary/agent-scaffolding|Agent Scaffolding]] — the non-model infrastructure that surrounds the LLM to enable agent behaviour
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/claude-agent-sdk-zero-to-production|Course: Claude Agent SDK — Zero to Production]] — hands-on practice with the concepts covered in this entry
