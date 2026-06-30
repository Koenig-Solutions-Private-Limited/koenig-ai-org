# Chapter 1 Code: Hello World Agents

Code examples for **Chapter 1: The Agent SDK & Responses API Model** of the [OpenAI Agents SDK Mastery](../outline.md) course.

## Files

| File | Language | What it demonstrates |
|---|---|---|
| `hello_agent.py` | Python 3.10+ | Basic agent, tool-calling loop, multi-turn conversation |
| `hello_agent.ts` | TypeScript / Node 18+ | Same three examples in TypeScript |

## Prerequisites

**Python:**
```bash
pip install openai-agents python-dotenv
```

**TypeScript:**
```bash
npm install @openai/agents dotenv zod
npm install -D typescript ts-node @types/node
```

## API Key Setup

Create a `.env` file in this directory (never commit it):

```bash
echo "OPENAI_API_KEY=sk-..." > .env
```

Or export it in your shell:

```bash
export OPENAI_API_KEY="sk-..."
```

## Running the Examples

**Python:**
```bash
python hello_agent.py
```

**TypeScript:**
```bash
npx ts-node hello_agent.ts
```

Expected output (paraphrased):
```
── Basic Hello World ──────────────────────────────────
The OpenAI Agents SDK handles the multi-turn loop, tool dispatch, and
handoffs so you build business logic instead of plumbing.

── Tool-Calling Agent ─────────────────────────────────
You are running openai-agents 0.0.x and Python 3.11.x.

── Multi-Turn Conversation ────────────────────────────
Turn 1: The Responses API is OpenAI's new HTTP primitive for agent workflows...
Turn 2: Unlike Chat Completions, the Responses API supports built-in tools...
```

## What Each Example Shows

### Basic Hello World
A single `Agent` + `Runner.run()` call. No tools. Demonstrates the minimum viable agent configuration.

### Tool-Calling Agent
Adds two `@function_tool` decorators (Python) or `tool()` calls (TypeScript). The agent loop: model calls the tool → SDK dispatches it → result injected → model produces final answer.

### Multi-Turn Conversation
Uses `result.to_input_list()` (Python) / `result.toInputList()` (TypeScript) to continue a conversation across multiple `Runner.run()` calls. Shows how context accumulates in the response chain.

## Next Steps

Continue to [Chapter 2: Tool Orchestration & Pydantic Safety](../ch02-tool-orchestration/) to build type-safe tool definitions with structured output validation.
