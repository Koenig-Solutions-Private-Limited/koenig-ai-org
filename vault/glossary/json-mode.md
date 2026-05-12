---
term: "JSON Mode"
definition: "An API setting that instructs an LLM to return only valid JSON in its response, using constrained decoding or strong instruction following to guarantee parseable output regardless of task complexity."
seo_description: "JSON mode: an LLM API setting that guarantees responses are valid JSON, enabling reliable machine-readable output from language models."
category: "Agentic AI concepts"
related_terms: [structured-output, function-calling, tool-use, sampling-parameters, agent-scaffolding]
---

JSON mode is the simplest form of structured output: the model is told to respond in JSON, and the API either uses constrained decoding to enforce it or relies on instruction-following. The difference matters in practice—instruction-following JSON mode occasionally produces invalid JSON under adversarial inputs or complex nested schemas; constrained decoding guarantees validity.

JSON mode is useful for lightweight data extraction tasks where a full tool-calling setup would add unnecessary overhead. Common patterns include: extracting entities from a document, classifying text into a fixed taxonomy, and generating configuration objects for downstream tools.

The limitation of simple JSON mode (versus full structured output with schema) is that it guarantees valid JSON syntax but not schema conformance—the model might return a valid JSON object with wrong field names or missing required keys. Adding an explicit JSON schema (via OpenAI's `response_format.json_schema` or Anthropic's tool schema) solves this at the cost of slightly more setup.
