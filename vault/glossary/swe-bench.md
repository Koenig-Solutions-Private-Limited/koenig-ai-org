---
term: "SWE-bench"
definition: "A software engineering benchmark that evaluates whether AI systems can resolve real GitHub issues by modifying repositories and passing tests."
seo_description: "SWE-bench: a software engineering benchmark for evaluating whether AI systems can resolve real GitHub issues by editing repositories and passing tests."
category: "Evaluation concepts"
related_terms: [benchmark-suite, coder-agent, code-generation, humaneval, agent-evaluation]
---

SWE-bench evaluates AI systems on software engineering work that closely resembles what a human engineer would face: a real GitHub repository, a real issue report describing a bug or feature, and a real test suite that must pass after the model's changes. The system must read existing code, understand what is broken, modify one or more files, and produce a patch that makes the tests green.

**What the benchmark contains.** The original SWE-bench dataset contains 2,294 Python GitHub issues drawn from widely used open-source projects. SWE-bench Verified is a filtered subset of approximately 500 tasks that have been human-validated for quality and unambiguity. The evaluation metric is the percentage of issues for which all required tests pass after the model's patch is applied — no partial credit.

**Why it is more meaningful than [[humaneval]].** [[Humaneval]] asks the model to implement a single function from a docstring in isolation. SWE-bench requires navigating a multi-file codebase, understanding the existing architecture, identifying the root cause of a failure across multiple modules, and producing a minimal change that does not break other tests. This is the actual shape of software maintenance work.

**Current performance levels.** Frontier models as of mid-2026 score in the 50–70%+ range on SWE-bench Verified. This is a substantial improvement from sub-10% scores seen in early 2024, reflecting both model capability gains and improved [[agent-loop]] scaffolding (file search, test execution, iterative debugging). Performance on the full unfiltered set is consistently lower.

**What SWE-bench does not test.** The benchmark does not assess PR description quality, the ability to interact with a human reviewer, non-Python repositories, security or performance implications of changes, or behaviour when tests are absent or insufficient. A [[coder-agent]] that scores well here may still require significant scaffolding around code review, permissions, rollback, and incident reporting to operate safely in production.

**Using SWE-bench in model selection.** SWE-bench scores are a useful signal when choosing a model for software automation tasks, but they should be combined with task-specific [[evals]] on your own codebase and language stack. See [[agent-evaluation]] and [[benchmark-suite]] for broader evaluation frameworks, and [[production-agents-claude-agent-sdk-mcp-connector]] for deployment patterns that pair a capable [[coder-agent]] with safe production guardrails.

## Related Terms

- [[glossary/benchmark-suite|Benchmark Suite]] — a collection of standardised tasks used to compare model capabilities across dimensions
- [[glossary/coder-agent|Coder Agent]] — a specialized agent that writes, tests, and debugs code autonomously
- [[glossary/humaneval|HumanEval]] — the coding benchmark that tests models on 164 Python programming problems
- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
