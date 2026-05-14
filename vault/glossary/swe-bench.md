---
term: "SWE-bench"
definition: "A software engineering benchmark that evaluates whether AI systems can resolve real GitHub issues by modifying repositories and passing tests."
seo_description: "SWE-bench: a software engineering benchmark for evaluating whether AI systems can resolve real GitHub issues by editing repositories and passing tests."
category: "Evaluation concepts"
related_terms: [benchmark-suite, coder-agent, code-generation, humaneval, agent-evaluation]
---

SWE-bench is closer to real engineering work than single-function coding benchmarks because it uses repository issues and requires code changes against an existing project. Systems must inspect files, reason about failing behavior, edit code, and satisfy tests.

Even so, passing a benchmark is not the same as being production-ready. A working coding agent also needs repository-specific instructions, permissions, review flow, rollback behavior, and clear reporting when tests cannot prove the change.
