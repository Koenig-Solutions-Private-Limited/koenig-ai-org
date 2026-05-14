---
term: "Inference"
definition: "The runtime process of using a trained model to produce outputs from inputs, such as generating text, classifications, tool calls, or embeddings."
seo_description: "Inference: the runtime process of using a trained model to produce outputs such as text, classifications, tool calls, or embeddings."
category: "Infrastructure"
related_terms: [latency, caching, kv-cache, inference-time-compute, sampling-parameters]
---

Inference is where model capability becomes product behavior. The system receives an input, prepares the prompt or request, runs the model, applies decoding settings, and returns an output or tool action.

Production inference has practical constraints: latency, throughput, cost, reliability, privacy, and observability. A technically stronger model may be the wrong choice if it misses the serving budget or fails under peak traffic.
