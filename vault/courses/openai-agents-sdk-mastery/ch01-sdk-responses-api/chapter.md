---
slug: ch01-sdk-responses-api
course: openai-agents-sdk-mastery
chapter: 1
chapter_title: "The Agent SDK & Responses API Model (2026)"
status: awaiting-g0
date: 2026-06-01
author: course-author
ticket: KOEA-7084
level: Builder
duration_min: 60
reading_time_min: 15
tags:
  - OpenAI Agents SDK
  - Responses API
  - Agent Loop
  - Environment Setup
  - Hello World Agent
  - Chat Completions Migration
learning_objectives:
  - Compare the legacy Chat Completions API with the new Responses API model and identify when to use each
  - Configure the development environment using the Agents SDK and API credentials in both Python and TypeScript
  - Build a Hello World agent using the Agent class and the base SDK loop
prerequisites_chapters: []
chapter_primary_query: "How do I build a Hello World agent with the OpenAI Agents SDK and Responses API in 2026?"
first_60_words_answer: "The OpenAI Agents SDK + Responses API is the canonical way to build production agents as of 2026. Install openai-agents (Python) or @openai/agents (TypeScript), set your OPENAI_API_KEY, create an Agent with instructions, and call Runner.run(). The SDK manages the full agentic loop — multiple turns, tool calls, and handoffs — so you write business logic, not plumbing."
faq:
  - question: "What is the OpenAI Agents SDK?"
    answer: "The OpenAI Agents SDK is an orchestration framework (available in Python and TypeScript) that sits above the Responses API. It manages the agent loop — multiple turns, tool registration and execution, guardrails, handoffs between agents, and tracing — so you do not have to implement these from scratch."
  - question: "What is the Responses API and how does it differ from Chat Completions?"
    answer: "The Responses API (/v1/responses) is OpenAI's new primitive for agent-native workflows, launched March 2025. Unlike Chat Completions (/v1/chat/completions), it supports built-in tools (web search, code interpreter, file search, computer use), stateful conversations via stored=true, and a richer input/output item model. Use Chat Completions for simple one-shot LLM calls; use Responses API when building agents."
  - question: "Is the Assistants API being replaced?"
    answer: "Yes. The Assistants API was deprecated on August 26, 2025 with a sunset date of August 26, 2026. The official migration path moves Assistants → Prompts, Threads → Conversations, and Runs → Responses. New projects should use the Agents SDK and Responses API directly."
  - question: "Do I need the Agents SDK to use the Responses API?"
    answer: "No. You can call the Responses API directly via the base openai Python/TypeScript package. The Agents SDK is an optional but recommended orchestration layer that handles the run loop, tool dispatch, and multi-agent coordination for you."
  - question: "Which model should I use in my agents?"
    answer: "For 2026 production work, use the latest gpt-4.1 series or newer models as they become available. Check platform.openai.com/docs/models for the current recommended model for agentic tasks. The Agents SDK is model-agnostic and works with any OpenAI model ID."
inline_assets:
  - type: diagram
    path: ./img/sdk-architecture.svg
    alt: "Two-layer architecture: Responses API at the HTTP layer with Agents SDK above handling the orchestration loop including tools, guardrails, handoffs, and tracing"
last_updated: 2026-06-01
sources:
  - https://developers.openai.com/api/docs/changelog
  - https://openai.com/index/new-tools-for-building-agents/
  - https://openai.github.io/openai-agents-python/agents/
  - https://developers.openai.com/api/docs/assistants/migration
  - https://developers.openai.com/api/docs/guides/migrate-to-responses
---

# The Agent SDK & Responses API Model (2026)

> **Chapter 1 of 10 · 60 min (15 min reading + 45 min hands-on)**

The OpenAI Agents SDK + Responses API is the canonical way to build production agents as of 2026. Install `openai-agents` (Python) or `@openai/agents` (TypeScript), set your `OPENAI_API_KEY`, create an `Agent` with instructions, and call `Runner.run()`. The SDK manages the full agentic loop — multiple turns, tool calls, and handoffs — so you write business logic, not plumbing. This chapter covers the architecture, the setup, and gets you to a running agent in under 15 minutes.

---

## The Landscape Has Shifted

If you built something with the OpenAI Assistants API before August 2025, you are now on a deprecated path. OpenAI deprecated the Assistants API on August 26, 2025 and set its sunset date for **August 26, 2026**. The migration guide is direct: "We're moving from the Assistants API to the new Responses API for a simpler and more flexible mental model. Responses are simpler — send input items and get output items back." ([platform.openai.com](https://developers.openai.com/api/docs/assistants/migration))

For developers who never touched Assistants API, this chapter is where you start fresh. For developers migrating, it reframes everything you knew in terms of the new model. Either way, the destination is the same: the Responses API as the HTTP primitive, and the Agents SDK as the orchestration layer above it.

This is not just a version bump. OpenAI's March 2025 launch announced a clean two-layer architecture: "Released the Responses API, a new API for creating and using agents and tools. Released the Agents SDK, an orchestration framework for designing, building, and deploying agents." ([developers.openai.com/api/docs/changelog](https://developers.openai.com/api/docs/changelog)) Understanding these two layers — and the boundary between them — is the mental model that powers the remaining nine chapters of this course.

---

## Three APIs, One Winner

Before writing a single line of code, you need clarity on what each API is for and when the platform documentation recommends using it.

| API | Endpoint | Use case | Status |
|---|---|---|---|
| **Chat Completions** | `/v1/chat/completions` | Single-turn or simple multi-turn text generation; no built-in tools; stateless | Active, no planned deprecation |
| **Responses API** | `/v1/responses` | Agent-native workflows; built-in tools; stateful via `stored=true`; multi-modal | **Current standard** (March 2025+) |
| **Assistants API** | `/v1/assistants` | Legacy: Threads, Runs, Messages, Files | Deprecated Aug 2025; sunset Aug 2026 |

The practical rule: **if you are building an agent, use the Responses API and Agents SDK**. Use Chat Completions only for stateless, one-shot LLM calls where you need maximum portability and minimal abstraction.

### What the Responses API Adds

The Responses API's design principle is "send input items and get output items back." Each response can include:

- **Built-in tools**: `web_search`, `code_interpreter`, `file_search`, `computer_use` — no manual tool dispatch required.
- **Stateful conversations**: Set `stored=true` to persist context server-side, referenced by `previous_response_id`.
- **Rich input types**: Text, images, audio, file references — all first-class input items.
- **Structured output**: Native JSON mode with schema enforcement.

Chat Completions does none of this natively. The Assistants API did some of it with a complex Thread/Run/Step object model. The Responses API collapses that complexity into a single, consistent call pattern.

---

## SDK Architecture: Two Layers, One Purpose

```
┌─────────────────────────────────────────────┐
│              Your Application Code           │
├─────────────────────────────────────────────┤
│             OpenAI Agents SDK                │
│  ┌──────────┐ ┌────────────┐ ┌───────────┐  │
│  │  Agent   │ │  Runner    │ │ Guardrails│  │
│  │  class   │ │  (loop)    │ │ Handoffs  │  │
│  └──────────┘ └────────────┘ └───────────┘  │
│          Tracing · Sessions · Tools          │
├─────────────────────────────────────────────┤
│             Responses API (HTTP)             │
│      POST /v1/responses · Tool calls         │
│      Streaming · Stateful context            │
├─────────────────────────────────────────────┤
│         OpenAI Models (gpt-4.1, etc.)        │
└─────────────────────────────────────────────┘
```

*Architecture: Responses API at the HTTP layer, Agents SDK above handling the orchestration loop including tools, guardrails, handoffs, and tracing*

The SDK documentation states this directly: "The SDK uses the Responses API by default for OpenAI models, but the distinction here is orchestration: Agent plus Runner lets the SDK manage turns, tools, guardrails, handoffs, and sessions for you." ([openai.github.io/openai-agents-python](https://openai.github.io/openai-agents-python/agents/))

In practice:

- **Layer 1 — Responses API**: Raw HTTP. You can call it directly with the base `openai` package. One request, one response. You manage state yourself.
- **Layer 2 — Agents SDK**: Orchestration. The `Agent` class defines who the agent is (instructions, model, tools). The `Runner` manages the loop — it calls the Responses API repeatedly until the agent produces a final answer or hands off to another agent.

You can work at either layer. For production agents, work at Layer 2.

---

## Environment Setup

### Python Setup

```bash
# Requires Python 3.10+
pip install openai-agents

# Set your API key
export OPENAI_API_KEY="sk-..."
```

Verify the install:

```python
from agents import Agent, Runner
print("Agents SDK ready")
```

### TypeScript / Node.js Setup

```bash
# Requires Node 18+
npm install @openai/agents

# Set your API key
export OPENAI_API_KEY="sk-..."
```

Verify the install:

```typescript
import { Agent, run } from "@openai/agents";
console.log("Agents SDK ready");
```

### Codex CLI (Optional but Recommended)

Codex CLI is OpenAI's terminal-native coding assistant. It is useful for interactive exploration of the Agents SDK — you can ask it to generate boilerplate, debug agent configs, and scaffold new tool definitions without leaving the terminal.

```bash
npm install -g @openai/codex
codex --version
```

With Codex CLI you can scaffold a new agent project:

```bash
codex "Create a basic OpenAI agent that can answer questions about the Responses API"
```

Codex uses the same `OPENAI_API_KEY` as the Agents SDK. No separate configuration needed.

<Callout type="warning" title="Never commit your API key">
  Store `OPENAI_API_KEY` in a `.env` file (Python: use `python-dotenv`; TypeScript: use `dotenv`) and add `.env` to `.gitignore`. Exposed API keys are immediately scraped by bots and can result in significant unexpected charges. Consider also setting a hard spend limit in the OpenAI platform dashboard.
</Callout>

---

<Callout type="tip" title="Cost Tip: Sidecar Model Routing">

Before your token usage climbs, consider the **sidecar pattern** that Claude Code power users are already applying in production: route routine work to a cheap or local model and reserve your premium model — `gpt-4.1` or equivalent — for the steps that need genuine reasoning and planning.

In practice this means planning and multi-step reasoning calls hit the premium model, while mechanical tasks — summarising a retrieved document, formatting a JSON response, or verifying a tool call succeeded — go to a lighter, cheaper model. The cost difference between a `gpt-4.1-mini`-level call and a full `gpt-4.1` call is approximately 5× ([OpenAI Pricing](https://platform.openai.com/docs/pricing), retrieved 2026-06-10); across thousands of tool calls, that gap dominates your bill.

Community builders are already designing multi-agent pipelines around this boundary: a premium-planner orchestrator hands off sub-tasks to cheap executors, staying inside free-tier or low-cost quotas without sacrificing output quality. ([Community Signal Brief](vault/research/community/2026-05-26.md), retrieved 2026-05-26; [Daily Brief, community section](vault/research/_daily/2026-05-26.md), retrieved 2026-05-26)

</Callout>

---

## Your First Agent: Hello World in Python

An `Agent` in the SDK is a configuration object. It does not execute anything on its own. Execution happens when you pass it to `Runner.run()`.

```python
# hello_agent.py
import asyncio
from agents import Agent, Runner

agent = Agent(
    name="Academy Guide",
    instructions=(
        "You are a concise guide for the Koenig AI Academy. "
        "Answer questions about AI agents clearly and briefly."
    ),
    model="gpt-4.1",
)

async def main():
    result = await Runner.run(
        agent,
        "In one sentence: what is the OpenAI Agents SDK?"
    )
    print(result.final_output)

if __name__ == "__main__":
    asyncio.run(main())
```

**Expected output** (paraphrased — the exact wording varies):
```
The OpenAI Agents SDK is an orchestration framework that manages the multi-turn loop, tool execution, handoffs, and guardrails needed to build production-grade AI agents on top of the Responses API.
```

Three things to notice:

1. `Agent` takes `name`, `instructions`, and `model` at minimum. The instructions are the system prompt — they define the agent's persona and capabilities.
2. `Runner.run()` is an async call. It returns a `RunResult` object with `final_output` (the agent's last text response).
3. There is no explicit HTTP call. The SDK manages the Responses API loop internally.

<RunPromptCell
  id="cell-python-hello"
  model="gpt-4.1"
  prompt="In one sentence: what problem does the OpenAI Agents SDK solve that the base Chat Completions API does not?"
  systemPrompt="You are a concise technical guide for the Koenig AI Academy. Answer in exactly one sentence."
  expectedOutput="The Agents SDK handles the multi-turn execution loop, tool dispatch, handoffs, and guardrails that you would otherwise have to implement manually when building production agents on top of the Chat Completions or Responses API."
/>

<KnowledgeCheck
  id="kc-1"
  question="When you call Runner.run(agent, 'Hello'), what does the Runner do internally?"
  answers={[
    "It sends a single Chat Completions request and returns the response text",
    "It calls the Responses API in a loop, dispatching tool calls and re-invoking the model until it produces a final answer or handoff",
    "It runs the agent locally on your machine without making any API calls",
    "It creates an Assistants API Thread and waits for the Run to complete"
  ]}
  correct={1}
  explanation="Runner manages the agent loop — it calls the Responses API repeatedly, dispatching any tool calls the model requests, until the model produces a final answer (no more tool calls) or transfers control to another agent via a Handoff."
/>

---

## The Agent Loop: What Runner Does For You

Understanding the loop is not optional. When an agent takes unexpected actions or loops indefinitely, the loop internals are where you debug. Here is what `Runner.run()` does on every turn:

```
1. Format agent instructions + conversation history as a Responses API request
2. Call POST /v1/responses
3. Receive output items (text, tool_call, handoff, etc.)
4. If output contains tool_calls:
     a. Execute each tool call
     b. Append results to conversation history
     c. Return to step 1
5. If output contains a handoff:
     a. Switch active Agent to the handoff target
     b. Return to step 1 with new agent's instructions
6. If output contains only text (no tool calls or handoff):
     a. Return RunResult with final_output = text
```

This is exactly the loop you would have written yourself before the SDK existed — but it also handles streaming, error recovery, guardrail checks, and distributed tracing. The loop terminates when the model produces a text-only response.

### Loop Safety: Max Turns

Production agents need a maximum turn limit to prevent runaway loops. The SDK's `max_turns` parameter (default: unlimited in development mode) should be set explicitly in production:

```python
result = await Runner.run(agent, user_input, max_turns=10)
```

If the agent hits `max_turns`, `RunResult.last_agent` and `RunResult.new_messages` let you inspect the state and decide whether to resume, abort, or escalate.

### Hello World in TypeScript

The TypeScript SDK mirrors the Python API closely. The main differences: `run()` instead of `Runner.run()`, and `finalOutput` (camelCase) instead of `final_output`:

```typescript
// hello_agent.ts
import { Agent, run } from "@openai/agents";

const agent = new Agent({
  name: "Academy Guide",
  instructions:
    "You are a concise guide for the Koenig AI Academy. " +
    "Answer questions about AI agents clearly and briefly.",
  model: "gpt-4.1",
});

async function main() {
  const result = await run(
    agent,
    "In one sentence: what is the OpenAI Agents SDK?"
  );
  console.log(result.finalOutput);
}

main().catch(console.error);
```

Run it with `ts-node hello_agent.ts` or compile first with `tsc`.

<RunPromptCell
  id="cell-ts-hello"
  model="gpt-4.1"
  prompt="Compare the OpenAI Agents SDK's Runner.run() to a raw Responses API call. What does Runner.run() add beyond a single POST /v1/responses?"
  systemPrompt="You are a technical educator. Be specific and concise. Focus on orchestration mechanics."
  expectedOutput="Runner.run() adds the multi-turn loop (re-invoking the model after each tool call), automatic tool dispatch and result injection, handoff routing between agents, guardrail checks on inputs and outputs, and structured tracing — none of which are provided by a single raw POST /v1/responses call."
/>

<KnowledgeCheck
  id="kc-2"
  question="You set max_turns=5 and your agent requires 6 tool calls to complete its task. What happens?"
  answers={[
    "The SDK raises a MaxTurnsExceeded exception and the process exits",
    "The SDK returns a RunResult with final_output=None and the partial conversation state; you can inspect and decide whether to resume",
    "The SDK automatically increases max_turns to allow the task to complete",
    "The agent silently truncates its output to fit within 5 turns"
  ]}
  correct={1}
  explanation="The SDK stops the loop at max_turns and returns a RunResult object. final_output will be None (no text-only response was produced), but new_messages and last_agent give you everything you need to inspect the state, log it, and decide whether to call Runner.run() again with the partial result as input."
/>

---

## Migrating From the Assistants API

If you have existing Assistants API code, here is the object model mapping. The conceptual shift matters more than the syntax: the Responses API has no separate Thread or Run resource — context accumulates in the response chain itself.

| Assistants API | Responses API / Agents SDK |
|---|---|
| `Assistant` | `Agent` (SDK) or Prompt (dashboard) |
| `Thread` | Conversation (implicit in `previous_response_id` chain) |
| `Run` | `Runner.run()` call |
| `Run Step` | Output item (tool call, text, etc.) |
| `Message` | Input/output item |
| `File` | Upload via `/v1/files`, reference by `file_id` |

The key operational difference: Assistants API state lived in Thread objects you queried by ID. Responses API state lives in the response chain — each response references its predecessor via `previous_response_id`. The Agents SDK abstracts this completely; `Runner.run()` maintains the chain internally.

For teams with production Assistants API code, the official migration guide at `platform.openai.com/docs/guides/migrate-to-responses` walks through the incremental path: keep stable Chat Completions flows untouched, move new agent-native flows to the Responses API, and migrate legacy Assistants flows before the August 2026 sunset.

---

## Common Pitfalls in Chapter 1

<Callout type="warning" title="Three mistakes every newcomer makes">

**1. Using Chat Completions inside an Agent.** The Agents SDK uses the Responses API by default. If you pass a `model` string to `Agent()`, the SDK routes requests through the Responses API automatically. Do not create a separate `openai.ChatCompletion` client and try to wire it in — you will bypass the SDK's loop management entirely.

**2. Forgetting async.** `Runner.run()` is a coroutine. In Python, you must `await` it inside an `async def` function and run it with `asyncio.run()`. The most common error is calling `Runner.run(agent, prompt)` synchronously and receiving a coroutine object instead of a result.

**3. Hardcoding instructions as a one-liner and wondering why the agent "forgets" context.** Instructions are the system prompt — they apply to every turn in the loop. If your agent needs dynamic context (user preferences, session data), inject it at the `input` level (the message content), not by modifying `instructions` per turn. Modifying `instructions` creates a new agent configuration and resets the loop context.

</Callout>

---

## Hands-On Exercise: System Query Agent

**Time estimate:** 45 minutes  
**Success criteria:** A working agent that answers queries about your development environment and returns structured output.

### Part 1: Basic Agent (15 min)

Create `system_agent.py` (or `system_agent.ts`) with an agent whose `instructions` define it as a "system administrator assistant that helps with development environment questions." Call it with three different queries:

1. "What Python version should I use for the Agents SDK?"
2. "How do I set environment variables securely in a Python project?"
3. "What is the difference between `asyncio.run()` and `await` in Python?"

Observe: each call is independent (no shared context). The agent answers from its instructions and the model's knowledge.

### Part 2: Verify the Loop (15 min)

Add a simple tool to your agent:

```python
from agents import Agent, Runner, function_tool

@function_tool
def get_sdk_version() -> str:
    """Returns the currently installed openai-agents version."""
    import importlib.metadata
    return importlib.metadata.version("openai-agents")

agent = Agent(
    name="System Assistant",
    instructions="You are a helpful system assistant. Use the get_sdk_version tool when asked about SDK versions.",
    model="gpt-4.1",
    tools=[get_sdk_version],
)
```

Ask: "What version of the Agents SDK am I running?" The agent should call `get_sdk_version()` and incorporate its output. This confirms the loop is working: model → tool call → tool result → model → final answer.

### Part 3: TypeScript Variant (15 min)

Rewrite the same agent in TypeScript. Verify that `result.finalOutput` produces equivalent output to Python's `result.final_output`. This cross-language exercise solidifies the API parity between the two SDK implementations.

**You've completed Chapter 1 when:**
- [ ] Both Python and TypeScript hello world agents run without error
- [ ] The tool-calling agent in Part 2 correctly invokes `get_sdk_version` and returns the version number
- [ ] You can explain in your own words what `Runner.run()` does between the first API call and `final_output`

---

## Concepts at a Glance

| Term | Definition |
|---|---|
| **Responses API** | OpenAI's HTTP primitive for agent-native workflows (`POST /v1/responses`); replaced Assistants API |
| **Chat Completions API** | Stateless single-turn or multi-turn LLM calls; no built-in agent tooling |
| **Assistants API** | Deprecated Aug 2025; sunset Aug 2026; superseded by Responses API |
| **Agent** | SDK class defining an agent's identity: `name`, `instructions`, `model`, `tools` |
| **Runner** | SDK class that executes the agent loop — calls Responses API, dispatches tools, manages handoffs |
| **Agent Loop** | The multi-turn cycle: call API → dispatch tools → inject results → call API until final answer |
| **max_turns** | Guard against infinite loops; returns partial RunResult if hit |
| **final_output** | The text content of the model's last response when no further tool calls are pending |

---

## What's Next

[[openai-agents-sdk-mastery/ch02-tool-orchestration|Chapter 2: Tool Orchestration & Pydantic Safety]] builds on the loop you just learned. You will implement type-safe tool definitions using Pydantic (Python) and Zod (TypeScript), build automated error-recovery loops for tool failures, and design tools with structured output that downstream agents can safely consume.

If you are migrating from the Assistants API, bookmark [[picking-a-frontier-model-2026-q2|Picking a Frontier Model (2026 Q2)]] — its Responses API context section provides the model-selection decision framework you need before Chapter 4's migration labs.

The loop runs. The tools are next.

---

*Sources: [OpenAI Platform Changelog](https://developers.openai.com/api/docs/changelog) · [New Tools for Building Agents (Mar 2025)](https://openai.com/index/new-tools-for-building-agents/) · [Agents SDK Documentation](https://openai.github.io/openai-agents-python/agents/) · [Assistants API Migration Guide](https://developers.openai.com/api/docs/assistants/migration) · [Migrate to Responses API](https://developers.openai.com/api/docs/guides/migrate-to-responses)*
