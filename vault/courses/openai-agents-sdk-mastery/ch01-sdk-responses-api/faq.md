---
slug: ch01-sdk-responses-api-faq
course: openai-agents-sdk-mastery
chapter: 1
type: faq
status: awaiting-g0
date: 2026-06-01
author: course-author
ticket: KOEA-7084
---

# Chapter 1 FAQ: The Agent SDK & Responses API Model

## Q1: What is the OpenAI Agents SDK and do I need it to use the Responses API?

**A:** The Agents SDK is an orchestration framework (available in both Python and TypeScript) that sits above the Responses API. It handles the multi-turn agent loop — calling the Responses API repeatedly, dispatching tool calls and injecting their results, routing handoffs between agents, running guardrail checks, and recording traces.

You do not *need* it. You can call `POST /v1/responses` directly using the base `openai` Python or TypeScript package and manage the loop yourself. The SDK is the right choice for any non-trivial agent because it saves you from implementing loop management, error recovery, and trace collection from scratch.

---

## Q2: What is the Responses API, and how is it different from Chat Completions?

**A:** Both APIs call OpenAI models, but they are designed for different use cases:

| Feature | Chat Completions (`/v1/chat/completions`) | Responses API (`/v1/responses`) |
|---|---|---|
| State management | None — you pass full history every call | Optional via `stored=true` + `previous_response_id` |
| Built-in tools | None (you define function-call tools yourself) | Web search, code interpreter, file search, computer use |
| Multi-modal input | Text + images (in supported models) | Text, images, audio, file references |
| Agent loop support | None — single request/response | First-class (designed for multi-turn loops) |
| Status | Active, no deprecation planned | Current standard (March 2025+) |

Use Chat Completions for simple, stateless text generation where portability matters. Use the Responses API (via the Agents SDK) when building agents.

---

## Q3: The Assistants API is deprecated — how urgent is migration?

**A:** Very urgent if you have production code. OpenAI deprecated the Assistants API on **August 26, 2025** and will sunset it on **August 26, 2026**. After that date, Assistants API calls will return errors.

The migration path:
1. `Assistants` → Create Prompts in the OpenAI dashboard or via API
2. `Threads` → Conversations (managed via `previous_response_id` chains in the Responses API)
3. `Runs` → `Runner.run()` calls in the Agents SDK
4. `Run Steps` → Output items (tool calls, text) in the response

The official guide at `platform.openai.com/docs/guides/migrate-to-responses` recommends an incremental path: keep stable Chat Completions flows unchanged, move agent-native flows to the Responses API first, then backfill legacy Assistants flows.

---

## Q4: How does the agent loop terminate? Can it run forever?

**A:** The loop terminates when the model produces a response containing only text — no pending tool calls and no handoff directive. This is the "final answer" state.

Without a `max_turns` limit, a poorly designed agent *can* loop indefinitely if it keeps generating tool calls (for example, due to a tool always returning an error that the model retries). Always set `max_turns` in production:

```python
result = await Runner.run(agent, user_input, max_turns=10)
```

If `max_turns` is hit, `Runner.run()` returns a `RunResult` with `final_output=None`. Inspect `result.new_messages` to see where the loop stopped and decide whether to resume.

---

## Q5: Can I use the Agents SDK with models other than OpenAI's?

**A:** Yes. The Agents SDK supports non-OpenAI models through its model provider abstraction. You can use any model that exposes a Chat Completions-compatible interface (e.g., models via Azure OpenAI, Anthropic's API via a wrapper, or local models via Ollama). However, built-in tools (web search, code interpreter) only work with OpenAI's hosted models. For non-OpenAI models, you must define and dispatch all tools manually.

---

## Q6: What is the difference between `Agent.instructions` and the message I pass to `Runner.run()`?

**A:** These map to different parts of the Responses API request:

- `Agent.instructions` → **System prompt**. Applies to every turn in the loop. Defines the agent's persona, constraints, and capabilities. Set once; do not modify per turn.
- The message passed to `Runner.run()` → **User input**. The first human message in the conversation. Changes with every call.

A common mistake is injecting dynamic context (user name, session data) by modifying `instructions`. Instead, embed that context in the user message or as additional context input to `Runner.run()`.

---

## Q7: Is the Python SDK async-only? What if I am in a synchronous codebase?

**A:** `Runner.run()` is a coroutine (async) by default. In a synchronous codebase, use `asyncio.run()`:

```python
import asyncio
result = asyncio.run(Runner.run(agent, "Hello"))
```

For Jupyter notebooks or environments with a running event loop (like FastAPI), use `await Runner.run(...)` directly inside an async function, or use `Runner.run_sync()` if the SDK provides it. Check the SDK's latest docs — a synchronous wrapper may have been added in recent releases.

---

## Q8: How do I test my agent without spending API credits on every run?

**A:** Use the `FakeModel` test utility included in the Agents SDK:

```python
from agents.testing import FakeModel

fake_model = FakeModel(responses=["This is a test response."])
agent = Agent(name="Test Agent", instructions="...", model=fake_model)
result = await Runner.run(agent, "Test input")
assert result.final_output == "This is a test response."
```

`FakeModel` returns predefined responses in sequence without making API calls. It supports tool call simulation for testing tool-calling loops. For integration tests that should hit real APIs, use a real model with a dedicated test `OPENAI_API_KEY` and a separate spend limit.

---

## Q9: What does `result.final_output` return if my agent calls a tool?

**A:** It returns the model's *final text response* — the output the model produces after processing all tool results. You never see raw tool output in `final_output`. The tool was called, its result was injected into the conversation, and the model then synthesized a final answer from that result.

To inspect the full turn-by-turn interaction (including tool calls and their results), use `result.new_messages`. Each entry in this list is an output item: text, tool call, tool result, or handoff.

---

## Q10: The Agents SDK documentation mentions "guardrails" — are those required in Chapter 1?

**A:** No — guardrails are optional and introduced in Chapter 8 (Enterprise Guards & Production Safety). For Chapter 1, ignore them. Guardrails are input/output validation layers that let you reject or transform agent inputs and outputs before they reach the model or the user. They are important for production but add complexity you do not need for a Hello World agent.
