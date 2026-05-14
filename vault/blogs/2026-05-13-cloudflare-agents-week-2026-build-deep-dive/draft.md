---
date: 2026-05-13
title: "Build Production AI Agents on Cloudflare: What Agents Week Actually Shipped"
slug: "2026-05-13-cloudflare-agents-week-2026-build-deep-dive"
description: "A practical deep dive into Cloudflare's Agents Week 2026 stack — Durable Objects, Workers AI, Vectorize, and R2 — with real code, cost math, and production limits for full-stack developers building edge-native AI agents."
author: blog-author
ticket: KOEA-1748
vendor_tag: community
content_type: article
status: published
reading_time_min: 7
tags:
  - cloudflare
  - durable-objects
  - workers-ai
  - vectorize
  - ai-agents
  - edge-computing
  - rag
primary_query: "build ai agents cloudflare durable objects workers ai vectorize 2026"
contrarian_angle: "The cost math on Cloudflare's edge-agent stack hasn't been widely run — and once you do the numbers, it's hard to justify a managed cloud stack for most agentic workloads"
faq:
  - q: "What is the Cloudflare Agents SDK?"
    a: "The Agents SDK is a TypeScript library that wraps Durable Objects to give each AI agent instance its own persistent SQLite database, WebSocket connections, and task scheduler. You extend AIChatAgent and deploy it like a normal Worker."
  - q: "How much does it cost to run a Cloudflare AI agent for 1,000 concurrent users?"
    a: "Based on published Cloudflare pricing for Durable Objects, Workers AI (Llama 3.1-8B), and Vectorize, a 1,000-user concurrent agent sending 10 messages/day costs roughly $4–6/month with WebSocket hibernation enabled."
  - q: "What CPU limits apply to Cloudflare Durable Object agents?"
    a: "Each agent gets 30 seconds of CPU time per request by default, which resets on every new HTTP request or WebSocket message. The configurable maximum is 5 minutes per request on paid plans."
sources:
  - https://developers.cloudflare.com/agents/
  - https://blog.cloudflare.com/agents-week-in-review/
  - https://developers.cloudflare.com/vectorize/get-started/embeddings/
  - https://developers.cloudflare.com/durable-objects/platform/pricing/
  - https://developers.cloudflare.com/agents/platform/limits/
  - https://developers.cloudflare.com/vectorize/platform/limits/
  - https://developers.cloudflare.com/r2/pricing/
  - https://developers.cloudflare.com/workers-ai/platform/pricing/
  - https://github.com/cloudflare/agents-starter
  - https://blog.cloudflare.com/durable-object-facets-dynamic-workers/
  - https://developers.cloudflare.com/workflows/get-started/durable-agents/
  - https://developers.cloudflare.com/durable-objects/platform/limits/
whats_new:
  - Cloudflare Agents Week shipped a complete edge-native AI agent stack — DO-backed stateful agents, Vectorize RAG, R2 artifacts, Sandboxes GA — and 1,000 concurrent users costs under $10/mo based on published pricing
learning_objectives:
  - Understand how the Agents SDK maps TypeScript classes to Durable Objects for per-user persistent state
  - Wire a full RAG pipeline using Workers AI embeddings, Vectorize, and R2 with real wrangler.toml bindings
  - Know the compute and cost limits before shipping an agent to production
---

# Build Production AI Agents on Cloudflare: What Agents Week Actually Shipped

Cloudflare's Agents Week (May 2026) shipped a complete edge-native AI stack in a single week: stateful TypeScript agents, vector search, R2-backed artifact storage, and Sandboxes GA. If you read the [[cloudflare-agents-week-2026-explained|week-one overview]], this post goes deeper on the APIs, sharp edges, and pricing.

The non-obvious angle: based on the published pricing below, this stack is one of the lowest-cost options for stateful AI agents at realistic user volumes. A 1,000-user concurrent agent running on Durable Objects + Workers AI + Vectorize costs roughly **$4–6/month** — before you've stood up a database, a cache layer, or paid for egress.[^1]

## The Agents SDK Is Just a Durable Objects Wrapper — and That's the Point

The [Agents SDK](https://developers.cloudflare.com/agents/) (retrieved 2026-05-12) gives you a TypeScript class that compiles down to a Durable Object. Each instance is a stateful micro-server with its own SQLite database, WebSocket connections, and alarm scheduler:

```ts
// excerpt — ragTool and scheduleTool defined separately; full scaffold at agents-starter
import { AIChatAgent } from 'agents';
import { streamText } from 'ai';
import type { Message } from '@ai-sdk/ui-utils';
import type { Env } from './types';

export class ChatAgent extends AIChatAgent<Env> {
  async onChatMessage(msg: Message) {
    return streamText({
      model: this.env.AI,
      messages: this.messages,
      tools: { ragTool: buildRagTool(this.env), scheduleTool },
    });
  }
}
```

Route HTTP/WebSocket to a specific user's agent instance via `env.CHAT_AGENT.get(idFromName('user-123'))`. That instance persists indefinitely — messages, tool state, scheduled tasks — without a separate database.

The `useAgent` React hook syncs frontend state over WebSockets in real time. The starter template (`npx create-cloudflare@latest --template cloudflare/agents-starter`) wires weather lookup, timezone detection, image vision, and approval-gated calculations out of the box.[^2]

**Not a hosted LLM service**: the SDK manages state, routing, and scheduling; bring your own model via Workers AI or AI Gateway.

## Compute Limits That Will Bite You in Production

[Per the platform limits docs](https://developers.cloudflare.com/agents/platform/limits/) (retrieved 2026-05-12), each agent gets 30 seconds of CPU time per request — but that resets on every new HTTP request or WebSocket message. For long-running reasoning loops this works fine; for a single synchronous chain that runs longer than 30 CPU-seconds, it doesn't.

The harder constraint: Durable Objects are single-threaded. Under high message frequency you can saturate a single instance. Design for one DO per user/session, not one DO per application.[^3]

Storage is 10 GB per object (paid plan), with reads at $0.001/M rows and writes at $1/M rows. The [DO pricing page](https://developers.cloudflare.com/durable-objects/platform/pricing/) (retrieved 2026-05-12) lists duration charges at $12.50/M GB-seconds — which sounds alarming until you enable WebSocket hibernation. Hibernation drops idle cost to near zero; without it, an idle agent burns duration at the full rate.

```toml
# wrangler.toml — essential for cost control
[[durable_objects.bindings]]
name = "CHAT_AGENT"
class_name = "ChatAgent"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["ChatAgent"]
```

## [[glossary/rag|RAG]] in Six Lines: Workers AI + Vectorize

[Vectorize](https://developers.cloudflare.com/vectorize/get-started/embeddings/) (retrieved 2026-05-12) is Cloudflare's vector database, and it composes cleanly with Workers AI embeddings. Create an index:

```bash
wrangler vectorize create rag-index --dimensions=768 --metric=cosine
```

Bind it in `wrangler.toml`, then define the RAG tool as a complete, importable module:

```ts
// rag-tool.ts — runnable as-is; wire bindings in wrangler.toml below
import { tool } from 'ai';
import { z } from 'zod';

export interface Env {
  AI: Ai;
  VECTORIZE: VectorizeIndex;
}

export function buildRagTool(env: Env) {
  return tool({
    description: 'Retrieve relevant context from the knowledge base',
    parameters: z.object({ query: z.string() }),
    execute: async ({ query }) => {
      const embedded = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
        text: [query],
      });
      const results = await env.VECTORIZE.query(embedded.data[0], {
        topK: 3,
        returnMetadata: 'all',
      });
      return results.matches.map(m => m.metadata?.text ?? '').join('\n');
    },
  });
}
```

Add the corresponding bindings to `wrangler.toml`:

```toml
[ai]
binding = "AI"

[[vectorize]]
binding = "VECTORIZE"
index_name = "rag-index"
```

The `@cf/baai/bge-base-en-v1.5` model outputs 768-dimensional vectors and runs entirely within Workers AI — no external API key required.[^4] [Vectorize platform limits](https://developers.cloudflare.com/vectorize/platform/limits/) (retrieved 2026-05-12): 50,000 indexes on the paid plan, 10M vectors per index, topK capped at 50 when metadata filters are active.

Pricing: $0.01/M queried dimensions + $0.05/100M stored dimensions. For a 50,000-document knowledge base queried 100,000 times/day, that's under $5/month.

**One immutable constraint**: dimensions and distance metric are set at index creation time. You cannot change them without deleting and rebuilding the index. Plan your embedding model choice before production ingestion.

## R2 as the Agent's File System

[R2](https://developers.cloudflare.com/r2/pricing/) (retrieved 2026-05-12) handles everything too large for SQLite: raw documents, image uploads, generated artifacts, and the Git repos backing Cloudflare Sandboxes. Zero egress fees make it the practical choice for agent outputs users need to download.

The Agents Week `Artifacts` feature stores agent-generated files on R2 and surfaces them with preview links. Sandboxes GA — each agent gets a persistent isolated computer with shell and filesystem — is also R2-backed.[^5]

In your own pipeline: `env.MY_BUCKET.put('doc-123.txt', text)` stores a document; retrieve it, chunk it into ~500-token passages, embed each chunk via Workers AI, and upsert to Vectorize. That's the full [[glossary/rag|RAG]] ingestion pipeline without leaving Cloudflare's network.

Standard storage is $0.015/GB-month after the free 10 GB tier. Class A write operations (PUT/POST) are $4.50/M after the free 1M/month — the one cost to watch for high-churn agent state, which is better kept in DO SQLite.

## Durable Object Facets: Dynamic Code Loading (Beta)

The least-covered Agents Week drop is [Facets](https://blog.cloudflare.com/durable-object-facets-dynamic-workers/) (retrieved 2026-05-12): each Durable Object can now spawn child objects with isolated SQLite databases and dynamically loaded code.

```ts
const child = ctx.facets.get('sub-agent', () => loader.get(codeId));
```

The practical use case: agent runtimes where tool implementations are user-defined or AI-generated. The supervisor DO orchestrates; each Facet executes code in isolation with its own storage. This is still beta — don't ship it as a load-bearing production primitive yet — but it closes the gap for fully dynamic agent graphs.

## Durable Workflows: Checkpointed Multi-Step Agents

For agents that span hours or days — research pipelines, approval workflows, batch jobs — [Cloudflare Workflows](https://developers.cloudflare.com/workflows/get-started/durable-agents/) (retrieved 2026-05-12) checkpoints every step:[^6]

```ts
class ResearchWorkflow extends AgentWorkflow {
  async run(event: WorkflowEvent, step: WorkflowStep) {
    const result = await step.do('llm-call', () =>
      client.messages.create({ model: 'claude-opus-4-7', tools })
    );
    await step.waitForEvent('human-approval', { timeout: '24h' });
  }
}
```

Steps have unlimited wall-clock time. The workflow survives process crashes, deploys, and network failures. Concurrency cap: 50,000 simultaneous workflows on paid plans.

## The Cost Math Nobody Is Doing

For 1,000 concurrent users sending 10 messages/day, calculated from published Cloudflare pricing:

| Component | Basis | Cost/month |
|---|---|---|
| DO requests (10M/mo) | $0.15/M | $1.50 |
| DO duration (hibernated) | ~$12.50/M GB-s | ~$0.10 |
| Workers AI (Llama 3.1-8B) | $0.045/M in-tokens | ~$2–4 |
| Vectorize queries (10M dims) | $0.01/M dims | $0.10 |
| R2 storage (10 GB) | free tier | $0.00 |
| **Total** | | **~$4–6/mo** |

[Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/) (retrieved 2026-05-12): $0.011 per 1,000 Neurons with 10,000 free daily. Llama 3.1-8B runs approximately $0.045/M input tokens. Larger models (Qwen, Mixtral variants) cost significantly more — model selection should track task requirements, not benchmarks.

For context on how this compares to managed SDK alternatives, see [[2026-04-30-vercel-ai-sdk-6-vs-claude-agent-sdk|Vercel AI SDK 6 vs Claude Agent SDK]]. The Cloudflare stack trades a managed LLM API + Postgres + Redis + S3 + egress for the 30-second CPU limit and single-threaded DO execution model — both are solvable with architecture, not additional spend.

## Start Here

```bash
npx create-cloudflare@latest --template cloudflare/agents-starter
```

The [agents-starter](https://github.com/cloudflare/agents-starter) (retrieved 2026-05-12) includes WebSocket state sync, tool use with approval flows, vision via `@cf/llava-hf/llava-1.5-7b`, and task scheduling. Wire in Vectorize bindings and you have a full [[glossary/rag|RAG]] agent in under 200 lines.

<KnowledgeCheck
  question="What happens to Durable Object duration billing when WebSocket hibernation is disabled?"
  options={[
    "Billing pauses when there are no active WebSocket connections",
    "The DO is billed for duration even when idle between messages",
    "Duration billing only applies during HTTP requests, not WebSocket connections",
    "Idle DOs are automatically evicted after 30 seconds"
  ]}
  correct={1}
  explanation="Without hibernation, a Durable Object incurs duration charges even when idle between WebSocket messages. Enabling WebSocketHibernation drops idle cost to near zero by suspending the isolate between messages."
/>

If you're building production AI agents and haven't looked at Cloudflare's stack since 2024, Agents Week is the inflection point worth reviewing. For a deeper look at how [[glossary/durable-objects|Durable Objects]] compose with multi-agent orchestration patterns, the Koenig AI Academy covers that in the [[courses/multi-agent-orchestration-a2a|Multi-Agent Orchestration]] course.

[^1]: Cost estimate derived from: [Durable Objects pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/) (retrieved 2026-05-12), [Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/) (retrieved 2026-05-12), and [Vectorize limits](https://developers.cloudflare.com/vectorize/platform/limits/) (retrieved 2026-05-12). Assumes hibernation enabled, Llama 3.1-8B, 10 msgs/user/day.
[^2]: [agents-starter GitHub repository](https://github.com/cloudflare/agents-starter), retrieved 2026-05-12.
[^3]: [Durable Objects platform limits](https://developers.cloudflare.com/durable-objects/platform/limits/): 10 GB storage/object, 30s CPU default, 5m CPU max on paid plans, retrieved 2026-05-12.
[^4]: [Vectorize embeddings quickstart](https://developers.cloudflare.com/vectorize/get-started/embeddings/), retrieved 2026-05-12. Dimensions must be set to 768 for `@cf/baai/bge-base-en-v1.5`.
[^5]: [Agents Week in review](https://blog.cloudflare.com/agents-week-in-review/), retrieved 2026-05-12. Covers Sandboxes GA, Artifacts, and persistent compute environments.
[^6]: [Cloudflare Workflows durable agents guide](https://developers.cloudflare.com/workflows/get-started/durable-agents/), retrieved 2026-05-12. Includes GitHub repo research agent example with real-time progress via Agents SDK.
