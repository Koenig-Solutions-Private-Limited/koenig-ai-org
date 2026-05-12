---
term: "Chain of Thought"
definition: "A prompting technique that elicits intermediate reasoning steps from an LLM before its final answer, improving accuracy on multi-step tasks by making the model's reasoning process explicit and sequential."
seo_description: "Chain of thought: prompting an LLM to show intermediate reasoning steps before its final answer, improving accuracy on complex tasks."
category: "Agentic AI concepts"
related_terms: [few-shot-prompting, self-consistency, chain-of-draft, extended-thinking, react-prompting, prompt-engineering]
---

Introduced in the Wei et al. (2022) paper, chain-of-thought (CoT) prompting involves appending "Let's think step by step" or providing worked examples with explicit reasoning traces. This simple addition yielded dramatic accuracy gains on arithmetic, commonsense, and symbolic reasoning benchmarks, particularly for models above roughly 100B parameters.

Modern frontier models like Claude and GPT-5 have been trained to produce CoT reasoning by default for hard questions. Extended thinking mode in Claude takes this further: the model has a private reasoning scratch-pad (not billed to the user's context) where it can explore multiple reasoning paths before producing a response.

In agentic systems, CoT serves another purpose: it makes tool-call decisions auditable. When the model writes out why it is calling a tool and what it expects to learn, human reviewers can catch reasoning errors before they cascade into irreversible actions.
