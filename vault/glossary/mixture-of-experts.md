---
term: "Mixture of Experts"
definition: "A neural network architecture where each input is routed to a small subset of specialized sub-networks (experts) by a learned gating function, enabling very large total parameter counts while keeping per-token computation constant."
seo_description: "Mixture of experts: an LLM architecture that routes tokens to specialized expert sub-networks, enabling massive model scale with constant per-token compute."
category: "LLM concepts"
related_terms: [scaling-laws, transformer, inference-server, gpu-cluster, emergent-abilities]
---

In a Mixture of Experts (MoE) transformer, each feed-forward layer is replaced with N expert networks and a gating function that selects the top-k experts for each token. Only k/N of the experts' parameters are active for any given token, making inference cost similar to a dense model of size k/N × total while benefiting from the full expressivity of total parameters during training.

Mixtral 8×7B (Mistral, 2023) popularized open MoE models: it has ~46B total parameters but only ~13B active per token, matching Llama 2 70B quality at Llama 2 13B inference cost. GPT-4 is widely believed to be MoE-based. Gemini 2.5 and other frontier models use MoE to achieve their scale-quality-cost tradeoff.

Load balancing is the main engineering challenge: if the gating always selects the same top-k experts, most of the model is underutilized. Auxiliary loss terms (load balancing loss) are added during training to encourage uniform expert utilization. Expert routing is non-differentiable through hard selection; the straight-through estimator or soft routing (softmax over experts) is used during training.
