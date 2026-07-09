---
term: "Structured Output"
definition: "A mode of LLM generation in which the model is constrained to produce output conforming to a predefined schema—typically JSON—enabling reliable downstream parsing without post-processing heuristics."
seo_description: "Structured output: LLM generation constrained to a schema (typically JSON), enabling reliable machine-readable output without brittle parsing."
category: "Agentic AI concepts"
related_terms: [json-mode, function-calling, tool-use, sampling-parameters, agent-scaffolding]
---

Structured output solves a fundamental integration problem: LLMs naturally produce free-form text, but downstream systems need machine-readable data. Early approaches used regex post-processing to extract structured data from text, which was brittle. Constrained decoding (grammar-based sampling, logit masking) enforces schema conformance at the token level, guaranteeing valid output.

OpenAI introduced structured outputs in 2024; Anthropic supports it via tool-use schema enforcement and, with Claude Sonnet 4.6+, via direct JSON mode. The practical effect is that agents can reliably emit structured action plans, classification decisions, or database records without the scaffolding needing a fallback parsing strategy.

Structured output is most valuable for: agent-to-agent communication (typed payloads reduce parsing errors), data extraction from documents (financial reports, contracts), and any workflow where downstream code consumes LLM output programmatically. The cost is slight: constrained decoding can marginally reduce output quality by preventing the model from using intermediate reasoning tokens.

## Related Terms

- [[glossary/json-mode|JSON Mode]] — the model output mode that constrains generation to valid JSON
- [[glossary/function-calling|Function calling]] — the mechanism by which the model emits structured JSON to invoke an external function
- [[glossary/tool-use|Tool use]] — the protocol Claude follows when invoking external tools from an agent loop
- [[glossary/sampling-parameters|Sampling Parameters]] — the temperature, top-k, and top-p settings that control output randomness
- [[courses/claude-tool-use-from-zero|Course: Claude Tool Use from Zero]] — hands-on practice with the concepts covered in this entry
