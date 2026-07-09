---
term: "Reasoning Model"
definition: "A reasoning model is an LLM specifically fine-tuned or trained to prioritize extended, multi-step chain-of-thought processing over immediate response generation."
seo_description: "Reasoning models explained: LLMs designed for complex multi-step reasoning."
category: "model-architecture"
related_terms: [chain-of-thought, inference-time-compute, agentic-loop]
related_courses: [picking-a-frontier-model-2026-q2]
---

Reasoning models differ from standard generation models in a fundamental architectural choice: they allocate a variable compute budget to an internal "thinking" phase before producing their visible output. This thinking phase — sometimes exposed as a scratchpad, sometimes hidden — allows the model to decompose problems, propose candidate answers, identify contradictions, and backtrack before committing to a response. Examples include OpenAI's o-series and Anthropic's Claude with extended thinking enabled.

**The inference-time compute tradeoff.** More thinking tokens translate to higher [[latency]] and cost, often by an order of magnitude compared to a standard model call. A problem that takes a 4o-mini call 200ms to answer might take a reasoning model 20–60 seconds. The payoff is meaningfully better accuracy on tasks with a verifiable correct answer — mathematical proofs, multi-constraint planning, formal code verification — where a fast wrong answer is worse than a slow correct one.

**When to use a reasoning model.** Reasoning models shine in [[orchestrator]] and planner roles within an [[agent-loop]]: generating the step-by-step plan that cheaper execution agents then carry out. They are also well-suited to self-verification steps — checking whether a generated output satisfies a specification before passing it downstream. The [[chain-of-thought]] they produce can itself serve as an explanation artifact.

**When not to use one.** Simple retrieval, classification, and formatting tasks do not benefit from extended thinking. Worse, a reasoning model given a trivial task may "overthink" it — exploring unnecessary branches, introducing spurious hedges, or producing verbose outputs where brevity was wanted. The thinking budget should be calibrated to task complexity, not set to maximum by default.

**Common misconception: bigger budget always wins.** Increasing the thinking token limit beyond the complexity floor of the task yields diminishing returns and can degrade output quality through over-elaboration. Some evaluations show that reasoning models underperform smaller standard models on simple factual recall because the thinking phase introduces additional opportunities to second-guess a correct initial answer.

**[[hallucination]] and reasoning models.** Reasoning models reduce certain classes of hallucination — particularly errors caused by insufficient deliberation on hard tasks — but they do not eliminate it. They can hallucinate confidently within a well-structured scratchpad. Treat their outputs with the same retrieval verification discipline ([[rag]], citation checking) you would apply to any model.

See [[picking-a-frontier-model-2026-q2]] for a structured framework for deciding when a reasoning model's cost premium is justified against task requirements.

## Related Terms

- [[glossary/chain-of-thought|Chain of Thought]] — the prompting technique that asks the model to reason step-by-step before answering
- [[glossary/inference-time-compute|Inference-Time Compute]] — additional computation at inference time (e.g. chain-of-thought, search) that improves output quality
- [[glossary/agentic-loop|Agentic Loop]] — related concept that intersects with this term in agent workflows
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
