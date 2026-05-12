---
term: "Hallucination"
definition: "A phenomenon in which a language model generates plausible-sounding but factually incorrect, fabricated, or unsupported content, often with confident tone, when the correct information is absent from or conflicts with its training data."
seo_description: "Hallucination: when an LLM generates confident but factually incorrect or fabricated content not supported by its training data or context."
category: "LLM concepts"
related_terms: [confabulation, grounding, rag, factual-accuracy, faithfulness, calibration]
---

Hallucination is the most consequential failure mode of current LLMs. Models hallucinate citations to nonexistent papers, invent biographical details, confabulate statistics, and fabricate code APIs. The problem arises because LLMs are trained to produce fluent, plausible continuations—a goal that is orthogonal to factual accuracy.

Mechanistically, hallucinations occur when the model's internal representation of a fact is weak (low-frequency training data) or the model attempts to extrapolate beyond its knowledge. Confident-sounding hallucinations are particularly dangerous because users may not recognize them as errors.

Mitigation strategies fall into three categories: grounding (RAG, tool use—give the model the facts so it doesn't have to recall them), training (RLHF with factuality rewards, Constitutional AI), and post-hoc verification (citation checking, cross-validation with a fact-checker model). No single strategy eliminates hallucination; production systems combine all three. Calibration research aims to make models better at expressing uncertainty rather than confabulating.
