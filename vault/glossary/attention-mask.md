---
term: "Attention Mask"
definition: "A mechanism used in Transformer-based models to prevent the model from 'paying attention' to certain parts of the input, such as padding tokens, ensuring they do not influence the output."
seo_description: "Attention mask: Transformer model mechanism to ignore specific input tokens (like padding) to focus model learning and output on relevant data."
category: "LLM concepts"
related_terms: [transformer, attention-mechanism, context-length]
---

## Definition
The attention mask is a binary vector or matrix applied to the input of a Transformer model. Its primary purpose is to define which tokens should be processed and which should be disregarded. During the self-attention calculation, tokens corresponding to 0s in the mask are given effectively negative infinite attention weight, essentially zeroing out their influence on the subsequent layers. This is essential for batch processing where variable-length input sequences must be padded to the same length with 'dummy' tokens that should not participate in the final representations.
