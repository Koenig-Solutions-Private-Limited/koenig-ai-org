---
term: "Dependency Injection"
definition: "A software design pattern where an object or function receives its dependencies as arguments from an external source rather than creating them internally, promoting modularity, testability, and the ability to swap implementations at runtime."
seo_description: "Dependency injection in AI agents: how passing tools and resources as arguments rather than hard-coding them makes agent systems testable, modular, and easier to deploy."
category: "architecture"
related_terms: [agent-scaffolding, agent-harness, tool-use, sandboxing, agent-evaluation]
related_courses: [production-agents-claude-agent-sdk-mcp-connector, mcp-from-first-principles-to-production]
---

**Dependency injection** is the design pattern that separates "what a component does" from "what it uses to do it." Instead of an agent hardcoding a specific database driver, file system path, or API client, those resources are passed in at construction time. The agent declares what kind of resource it needs (an interface or type); the harness that creates the agent provides the concrete implementation. This is the same pattern that makes traditional software testable, and it matters equally for agent systems.

In agentic workflows, the dependencies being injected are typically tool implementations. An agent that needs to read files, query a database, and send notifications describes what it needs in its tool schema. In local testing, mock implementations of those tools are injected—the file tool returns fixture data, the notification tool logs to stdout instead of sending messages. In production, real implementations are injected—the file tool accesses actual storage, the notification tool calls the live API. The agent code itself is identical in both cases. This pattern makes [[agent-evaluation]] far more reliable: evaluations run against the same agent logic that runs in production, just with controlled tool implementations.

A common misconception is that dependency injection requires a framework. The core pattern is just "pass it as an argument"—a function that takes a `tool_list` parameter is practicing dependency injection, even without an IoC container. Another misconception is that it conflicts with the dynamic nature of agent systems: in fact, [[mcp]] servers are themselves a dependency injection mechanism for tools, providing a runtime-discovered set of capabilities that the agent uses without knowing their implementations. Production systems that combine dependency injection at the harness level with MCP discovery at the tool level can swap entire capability sets—including [[sandboxing]] boundaries—between deployment environments without changing agent code. See [[production-agents-claude-agent-sdk-mcp-connector]] for how this pattern is applied in production Claude agent deployments.

## Related Terms

- [[glossary/agent-scaffolding|Agent Scaffolding]] — the non-model infrastructure that surrounds the LLM to enable agent behaviour
- [[glossary/agent-harness|Agent harness]] — the software framework that runs the agent loop with tools and stopping criteria
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/sandboxing|Sandboxing]] — the isolation mechanism that prevents agent code execution from affecting the host system
- [[courses/mcp-from-first-principles-to-production|Course: MCP from First Principles to Production]] — hands-on practice with the concepts covered in this entry
