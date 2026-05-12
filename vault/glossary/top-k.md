---
term: "Top-k Sampling"
definition: "A token sampling strategy that restricts the sampling pool to the k highest-probability tokens at each generation step, then samples from those k tokens according to their normalized probabilities."
seo_description: "Top-k sampling: an LLM decoding strategy that limits each token selection to the k most probable candidates to improve output coherence."
category: "LLM concepts"
related_terms: [sampling-parameters, temperature, top-p, greedy-decoding, completion]
---

Top-k sampling was one of the first practical sampling improvements over naive temperature sampling. By hard-cutting off the long tail of low-probability tokens, it prevents the model from occasionally generating bizarre or incoherent tokens that, while grammatically valid, are contextually implausible.

The choice of k involves a tradeoff: small k (10–50) produces conservative, coherent output; large k (500+) allows more diversity. Unlike top-p, top-k does not adapt to the shape of the distribution—it applies the same cutoff regardless of whether the model is confident or uncertain. This is why top-p has largely superseded top-k as the preferred sampling method for text generation.

Top-k is still widely used in image and audio generation, where the vocabulary is much smaller (typically a few thousand codebook tokens) and a fixed k cutoff is more intuitive. For language models, many APIs expose both top-k and top-p; common practice is to set one or the other (not both) to avoid unexpected interactions.
