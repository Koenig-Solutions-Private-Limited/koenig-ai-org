---
term: "Gemini"
definition: "Google's family of multimodal AI models and assistants used for text, code, image, audio, video, and agent-style workflows."
seo_description: "Gemini: Google's family of multimodal AI models and assistants for text, code, image, audio, video, and agent workflows."
category: "Products"
related_terms: [multimodal, vision-language-model, reasoning-model, tool-use, context-window]
related_courses: [gemini-enterprise-agents]
---

Gemini models are used in consumer products, developer APIs, and enterprise workflows. Their distinguishing design center is [[multimodal|multimodality]]: many use cases combine text with images, video, audio, code, or documents in a single native request, rather than treating non-text inputs as add-ons.

When comparing Gemini with other model families, teams should test the exact modality mix they need. A model can be strong in visual reasoning or long-context processing while still requiring careful evaluation for structured output, determinism, [[latency]], or [[tool-use]] reliability.

**Model tiers** map to different workload profiles. Gemini Nano runs on-device for latency-critical or privacy-sensitive mobile use cases. Flash is optimized for speed and cost, making it well-suited for high-volume tasks where response time matters. Pro balances capability and cost for general workloads. Ultra and the 1.5 Pro generation handle demanding reasoning, long documents, and complex agentic pipelines.

**Long context window.** Some Gemini versions support up to one million tokens in a single [[context-window|context window]]. This enables full-document analysis, multi-session conversation history, and ingesting entire codebases without chunking. A common misconception is that this eliminates the need for [[rag]]: long context and retrieval solve different problems. Long context is expensive and slow for large collections; [[rag]] scales to millions of documents and surfaces precisely the relevant subset. In practice, long context and [[rag]] are complementary.

**Access paths.** Google AI Studio is the developer playground for rapid prototyping, with generous free-tier access. Vertex AI is the enterprise access path, adding VPC controls, IAM integration, [[audit-trail]] logging, regional [[data-residency]], and SLAs. Compliance-sensitive workloads should always go through Vertex AI.

**Agent platform.** Vertex AI hosts the Gemini Enterprise Agent platform, which provides orchestration primitives for building multi-agent systems with state persistence, tool calling, and session management. This is distinct from using the raw Gemini API. See [[gemini-enterprise-agents]] for a production walkthrough covering orchestration, security, observability, and scale.

**Tool calling and code tasks.** Gemini supports structured [[tool-use]] via function declarations, enabling [[agent-loop]] patterns where the model plans actions and the harness executes them. Evaluation on coding and tool-call reliability should be done on your own task distribution — public [[benchmark-suite]] scores do not reliably predict behavior on specific integration patterns.

## Related Terms

- [[glossary/multimodal|Multimodal]] — the ability to process and generate content across text, images, audio, and other modalities
- [[glossary/vision-language-model|Vision-Language Model]] — a multimodal model that understands and reasons over both images and text
- [[glossary/reasoning-model|Reasoning Model]] — a model trained or prompted to perform multi-step deliberate reasoning before answering
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[courses/gemini-enterprise-agents|Course: Gemini Enterprise Agents]] — hands-on practice with the concepts covered in this entry
