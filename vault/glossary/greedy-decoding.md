---
term: "Greedy Decoding"
definition: "A token generation strategy that always selects the single highest-probability token at each step, producing a fully deterministic output that maximizes local probability but may miss globally higher-probability sequences."
seo_description: "Greedy decoding: always selecting the highest-probability next token, producing deterministic but potentially suboptimal LLM outputs."
category: "LLM concepts"
related_terms: [beam-search, sampling-parameters, temperature, top-p, completion]
---

Greedy decoding is the simplest possible decoding strategy: at each step, `argmax(softmax(logits))`. It is deterministic (the same input always produces the same output), fast (no sampling overhead), and interpretable. These properties make it attractive for production systems that need reproducibility and low latency.

The main weakness is local optimality. Committing to the highest-probability token at step t can foreclose globally higher-probability sequences that required a slightly less probable token at step t. This is most evident in tasks with a clear globally optimal answer (math, code) where an early wrong choice cascades into an incorrect result.

In practice, temperature=0 in modern APIs implements greedy-equivalent decoding. For most agentic tasks—tool calls, structured output, JSON generation—temperature=0 is the recommended setting. The model's capabilities at zero temperature are so high for these structured tasks that sampling variance provides no benefit while complicating reproducibility.
