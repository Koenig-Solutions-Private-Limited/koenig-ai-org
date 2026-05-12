---
term: "Self-Consistency"
definition: "A decoding strategy that samples multiple independent chain-of-thought reasoning paths from a model at non-zero temperature, then takes the majority-vote answer across those paths, improving accuracy over a single greedy sample."
seo_description: "Self-consistency: sampling multiple reasoning chains from an LLM and taking the majority-vote answer to improve accuracy on complex tasks."
category: "Agentic AI concepts"
related_terms: [chain-of-thought, sampling-parameters, temperature, beam-search, reflection-agent]
---

Self-consistency (Wang et al., 2022) addresses a fundamental limitation of chain-of-thought prompting: a single reasoning chain can take a wrong turn early and confidently arrive at an incorrect answer. By sampling many chains—typically 10–40—and voting on the final answer, the approach achieves robustness similar to ensemble methods in classical ML.

The technique requires no additional training and works with any model that supports temperature sampling. It is most effective on tasks with a small, well-defined answer space (multiple choice, math, code correctness) where majority vote is meaningful. For open-ended generation it is less applicable.

The cost is linear in the number of samples, which can be prohibitive for long chains. Practical systems often combine self-consistency with fast inference—running many short reasoning chains on a cheap model (e.g., Gemini 2.5 Flash) and escalating only borderline cases to a stronger model for a single careful answer.
