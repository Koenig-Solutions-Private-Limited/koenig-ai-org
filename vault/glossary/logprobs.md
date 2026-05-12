---
term: "Logprobs"
definition: "The log-probabilities assigned by an LLM to each token in its output, exposing the model's internal confidence scores and enabling calibration analysis, uncertainty estimation, and post-hoc token selection."
seo_description: "Logprobs: the log-probability scores an LLM assigns to its output tokens, used for calibration, uncertainty estimation, and token analysis."
category: "LLM concepts"
related_terms: [perplexity, cross-entropy, temperature, sampling-parameters, completion, calibration]
---

When a language model generates a token, it internally computes a probability distribution over all vocabulary items and samples from it. Logprobs are the natural logarithm of the selected token's probability (and optionally the top-k alternative tokens' probabilities). APIs like OpenAI's GPT and Anthropic's Claude can return logprobs alongside completions for analysis.

Logprobs enable several downstream applications: computing sequence perplexity (how surprised the model is by a given text), uncertainty quantification (low confidence = broad distribution = low logprob of the chosen token), speculative decoding (use a fast draft model's logprobs to skip verification of high-confidence tokens), and minimum Bayes risk decoding.

One important use is classification: instead of asking a model to answer "Yes" or "No" in natural language, extract the logprobs for those specific tokens and compare them directly—this gives calibrated probability estimates and avoids sensitivity to response format. OpenAI's completion API returns logprobs natively; Anthropic currently exposes them through select use cases.
