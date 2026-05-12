---
term: "Sampling Parameters"
definition: "The set of numeric knobs—temperature, top-p, top-k, max tokens, stop sequences—that control how an LLM samples tokens from its output distribution, trading off diversity against determinism."
seo_description: "Sampling parameters: temperature, top-p, top-k, and related knobs that control LLM output diversity and determinism."
category: "Agentic AI concepts"
related_terms: [temperature, top-p, top-k, greedy-decoding, beam-search, completion]
---

When an LLM predicts the next token, it produces a probability distribution over its vocabulary. Sampling parameters determine how a single token is chosen from that distribution. Temperature scales the logits before softmax: values below 1.0 sharpen the distribution (more deterministic), values above 1.0 flatten it (more random). Temperature 0 is equivalent to greedy (argmax) decoding.

Top-p (nucleus sampling) truncates the distribution to the smallest set of tokens whose cumulative probability reaches p, then samples from that subset. Top-k simply keeps the k most probable tokens. These two filters are often combined to avoid both highly improbable tokens and overly greedy selection.

For agentic tasks, low temperature (0.0–0.3) is preferred for tool calls and structured output, where format correctness matters more than creativity. Higher temperature (0.7–1.0) suits brainstorming and content generation. Extended thinking modes in Claude models can sometimes substitute for higher temperature by exploring more reasoning paths at low temperature.
