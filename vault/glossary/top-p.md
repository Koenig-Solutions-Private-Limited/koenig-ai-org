---
term: "Top-p (Nucleus Sampling)"
definition: "A token sampling strategy that restricts sampling to the smallest set of tokens whose cumulative probability mass meets or exceeds a threshold p, dynamically adjusting the vocabulary size based on the distribution's shape."
seo_description: "Top-p nucleus sampling: an LLM sampling strategy that restricts token selection to the top cumulative probability mass p, balancing diversity and coherence."
category: "LLM concepts"
related_terms: [sampling-parameters, temperature, top-k, greedy-decoding, completion]
---

Nucleus sampling (Holtzman et al., 2020) addresses a weakness of top-k sampling: the value k that is appropriate varies by context. When the model is very confident (peaked distribution), k=50 might include many implausible tokens. When the model is uncertain (flat distribution), k=50 might miss good options. Top-p adapts the effective k to the distribution's entropy.

With p=0.9, the model samples from the smallest set of tokens that together account for 90% of the probability mass. On confident predictions, this might be just 5 tokens; on uncertain predictions, it might be 500. This dynamic adjustment generally produces more coherent text than fixed top-k.

Top-p=1.0 (full vocabulary sampling) combined with temperature close to 0.0 is functionally equivalent to greedy decoding. Typical production settings use top-p between 0.9 and 0.95. Setting top-p=0.0 or top-p=1.0 are edge cases—the former is unusual (would select the single highest-probability token), the latter disables the filter entirely.
