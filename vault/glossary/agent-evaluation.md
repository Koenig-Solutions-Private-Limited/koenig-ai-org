---
term: "Agent Evaluation"
definition: "The systematic assessment of an AI agent's performance across task completion, tool use accuracy, memory reliability, safety, and cost efficiency, typically using automated harnesses, human raters, or model-graded judges."
seo_description: "Agent evaluation: systematic assessment of AI agent performance on task completion, tool accuracy, safety, and cost across benchmark scenarios."
category: "Agentic AI concepts"
related_terms: [benchmark, agentic-eval, evals-framework, model-graded-eval, human-preference, definition-of-done]
---

Evaluating agents is harder than evaluating static LLM outputs because the space of possible action sequences is exponentially larger, and intermediate steps matter as much as final outputs. Agent evals typically cover: task success rate (did the agent achieve the goal?), efficiency (how many steps / tokens did it take?), safety (did it perform any disallowed actions?), and robustness (does performance degrade under adversarial inputs?).

Automated evaluation uses either ground-truth test cases (for tasks with verifiable answers) or model-graded rubrics (for open-ended tasks). Human evaluation remains the gold standard but is expensive and slow. Hybrid approaches use a strong model (e.g., Opus 4.7) as a judge, validated against human ratings on a calibration set.

Frameworks like Anthropic's evals library, OpenAI Evals, and HELM provide standardized scaffolding. SWE-bench Verified is the dominant benchmark for coder agents; WebArena and AssistGUI cover web and GUI agents. Bespoke eval suites for specific products—like grading content quality in a content production pipeline—often provide more actionable signal than general benchmarks.
