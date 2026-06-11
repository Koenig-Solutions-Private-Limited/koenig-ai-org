/**
 * Chapter 1: Hello World agent using the OpenAI Agents SDK (TypeScript)
 *
 * Requirements:
 *   npm install @openai/agents dotenv
 *   npm install -D typescript ts-node @types/node
 *
 * Usage:
 *   export OPENAI_API_KEY="sk-..."
 *   npx ts-node hello_agent.ts
 *
 *   # Or with a .env file:
 *   echo "OPENAI_API_KEY=sk-..." > .env
 *   npx ts-node hello_agent.ts
 */

import * as dotenv from "dotenv";
dotenv.config();

import { Agent, run, tool } from "@openai/agents";
import { execSync } from "child_process";
import { z } from "zod";

// ── Validate Environment ─────────────────────────────────────────────────────

if (!process.env.OPENAI_API_KEY) {
  throw new Error(
    "OPENAI_API_KEY is not set. Export it or add it to a .env file."
  );
}

// ── Basic Hello World ────────────────────────────────────────────────────────

const basicAgent = new Agent({
  name: "Academy Guide",
  instructions:
    "You are a concise technical guide for the Koenig AI Academy. " +
    "Answer questions about AI agents clearly and in plain language. " +
    "Keep answers to 2-3 sentences unless more detail is requested.",
  model: "gpt-4.1",
});

async function runBasicExample(): Promise<void> {
  console.log("── Basic Hello World ──────────────────────────────────");
  const result = await run(
    basicAgent,
    "In one sentence: what problem does the OpenAI Agents SDK solve?"
  );
  console.log(result.finalOutput);
  console.log();
}

// ── Tool-Calling Agent ───────────────────────────────────────────────────────

const getSdkVersion = tool({
  name: "get_sdk_version",
  description: "Returns the currently installed @openai/agents package version.",
  parameters: z.object({}),
  execute: async () => {
    try {
      const output = execSync("npm list @openai/agents --depth=0 2>/dev/null").toString();
      const match = output.match(/@openai\/agents@([\d.]+)/);
      return match ? match[1] : "version not found";
    } catch {
      return "@openai/agents package not found — is it installed?";
    }
  },
});

const getNodeVersion = tool({
  name: "get_node_version",
  description: "Returns the current Node.js version.",
  parameters: z.object({}),
  execute: async () => process.version,
});

const toolAgent = new Agent({
  name: "System Assistant",
  instructions:
    "You are a helpful system assistant. " +
    "When asked about SDK or Node.js versions, always use the provided tools " +
    "to retrieve the real values rather than guessing.",
  model: "gpt-4.1",
  tools: [getSdkVersion, getNodeVersion],
});

async function runToolExample(): Promise<void> {
  console.log("── Tool-Calling Agent ─────────────────────────────────");
  const result = await run(
    toolAgent,
    "What version of the Agents SDK am I running, and what Node.js version is this?",
    { maxTurns: 5 } // safety guard — never omit in production
  );
  console.log(result.finalOutput);
  console.log();
}

// ── Multi-Turn Conversation ──────────────────────────────────────────────────

async function runMultiTurnExample(): Promise<void> {
  console.log("── Multi-Turn Conversation ────────────────────────────");

  const conversationAgent = new Agent({
    name: "Responses API Expert",
    instructions:
      "You are an expert on the OpenAI Responses API. " +
      "Answer questions concisely and build on previous answers.",
    model: "gpt-4.1",
  });

  // Turn 1
  const result1 = await run(conversationAgent, "What is the Responses API?");
  console.log(`Turn 1: ${result1.finalOutput}\n`);

  // Turn 2 — pass result1.toInputList() to continue the conversation
  const result2 = await run(
    conversationAgent,
    [
      ...result1.toInputList(),
      { role: "user" as const, content: "How does it differ from Chat Completions?" },
    ]
  );
  console.log(`Turn 2: ${result2.finalOutput}\n`);
}

// ── Entry Point ──────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  await runBasicExample();
  await runToolExample();
  await runMultiTurnExample();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
