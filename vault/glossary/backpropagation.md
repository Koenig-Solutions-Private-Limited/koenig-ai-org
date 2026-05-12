---
term: "Backpropagation"
definition: "A fundamental optimization algorithm in neural networks that calculates the gradient of the loss function with respect to each model weight by traversing backward from the output layer to the input layer."
seo_description: "Backpropagation: core neural network training algorithm calculating weight loss gradients backward from the output to input layer for model optimization."
category: "LLM concepts"
related_terms: [fine-tuning, pre-training, supervised-fine-tuning, training]
---

## Definition
Backpropagation, or backward propagation of errors, is the primary mechanism used to train neural networks. It works in conjunction with an optimization method like stochastic gradient descent. In the forward pass, the model makes a prediction, and the error (loss) is calculated. Backpropagation then uses the chain rule of calculus to compute the contribution (gradient) of each model parameter to that error, propagating the signal from the network's output backward. These gradients are subsequently used to update the weights in the direction that reduces the error, iteratively refining the model's performance.
