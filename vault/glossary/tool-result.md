---
term: "Tool Result"
definition: "The structured response returned to an LLM after it executes a tool call, containing the output data (or error information) that the model incorporates into its next reasoning step."
seo_description: "Tool result: the structured response an LLM receives after executing a tool call, used as context for its next reasoning step."
category: "Agentic AI concepts"
related_terms: [tool-use, function-calling, parallel-tool-calls, agent-loop, grounding, structured-output]
---

When an LLM emits a tool call, the scaffolding executes it and returns a tool result. In Anthropic's Messages API, tool results are injected as `tool_result` blocks in the conversation. The model receives the content of the result (text, JSON, binary data) alongside the original tool call ID, allowing it to associate results with the specific call that generated them.

Tool results are the primary grounding mechanism in agentic systems. They replace the model's internal knowledge with authoritative external data: a web search result, a database row, a code execution output, or a file read. The quality of downstream reasoning depends heavily on how faithfully the tool result represents ground truth.

Error handling in tool results is a critical design decision. Returning a structured error (`{"error": "rate_limited", "retry_after": 30}`) is far more useful than returning an empty response or raising an exception, because it gives the model actionable information to decide its next step—wait and retry, try a different tool, or escalate to a human.
