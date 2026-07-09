---
term: "Perplexity"
definition: "A metric for language model quality defined as the exponentiated average negative log-likelihood per token on a test set, measuring how surprised the model is by text—lower perplexity indicates better fit to the data distribution."
seo_description: "Perplexity: an LLM quality metric measuring how well the model predicts text—lower values indicate better language modeling performance."
category: "LLM concepts"
related_terms: [cross-entropy, logprobs, pre-training, benchmark, calibration]
---

Perplexity (PPL) = exp(-1/N * Σ log P(token_i | context)). A perplexity of k means the model is as uncertain as if it had to choose uniformly among k equally probable tokens at each step. Human text typically has perplexity of 10–50 on well-trained models depending on domain.

Perplexity is useful for comparing model quality on held-out text from the training distribution, evaluating the effect of fine-tuning or quantization, and detecting distribution shift (perplexity spikes when inputs are out-of-distribution). It is less useful for evaluating instruction-following or reasoning ability, which require task-specific benchmarks.

Perplexity can be gamed: a model can achieve low perplexity on a benchmark test set through contamination (training data overlap). This is a known issue with leaderboards that report perplexity on public datasets. Evaluating on private, held-out test sets and using task-based benchmarks alongside perplexity provides a more complete picture of model quality.

## Related Terms

- [[glossary/cross-entropy|Cross-Entropy]] — the loss function used to measure the gap between predicted and true token distributions
- [[glossary/logprobs|Logprobs]] — the log-probabilities of candidate tokens returned alongside the model's chosen token
- [[glossary/pre-training|Pre-training]] — the large-scale unsupervised training run that teaches the model language and world knowledge
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
