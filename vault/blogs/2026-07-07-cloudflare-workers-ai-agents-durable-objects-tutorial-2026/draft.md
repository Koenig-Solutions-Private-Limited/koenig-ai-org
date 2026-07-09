---
date: 2026-07-07
title: "Build a Cloudflare Workers AI Agent with Durable Objects in 2026"
description: "Step-by-step tutorial for building a stateful Cloudflare Workers AI agent with Durable Objects, platform bindings, MCP transport, observability, and production pricing checks."
author: blog-author
ticket: KOEA-10374
parent_issue: KOEA-10190
vendor_tag: community
content_type: article
status: awaiting-g0
reading_time_min: 8
slug: 2026-07-07-cloudflare-workers-ai-agents-durable-objects-tutorial-2026
tags:
  - cloudflare
  - workers
  - durable-objects
  - ai-agents
  - mcp
  - tutorial
source_research: vault/research/community/cloudflare-workers-ai-agents-durable-objects-tutorial-2026.md
primary_query: "Cloudflare Workers AI agents tutorial Durable Objects"
first_60_words_answer: "Build a Cloudflare Workers AI agent by extending the Agents SDK, binding it to a Durable Object, storing per-user state in the object's SQLite-backed storage, and deploying with Wrangler. Durable Objects matter because each agent becomes an addressable actor with persistent state, WebSocket support, alarms, and hibernation-aware billing instead of a stateless function plus external database."
contrarian_angle: "The real tutorial is not 'call an LLM from a Worker.' It is learning when Durable Objects should own agent state, when bindings should replace HTTP tools, and where Cloudflare's agent stack still needs explicit observability before production."
positions:
  - id: cloudflare-workers-edge-first
    engagement: defends
  - id: edge-native-ai-beats-centralized-cloud
    engagement: defends
  - id: platform-bindings-beat-http-tools
    engagement: refines
  - id: ai-gateway-beats-third-party-observability
    engagement: refines
sources:
  - https://developers.cloudflare.com/agents/
  - https://blog.cloudflare.com/project-think
  - https://developers.cloudflare.com/durable-objects/
  - https://developers.cloudflare.com/workers/platform/pricing/
  - https://developers.cloudflare.com/changelog/post/2026-02-25-agents-sdk-v060/
  - https://blog.cloudflare.com/agents-platform-flue-sdk/
  - https://blog.cloudflare.com/code-mode/
  - https://developers.cloudflare.com/workers/best-practices/workers-best-practices/
  - https://developers.cloudflare.com/workers-ai/platform/pricing/
  - https://developers.cloudflare.com/r2/pricing/
  - https://developers.cloudflare.com/ai-gateway/
faq:
  - question: "Do Cloudflare Workers AI agents need Durable Objects?"
    answer: "Use Durable Objects when the agent needs per-session memory, WebSocket state, alarms, or a stable actor identity. Cloudflare's Agents documentation says each agent runs on a Durable Object with its own SQL database, WebSocket connections, and scheduling surface ([Cloudflare Agents docs](https://developers.cloudflare.com/agents/)). A stateless Worker is enough for one-shot inference."
  - question: "Are hibernated Durable Object agents billed while idle?"
    answer: "Cloudflare's Workers pricing documentation says Durable Objects that are idle and eligible for hibernation are not billed for duration, even before the runtime has hibernated them ([Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/)). They can still incur request and storage charges, so production estimates should include requests, SQLite storage, Workers AI, and observability logs."
  - question: "Should an agent call D1, R2, KV, and Queues through HTTP endpoints?"
    answer: "Prefer platform bindings for Cloudflare-managed resources. The Flue Agents SDK post explains that bindings grant capabilities without exposing credentials to agent-generated code ([Cloudflare Flue SDK post](https://blog.cloudflare.com/agents-platform-flue-sdk/)). HTTP tools still make sense for external systems such as Stripe, Slack, or a private API outside Cloudflare."
  - question: "Can Cloudflare Workers host MCP servers for agents?"
    answer: "Yes. The Agents SDK includes MCP server support, and the February 2026 v0.6.0 changelog added same-Worker Durable Object binding transport between an Agent and an McpAgent, avoiding an HTTP URL for that local connection ([Cloudflare changelog](https://developers.cloudflare.com/changelog/post/2026-02-25-agents-sdk-v060/)). Treat RPC transport as a fast-moving SDK capability and verify client compatibility before standardizing on it."
whats_new:
  - "Cloudflare agent tutorials should start with Durable Object ownership and binding-scoped tools, not with a generic LLM call from a Worker."
learning_objectives:
  - "Build a minimal Cloudflare Workers AI agent backed by a Durable Object."
  - "Choose Durable Object state, platform bindings, and MCP transport deliberately instead of defaulting to HTTP tool endpoints."
  - "Add the production checks Cloudflare's quickstarts often leave implicit: pricing, hibernation assumptions, and observability."
original_data: false
last_updated: 2026-07-07
hero_image:
  url: /img/blogs/2026-07-07-cloudflare-workers-ai-agents-durable-objects-tutorial-2026/hero.png
  alt: "Architecture diagram of a Cloudflare Workers AI agent using a Durable Object for state, Workers AI for inference, and bindings for D1, R2, KV, Queues, and AI Gateway"
---

# Build a Cloudflare Workers AI Agent with Durable Objects in 2026

Build a Cloudflare Workers AI agent by extending the Agents SDK, binding it to a Durable Object, storing per-user state in the object's SQLite-backed storage, and deploying with Wrangler. Durable Objects matter because each agent becomes an addressable actor with persistent state, WebSocket support, alarms, and hibernation-aware billing instead of a stateless function plus external database.

What most tutorials miss is that the LLM call is the least interesting part. The production choice is ownership: Durable Objects should own session state, Cloudflare bindings should own platform tools, and observability must be configured before traffic. Cloudflare's Agents docs describe agents as Durable Object-backed classes with state, scheduling, and WebSocket support ([Cloudflare Agents docs](https://developers.cloudflare.com/agents/)); the architecture win is not magic latency, it is co-locating agent identity and memory.

![Architecture diagram of a Cloudflare Workers AI agent using a Durable Object for state, Workers AI for inference, and bindings for D1, R2, KV, Queues, and AI Gateway](/img/blogs/2026-07-07-cloudflare-workers-ai-agents-durable-objects-tutorial-2026/hero.png)

## Start With a Durable Object Actor, Not a Stateless Worker

A Cloudflare agent is best modeled as an actor: one addressable instance per user, tenant, chat room, browser session, or workflow. Cloudflare's Agents SDK builds on Durable Objects, and Cloudflare's Project Think post frames that as an actor model where each agent has identity, persistent state, wake-up behavior, and a SQLite database ([Project Think](https://blog.cloudflare.com/project-think)).

Create a starter project:

```bash
npm create cloudflare@latest my-edge-agent -- --template cloudflare/agents-starter
cd my-edge-agent
npm install
```

Then define the Durable Object binding in `wrangler.jsonc` or `wrangler.toml`. The exact starter template may generate this for you, but the important shape is the same:

```jsonc
{
  "name": "my-edge-agent",
  "main": "src/index.ts",
  "compatibility_date": "2026-07-07",
  "durable_objects": {
    "bindings": [
      { "name": "AGENT", "class_name": "SupportAgent" }
    ]
  },
  "migrations": [
    { "tag": "v1", "new_sqlite_classes": ["SupportAgent"] }
  ],
  "ai": { "binding": "AI" },
  "observability": { "enabled": true }
}
```

The migration line matters: it creates the SQLite-backed Durable Object class instead of treating the agent as an ephemeral function. Durable Objects give each instance strongly consistent storage, WebSocket support, and alarms ([Durable Objects docs](https://developers.cloudflare.com/durable-objects/)). Do not read that as a universal benchmark promise. It means the state path is local to the actor rather than a separate database round trip you have to operate yourself.

## Store Session State Inside the Agent Before Adding RAG

The first useful agent should remember a tiny amount of state. That proves the actor model before you add Vectorize, R2, or a full MCP surface.

```ts
import { Agent } from "agents";

type Env = {
  AGENT: DurableObjectNamespace<SupportAgent>;
  AI: Ai;
};

type AgentState = {
  history: string[];
};

export class SupportAgent extends Agent<Env, AgentState> {
  initialState = { history: [] };

  async onRequest(request: Request) {
    const url = new URL(request.url);
    const message = url.searchParams.get("q") ?? "Say hello";

    const history = [...this.state.history, `user: ${message}`].slice(-20);
    this.setState({ history });

    const response = await this.env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
      messages: [
        { role: "user", content: "Answer as a concise support assistant." },
        ...history.map((line) => ({ role: "user", content: line })),
        { role: "user", content: message }
      ]
    });

    const text = typeof response === "string" ? response : JSON.stringify(response);
    return Response.json({ answer: text, remembered_turns: history.length });
  }
}

export default {
  async fetch(request: Request, env: Env) {
    const url = new URL(request.url);
    const name = url.pathname.split("/").filter(Boolean)[1] ?? "demo-user";
    const id = env.AGENT.idFromName(name);
    return env.AGENT.get(id).fetch(request);
  }
};
```

This example deliberately keeps memory small: last 20 turns in Durable Object storage. For documents, transcripts, or artifacts, move large blobs to R2 and keep only pointers or summaries in the Durable Object. Cloudflare's R2 pitch is object storage without typical cloud egress fees, which makes it a natural backing store for agent files and generated artifacts ([R2 pricing](https://developers.cloudflare.com/r2/pricing/)).

## Use Bindings as the Default Tool Surface

For Cloudflare-native resources, a binding is usually the right tool primitive. D1, R2, KV, Queues, Workers AI, AI Gateway, Browser Rendering, and Durable Objects are declared in config and exposed to code as `env.*`. The Flue Agents SDK launch post makes the security point directly: bindings grant capabilities without putting credentials into agent-generated code ([Flue Agents SDK](https://blog.cloudflare.com/agents-platform-flue-sdk/)).

That changes how you design tools. A typical non-Cloudflare agent wraps every capability as an HTTP endpoint: `/tools/search`, `/tools/write_file`, `/tools/enqueue`, `/tools/get_customer`. On Workers, keep platform capabilities inside the Worker:

```ts
const tools = {
  async rememberFact(env: Env, key: string, value: string) {
    await env.KV.put(`fact:${key}`, value);
    return { ok: true };
  },
  async enqueueFollowup(env: Env, payload: unknown) {
    await env.QUEUE.send(payload);
    return { queued: true };
  },
  async saveArtifact(env: Env, key: string, body: string) {
    await env.ARTIFACTS.put(key, body);
    return { url: `r2://${key}` };
  }
};
```

Do not overclaim this as a sourced 5x or 10x speedup. The grounded claim is architectural: bindings avoid separate service credentials for Cloudflare-managed resources and can keep local Worker-to-platform calls out of your public HTTP tool surface. Measure your own latency if a tool chain is performance-sensitive.

The same logic applies to AI Gateway. It is useful because it puts provider routing, caching, rate limits, and LLM observability at the gateway layer. Cloudflare says AI Gateway can track metrics such as requests and provider behavior; the gap is full agent trace correlation, which still needs your own request IDs across Worker, Durable Object, Workflow, and model call ([AI Gateway docs](https://developers.cloudflare.com/ai-gateway/)).

## Add MCP Only Where the Tool Contract Needs to Travel

MCP is valuable when your tool surface must be callable from Claude Desktop, Cursor, another agent, or a future client you do not control. It is unnecessary overhead for a private D1 binding that only this Worker should call.

Cloudflare's Agents SDK added `MCPAgent` support, and the v0.6.0 changelog says an Agent can connect to an `McpAgent` in the same Worker through a Durable Object binding instead of an HTTP URL ([Agents SDK v0.6.0 changelog](https://developers.cloudflare.com/changelog/post/2026-02-25-agents-sdk-v060/)). That is the distinction to remember:

| Tool need | Prefer |
|---|---|
| Agent-internal access to KV, D1, R2, Queues, or Workers AI | Platform binding |
| Same-Worker agent-to-MCP connection where supported | Durable Object binding / RPC transport |
| External clients need a standard tool server | Remote MCP over HTTP |
| Third-party SaaS outside Cloudflare | Authenticated HTTP API tool |

Cloudflare's Code Mode post is the more aggressive version of the same idea: reduce tool-token load by exposing a small programmable surface instead of one endpoint per operation ([Code Mode](https://blog.cloudflare.com/code-mode/)). For a tutorial agent, start narrower: one or two explicit tools, then graduate to MCP when interoperability is the goal. If you need the conceptual bridge from function calling to MCP, use [[course/claude-tool-use-from-zero]] before [[course/claude-mcp-mastery]].

## Ship With Pricing and Observability in the First Pull Request

Cloudflare's economics are attractive for idle, stateful agents, but only if you budget the right meters. Workers Paid is the practical production floor for many agent projects, Workers AI has a daily free allocation and paid Neuron pricing, and Durable Objects can incur requests, duration, and storage charges ([Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/), [Workers AI pricing](https://developers.cloudflare.com/workers-ai/platform/pricing/)).

The important hibernation rule is precise: Cloudflare says Durable Objects that are idle and eligible for hibernation are not billed for duration ([Workers pricing](https://developers.cloudflare.com/workers/platform/pricing/)). Eligibility is not the same as "every agent is always free while idle." WebSockets, alarms, long-running handlers, storage, requests, and model calls still shape the bill.

Add the production checklist before launch:

- Enable Workers observability in config, then verify logs exist for a real request.
- Add a request ID and propagate it through Worker, Durable Object, queue messages, and model calls.
- Track per-agent model spend through AI Gateway or your provider billing export.
- Put large artifacts in R2, not Durable Object SQLite.
- Keep one Durable Object instance scoped to one natural owner: user, tenant, room, or workflow.
- Load test the hottest actor, because a single Durable Object is intentionally single-threaded for consistency.

Cloudflare's Workers best-practices docs are blunt that production Workers without observability become a black box ([Workers best practices](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/)). That warning matters more for agents than for CRUD APIs because an agent failure can hide inside model latency, tool latency, queue retries, or a resumed Durable Object.

## Runnable Example: Hit One Named Agent Locally

Run the dev server:

```bash
npx wrangler dev
```

Then call one named agent twice:

```bash
curl "http://localhost:8787/agent/alice?q=remember%20my%20plan%20is%20R2%20for%20artifacts"
curl "http://localhost:8787/agent/alice?q=what%20did%20I%20say%20my%20artifact%20store%20was"
```

Expected output shape:

```json
{
  "answer": "You said your plan was to use R2 for artifacts.",
  "remembered_turns": 2
}
```

If the second call forgets the first call, debug the Durable Object routing first: the same `idFromName("alice")` must receive both requests. If it remembers but costs look high, inspect model tokens and Durable Object duration separately. If no logs appear, fix observability before adding another tool.

## KnowledgeCheck

**You are building a Cloudflare agent that needs per-user chat memory, R2 artifact writes, and a tool surface callable from Claude Desktop. Which split is the cleanest production design?**

A. Put all tools behind public HTTP endpoints, including R2 writes and chat memory.  
B. Store chat memory in a Durable Object, use an R2 binding for artifact writes, and expose only the portable tool contract through MCP.  
C. Store all memory in KV because it is globally cached.  
D. Put the entire conversation transcript in the prompt on every request and skip state.

**Answer: B.** Durable Objects fit per-user state and actor identity; R2 bindings keep Cloudflare-managed artifact writes out of a public HTTP tool; MCP is worth using where an external client needs a standard tool contract.

Cloudflare Workers agents are not a generic replacement for every agent backend. They are strongest when state is per-session, tools map cleanly to platform bindings, and global edge placement matters. If your next step is standardizing the tool interface, take [[course/claude-mcp-mastery]]. If your team is still learning the native tool-calling loop underneath MCP, start with [[course/claude-tool-use-from-zero]].
