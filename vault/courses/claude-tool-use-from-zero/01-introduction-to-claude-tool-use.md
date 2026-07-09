---
chapter_num: 1
course_slug: claude-tool-use-from-zero
title: "Introduction to Claude's Tool Use"
status: draft-for-review
author: course-author
ticket: KOEA-2461
learning_objectives:
  - "Explain the difference between a normal text response and a tool-use turn"
  - "Define a small client-side tool with a clear input schema"
  - "Parse Claude's tool-use response and send the tool result back"
  - "Name three failure modes in first tool integrations"
prerequisites_chapters: []
duration_min: 40
level: Builder
vendor_tag: anthropic
sources:
  - https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
  - https://docs.anthropic.com/en/api/messages
  - https://docs.anthropic.com/en/docs/test-and-evaluate/strengthen-guardrails/increase-consistency
tags:
  - course/claude-tool-use-from-zero
  - claude
  - tool-use
  - function-calling
quiz:
  - question: "In Claude's tool-use loop, which stop reason signals that the model is requesting a tool rather than producing a final answer?"
    options:
      - "`end_turn` — the model finished its response and no further action is needed by the host"
      - "`tool_use` — the model returned a tool_use content block and the host must execute it"
      - "`max_tokens` — the model hit its output limit and the call should be retried with more tokens"
      - "`stop_sequence` — a custom stop string was matched and the conversation is now complete"
    correct_idx: 1
    explanation: "The Anthropic API uses stop_reason 'tool_use' when Claude returns a tool_use content block. 'end_turn' appears on final text answers. 'max_tokens' means the output budget was exhausted, and 'stop_sequence' means a custom delimiter was matched — neither signals a tool request."
    section_anchor: the-mental-model-model-chooses-host-executes
  - question: "What problem does omitting a required field from a tool's input schema create?"
    options:
      - "Claude refuses to call the tool and returns an error explaining the missing required field"
      - "API latency increases because the server must infer the argument shape from surrounding context"
      - "The model uses inconsistent field names across calls, breaking host-side argument parsing"
      - "The tool's response is automatically blocked by the API's input safety classification layer"
    correct_idx: 2
    explanation: "Without a schema, Claude has no field-name contract and may send 'ticker', 'symbol', 'stock_code', or other variants across calls. Your host parser then either breaks or accepts loose input. A well-defined schema gives both Claude and your host the same contract so field names are stable."
    section_anchor: why-input-schemas-are-not-optional
  - question: "Which is an example of the 'over-broad tool' anti-pattern the chapter warns against?"
    options:
      - "`get_invoice_status(invoice_id)` — reads one invoice record scoped to a business identifier"
      - "`list_open_support_cases(user_id)` — returns only the cases owned by the specified user"
      - "`run_python(code)` — executes arbitrary Python code with no bounded business scope"
      - "`lookup_stock_price(ticker)` — fetches one price quote from the demo portfolio price feed"
    correct_idx: 2
    explanation: "run_python(code) gives Claude a general-purpose execution primitive instead of a bounded business action. The other three tools are narrow and domain-specific: get_invoice_status, list_open_support_cases, and lookup_stock_price all constrain scope to a single identifiable business object."
    section_anchor: common-first-failures
---

# Introduction to Claude's Tool Use

This chapter gets you from "Claude can answer questions" to "Claude can decide when to call a structured function, receive the result, and continue the job." That is the first practical step toward real connectors.

Claude tool use is not magic plugin installation. In the Anthropic Messages API, you describe tools with names, descriptions, and JSON input schemas. When Claude decides a tool is needed, the response contains a `tool_use` content block and the API response stop reason is `tool_use`.[^1] Your application runs the actual code, then sends a follow-up message containing a `tool_result`. Claude never reaches into your runtime by itself; your host application remains the executor and policy boundary.

That boundary matters. If your tool fetches a stock price, deletes a file, sends an invoice, or queries a customer database, Claude only proposes the call. Your software decides whether the call is valid, authorized, observable, and safe.

## Prerequisites check

Before you start, verify that you can do three things:

1. Read and write a small Python or TypeScript script.
2. Store an API key in an environment variable rather than hard-coding it.
3. Understand JSON objects, required fields, and string/number types.

If those are shaky, finish a basic API-client tutorial first. Tool use adds a multi-step protocol on top of ordinary API calls; it is not a good place to learn HTTP from scratch.

## The mental model: model chooses, host executes

A tool-use exchange has four parts:

1. You send Claude a user request plus a list of available tools.
2. Claude returns either normal text or a `tool_use` block.
3. Your host validates the tool name and input, executes local code, and returns a `tool_result`.
4. Claude uses that result to produce the final answer or request another tool.

```takeaways
- Claude only proposes a tool call; your host application is always the executor and the security boundary.
- The stop reason `tool_use` signals that Claude is requesting a tool rather than producing a final answer.
- The four-step loop (request → tool_use block → tool_result → final answer) is the stable control flow regardless of SDK version.
```

The tool description is part of the model's context. It should say what the tool does, when to use it, and what each field means. The input schema is the contract your code can validate before execution. Anthropic recommends precise tool definitions because ambiguous descriptions make tool selection less reliable.[^1]

Here is the smallest useful stock-price tool. It uses a fake in-memory price table so the first exercise is reproducible without a paid market-data provider.

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="You have a tool named get_stock_price that accepts {ticker: string}. Use it to answer: What is the current price of KOENIG?"
  expectedOutput={`Claude should return a tool request similar to:

[tool_use]
name: get_stock_price
input: {"ticker":"KOENIG"}

After your host returns the tool result:
{"ticker":"KOENIG","price":42.15,"currency":"USD","as_of":"2026-05-14T12:00:00Z"}

Claude can answer:
KOENIG is trading at 42.15 USD as of 2026-05-14T12:00:00Z.`}
/>

The important phrase is "your host returns." Claude does not know the price. The model selected the tool and filled the arguments; your program supplied the facts.

## A first implementation shape

The exact SDK syntax can change, but the control flow is stable:

```takeaways
- SDK syntax evolves between releases, but the underlying request-tool_use-tool_result-answer loop does not change.
- The tool definition object must include a name, description, and a JSON input schema with required fields declared explicitly.
- In a full application, tool dispatch is a switch or map by tool name, not a single hardcoded function.
```

```python
TOOLS = [
    {
        "name": "get_stock_price",
        "description": "Return the latest known price for a ticker symbol from the demo portfolio feed.",
        "input_schema": {
            "type": "object",
            "properties": {
                "ticker": {
                    "type": "string",
                    "description": "Uppercase ticker symbol, for example KOENIG"
                }
            },
            "required": ["ticker"]
        }
    }
]

def get_stock_price(ticker: str) -> dict:
    prices = {
        "KOENIG": {"price": 42.15, "currency": "USD"},
        "PAPER": {"price": 18.40, "currency": "USD"},
    }
    symbol = ticker.upper()
    if symbol not in prices:
        raise ValueError(f"Unknown demo ticker: {symbol}")
    return {"ticker": symbol, **prices[symbol], "as_of": "2026-05-14T12:00:00Z"}
```

In a full app, the code around this function calls the Messages API, checks for a `tool_use` block, dispatches by name, catches errors, and sends the result back as a tool result. Anthropic's Messages API is the primary API surface for this interaction.[^2]

## Why input schemas are not optional

Without a schema, every tool call becomes a guess. The model may send `stock`, `symbol`, `ticker_symbol`, or `company_name`. Your application then either breaks or accepts loose input that later creates security problems.

```takeaways
- Without a required input schema, the model has no contract and will use inconsistent field names across calls.
- A well-defined schema lets your host reject malformed input before it touches any external system.
- Specific descriptions ("return the latest quote for one uppercase ticker") are more reliable than vague descriptions ("fetch data").
```

Schemas protect both sides:

- Claude gets a compact contract for which fields to fill.
- Your host can reject malformed input before touching external systems.
- Logs become comparable because the same tool always receives the same shape.

Use specific descriptions. "Fetch data" is weak. "Return the latest quote for one uppercase ticker in the demo portfolio feed" is useful.

<Callout type="warning">
Do not connect a write-capable production tool on your first pass. Start with a read-only tool whose output you can verify manually. Once parsing, validation, and logging work, then add mutation tools with explicit approval gates.
</Callout>

## Common first failures

The first failure is over-broad tools. A tool named `run_python` or `query_database` is easy to demo and dangerous to operate. It gives the model a low-level execution primitive instead of a business action. Prefer `get_invoice_status`, `lookup_stock_price`, or `list_open_support_cases`.

```takeaways
- Over-broad tools like `run_python` or `query_database` hand the model a general primitive instead of a bounded business action.
- Hidden side effects (a tool that reads, updates, and emails) must be named explicitly in the description and confirmed in host code.
- Model-produced JSON must still be validated in your runtime; schemas guide the model but do not replace server-side input checks.
```

The second failure is hidden side effects. A tool named `sync_customer` might read from Salesforce, update Stripe, and email an account manager. The model cannot reason about that safely from the name. If a tool changes state, say so in the description and require confirmation in your host.

The third failure is treating model output as trusted JSON. Even when using tool schemas, validate inputs in your own runtime. Consistency guidance from Anthropic emphasizes strengthening outputs through constraints and checks, not wishful parsing.[^3]

<KnowledgeCheck
  questions={[
    {
      question: "In Claude tool use, who executes the tool code?",
      answers: [
        "Claude's model runtime",
        "The host application that received the tool_use block",
        "The tool schema itself",
        "The browser automatically"
      ],
      correct: 1,
      explanation: "Claude requests a tool call. Your host validates and executes it, then returns a tool_result."
    },
    {
      question: "Why should the stock-price tool require a ticker field in its schema?",
      answers: [
        "So Claude can infer prices without calling the tool",
        "So the host can validate the required argument before execution",
        "So API latency is lower",
        "So the tool can bypass authorization"
      ],
      correct: 1,
      explanation: "The schema gives Claude and your host the same contract."
    }
  ]}
/>

<RunPromptCell
  model="claude-sonnet-4-6"
  prompt="I am designing a first Claude tool for a finance assistant. Compare these tool names and tell me which is safer: run_sql(query), get_customer_balance(customer_id), or update_account(anything). Explain the operational risk."
  expectedOutput={`The safer first tool is get_customer_balance(customer_id).

Why:
- It is narrow and business-specific.
- Its input is constrained to a customer identifier.
- It sounds read-only, which makes review and logging easier.

run_sql(query) is too powerful because it exposes a general database primitive. update_account(anything) is vague and write-capable, so it needs a much stronger schema, authorization check, and human approval step.`}
/>

<KnowledgeCheck
  questions={[
    {
      question: "Free-form: Describe one tool you would NOT expose directly to Claude in production and rewrite it as a safer business-level tool."
    }
  ]}
/>

## Hands-on exercise

Build a local script that defines `get_stock_price(ticker)` and exposes it to Claude as a tool. Use only a hard-coded demo price table.

Success criteria:

- The tool schema has exactly one required field: `ticker`.
- A request for `KOENIG` produces a tool-use turn, then a final answer with price, currency, and timestamp.
- A request for an unknown ticker returns a controlled error, not a stack trace.
- You log the tool name, validated input, and success/failure.

## What's next

Chapter 2 moves from one client-side function to MCP, the protocol that lets hosts discover and call tools, resources, and prompts from external servers.

[^1]: Anthropic, "Tool use with Claude", https://docs.anthropic.com/en/docs/agents-and-tools/tool-use/overview
[^2]: Anthropic, "Messages API", https://docs.anthropic.com/en/api/messages
[^3]: Anthropic, "Increase output consistency", https://docs.anthropic.com/en/docs/test-and-evaluate/strengthen-guardrails/increase-consistency
