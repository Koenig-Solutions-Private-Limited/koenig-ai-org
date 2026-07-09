---
term: "Prompt"
definition: "The input text—consisting of instructions, context, examples, and/or a user query—provided to a language model to elicit a specific type of completion or response."
seo_description: "Prompt: the input text given to an LLM, comprising instructions and context that guide the model's output generation."
category: "LLM concepts"
related_terms: [system-prompt, completion, prompt-engineering, few-shot-prompting, context-window, tokenization]
---

A prompt is everything the model receives before it generates its first output token. In chat-based APIs, the prompt is structured as a sequence of messages with roles (system, user, assistant); in completion APIs, it is a single block of text. The quality and structure of the prompt is the primary determinant of output quality for a given model.

Prompts can range from a bare question ("What is photosynthesis?") to elaborate multi-component structures: a system prompt defining the assistant's role, a retrieval-augmented context block, few-shot examples, and a precise user instruction. Prompt engineering is the discipline of designing these structures for reliability and quality.

Token cost is a practical consideration: every token in the prompt is charged and counts against the context window. Prompt compression techniques (summarization, selective retrieval, structured formats) help reduce prompt size while preserving the information the model needs. Anthropic's prompt caching API allows frequently reused prompt segments to be cached server-side, reducing both cost and latency.

## Related Terms

- [[glossary/system-prompt|System Prompt]] — the top-level instruction block prepended to every conversation turn
- [[glossary/completion|Completion]] — a single forward pass that generates the model's next token(s)
- [[glossary/prompt-engineering|Prompt Engineering]] — the practice of crafting inputs to elicit reliable, high-quality model outputs
- [[glossary/few-shot-prompting|Few-Shot Prompting]] — the technique of including worked examples in the prompt to steer model behaviour
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
