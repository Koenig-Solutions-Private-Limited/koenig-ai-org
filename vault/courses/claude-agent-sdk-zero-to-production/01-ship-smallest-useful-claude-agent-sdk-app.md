---
chapter_num: 1
course_slug: claude-agent-sdk-zero-to-production
title: "Ship the smallest useful Claude Agent SDK app"
status: awaiting-g0
duration_min: 60
vendor_tag: claude-agent-sdk
learning_objectives:
  - "Install @anthropic-ai/claude-agent-sdk and authenticate against the Anthropic API using ANTHROPIC_API_KEY"
  - "Implement a minimal agent using query() and explain each parameter it accepts"
  - "Compare streaming vs. blocking response consumption and choose the right pattern for a given use case"
  - "Select the appropriate model tier (Haiku / Sonnet / Opus) based on task class and cost"
sources:
  - url: "https://code.claude.com/docs/en/agent-sdk/overview"
    title: "Claude Agent SDK Overview"
  - url: "https://code.claude.com/docs/en/agent-sdk/typescript"
    title: "Claude Agent SDK TypeScript Reference"
owns:
  - "SDK installation via npm and ANTHROPIC_API_KEY authentication"
  - "Minimal query() call — the five-line agent pattern"
  - "Streaming vs. blocking response consumption modes"
  - "Model tier selection: haiku / sonnet / opus and task-class matching"
defers_to:
  - "session resume and the options.resume field → ch2"
  - "dynamic system prompts and environment-driven persona swap → ch2"
  - "MCP server configuration and tool schemas → ch3"
  - "artifact storage and resumable runs → ch4"
  - "evals, Langfuse tracing, and cost attribution → ch5"
  - "HTTP entrypoints and operator runbook → ch6"
quiz_topics:
  - "steps to install and authenticate the SDK"
  - "what query() returns and how to consume it as an async generator"
  - "when to choose streaming vs. blocking message consumption"
  - "which model tier matches a given task class"
notebooklm_source_focus:
  - "https://code.claude.com/docs/en/agent-sdk/overview"
  - "https://code.claude.com/docs/en/agent-sdk/typescript"
word_budget: { min: 800, max: 1200 }
quiz:
  - question: "Which command installs the Claude Agent SDK for a TypeScript project?"
    options:
      - "npm install @anthropic-ai/claude-agent-sdk — the current package name since the April 2026 rename"
      - "npm install @anthropic-ai/claude-code — the original SDK package before it was renamed in April 2026"
      - "npm install anthropic-agent-sdk — a package name that looks plausible but does not actually resolve"
      - "npm install @anthropic-ai/sdk — the raw Anthropic Client SDK for single-turn Messages API calls"
    correct_idx: 0
    explanation: "The npm package was renamed from @anthropic-ai/claude-code to @anthropic-ai/claude-agent-sdk in April 2026. The @anthropic-ai/sdk package is the raw Anthropic Client SDK for the Messages API — a completely different library."
    section_anchor: install-the-sdk-and-set-up-auth

  - question: "What does query() return in the Claude Agent SDK TypeScript library?"
    options:
      - "An async generator that yields typed message objects as the agent reasons and acts"
      - "A Promise that resolves to the final answer string once the agent loop completes"
      - "A WebSocket connection that emits agent events as Server-Sent Events in real time"
      - "A synchronous array of all message objects returned after the agent finishes its work"
    correct_idx: 0
    explanation: "query() is an async generator — you consume it with for-await-of and receive message objects (assistant, result, etc.) as they arrive during execution. It is not a Promise, WebSocket, or synchronous array."
    section_anchor: the-smallest-useful-agent

  - question: "Your CI pipeline calls query() to validate a commit message and write the verdict to a JSON file. Which pattern should you use?"
    options:
      - "Blocking — collect all message objects in an array, extract the result field, then write to JSON"
      - "Streaming — write assistant text blocks to stdout in real time so CI logs stay readable"
      - "Both patterns produce the same output, so use streaming since it costs less per token"
      - "Blocking — pass blocking: true to query() to get a Promise instead of an async generator"
    correct_idx: 0
    explanation: "A pipeline writing structured output to a file needs the complete final response before acting, which is blocking mode. Streaming is for interactive display. Token cost and the generator interface are identical between patterns — there is no blocking: true flag."
    section_anchor: streaming-vs-blocking-responses

  - question: "Your agent classifies support tickets into one of five categories. No multi-step reasoning or file access is needed. Which model tier is the best default?"
    options:
      - "haiku — cheapest and fastest for structured classification with a fixed, small label space"
      - "sonnet — the default tier is always the safest starting choice regardless of task class"
      - "opus — maximum reasoning capability always produces the most accurate classification results"
      - "Use the full model ID like claude-haiku-4-5-20251001 to prevent automatic model drift"
    correct_idx: 0
    explanation: "Structured classification with a fixed label space is exactly the task class Haiku is built for: the output is deterministic, reasoning depth is not required, and cost and latency are the variables that matter. Sonnet is the right default for general-purpose agents, not for specialized low-complexity tasks. Opus should be reserved for tasks where Sonnet demonstrably falls short."
    section_anchor: picking-the-right-model-tier
---

# Ship the smallest useful Claude Agent SDK app

The Claude Agent SDK turns Claude into a library call: your TypeScript process spawns an agent loop that can read files, run shell commands, search the web, and self-correct across multiple turns — all from a single `for-await-of`. This chapter takes you from nothing to a working streaming agent, then covers the two architectural decisions that matter most at this stage: how to consume responses, and which model to pay for.

## Install the SDK and set up auth

The SDK ships as a single npm package. The TypeScript distribution bundles a native Claude Code binary for your platform, so you do not need a separate Claude Code CLI installation.

```bash
npm install @anthropic-ai/claude-agent-sdk
```

Authentication uses one environment variable:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

Get your key from the [Anthropic Console](https://console.anthropic.com). The SDK reads `ANTHROPIC_API_KEY` automatically on every call. You can also pass credentials per-call via `options.env`, but the environment variable is the right default for local development and CI.

If your team runs workloads behind Amazon Bedrock, Google Vertex AI, or Azure AI Foundry, the SDK respects `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, and `CLAUDE_CODE_USE_FOUNDRY` — no code changes needed, only environment variable switches ([Claude Agent SDK Overview](https://code.claude.com/docs/en/agent-sdk/overview)).

<Callout type="warn">
The package was renamed from `@anthropic-ai/claude-code` to `@anthropic-ai/claude-agent-sdk` in April 2026. If you have an existing project, run `npm uninstall @anthropic-ai/claude-code && npm install @anthropic-ai/claude-agent-sdk` and update every import before proceeding.
</Callout>

## The smallest useful agent

The entire public TypeScript API of the Claude Agent SDK is one function: `query()`. It is an async generator that yields typed message objects as the agent reasons and acts. Here is a complete, runnable agent in five lines:

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const msg of query({ prompt: "Name three cloud cost-optimization techniques in one sentence each." })) {
  if ("result" in msg) console.log(msg.result);
}
```

`query()` accepts an object with one required field (`prompt`) and one optional field (`options`). The generator produces a sequence of typed objects — `assistant`, `result`, and others — as the agent works through the task. The `result` message arrives last and contains the final synthesized answer, token usage, and `total_cost_usd`. The `assistant` messages arrive before that and carry the model's intermediate reasoning and any tool calls.

The `options` object controls everything else: which model to use, how many turns to allow, which tools to expose, and which environment variables to pass into the agent's process. The defaults are safe for getting started: the SDK picks Claude Sonnet as the model and grants no built-in tools, so the agent works purely from its own knowledge.

This is meaningfully different from calling the Anthropic Messages API directly. `query()` runs a full agent loop — it can make multiple model calls, execute tools between turns, and self-correct before delivering a final answer. The Messages API sends one request and returns one response. For a weather summary, a single Messages API call can suffice. For an agent that reads a codebase, searches documentation, and synthesizes a diagnosis, you need `query()`. Session tracking, turn counting, and tool execution are handled by the SDK ([Claude Agent SDK TypeScript Reference](https://code.claude.com/docs/en/agent-sdk/typescript)).

## Streaming vs blocking responses

`query()` always returns an async generator — what you do inside the `for-await-of` loop determines whether the experience feels streaming or blocking to the end user.

**Streaming** — act on each message object as it arrives:

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

for await (const msg of query({ prompt: "Summarize the tradeoffs between REST and GraphQL." })) {
  if (msg.type === "assistant") {
    for (const block of msg.message.content) {
      if (block.type === "text") process.stdout.write(block.text);
    }
  }
}
process.stdout.write("\n");
```

Words appear in the terminal as Claude generates them. This is the right pattern for CLI tools and interactive applications where perceived latency matters — users see progress immediately rather than waiting for the full answer.

**Blocking** — collect all messages first, then act on the result:

```typescript
import { query, SDKMessage } from "@anthropic-ai/claude-agent-sdk";

const messages: SDKMessage[] = [];
for await (const msg of query({ prompt: "Summarize the tradeoffs between REST and GraphQL." })) {
  messages.push(msg);
}
const result = messages.find(m => m.type === "result");
if (result && "result" in result) console.log(result.result);
```

Blocking mode is the right choice for background pipelines, batch jobs, and any context where you need the complete response before taking an action — writing to a database, calling a downstream API, or rendering a structured JSON payload. The runtime token cost and the generator interface are identical between the two patterns; the only variable is when your code reads the data.

<KnowledgeCheck
  question="A nightly job calls query() to generate a summary of the day's incidents and POST it to a Slack webhook. Which consumption pattern is correct?"
  options={[
    "Blocking — collect all messages, extract the result string, then POST the complete summary to Slack",
    "Streaming — write text blocks to a buffer as they arrive and flush to Slack in real time",
    "Either pattern works identically since query() returns all data regardless of how you read it",
    "Streaming — add stream: true to options so query() switches its return type to a Promise"
  ]}
  correctIdx={0}
  explanation="A job that POSTs to a downstream API needs the complete, finalized answer before making the HTTP call — blocking mode. Streaming is for interactive display. The generator interface and token cost are the same either way; there is no stream: true flag."
/>

## Picking the right model tier

The SDK accepts three shorthand strings as `options.model` — `"haiku"`, `"sonnet"`, or `"opus"` — or a full versioned model ID like `"claude-haiku-4-5-20251001"`. Shorthand strings always resolve to the latest promoted version of that tier:

```typescript
query({ prompt: "...", options: { model: "haiku" }  })   // fast, cheapest
query({ prompt: "...", options: { model: "sonnet" } })   // balanced (default)
query({ prompt: "...", options: { model: "opus" }   })   // highest capability
```

The decision rule maps to task class:

| Task class | Tier | Why |
|---|---|---|
| Structured classification, routing, short-form extraction | `haiku` | Deterministic output, no deep reasoning; cost and latency dominate |
| General-purpose agents, code generation, summarization | `sonnet` | Balanced capability and cost; right default for most production workloads |
| Complex multi-step reasoning, architecture review, nuanced judgment | `opus` | Reasoning depth matters more than cost; typically 5–10× the Sonnet price |

Cost discipline compounds faster than most engineers expect. An agent running fifty times per day on Opus costs roughly ten times more than the same agent on Sonnet, with no measurable quality difference on classification or extraction tasks. The right engineering posture is to start on Sonnet, benchmark your specific task class against Haiku, and promote to Opus only when Sonnet's output quality is demonstrably insufficient.

The shorthand tier strings also give you automatic version tracking: when Anthropic promotes a new Haiku or Sonnet checkpoint, `"haiku"` and `"sonnet"` resolve to it automatically. Use a full versioned model ID only when you need to pin a specific checkpoint for eval reproducibility.

<KnowledgeCheck
  question="Your agent reads legal contracts and identifies clause conflicts. You benchmarked Sonnet against a human-reviewed test set: it misses 18% of conflicts. What is the correct next step?"
  options={[
    "Switch to Opus — the task requires multi-step reasoning depth that Sonnet demonstrably cannot provide",
    "Switch to Haiku — legal text is structured, so the cheapest tier should perform just as well",
    "Increase maxTurns — giving Sonnet more agentic turns will eventually catch the missed conflicts",
    "Pin to a specific Sonnet model ID — automatic version promotion must have caused this regression"
  ]}
  correctIdx={0}
  explanation="When a benchmark shows a model tier failing at a target quality bar on a reasoning-heavy task, the correct move is to promote to the next tier. This is exactly the use case for Opus. More turns (maxTurns) helps multi-step task completion but does not improve per-turn reasoning quality. Model drift (automatic version updates) is a separate concern unrelated to a quality gap on the current model."
/>

## Hands-on exercise: weather-summary CLI agent

Build a command-line agent that prints a weather summary for a city, streams tokens to the terminal as they arrive, and exits with code `1` on any API error.

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const city = process.argv[2];
if (!city) {
  console.error("Usage: ts-node weather.ts <city>");
  process.exit(1);
}

(async () => {
  try {
    for await (const msg of query({
      prompt: `Give a concise one-paragraph summary of current and typical June weather in ${city}.`,
      options: {
        model: "haiku",
        allowedTools: ["WebSearch"],
      },
    })) {
      if (msg.type === "assistant") {
        for (const block of msg.message.content) {
          if (block.type === "text") process.stdout.write(block.text);
        }
      }
    }
    process.stdout.write("\n");
  } catch (err) {
    console.error("API error:", err);
    process.exit(1);
  }
})();
```

**Success criteria:**
- `ts-node weather.ts Tokyo` streams a weather paragraph to stdout word-by-word
- Running without an argument exits immediately with code 1 and prints the usage line
- Temporarily unset `ANTHROPIC_API_KEY` — the agent catches the error and exits with code 1
- The `WebSearch` tool allows the agent to retrieve current conditions, not just training-data knowledge

Haiku is the right model here: the task is short-form generation with a fixed structure, latency matters for a CLI, and the WebSearch tool offloads the reasoning-heavy part (finding current data) to the API rather than the model.

Next: [[02-turn-a-prompt-script-into-a-controllable-agent-harness|Chapter 2 — Turn a prompt script into a controllable agent harness]] covers session persistence, environment-driven persona selection, and the configurable harness pattern that every production agent needs before it ships.
