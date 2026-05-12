---
term: "Confabulation"
definition: "The specific sub-type of hallucination in which a model generates false information that is plausibly connected to real facts in its training data, filling in memory gaps with coherent but invented details—analogous to the neurological confabulation seen in amnesia patients."
seo_description: "Confabulation: LLM hallucination where false content is plausibly connected to real training data, filling knowledge gaps with invented details."
category: "LLM concepts"
related_terms: [hallucination, grounding, factual-accuracy, calibration, faithfulness]
---

The term confabulation, borrowed from neuroscience, describes fabrications that are structurally coherent and contextually plausible. A model confabulates when it "knows" a concept (e.g., a real author) but the specific detail asked about (a specific paper title) is absent from training data, so the model generates a title that sounds like it could be real. The output is not random noise—it is a learned interpolation that happens to be false.

Confabulation is often harder to detect than simple hallucination because the fabricated content is stylistically and contextually appropriate. A confabulated citation might have the right author name, plausible journal name, and realistic year—requiring active verification to disprove. This makes confabulation particularly risky in academic, legal, and medical applications.

The distinction from hallucination is partly semantic—many researchers use the terms interchangeably. The neurological framing is useful because it implies a mechanism: the model is not malfunctioning but performing exactly the interpolation it was trained to do, which happens to produce false output when the target fact is not in its training distribution.
