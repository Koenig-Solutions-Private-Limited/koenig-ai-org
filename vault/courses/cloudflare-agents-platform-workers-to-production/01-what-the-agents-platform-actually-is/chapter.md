---
chapter_num: 1
course_slug: cloudflare-agents-platform-workers-to-production
title: "What the Cloudflare Agents Platform Actually Is — and Isn't (2026)"
status: g0-passed
author: course-author
ticket: KOEA-6699
learning_objectives:
  - "Explain the four primitives of the Cloudflare Agents Platform: Workers, Durable Objects, Workflows, AI Gateway"
  - "Map the difference between a stateless Worker function and a stateful agent instance"
  - "Identify when to choose Cloudflare Agents over Lambda, Cloud Run, or self-hosted containers"
  - "Deploy a Hello World agent that responds to a user message and persists the exchange"
prerequisites_chapters: []
duration_min: 40
level: Intermediate-Advanced
positions:
  - id: cloudflare-workers-edge-first
    engagement: defends
  - id: edge-native-ai-beats-centralized-cloud
    engagement: defends
chapter_primary_query: "What is the Cloudflare Agents Platform and how does it work in 2026?"
first_60_words_answer: "The Cloudflare Agents Platform is a set of four native primitives — Workers (compute), Durable Objects (per-agent state), Workflows (durable multi-step execution), and AI Gateway (LLM routing) — that let you build stateful AI agents that run in 330+ global PoPs without managing servers. Unlike Lambda or Cloud Run, your agent wakes from hibernation with its SQLite state intact in milliseconds, at no extra cost."
faq:
  - question: "What is the Cloudflare Agents Platform?"
    answer: "The Cloudflare Agents Platform is a suite of serverless primitives — Workers, Durable Objects, Workflows v2, and AI Gateway — designed for building stateful AI agents that run on Cloudflare's global edge network. Unlike generic cloud functions, it provides per-agent persistent state via Durable Object SQLite, durable multi-step execution via Workflows, and unified LLM routing via AI Gateway. ([Cloudflare Agents](https://developers.cloudflare.com/agents/))"
  - question: "What is the Cloudflare Agents SDK?"
    answer: "The Cloudflare Agents SDK (`@cloudflare/agents`) is a TypeScript library that provides the `Agent` base class, WebSocket management, streaming chat helpers, and built-in tool dispatch for Workers-based agents. It abstracts Durable Object setup and Hibernation API wiring, letting you focus on agent logic rather than infrastructure boilerplate. ([Agents SDK](https://developers.cloudflare.com/agents/api-reference/agents-api/))"
  - question: "How is Cloudflare Workers different from AWS Lambda for AI agents?"
    answer: "Lambda is regional, starts in 1–100ms from cold, and has no built-in persistent state — you need DynamoDB, ElastiCache, or RDS for agent memory. Cloudflare Workers run in 330+ PoPs globally, reach active hibernation state in milliseconds (not seconds), and co-locate SQLite state via Durable Objects in the same V8 isolate. For agents that need sub-100ms wake times and zero-latency state reads, Workers wins. ([Workers vs Lambda](https://developers.cloudflare.com/workers/platform/pricing/))"
  - question: "What is Durable Object hibernation and why does it matter for agents?"
    answer: "Durable Object hibernation is Cloudflare's cost optimization that evicts a DO instance from memory when there are no active connections. The instance wakes on the next incoming request and restores its SQLite state from durable storage. Hibernation matters for agents because it means you pay only for active compute time — a dormant agent session costs nothing — while the agent's full state remains available on the next request. ([Durable Objects](https://developers.cloudflare.com/durable-objects/))"
howto_schema:
  name: "Deploy your first Cloudflare Workers agent with the Agents SDK"
  steps:
    - name: "Install the Agents SDK and create a new Workers project"
      text: "Run `npm create cloudflare@latest my-agent -- --template cloudflare/agents-starter` to scaffold a Workers project pre-configured with the Agents SDK, wrangler.toml, and a minimal agent class. Alternatively, add `@cloudflare/agents` to an existing project with `npm install @cloudflare/agents`."
    - name: "Define your agent class by extending Agent"
      text: "In `src/agent.ts`, export a class that extends `Agent` from `@cloudflare/agents`. Override the `onMessage(connection, message)` method to handle incoming chat messages. Call `this.reply(connection, text)` to stream a response back to the caller."
    - name: "Call a model via Workers AI inside the agent"
      text: "Use `env.AI.run('@cf/meta/llama-3.1-8b-instruct', { messages })` inside `onMessage` to call a Workers AI model. Pass the user's message as a `user` role entry and any prior history you retrieve from storage. Await the response and pass the assistant content to `this.reply()`."
    - name: "Wire the agent to your Worker's fetch handler"
      text: "In `src/index.ts`, export your agent class and route WebSocket upgrade requests to it using `routeAgentRequest(request, env)` from the Agents SDK. Add `[[durable_objects.bindings]]` in wrangler.toml pointing to your agent class and a `[[migrations]]` block with `new_classes = ['MyAgent']`."
    - name: "Deploy and test with the Agents playground"
      text: "Run `wrangler deploy` to push your Worker to the Cloudflare network. Open the Cloudflare dashboard, navigate to Workers & Pages → your worker → the Agents tab, and start a chat session. Verify the agent responds and that the session ID appears in the DO instances list."
inline_assets:
  - type: diagram
    path: ./img/agents-platform-stack.svg
    alt: "Cloudflare Agents Platform stack diagram showing Workers compute layer, Durable Objects state layer, Workflows orchestration layer, and AI Gateway routing layer, with user request flowing top-down"
  - type: diagram
    path: ./img/stateless-vs-stateful-worker.svg
    alt: "Side-by-side comparison of a stateless Worker (request in, response out, no memory) versus a stateful agent Worker (request routed to Durable Object instance, state retrieved, LLM called, response returned, state updated)"
last_updated: 2026-06-14
sources:
  - https://developers.cloudflare.com/agents/
  - https://developers.cloudflare.com/agents/api-reference/agents-api/
  - https://developers.cloudflare.com/durable-objects/
  - https://developers.cloudflare.com/workflows/
  - https://developers.cloudflare.com/ai-gateway/
  - https://developers.cloudflare.com/workers-ai/
tags:
  - cloudflare
  - workers
  - agents
  - durable-objects
  - agents-sdk
  - edge-ai
  - serverless
  - 2026
---

# What the Cloudflare Agents Platform Actually Is — and Isn't (2026)

The Cloudflare Agents Platform is a set of four native primitives — Workers (compute), Durable Objects (per-agent state), Workflows (durable multi-step execution), and AI Gateway (LLM routing) — that let you build stateful AI agents that run in 330+ global PoPs without managing servers. Unlike Lambda or Cloud Run, your agent wakes from hibernation with its SQLite state intact in milliseconds, at no extra cost.

This chapter gives you the mental model and the first running agent. By the end, you'll understand what makes edge-native agents different, when to use the Cloudflare platform versus centralized alternatives, and you'll have a deployed `Hello World` agent that persists conversation state across sessions.

---

## The four primitives

Before touching code, you need a clear map of what the Cloudflare Agents Platform actually is. It's not a single product — it's four composable primitives that each solve a different part of the agent problem.

### Workers: the compute layer

A Cloudflare Worker is a JavaScript/TypeScript function that runs in a V8 isolate on Cloudflare's edge network. It receives HTTP requests (or WebSocket connections, or queue messages) and returns responses. Workers are:

- **Global by default**: a single `wrangler deploy` deploys to 330+ PoPs simultaneously. There is no "region" to pick.
- **Fast to start**: Workers skip the OS and runtime cold-start layers. A fresh V8 isolate initializes in under 5ms.
- **Stateless by design**: each invocation is isolated. No shared memory between concurrent Workers, no persisted local state between requests.

The stateless constraint is the defining feature of Workers — and the first obstacle for AI agents, which need to remember things.

### Durable Objects: the state layer

A Durable Object is a Worker that breaks the stateless rule. Each DO instance:

- Has a **globally unique identity** (derived from a string key you provide, like a session ID or user ID)
- Has a **built-in SQLite database** that persists across hibernation cycles
- Is **co-located** with its compute — state reads have zero network hop because the data is in the same V8 isolate as the code
- Can **hibernate** when there are no active connections, then wake with full state restored in milliseconds

For AI agents, Durable Objects solve the memory problem. Each user session gets its own DO instance. Conversation history, user preferences, tool call logs, and mid-task state all live in the DO's SQLite database — available on every request, with no external database required.

### Workflows v2: the orchestration layer

A Cloudflare Workflow is a durable, resumable execution engine for multi-step logic. Each step is checkpointed automatically — if a step fails (network timeout, API error, budget exceeded), the Workflow retries from the last successful step, not from the start.

Workflows solve the problem of long-running agent tasks. An agent that needs to: (1) classify the request, (2) retrieve context from a database, (3) call an LLM, (4) dispatch a follow-up email, and (5) update a CRM record — can't fit that sequence into a single 30-second Worker request. A Workflow can run for hours, days, or weeks, surviving transient failures at each step.

### AI Gateway: the routing layer

AI Gateway is Cloudflare's reverse proxy for LLM APIs. It sits between your Worker and any model provider (OpenAI, Anthropic, Hugging Face, Workers AI) and provides:

- **Unified logging**: every request, token count, latency, and cost in one dashboard
- **Semantic caching**: cache LLM responses for semantically similar queries (not just exact matches), cutting repeat-query costs dramatically
- **Rate limiting**: per-model and per-user token budgets enforced at the gateway, before the request reaches the model
- **Fallback routing**: configure a primary model and a fallback — if the primary errors, the request routes to the fallback automatically

For production agents, routing all LLM calls through AI Gateway is not optional — it's the only way to get cost visibility and reliability without building your own proxy. ([AI Gateway](https://developers.cloudflare.com/ai-gateway/))

---

## Stateless Workers vs. stateful agents: the mental model shift

Most backend engineers understand Cloudflare Workers as HTTP function handlers. The Agents Platform requires a shift in mental model.

**Stateless Worker** (what most tutorials teach):

```
Request → Worker (boot, process, respond) → Response
```

No state is carried between requests. Every invocation starts from scratch. This is perfect for APIs, redirects, and edge transforms — but unusable for agents.

**Stateful agent on Workers**:

```
Request → Worker (route to DO by session ID) → DO instance (wake, restore SQLite state)
       → (retrieve conversation history) → (call LLM with history) → (store new messages)
       → Response
```

The Worker itself is still stateless. The state lives in the Durable Object. The Worker is a router that identifies *which* DO instance handles this request, forwards it, and returns the result. The DO instance is where your agent "lives."

This separation is intentional. Workers scale horizontally without limit because they carry no state. Durable Objects scale to millions of instances because each is isolated. The platform handles routing between them transparently.

---

## When to choose Cloudflare Agents over alternatives

This is the question the platform's marketing material won't answer directly. Here's the honest comparison:

| Constraint | Choose Cloudflare Agents | Choose alternatives |
|---|---|---|
| Agent needs sub-100ms wake time | ✓ Workers hibernation | Lambda cold starts are 100–1000ms |
| Agent needs global presence without regional config | ✓ Single deploy to 330+ PoPs | Lambda requires multi-region setup |
| State is per-session, simple, SQL-queryable | ✓ Durable Object SQLite | DynamoDB or RDS if you need complex joins |
| Task is long-running (hours to days) | ✓ Cloudflare Workflows | Lambda max 15 min; Cloud Run needs custom retry logic |
| You're already on Cloudflare | ✓ Zero new accounts or SDKs | Anywhere else adds a vendor |
| You need GPU inference at scale | ✗ Workers AI has model limits | SageMaker, Modal, or managed inference APIs |
| Your state is relational with complex cross-user queries | ✗ DO SQLite is per-instance, not shared | PlanetScale, Neon, or Supabase |
| Your agent needs long TCP connections to external services | ✗ Workers socket support is limited | Cloud Run or traditional servers |

The clearest "no" is complex shared relational state. Durable Objects give each agent its own isolated SQLite instance — they are explicitly not designed for cross-user queries or global aggregations. If your agent needs to JOIN across user sessions or run analytics, add D1 (Cloudflare's managed SQLite) or a Hyperdrive-connected Postgres for shared state, and keep the DO for per-session context.

---

## The Agents SDK: what it gives you

Before the Agents SDK (`@cloudflare/agents`), building an agent on Workers required manually wiring Durable Objects, managing WebSocket connections across hibernation, and implementing tool dispatch from scratch. The SDK abstracts this into an `Agent` base class with four hooks you override:

```typescript
import { Agent } from "@cloudflare/agents";

export class MyAgent extends Agent<Env> {
  // Called when a new WebSocket client connects
  async onConnect(connection: Connection) {}

  // Called for each message from the client
  async onMessage(connection: Connection, message: WSMessage) {}

  // Called when a client disconnects
  async onClose(connection: Connection, code: number, reason: string) {}

  // Called when an error occurs on the connection
  async onError(connection: Connection, error: Error) {}
}
```

Under the hood, `Agent` extends `DurableObject`. When you write `new MyAgent()`, you're defining a Durable Object class that the SDK wires to the Hibernation API, manages connection state for, and provides storage utilities on top of.

The SDK also includes:
- `routeAgentRequest(request, env)` — routes HTTP/WebSocket requests to the correct agent instance by session ID
- `this.setState(key, value)` / `this.getState(key)` — key-value storage backed by the DO's SQLite
- `this.schedule(delay, method, args)` — schedule a method call in the future (backed by DO alarms)
- `useAgent()` — a React hook for client-side agent connections (if you're building a UI)

---

## Hands-on: deploy a Hello World agent

You'll build a minimal agent that:
1. Accepts chat messages over WebSocket
2. Calls a Workers AI model (Llama 3.1 8B)
3. Streams the response back
4. Persists conversation history across sessions

### Step 1: Scaffold the project

```bash
npm create cloudflare@latest hello-agent -- --template cloudflare/agents-starter
cd hello-agent
npm install
```

The starter template gives you a pre-wired `wrangler.toml` with Durable Object bindings and a basic agent class.

### Step 2: Define the agent

Replace `src/agent.ts` with:

```typescript
import { Agent, type Connection, type WSMessage } from "@cloudflare/agents";

interface Env {
  AI: Ai;
  HELLO_AGENT: DurableObjectNamespace;
}

interface Message {
  role: "user" | "assistant";
  content: string;
}

export class HelloAgent extends Agent<Env> {
  private history: Message[] = [];

  async onMessage(connection: Connection, message: WSMessage) {
    const text = typeof message === "string" ? message : message.toString();

    // Add user message to history
    this.history.push({ role: "user", content: text });

    // Persist to DO storage so it survives hibernation
    await this.env.storage.put("history", this.history);

    // Call Workers AI
    const response = await this.env.AI.run(
      "@cf/meta/llama-3.1-8b-instruct",
      {
        messages: this.history,
        stream: true,
      }
    );

    // Stream response back
    let assistantText = "";
    for await (const chunk of response as AsyncIterable<{ response?: string }>) {
      if (chunk.response) {
        assistantText += chunk.response;
        connection.send(chunk.response);
      }
    }

    // Store assistant reply
    this.history.push({ role: "assistant", content: assistantText });
    await this.env.storage.put("history", this.history);
  }

  async onConnect(connection: Connection) {
    // Restore history from storage on wake (handles hibernation)
    const stored = await this.env.storage.get<Message[]>("history");
    if (stored) {
      this.history = stored;
    }
    connection.send(
      JSON.stringify({ type: "connected", historyLength: this.history.length })
    );
  }
}
```

### Step 3: Wire the Worker

In `src/index.ts`:

```typescript
import { routeAgentRequest } from "@cloudflare/agents";
import { HelloAgent } from "./agent";

export { HelloAgent };

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // routeAgentRequest handles WebSocket upgrades and routes to the correct DO instance
    const agentResponse = await routeAgentRequest(request, env);
    if (agentResponse) return agentResponse;

    return new Response("Cloudflare Agent ready", { status: 200 });
  },
};
```

### Step 4: Configure wrangler.toml

```toml
name = "hello-agent"
main = "src/index.ts"
compatibility_date = "2025-01-01"

[ai]
binding = "AI"

[[durable_objects.bindings]]
name = "HELLO_AGENT"
class_name = "HelloAgent"

[[migrations]]
tag = "v1"
new_classes = ["HelloAgent"]
```

### Step 5: Deploy and test

```bash
wrangler deploy
```

To test from a terminal using `wscat`:

```bash
npm install -g wscat
wscat -c "wss://hello-agent.<your-subdomain>.workers.dev/agents/hello-agent/my-test-session"
```

Send a message: `Hello, what can you help me with?`

The agent responds streamed. Send another message: `What did I just say?`

The agent recalls the prior exchange from history — persisted through the DO's `storage.put`, restored in `onConnect`. If you wait 30 seconds and reconnect with the same session ID, the history is still there after hibernation.

---

## What you should not use the Agents Platform for

The Agents Platform is genuinely novel but not universally better. Situations where it's the wrong choice:

**Long TCP connections to databases or message brokers**: Workers can open TCP connections via `connect()`, but they're not suited for maintaining persistent pool connections to Postgres or Kafka. Use Cloud Run or a traditional server for brokers.

**Agents that need GPU inference at sustained scale**: Workers AI is adequate for prototyping, but for production throughput above a few hundred concurrent inference calls, managed inference endpoints (Fireworks, Modal, Together AI) or dedicated GPU instances are more cost-effective.

**Complex graph-structured agent orchestration**: Cloudflare Workflows are a sequence of steps with branching — not a general graph executor. If your agent requires dynamic DAG execution (like complex LangGraph flows with dozens of conditional branches), you'll fight the platform. Consider a dedicated orchestrator (Inngest, Temporal) and use Workers as edge entry points.

**Cross-instance shared state at query time**: DO SQLite is per-instance. You can't run a SELECT across all user sessions from a single DO. If your agent needs a global view of state (leaderboards, org-wide analytics, cross-user recommendations), use D1 or an external database and keep the DO for session context only.

---

## The contrarian take: "serverless" should mean stateful

The industry conflated "serverless" with "stateless" for a decade. Lambda's success reinforced this: functions are pure transformations, state lives elsewhere, scale to zero means start from scratch.

Cloudflare's Agents Platform is the first mainstream serverless environment to break this conflation. Durable Objects are serverless (no servers to manage, pay-per-use, automatic scaling) AND stateful (SQLite-backed, per-instance, consistent). The architecture isn't a compromise — it's a deliberate rejection of the assumption that stateless is simpler.

For AI agents specifically, the stateless model is a mismatch. Agents *are* their state. An agent that forgets everything between requests isn't an agent — it's an API wrapper. The Cloudflare model aligns the compute primitive with what agents actually need: durable, co-located, low-latency state that survives across sessions.

---

## Chapter summary

- The Cloudflare Agents Platform has four composable primitives: **Workers** (global stateless compute), **Durable Objects** (per-agent persistent SQLite state), **Workflows v2** (durable multi-step execution), and **AI Gateway** (LLM routing, caching, cost control).
- A Worker is still stateless. Your agent "lives" in a Durable Object instance, addressed by session ID. The Worker routes requests to the correct DO.
- The Agents SDK (`@cloudflare/agents`) provides the `Agent` base class, `routeAgentRequest()`, storage helpers, and scheduling — abstracting the Durable Object + Hibernation API boilerplate.
- Choose Cloudflare Agents when you need sub-100ms wake time, global presence, and per-session state. Choose alternatives when you need shared cross-session queries, GPU inference at scale, or long-lived TCP connections.
- In the next chapter, you'll go deep on Durable Objects: the hibernation lifecycle, SQLite schema design for agent memory, alarms for scheduled work, and the Facets pattern for production-scale isolation.
