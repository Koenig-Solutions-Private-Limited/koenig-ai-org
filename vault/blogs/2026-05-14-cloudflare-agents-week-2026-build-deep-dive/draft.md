---
date: 2026-05-14
last_updated: 2026-05-14
title: "Build a Cloudflare Agent with Durable Objects, Workers AI, R2, and Vectorize"
slug: "2026-05-14-cloudflare-agents-week-2026-build-deep-dive"
description: "Build a persistent Cloudflare RAG agent by treating Durable Objects, Workers AI, R2, and Vectorize as platform bindings instead of separate services."
seo_description: "Build a persistent Cloudflare RAG agent by treating Durable Objects, Workers AI, R2, and Vectorize as platform bindings instead of separate services."
author: koenig-ai-academy
ticket: KOEA-2099
vendor_tag: community
content_type: article
status: published
reading_time_min: 11
tags:
  - cloudflare-agents
  - durable-objects
  - workers-ai
  - vectorize
  - r2
primary_query: "build Cloudflare AI agent Durable Objects Workers AI Vectorize R2"
contrarian_angle: "Cloudflare's agent stack is not a thinner LangChain host; the important shift is that memory, retrieval, files, scheduling, and realtime transport all collapse into platform bindings on the same Durable Object."
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
  - https://developers.cloudflare.com/workflows/get-started/durable-agents/
whats_new:
  - You can now build a persistent RAG agent on Cloudflare with one Durable Object class, Workers AI embeddings, Vectorize retrieval, and R2 document storage before adding any external database.
learning_objectives:
  - Build the minimal Durable-Object-backed agent shape with Workers AI, R2, and Vectorize bindings.
  - Explain why R2 is for source blobs, Vectorize is for retrieval, and the Agent Durable Object is for interaction state.
  - Identify the limits and pricing gotchas that matter before shipping a production Cloudflare agent.
hero_image: auto:flux
og_image_alt: "A Cloudflare Worker agent graph showing Durable Objects, Workers AI, R2, and Vectorize connected by typed bindings."
schema:
  "@context": "https://schema.org"
  "@type": "Article"
  headline: "Build a Cloudflare Agent with Durable Objects, Workers AI, R2, and Vectorize"
  datePublished: "2026-05-14"
  author:
    "@type": "Organization"
    name: "Koenig AI Academy"
  about:
    - "Cloudflare Agents"
    - "Durable Objects"
    - "Workers AI"
    - "Vectorize"
    - "R2"
faq:
  - question: "What is the fastest way to build a Cloudflare AI agent?"
    answer: "Start from cloudflare/agents-starter, keep one Durable Object per user or session, add Workers AI for model and embedding calls, put source files in R2, and use Vectorize for semantic retrieval."
  - question: "Do Cloudflare Agents need a separate database?"
    answer: "Not for chat state, schedules, WebSockets, or small per-agent state. Each Agent runs on a Durable Object with SQL storage. Use R2 for large blobs and Vectorize for retrieval indexes."
  - question: "What is the main production risk?"
    answer: "The main risk is treating a Durable Object like a horizontally scaled stateless worker. Each object is single-threaded, so high-traffic systems should shard by user, session, tenant, or workflow."
---

# Build a Cloudflare Agent with Durable Objects, Workers AI, R2, and Vectorize

Build the Cloudflare agent as four platform bindings, not as a framework wrapped around five external services: a Durable Object owns the conversation and schedule, Workers AI runs the model and embeddings, R2 stores source documents, and Vectorize retrieves relevant chunks. Cloudflare's Agents docs describe each Agent as a TypeScript class running on a Durable Object with SQL storage, WebSockets, and scheduling; the starter template already uses Workers AI with no external model key ([Cloudflare Agents docs](https://developers.cloudflare.com/agents/), retrieved 2026-05-14).

The missed point from Agents Week is architectural, not cosmetic. Most agent tutorials start with an LLM SDK and bolt on Postgres, Redis, object storage, a vector database, and a queue. Cloudflare starts with a named stateful object and gives it bindings. That inversion changes what you optimize: less glue code, more attention to object boundaries, hibernation, index dimensions, and what belongs in the agent versus the retrieval layer.

Cloudflare's own Agents Week recap frames the release as the "agentic cloud," spanning compute, security, and agent tooling rather than one new SDK ([Agents Week in review](https://blog.cloudflare.com/agents-week-in-review/), retrieved 2026-05-14). That broad launch matters here because the smallest credible build now uses multiple Cloudflare primitives together. An Agent without R2 becomes hard to audit; RAG without Vectorize becomes another hosted database decision; long jobs without Workflows become fragile request handlers.

## Start with one Durable Object per user or session

Use the Agent Durable Object as the interaction boundary because Cloudflare's SDK gives every named agent instance durable SQL storage, realtime client sync, WebSocket handling, and scheduled tasks in one class ([Cloudflare Agents docs](https://developers.cloudflare.com/agents/), retrieved 2026-05-14). The practical rule is simple: one busy person, workspace, tenant, or workflow gets one named object. Do not put all users into one global agent.

Start from the official template, then strip it down:

```bash
npx create-cloudflare@latest --template cloudflare/agents-starter
cd agents-starter
npm install
npm run dev
```

The starter repository is intentionally broad: chat, tools, vision, scheduling, and approval examples are already wired for Cloudflare's agent runtime ([cloudflare/agents-starter](https://github.com/cloudflare/agents-starter), retrieved 2026-05-14). For a RAG agent, keep the chat lifecycle and replace demo tools with one retrieval tool.

```toml
# wrangler.toml
name = "rag-agent"
main = "src/index.ts"
compatibility_date = "2026-05-14"

[ai]
binding = "AI"

[[r2_buckets]]
binding = "DOCS"
bucket_name = "agent-docs"

[[vectorize]]
binding = "VECTORIZE"
index_name = "agent-rag"

[[durable_objects.bindings]]
name = "CHAT_AGENT"
class_name = "ChatAgent"

[[migrations]]
tag = "v1"
new_sqlite_classes = ["ChatAgent"]
```

That file is the real architecture diagram. The agent has one local state boundary (`CHAT_AGENT`), one model binding (`AI`), one blob store (`DOCS`), and one semantic index (`VECTORIZE`). Everything else is TypeScript. If you are coming from hosted SDK design, the shift is from framework-managed [[glossary/agent-orchestration|agent orchestration]] to platform-managed bindings.

<KnowledgeCheck
  question="Why is the Durable Object binding the right boundary for a Cloudflare chat agent?"
  options={[
    "It lets all users share one global SQL database for lower latency",
    "It gives each named agent instance durable state, WebSockets, and scheduling behind one routing key",
    "It replaces Workers AI so no model binding is needed",
    "It makes Vectorize dimensions mutable after index creation"
  ]}
  correct={1}
  explanation="The Durable Object-backed Agent is the named stateful boundary. It keeps session state, realtime connections, and scheduled work together while the other bindings handle models, blobs, and retrieval."
/>

## Put chat state in the Agent, source files in R2, and chunks in Vectorize

Separate state by access pattern. The Agent Durable Object should keep conversation messages, per-user settings, scheduled work, and small [[glossary/agent-memory|agent memory]] that must follow the live session. R2 should keep full source documents and generated artifacts because Cloudflare positions R2 for large unstructured data with no egress bandwidth fees ([R2 pricing](https://developers.cloudflare.com/r2/pricing/), retrieved 2026-05-14). Vectorize should keep only embedding vectors plus retrieval metadata.

Here is the minimal environment surface:

```ts
// src/env.ts
export interface Env {
  AI: Ai;
  DOCS: R2Bucket;
  VECTORIZE: VectorizeIndex;
  CHAT_AGENT: DurableObjectNamespace;
}
```

The ingestion path is intentionally boring: store the original file, split it, embed chunks, then upsert vectors.

```ts
// src/ingest.ts
type Chunk = { id: string; text: string; sourceKey: string };

export async function ingestDocument(
  env: Env,
  key: string,
  text: string,
  ownerId: string
) {
  await env.DOCS.put(key, text, {
    httpMetadata: { contentType: "text/plain" },
    customMetadata: { ownerId },
  });

  const chunks = chunkText(text, key);
  const embedded = await env.AI.run("@cf/baai/bge-base-en-v1.5", {
    text: chunks.map((chunk) => chunk.text),
  });

  await env.VECTORIZE.upsert(
    chunks.map((chunk, index) => ({
      id: chunk.id,
      values: embedded.data[index],
      namespace: ownerId,
      metadata: {
        text: chunk.text,
        sourceKey: chunk.sourceKey,
      },
    }))
  );

  return { chunks: chunks.length };
}

function chunkText(text: string, sourceKey: string): Chunk[] {
  const paragraphs = text.split(/\n{2,}/).filter(Boolean);
  return paragraphs.map((paragraph, index) => ({
    id: `${sourceKey}:${index}`,
    sourceKey,
    text: paragraph.slice(0, 1800),
  }));
}
```

Cloudflare's Vectorize embeddings tutorial calls out the important compatibility detail: when using `@cf/baai/bge-base-en-v1.5`, create the Vectorize index with 768 dimensions ([Vectorize embeddings guide](https://developers.cloudflare.com/vectorize/get-started/embeddings/), retrieved 2026-05-14). Create it once:

```bash
wrangler vectorize create agent-rag --dimensions=768 --metric=cosine
```

The dimension choice is not a formatting detail. Vector index dimensions and metric are part of the storage layout, so changing embedding models later usually means rebuilding the index. Pick the embedding model before you ingest production documents.

## Expose retrieval as one tool, not a second agent loop

Make retrieval a tool called by the chat agent because Workers AI and Vectorize already sit behind bindings. The tool embeds the user's query, searches the user's namespace, and returns short grounded context. Vectorize's documented limits include large paid-plan index counts and up to 10 million vectors per index, but the retrieval shape still works best when each query asks for a small top-K result set ([Vectorize limits](https://developers.cloudflare.com/vectorize/platform/limits/), retrieved 2026-05-14).

```ts
// src/rag-tool.ts
import { tool } from "ai";
import { z } from "zod";

export function buildRagTool(env: Env, ownerId: string) {
  return tool({
    description: "Search this user's uploaded documents for relevant context.",
    parameters: z.object({
      query: z.string().min(3),
    }),
    execute: async ({ query }) => {
      const embedded = await env.AI.run("@cf/baai/bge-base-en-v1.5", {
        text: [query],
      });

      const results = await env.VECTORIZE.query(embedded.data[0], {
        namespace: ownerId,
        topK: 5,
        returnMetadata: "all",
      });

      return results.matches
        .map((match, index) => {
          const text = String(match.metadata?.text ?? "");
          const source = String(match.metadata?.sourceKey ?? "unknown");
          return `[${index + 1}] ${source}\n${text}`;
        })
        .join("\n\n");
    },
  });
}
```

Now wire that tool into the chat agent:

```ts
// src/agent.ts
import { AIChatAgent } from "agents";
import { createWorkersAI } from "workers-ai-provider";
import { convertToModelMessages, streamText } from "ai";
import { buildRagTool } from "./rag-tool";

export class ChatAgent extends AIChatAgent<Env> {
  async onChatMessage() {
    const workersai = createWorkersAI({ binding: this.env.AI });
    const ownerId = this.name;

    const result = streamText({
      model: workersai("@cf/zai-org/glm-4.7-flash"),
      messages: await convertToModelMessages(this.messages),
      tools: {
        searchDocs: buildRagTool(this.env, ownerId),
      },
      system:
        "Answer from retrieved context when available. If context is missing, say what file the user should upload next.",
    });

    return result.toUIMessageStreamResponse();
  }
}
```

The answer-first design is deliberate: the agent handles conversation and tool orchestration; Vectorize handles recall; R2 remains the recoverable source of truth. When retrieval looks wrong, you can re-embed from R2 without trying to reconstruct lost text from vector metadata.

## Route requests by stable names, then let Agents hibernate

Route each user or workspace to a stable Durable Object name because Cloudflare's Agent model is named-instance based: a request wakes the instance, the instance reads durable state, does work, and hibernates when idle ([Cloudflare Agents docs](https://developers.cloudflare.com/agents/), retrieved 2026-05-14). This is where Cloudflare's model departs from normal stateless Workers.

```ts
// src/index.ts
export { ChatAgent } from "./agent";

export default {
  async fetch(request: Request, env: Env) {
    const url = new URL(request.url);
    const ownerId = url.searchParams.get("owner") ?? "demo";

    if (url.pathname === "/ingest" && request.method === "POST") {
      const text = await request.text();
      const key = `${ownerId}/${crypto.randomUUID()}.txt`;
      const { ingestDocument } = await import("./ingest");
      return Response.json(await ingestDocument(env, key, text, ownerId));
    }

    const id = env.CHAT_AGENT.idFromName(ownerId);
    const stub = env.CHAT_AGENT.get(id);
    return stub.fetch(request);
  },
};
```

The production caveat is single-threading. Durable Objects are excellent session coordinators, but each object is still an ordered execution point. Cloudflare's Agents limits page describes large account-level scale and a 30-second CPU-time budget that refreshes when an Agent receives a new HTTP request ([Agents limits](https://developers.cloudflare.com/agents/platform/limits/), retrieved 2026-05-14). That points to the correct shard key: user, workspace, document, or workflow, not "the application."

Cost depends on hibernation. Durable Object pricing charges requests, storage, and duration; the pricing docs state that duration applies while JavaScript is actively executing or while the object is idle but not eligible for hibernation ([Durable Objects pricing](https://developers.cloudflare.com/durable-objects/platform/pricing/), retrieved 2026-05-14). For chat, hibernate WebSockets and avoid background timers that keep the isolate hot.

<KnowledgeCheck
  question="What is the correct shard key for a production Cloudflare Agent?"
  options={[
    "One Durable Object for the entire application",
    "A stable user, workspace, document, tenant, or workflow identity",
    "A random ID on every request so state never persists",
    "The Vectorize index name"
  ]}
  correct={1}
  explanation="Durable Objects are stateful and single-threaded, so production systems should route by a stable identity boundary such as user, workspace, tenant, document, or workflow."
/>

## Know the limits before you turn this into a product

The build is small, but the product constraints are real. Workers AI pricing is neuron-based with a daily free allocation and model-specific rates ([Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/), retrieved 2026-05-14). Vectorize has explicit index, vector, metadata, and top-K limits ([Vectorize limits](https://developers.cloudflare.com/vectorize/platform/limits/), retrieved 2026-05-14). Durable Objects have CPU, storage, and duration rules. R2 has cheap storage but Class A write costs.

The clean operating model looks like this:

| Layer | Store here | Avoid |
|---|---|---|
| Agent Durable Object | messages, session state, schedules, approvals | raw PDFs, high-churn document blobs |
| R2 | uploaded documents, generated files, artifacts | per-message state that must sync live |
| Vectorize | embeddings, source keys, short chunk metadata | full canonical document copies |
| Workers AI | inference and embeddings | business state or audit records |

For multi-step jobs that run longer than a chat request, add Workflows instead of stretching one Agent method forever. Cloudflare's durable-agent workflow guide shows an Agent paired with Workflows so long-running research steps can checkpoint, retry, and stream progress back to the UI ([Workflows durable agents guide](https://developers.cloudflare.com/workflows/get-started/durable-agents/), retrieved 2026-05-14).

A useful rough cost model is per interaction, not per agent. A message that retrieves context pays for one Agent request, one embedding call, one Vectorize query, one chat completion, and any R2 read if you fetch canonical source text. Idle sessions should not dominate the bill if WebSocket hibernation is configured correctly; active model calls will. That makes observability straightforward: log request count, model selection, prompt tokens, embedding count, Vectorize dimensions queried, and R2 Class A/Class B operations.

The main engineering trap is overusing the Durable Object database because it feels convenient. Keep audit records and canonical content out of the chat object unless they must participate in realtime state. Agent SQL is excellent for messages, tool approvals, and small per-session memory. R2 is better for replayable artifacts. Vectorize is better for fuzzy recall. Workflows are better for work that should survive deploys and external outages.

Test the pipeline in three passes before trusting the chat answer. First, call `/ingest` with a tiny text fixture and confirm the returned chunk count matches your splitter. Second, issue a query whose answer appears verbatim in one chunk and log the Vectorize match IDs before the model sees them. Third, ask the chat agent the same question and require it to cite the source key returned by the retrieval tool. That isolates ingestion bugs from retrieval bugs from model-grounding bugs.

The same separation helps when you add auth. The route handler should authenticate the user and derive `ownerId`; the Durable Object name, R2 key prefix, and Vectorize namespace should all come from that same identity boundary. If those three diverge, you have built a cross-tenant retrieval bug. Cloudflare's platform makes the primitives cheap to compose, but it does not remove the need for one clear tenancy key across storage, retrieval, and chat routing. That is the same boundary discipline we teach in [[course/ai-agent-security-for-developers|AI Agent Security for Developers]].

For production, add two boring controls early: a maximum document size before R2 upload and a maximum number of chunks per ingestion call. Without those limits, one bad upload can create a large embedding bill or a noisy namespace that degrades retrieval for the user. The Agent should also store the ingestion status in its own state so the UI can say "indexed 12 chunks" instead of letting users infer freshness from answer quality.

<curl>
curl -X POST "https://rag-agent.example.workers.dev/ingest?owner=acme" \
  -H "content-type: text/plain" \
  --data-binary @handbook.txt

# expected output
{"chunks":12}
</curl>

This is the smallest useful production shape: upload to R2, embed with Workers AI, retrieve from Vectorize, answer through the Agent. It is not the only shape, but it keeps every piece replaceable. You can swap the chat model through AI Gateway later, rebuild the vector index later, or move large document processing into Workflows without changing the user-facing agent identity.

<KnowledgeCheck
  question="Why should full documents live in R2 while only chunks and source keys live in Vectorize?"
  options={[
    "Vectorize cannot store metadata at all",
    "R2 is the recoverable source of truth, while Vectorize is an index optimized for semantic lookup",
    "Durable Objects cannot read from R2",
    "Workers AI requires all prompts to be stored in R2 before inference"
  ]}
  correct={1}
  explanation="R2 stores the canonical document cheaply and recoverably. Vectorize should store embeddings plus enough metadata to retrieve and cite chunks; if embeddings change, rebuild the index from R2."
/>

If you want to build the rest of this pattern into deployable agent workflows, the natural next step is [[course/multi-agent-orchestration-a2a]], where we connect stateful agents, tool calls, handoffs, and production control-plane design.

## Sources

1. Cloudflare Agents docs — https://developers.cloudflare.com/agents/ · retrieved 2026-05-14
2. Cloudflare Agents Week in review — https://blog.cloudflare.com/agents-week-in-review/ · retrieved 2026-05-14
3. Vectorize and Workers AI embeddings guide — https://developers.cloudflare.com/vectorize/get-started/embeddings/ · retrieved 2026-05-14
4. Cloudflare Durable Objects pricing — https://developers.cloudflare.com/durable-objects/platform/pricing/ · retrieved 2026-05-14
5. Cloudflare Agents limits — https://developers.cloudflare.com/agents/platform/limits/ · retrieved 2026-05-14
6. Cloudflare Vectorize limits — https://developers.cloudflare.com/vectorize/platform/limits/ · retrieved 2026-05-14
7. Cloudflare R2 pricing — https://developers.cloudflare.com/r2/pricing/ · retrieved 2026-05-14
8. Cloudflare Workers AI pricing — https://developers.cloudflare.com/workers-ai/platform/pricing/ · retrieved 2026-05-14
9. cloudflare/agents-starter — https://github.com/cloudflare/agents-starter · retrieved 2026-05-14
10. Cloudflare Workflows durable agents guide — https://developers.cloudflare.com/workflows/get-started/durable-agents/ · retrieved 2026-05-14
