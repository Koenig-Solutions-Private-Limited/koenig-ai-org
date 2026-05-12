---
term: "Multimodal"
definition: "Describing an AI model that processes and generates information across multiple data modalities—such as text, images, audio, and video—within a unified architecture rather than with separate single-modality models."
seo_description: "Multimodal: an AI model that processes text, images, audio, and/or video together in a single unified architecture."
category: "LLM concepts"
related_terms: [vision-language-model, text-to-image, text-to-speech, speech-to-text, transformer, embedding]
---

Multimodal LLMs extend the transformer architecture to handle non-text inputs by converting them into token-compatible representations. Images are tokenized using vision encoders (CLIP, SigLIP) into patch embeddings interleaved with text tokens. Audio is converted to log-mel spectrograms and processed by audio encoders. Video adds temporal modeling on top of image encoding.

As of 2026, frontier multimodal models include GPT-5 (text + image + audio), Claude Opus 4.7 (text + image + PDF), and Gemini 2.5 Ultra (text + image + audio + video + code + 1M token context). Gemini's native multimodal architecture (trained jointly across modalities from scratch) is contrasted with "bolted-on" vision (a vision encoder added to a text-only LLM).

The practical implications are significant for agents: a multimodal agent can read screenshots, interpret charts, transcribe audio, and describe video—tasks that were impossible without human perception. GUI automation agents use screenshot understanding to control computers without requiring API access to the underlying applications.
