---
term: "Dependency Injection"
definition: "Dependency injection is a design pattern where an object receives its dependencies (the services it needs to operate) rather than creating them itself, promoting decoupling and testability."
seo_description: "Dependency injection explained: design pattern for modular agent code."
category: "architecture"
related_terms: [agent-scaffolding]
related_courses: [production-agents-claude-agent-sdk-mcp-connector]
---

In modular agent systems, tools and resources should not be hard-coded. Dependency injection allows you to pass specific tool implementations into an agent's harness at runtime. This makes it trivial to swap a "Mock Tool" in for local unit testing or swap a "Cloud-backed Resource" in production, without changing the agent's core orchestration logic.
