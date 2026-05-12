---
term: "Vision-Language Model"
definition: "A multimodal model that processes both images and text jointly, enabling tasks like image captioning, visual question answering, document understanding, and image-grounded reasoning."
seo_description: "Vision-language model: a multimodal AI that processes images and text together for captioning, visual QA, and image-grounded reasoning tasks."
category: "LLM concepts"
related_terms: [multimodal, embedding, transformer, text-to-image, grounding]
---

Vision-language models (VLMs) combine a visual encoder (typically a ViT—Vision Transformer) with a language model decoder. The visual encoder converts an image into a sequence of patch embeddings; a projection layer aligns these into the language model's token space; the language model processes the combined sequence. CLIP and BLIP pioneered the architecture; LLaVA, InternVL, and Qwen-VL have advanced the open-source frontier.

Closed-source VLMs—GPT-4V, Claude Opus, Gemini—excel at real-world visual understanding: reading handwritten text, understanding diagrams, analyzing medical images, and interpreting screenshots. As of 2026, Claude's document understanding capability handles multi-page PDFs with embedded charts and tables.

VLMs are increasingly used in agentic contexts: browser-use agents screenshot the screen and use a VLM to identify UI elements; document processing agents extract structured data from scanned forms; quality assurance agents visually verify that rendered UIs match design specifications.
