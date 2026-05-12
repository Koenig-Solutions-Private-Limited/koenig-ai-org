---
term: "Parallel Tool Calls"
definition: "A capability allowing an LLM to emit multiple tool calls in a single response turn, which are then executed concurrently by the scaffolding, reducing total latency compared to sequential tool execution."
seo_description: "Parallel tool calls: an LLM capability to emit multiple tool calls in one turn for concurrent execution, reducing agentic task latency."
category: "Agentic AI concepts"
related_terms: [tool-use, tool-result, function-calling, agent-loop, latency, throughput]
---

Sequential tool calls are a major source of latency in agentic tasks. If a task requires searching three databases and the model makes one call at a time, total latency is the sum of three round trips. Parallel tool calls allow the model to identify independent sub-tasks and emit all three calls at once, reducing latency to the maximum of the three individual call times.

Both OpenAI's and Anthropic's APIs support parallel tool calls. The model must recognize that calls are independent to issue them together; tasks with data dependencies (the output of call A is the input of call B) must still be sequential. Good prompt engineering and system design can often restructure tasks to maximize parallelism.

Parallel tool calls complicate the scaffolding slightly: the orchestrator must fan out the calls to their respective executors, collect all results, and reassemble them into a consistent context before the next model turn. Failures in one branch must be handled without blocking results from successful branches.
