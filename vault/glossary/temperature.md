---
term: "Temperature"
definition: "A scalar parameter that controls the sharpness of an LLM's output probability distribution before sampling: values below 1.0 make the distribution more peaked (deterministic), values above 1.0 make it flatter (more random)."
seo_description: "Temperature: an LLM sampling parameter that controls output randomness—lower values are more deterministic, higher values more creative."
category: "LLM concepts"
related_terms: [sampling-parameters, top-p, top-k, greedy-decoding, completion, logprobs]
---

Temperature T is applied by dividing logits by T before the softmax: `softmax(logits / T)`. At T=1, the distribution is unchanged. At T→0, all probability mass concentrates on the highest-logit token (greedy decoding). At T→∞, the distribution becomes uniform—pure random sampling from the vocabulary.

In practice, temperatures between 0.0 and 0.3 are used for tasks requiring factual accuracy, code generation, and structured output. Temperatures between 0.7 and 1.0 suit creative writing, brainstorming, and diversity-requiring tasks. Values above 1.0 rarely produce useful output for language models (unlike some image generation models where high temperature produces creative variation).

Temperature interacts with top-p and top-k: they are usually applied together. A common production configuration is temperature=0.7 with top-p=0.9, which provides variety while avoiding extremely low-probability tokens. For API-facing agent tasks, temperature=0.0 is preferred to maximize consistency and testability.

**Claude Sonnet 5 caveat**: Sonnet 5 rejects any non-default temperature value and returns HTTP 400. Do not pass temperature (including temperature=0) when calling Sonnet 5. For deterministic structured output, use tool schemas with strict typing, few-shot prompting, or output format instructions — the same techniques work without relying on the temperature knob.
