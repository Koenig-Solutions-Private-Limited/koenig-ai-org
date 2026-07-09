---
term: "HumanEval"
definition: "A coding benchmark that evaluates whether a model can generate Python functions that pass hidden unit tests for programming problems."
seo_description: "HumanEval: a coding benchmark that tests whether a model can generate Python functions that pass hidden unit tests."
category: "Evaluation concepts"
related_terms: [benchmark-suite, code-generation, coder-agent, evals, swe-bench]
related_courses: [picking-a-frontier-model-2026-q2]
---

HumanEval is useful as a compact measure of code synthesis ability, especially for small programming tasks with clear specifications. It tests whether generated code passes unit tests rather than whether it reads well.

It is not a full measure of software engineering. Real repository work requires understanding existing architecture, making multi-file changes, preserving behavior, handling tests, and communicating tradeoffs.

**What HumanEval is.** Released by OpenAI in 2021, HumanEval consists of 164 Python programming problems. Each problem provides a function signature and docstring; the model must write the function body. Correctness is determined by running hidden unit tests against the generated code, not by string matching against a reference solution. This made it a significant step forward from [[mmlu]]-style question-answering benchmarks: it tests functional correctness rather than recall of training data.

**Pass@k.** The primary metric is pass@k — the probability that at least one of k independently sampled completions passes all tests. Pass@1 (a single attempt) measures the reliability of the model's first response. Pass@10 or pass@100 measures ceiling capability, showing what the model can produce given multiple tries. Teams deploying a [[coder-agent]] in an agentic loop that retries failures care most about pass@k for small k.

**Limitations.** HumanEval problems are self-contained single functions. They have no imports beyond the standard library, no interaction with existing classes or interfaces, and no multi-file dependencies. This is very different from real software engineering tasks, where the challenge is reading and modifying an existing codebase, not writing a function from a clean docstring. Additionally, because HumanEval problems are public and widely used in training, high scores can reflect memorization of the specific problems rather than general code synthesis ability.

**Comparison to [[swe-bench]].** SWE-bench addresses the gap HumanEval leaves open. Where HumanEval asks "can the model write a correct function from scratch?", [[swe-bench]] asks "can the model fix a real GitHub issue in a real repository?" — requiring the model to read existing code, understand context, make targeted edits, and pass a full test suite. For evaluating a [[coder-agent]] intended to work in production codebases, [[swe-bench]] is far more predictive than HumanEval.

**What HumanEval scores mean for model selection.** A model with a high HumanEval score is likely competent at isolated code generation tasks. It is not sufficient evidence that the model will perform well on multi-file refactors, framework-specific patterns, or long-horizon coding tasks. Always complement public [[benchmark-suite]] scores with internal [[evals]] on your own codebase and task distribution. See [[picking-a-frontier-model-2026-q2]] for a framework that combines public benchmarks with production-specific evaluation.

## Related Terms

- [[glossary/benchmark-suite|Benchmark Suite]] — a collection of standardised tasks used to compare model capabilities across dimensions
- [[glossary/coder-agent|Coder Agent]] — a specialized agent that writes, tests, and debugs code autonomously
- [[glossary/evals|Evals]] — the structured evaluation framework that measures model quality against defined criteria
- [[glossary/swe-bench|SWE-bench]] — the benchmark that evaluates agents on real GitHub software engineering issues
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
