---
term: "Scaling Laws"
definition: "Empirical relationships showing that LLM performance improves predictably as a power law with increases in model parameters, training compute, and data size, enabling researchers to forecast model quality before training."
seo_description: "Scaling laws: empirical power-law relationships showing how LLM performance improves with more parameters, compute, and training data."
category: "LLM concepts"
related_terms: [pre-training, emergent-abilities, mixture-of-experts, capability-overhang, inference-time-compute]
---

Kaplan et al. (2020) at OpenAI established the first LLM scaling laws: test loss decreases as a power law in model size (N), dataset tokens (D), and compute (C). Crucially, these relationships are smooth, predictable, and hold across many orders of magnitude. This turned LLM development from empirical alchemy into an engineering problem: compute a required quality target, run the scaling law backward to find the required training budget.

Hoffmann et al. (2022) (the Chinchilla paper) revised the optimal compute allocation: earlier models were undertrained—using too many parameters for too few tokens. Chinchilla laws prescribe training ~20 tokens per parameter for compute-optimal models. This led to a generation of smaller, better-trained models (Llama 3.2, Mistral) that outperformed larger but undertrained predecessors.

As models push toward AGI, there is evidence that scaling laws may plateau for next-token prediction as the fundamental limit of predicting text is approached. Inference-time compute scaling (chain-of-thought, extended thinking, test-time training) is emerging as the next scaling axis, with o3 and Claude Sonnet 4.7 extended thinking suggesting that more reasoning at inference time can substitute for more parameters at training time.

## Related Terms

- [[glossary/pre-training|Pre-training]] — the large-scale unsupervised training run that teaches the model language and world knowledge
- [[glossary/emergent-abilities|Emergent Abilities]] — capabilities that appear in large models but are absent in smaller ones at the same task
- [[glossary/mixture-of-experts|Mixture of Experts]] — an architecture where only a sparse subset of experts activates per token, scaling capacity efficiently
- [[glossary/capability-overhang|Capability Overhang]] — the phenomenon where latent capabilities emerge suddenly as model scale crosses a threshold
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
