---
term: "HumanEval"
definition: "A coding benchmark that evaluates whether a model can generate Python functions that pass hidden unit tests for programming problems."
seo_description: "HumanEval: a coding benchmark that tests whether a model can generate Python functions that pass hidden unit tests."
category: "Evaluation concepts"
related_terms: [benchmark-suite, code-generation, coder-agent, evals, swe-bench]
---

HumanEval is useful as a compact measure of code synthesis ability, especially for small programming tasks with clear specifications. It tests whether generated code passes unit tests rather than whether it reads well.

It is not a full measure of software engineering. Real repository work requires understanding existing architecture, making multi-file changes, preserving behavior, handling tests, and communicating tradeoffs.
