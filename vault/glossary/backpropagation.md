---
term: "Backpropagation"
definition: "The algorithm that computes how much each model weight contributed to a prediction error by applying the chain rule of calculus backwards through a neural network's layers, enabling gradient-based weight updates during training."
seo_description: "Backpropagation: the chain-rule-based algorithm that computes gradients for neural network training, enabling models like LLMs to learn from prediction errors."
category: "LLM concepts"
related_terms: [fine-tuning, pre-training, supervised-fine-tuning, rlhf, scaling-laws, lora]
related_courses: [picking-a-frontier-model-2026-q2]
---

**Backpropagation** is the computational backbone of virtually every deep learning system, including the large language models that power modern AI products. Training a neural network consists of two passes: a forward pass where the model produces a prediction from an input, and a backward pass where the error (loss) between the prediction and the correct answer is propagated back through the network to compute each weight's gradient. Those gradients tell the optimizer which direction to nudge each parameter to reduce the loss. Repeat millions of times over a large dataset and the model learns.

The algorithm works by applying the chain rule of calculus recursively, starting from the output layer's loss and propagating backwards through each layer. At each step it computes: how much did this layer's outputs affect the loss, and how does that translate into gradients for this layer's weights? Modern deep learning frameworks (PyTorch, JAX) compute this automatically through reverse-mode automatic differentiation—practitioners rarely implement backpropagation by hand, but understanding it clarifies why certain design choices matter. Deeper networks require more passes; very deep models suffer from vanishing or exploding gradients unless architectural techniques like layer normalization or residual connections stabilize the gradient flow.

For practitioners working with language models, backpropagation is directly relevant to [[fine-tuning]] and [[supervised-fine-tuning]] decisions. Full fine-tuning runs backpropagation through all model weights—expensive but flexible. [[lora]] reduces the cost by adding small low-rank matrices that capture gradients for the adaptation task while leaving the frozen base weights unchanged. [[rlhf]] combines backpropagation with a reward signal derived from human preferences, updating the model to produce outputs humans prefer. A common misconception is that backpropagation requires labels—self-supervised objectives like next-token prediction during [[pre-training]] also use backpropagation, using the next token as the implicit label for each position. See [[picking-a-frontier-model-2026-q2]] for how training methodology affects the model capabilities practitioners care about.

## Related Terms

- [[glossary/fine-tuning|Fine-tuning]] — the weight-update process that adapts a pre-trained base model for downstream tasks
- [[glossary/pre-training|Pre-training]] — the large-scale unsupervised training run that teaches the model language and world knowledge
- [[glossary/supervised-fine-tuning|Supervised Fine-Tuning]] — the weight-update process that adapts a pre-trained model to a target task using labeled data
- [[glossary/rlhf|Reinforcement Learning from Human Feedback (RLHF)]] — the training technique that uses human preference comparisons to steer model behaviour
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
