---
term: "GPT"
definition: "A family name for OpenAI's generative pre-trained transformer models, broadly used for language, reasoning, coding, multimodal, and agentic applications."
seo_description: "GPT: OpenAI's generative pre-trained transformer model family for language, reasoning, coding, multimodal, and agentic applications."
category: "Products"
related_terms: [transformer, llm, reasoning-model, codex, multimodal]
related_courses: [picking-a-frontier-model-2026-q2]
---

GPT models are general-purpose foundation models trained to generate and transform text and other modalities. Product teams use them directly through chat interfaces and indirectly through APIs, agents, copilots, and workflow automation.

The model name alone is not enough to choose the right system. Teams still need to evaluate [[context-window|context length]], [[tool-use|tool calling]], structured output, cost, [[latency]], safety behavior, and performance on their own workload.

**Model history.** GPT-1 and GPT-2 were language models released primarily as research artifacts. GPT-3 (2020) was the first version deployed at scale through an API, establishing the pre-trained [[transformer]] as a general-purpose capability platform. GPT-4 (2023) added [[multimodal]] input (text and images) and meaningfully stronger reasoning, and remains the foundation of the most capable GPT-class systems.

**The o-series reasoning models.** OpenAI's o1, o3, and related releases are distinct from the GPT-4 line in an important way: they perform extended [[chain-of-thought]] reasoning at [[inference]] time before producing a final answer. This trades latency and cost for accuracy on tasks that require multi-step logical or mathematical reasoning. Not every task benefits — for straightforward generation, retrieval, or formatting tasks, reasoning models add overhead without quality gain.

**Access paths.** ChatGPT is a consumer product built on top of GPT models. The raw model is accessed via OpenAI's Chat Completions API and the newer Assistants API, which adds built-in thread management, file retrieval, and code execution. These are distinct surfaces with different latency and feature profiles; the Assistants API abstracts away conversation state management at the cost of less direct control.

**Structured output and function calling.** GPT-4 and later models support JSON mode (constrained output format) and function calling (structured [[tool-use]]), allowing the model to emit a typed function invocation that a harness can execute. Parallel tool calls — requesting multiple tools in a single response — reduce round-trip [[latency]] in [[agent-loop]] workflows.

**Common misconception.** GPT and ChatGPT are not the same thing. ChatGPT is a product; GPT is the underlying model family. Similarly, not all GPT-based workflows go through ChatGPT — most production integrations use the raw API. See [[picking-a-frontier-model-2026-q2]] for a structured approach to comparing GPT models against alternatives for specific workloads.

## Related Terms

- [[glossary/transformer|Transformer]] — the neural architecture underlying virtually all modern LLMs
- [[glossary/llm|Large Language Model (LLM)]] — the large language model that generates responses and tool calls inside the loop
- [[glossary/reasoning-model|Reasoning Model]] — a model trained or prompted to perform multi-step deliberate reasoning before answering
- [[glossary/codex|Codex]] — OpenAI's code-generation model and the CLI agent built on it
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
