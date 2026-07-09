---
date: 2026-07-06
title: "Use Claude Tool Use in 5 Steps to Call Real Functions in 2026"
author: koenig-ai-academy
ticket: KOEA-10202
parent_issue: KOEA-10189
vendor_tag: anthropic
content_type: article
status: g3-passed
reading_time_min: 6
slug: claude-tool-use-in-5-steps-developer-tutorial
tags:
  - claude
  - tool-use
  - anthropic-api
  - tutorial
description: "Implement Claude tool use in five steps, avoid the Sonnet 5 sampling-parameter trap, and return tool_result blocks correctly for production API calls."
seo_description: "Implement Claude tool use in five steps, avoid the Sonnet 5 sampling-parameter trap, and return tool_result blocks correctly for production API calls."
source_research: vault/research/anthropic/claude-tool-use-in-5-steps-developer-tutorial.md
primary_query: "Claude tool use tutorial guide API"
first_60_words_answer: "Claude tool use lets your code execute real functions — database queries, API calls, web lookups — by following a deterministic 5-step loop: define a JSON Schema tool, send it with your request, detect stop_reason: 'tool_use', run the function locally and return a tool_result block, then receive Claude's final natural-language answer. The loop is identical across all current models."
contrarian_angle: "The loop itself takes 10 minutes to learn. What breaks production code is a 3-bullet W28 caveat buried in the course notes: Sonnet 5 silently rejects sampling params that every older tutorial uses."
positions:
  - id: stance:harness-over-model
    engagement: defends
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
sources:
  - url: https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview
    retrieved: 2026-07-06
  - url: https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools
    retrieved: 2026-07-06
  - url: https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls
    retrieved: 2026-07-06
  - url: https://platform.claude.com/docs/en/about-claude/models/overview
    retrieved: 2026-07-06
  - url: https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling
    retrieved: 2026-07-06
  - url: https://claudeapi.com/en/blog/dev-guides/langchain-claude-api-tutorial
    retrieved: 2026-07-06
faq:
  - question: "What is the difference between tool_choice: auto and tool_choice: any?"
    answer: "With auto (the default), Claude decides whether to call a tool or answer directly based on the user's request; with any, Claude must call one of the provided tools but can choose which one, according to Anthropic's [tool definition docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools). Use auto unless you specifically need to force a tool call — any also disables the natural-language preamble before the tool call block, which can surprise developers expecting a reasoning sentence."
  - question: "Why does my tool use return a 400 error about 'tool_use ids without tool_result blocks'?"
    answer: "Your tool_result message is malformed. Anthropic's [tool-call handling guide](https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls) requires tool_result blocks to be the first items in the content array of the user message. Any text content in that message must come after all tool_result blocks. Also verify that tool_use_id in your result exactly matches the id field Claude returned in its tool_use block."
  - question: "Can I pass temperature or top_p when using Claude Sonnet 5 with tool use?"
    answer: "No — and this is the most common copy-paste trap from older tutorials. The current Koenig course pinning note, based on Anthropic's [models overview](https://platform.claude.com/docs/en/about-claude/models/overview), warns that Claude Sonnet 5 rejects non-default temperature, top_p, and top_k with a validation error. Omit these parameters entirely when targeting Sonnet 5 or Opus 4.8."
  - question: "How do I handle a tool that fails at runtime?"
    answer: "Return a tool_result with is_error: true and a descriptive message in the content field (for example, a service-unavailable message), matching Anthropic's [error result format](https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls). Claude incorporates the error into its response and tells the user what went wrong. Do not raise an exception or leave the tool_result block empty — an empty result looks like a success to Claude."
  - question: "Does adding tool definitions increase my API cost?"
    answer: "Yes. Anthropic's [define-tools docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools) explain that the API constructs a tool-use system prompt from your tool definitions, tool configuration, and any user-specified system prompt. That means larger schemas consume more prompt tokens. Use cache_control on stable tool definitions to pin them in Anthropic's prompt cache and reduce repeated schema cost."
whats_new:
  - "W28 Sonnet 5 caveats: 3 specific changes that silently break code copied from older Claude tool-use tutorials"
learning_objectives:
  - "Implement the complete 5-step Claude tool use loop from a blank file"
  - "Avoid the three W28 Sonnet 5 breaking changes that affect any code migrated from Sonnet 4.x"
  - "Handle tool errors correctly so Claude can communicate failures to users"
original_data: false
last_updated: 2026-07-09
hero_image:
  url: /img/blogs/claude-tool-use-in-5-steps-developer-tutorial/hero.png
  alt: "Diagram of the Claude tool use loop: five steps from schema definition to final natural-language answer"
---

# Use Claude Tool Use in 5 Steps to Call Real Functions in 2026

Claude tool use lets your code execute real functions — database queries, API calls, web lookups — by following a deterministic 5-step loop: define a JSON Schema tool, send it with your request, detect `stop_reason: "tool_use"`, run the function locally and return a `tool_result` block, then receive Claude's final natural-language answer. The loop is identical across all current models and takes about 10 minutes to implement from scratch.

What most tutorials skip is the W28 caveat block: Claude Sonnet 5 silently rejects three API parameters that every pre-2026 tutorial uses. If you copy code from a 2024 blog post — temperature, top_p, top_k included — it will fail. Below, the 5 steps include the current model IDs, the exact breaking changes, and the error-handling pattern that most quick-start guides omit.

![Diagram of the Claude tool use loop: five steps from schema definition to final natural-language answer](/img/blogs/claude-tool-use-in-5-steps-developer-tutorial/hero.png)

---

## Step 1: Define the Tool Schema

Every tool requires exactly three fields: `name`, `description`, and `input_schema`. Per [Anthropic's tool definition docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/define-tools), the description is *by far the most important factor in tool performance*.

```python
tools = [
    {
        "name": "get_weather",
        "description": (
            "Retrieves the current weather for a given city. "
            "Provide the city name and optional country code. "
            "Returns temperature in Celsius, humidity percentage, and a short condition string. "
            "Use this when the user asks about current weather, temperature, or conditions in a specific location. "
            "Do not use for historical data or forecasts."
        ),
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "City name, e.g. 'Delhi' or 'Paris, FR'"
                }
            },
            "required": ["location"]
        },
        "strict": True
    }
]
```

Two field-level tips worth locking in early: add `"strict": True` from the start — it guarantees Claude's tool calls always match your schema exactly, eliminating missing-parameter errors at runtime. And spend more time on the description than on the schema itself. A one-sentence description produces tool misuse; four sentences covering domain, trigger condition, return format, and limitations produces reliable behavior.

---

## Step 2: Send the First API Request

```python
import anthropic

client = anthropic.Anthropic()

response = client.messages.create(
    model="claude-sonnet-5",   # current recommended model (July 2026)
    max_tokens=1024,
    tools=tools,
    messages=[{"role": "user", "content": "What's the weather in Delhi?"}]
)
```

**W28 breaking changes** — omit all three of the following from any call targeting `claude-sonnet-5` or `claude-opus-4-8`:

| Parameter | Old tutorials | Sonnet 5 behavior |
|-----------|--------------|-------------------|
| `temperature` | Common default: `0.7` | Rejected — 400 error |
| `top_p` | Common default: `0.9` | Rejected — 400 error |
| `top_k` | Common default: `40` | Rejected — 400 error |

Additionally, Sonnet 5 enables adaptive thinking by default. For predictable, concise tool-use responses in tutorial exercises, pass `"thinking": {"type": "disabled"}`. Note that the [Sonnet 5 tokenizer produces ~30% more tokens](https://platform.claude.com/docs/en/about-claude/models/overview) than Sonnet 4.x — rebaseline any `max_tokens` budgets accordingly.

For cost-sensitive volume, use `claude-haiku-4-5-20251001`. For complex multi-step agentic work, use `claude-opus-4-8`. Do not use any `claude-3-*` model IDs — they are retired.

---

## Step 3: Detect and Parse the Tool Call

```python
if response.stop_reason == "tool_use":
    tool_use_block = next(
        block for block in response.content
        if block.type == "tool_use"
    )
    tool_name = tool_use_block.name        # "get_weather"
    tool_input = tool_use_block.input      # {"location": "Delhi"}
    tool_use_id = tool_use_block.id        # "toolu_01A09q90qw..."
```

When `stop_reason` is `"tool_use"`, Claude has decided to call a function instead of answering directly. The `content` array may include both a text block (Claude's reasoning narration) and one or more `tool_use` blocks. Iterate over all blocks — in agentic workflows, Claude may issue parallel tool calls in a single turn.

Do not assume the first non-text block is the only call. If a user asks, "Compare the weather in Tokyo, Delhi, and Paris," Claude can emit three `get_weather` calls at once. Your handler should collect every `tool_use` block, execute the calls independently, and return one `tool_result` block per `tool_use_id` in the next user message. That pattern matters because parallel calls are where native tool use starts to resemble a real harness rather than a demo: you need stable IDs, ordered results, and a failure policy for one call failing while the others succeed.

The small text block before a tool call is not a contract. Treat it as narration for the user, not as machine-readable state. The machine-readable state is the `tool_use` block: `name` chooses the handler, `input` is the JSON payload, and `id` is the join key that binds the later `tool_result` to this exact request. This is also why [[glossary/tool-use]] examples should teach the ID plumbing early; most broken implementations fail after the model has already made the right tool decision.

---

## Step 4: Execute Locally and Return `tool_result`

Run your actual function with the inputs Claude provided, then send the result back as a new user message:

```python
# your real function
def get_weather(location: str) -> str:
    # ... call your weather API ...
    return "38°C, humidity 65%, partly cloudy"

try:
    result = get_weather(**tool_input)
    is_error = False
except Exception as e:
    result = f"{type(e).__name__}: {e}"
    is_error = True

messages = [
    {"role": "user", "content": "What's the weather in Delhi?"},
    {"role": "assistant", "content": response.content},
    {
        "role": "user",
        "content": [
            {
                "type": "tool_result",
                "tool_use_id": tool_use_id,
                "content": result,
                "is_error": is_error
            }
        ]
    }
]
```

Two constraints that cause 400 errors if violated: (1) `tool_result` blocks must be the **first** items in the user message's `content` array — any text after them is valid, but text before them fails; (2) `tool_use_id` must exactly match the `id` Claude returned in Step 3. [Per the handle-tool-calls docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/handle-tool-calls), you cannot insert any messages between Claude's tool-use response and your tool-result message.

Pass `is_error: True` when your function throws. Claude incorporates the error into its response and informs the user. An empty or missing `tool_result` block looks like a successful empty result to Claude.

---

## Step 5: Receive the Final Answer

```python
final_response = client.messages.create(
    model="claude-sonnet-5",
    max_tokens=1024,
    tools=tools,
    messages=messages
)
# final_response.stop_reason == "end_turn"
print(final_response.content[0].text)
# → "The current weather in Delhi is 38°C with 65% humidity and partly cloudy skies."
```

When `stop_reason` is `"end_turn"`, Claude has incorporated the tool result into a natural-language answer. If Claude calls another tool — `stop_reason == "tool_use"` again — loop back to Step 3. This is the multi-step agentic pattern. In production, the [Anthropic SDK's Tool Runner](https://platform.claude.com/docs/en/agents-and-tools/tool-use/programmatic-tool-calling) handles this loop automatically, parsing `tool_use` blocks, executing registered handlers, and formatting `tool_result` messages.

The loop should still have a hard stop. Set a maximum number of tool turns, track which tool names have already been called, and log the user prompt, tool name, input payload, `tool_use_id`, result status, and final `stop_reason`. Those fields are enough to debug most "Claude ignored my tool" reports without storing full private tool outputs. They also make migration to [[glossary/mcp]] easier later, because MCP servers expose the same basic contract: named tools, structured inputs, structured results, and an execution trace you can inspect.

One practical rule: retry transport failures outside the model loop, but send domain failures back to Claude as `is_error: true`. A timeout from your weather API may deserve one idempotent retry before Claude sees it. A valid "city not found" response should go straight into `tool_result` so Claude can ask the user for a better location. That split keeps the model responsible for conversation repair and keeps your application responsible for infrastructure repair.

---

## Runnable Example

```python
# RunPromptCell — paste into any Python 3.10+ environment with `pip install anthropic`
import anthropic

client = anthropic.Anthropic()

def get_weather(location: str) -> str:
    return f"Mock: 25°C, clear sky in {location}"

tools = [{
    "name": "get_weather",
    "description": "Returns current temperature and sky conditions for a city. Use when the user asks about weather in a specific location.",
    "input_schema": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]},
    "strict": True
}]

messages = [{"role": "user", "content": "Weather in Tokyo?"}]

r1 = client.messages.create(model="claude-sonnet-5", max_tokens=256, tools=tools, messages=messages)
# Note: omit temperature/top_p/top_k — Sonnet 5 rejects them

assert r1.stop_reason == "tool_use"
tu = next(b for b in r1.content if b.type == "tool_use")
result = get_weather(**tu.input)

messages += [{"role": "assistant", "content": r1.content},
             {"role": "user", "content": [{"type": "tool_result", "tool_use_id": tu.id, "content": result}]}]

r2 = client.messages.create(model="claude-sonnet-5", max_tokens=256, tools=tools, messages=messages)
print(r2.content[0].text)
# Expected: "The weather in Tokyo is currently 25°C with clear skies."
```

---

## KnowledgeCheck

**Which of these will cause a 400 error when using Claude Sonnet 5?**

A. Passing `temperature=0.7` in the API call  
B. Setting `tool_choice={"type": "auto"}`  
C. Including a text block *after* a `tool_result` block in the same user message  
D. Using `strict: True` on the tool definition

**Answer: A.** Claude Sonnet 5 rejects non-default `temperature`, `top_p`, and `top_k` values. Option C (text after tool_result) is valid — text must come *after* tool results, not before them. B and D are both fine.

---

## What's Next: From Function Calling to MCP

The 5-step loop above covers native tool use — tools you define and handle in your own code. The natural next step is [Model Context Protocol (MCP)](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview), which lets you expose those same tools as a standardized server callable from Claude Desktop, Cursor, and any other MCP-compatible client without changing your tool definitions.

The **[Claude Tool Use from Zero course on Koenig AI Academy](https://academy.kspl.tech/courses/claude-tool-use-from-zero)** picks up exactly where this tutorial ends. Chapter 1 walks through the full function-calling implementation, Chapter 2 maps the jump from native tools to MCP, and Chapters 3–6 cover building, securing, and observing a production MCP server. The course includes the W28 Sonnet 5 caveats inline so you won't hit the sampling-param trap mid-exercise.

→ [[course/claude-tool-use-from-zero]]
