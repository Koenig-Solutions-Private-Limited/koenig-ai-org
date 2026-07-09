---
term: "Evals"
definition: "Repeatable tests that measure whether a model, prompt, tool, or agent workflow performs acceptably for a defined task."
seo_description: "Evals: repeatable tests for measuring whether a model, prompt, tool, or agent workflow performs acceptably for a defined task."
category: "Evaluation concepts"
related_terms: [agent-evaluation, benchmark-suite, precision, recall, definition-of-done]
related_courses: [claude-tool-use-from-zero]
---

Evals turn subjective model impressions into measurable checks. They can test correctness, format compliance, reasoning quality, [[tool-use]] behavior, safety, [[latency]], and cost.

Good evals are tied to a decision. A model upgrade eval should answer whether to switch models. A regression eval should answer whether a prompt or code change broke a known behavior. Without that decision link, evals become dashboards that are easy to ignore.

**Types of evals** form a hierarchy. Unit evals test a single model call in isolation — does this prompt return the correct format? Integration evals test a full [[agent-loop]], including tool calls, retries, and state transitions. Human evals cover subjective quality dimensions such as tone, helpfulness, or factual depth that automated grading cannot reliably score.

**What makes a good eval dataset** is less obvious than it sounds. Golden examples drawn from real production traffic outperform synthetically generated ones because they capture the actual distribution of inputs, including edge cases and ambiguous phrasing. Failure cases and adversarial inputs are equally important: a model that passes on easy examples but breaks on tricky ones may still fail in production.

**Eval-driven development** inverts the usual order. Write the eval first, express what correct behavior looks like, then change the prompt or model or code. This keeps changes grounded in observable outcomes rather than intuition.

**Grading approaches** depend on the task. Exact match works for structured output with known correct answers. LLM-as-judge works when correctness is nuanced — the grading model evaluates reasoning quality or factual accuracy against a rubric. Human grading is expensive but necessary for tasks where model judges have systematic biases.

**The eval/[[benchmark-suite]] distinction** matters. Benchmarks such as [[mmlu]] or [[swe-bench]] are public comparison tools designed for model-to-model ranking. Evals are internal decision tools built against your own tasks and data. A model that tops a public benchmark may underperform on your specific retrieval, formatting, or [[tool-use]] pattern. Always run your own [[agent-evaluation]] before committing to a model upgrade.

A common misconception is that passing a public benchmark means production-ready. [[Precision]], [[recall]], and task-specific [[definition-of-done]] criteria are what actually govern whether a system is ready to ship. See [[claude-tool-use-from-zero]] for how evals integrate into a working agent development loop.

## Related Terms

- [[glossary/agent-evaluation|Agent Evaluation]] — the structured process for measuring how well an agent meets its goals
- [[glossary/benchmark-suite|Benchmark Suite]] — a collection of standardised tasks used to compare model capabilities across dimensions
- [[glossary/precision|Precision]] — the fraction of positive predictions that are actually correct
- [[glossary/recall|Recall]] — the fraction of true positives that the model successfully identifies
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
