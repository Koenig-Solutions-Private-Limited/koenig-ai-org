---
term: "Inference-Time Compute"
definition: "Additional computation performed during inference—rather than training—to improve output quality, including techniques like chain-of-thought generation, extended thinking, self-consistency sampling, and test-time search."
seo_description: "Inference-time compute: additional computation during LLM inference—via extended thinking, sampling, or search—to improve output quality."
category: "LLM concepts"
related_terms: [extended-thinking, chain-of-thought, self-consistency, scaling-laws, speculative-decoding]
---

The traditional AI scaling paradigm focused on training-time compute (bigger models, more data). Inference-time compute scaling is a complementary axis: allocating more computation at test time, often through iterative reasoning, can dramatically improve performance on hard tasks without changing model weights.

OpenAI's o-series models and Anthropic's extended thinking mode are the flagship examples. These systems allocate variable compute budgets to reasoning: easy problems get a short reasoning chain, hard problems get extended thinking that can span thousands of tokens and explore multiple solution paths. The result is a smooth compute-quality tradeoff dial that users can tune per request.

The economics favor inference-time compute for high-value, low-volume tasks: a complex legal analysis worth $1,000 can justify $10 in inference compute; a bulk classification task worth $0.01 per item cannot. Adaptive computation (automatically allocating more compute to harder inputs) is an active research area to make this tradeoff automatic.

## Related Terms

- [[glossary/chain-of-thought|Chain of Thought]] — the prompting technique that asks the model to reason step-by-step before answering
- [[glossary/self-consistency|Self-Consistency]] — the technique of sampling multiple reasoning paths and taking the majority answer
- [[glossary/scaling-laws|Scaling Laws]] — the empirical relationships between model size, compute, data, and performance
- [[glossary/speculative-decoding|Speculative Decoding]] — the technique of generating draft tokens with a small model and verifying with a large one
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
