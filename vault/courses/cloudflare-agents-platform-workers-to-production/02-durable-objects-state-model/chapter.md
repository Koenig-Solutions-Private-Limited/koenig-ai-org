---
chapter_num: 2
course_slug: cloudflare-agents-platform-workers-to-production
title: "Durable Objects 2026: Your Cloudflare Agent's State Model"
status: g0-passed
author: course-author
ticket: KOEA-7068
learning_objectives:
  - "Explain the Durable Object lifecycle: creation, hibernation, wake, destruction"
  - "Implement per-session agent state using Durable Object SQLite storage"
  - "Design a memory schema that stores conversation history, user preferences, and tool call logs"
  - "Apply the Durable Object Facets pattern to give each dynamic agent its own isolated database"
prerequisites_chapters:
  - "01-what-the-agents-platform-actually-is"
duration_min: 55
level: Intermediate-Advanced
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
  - id: audit-trail-as-enterprise-gate
    engagement: defends
chapter_primary_query: "How do Durable Objects work as agent state in Cloudflare Workers 2026?"
first_60_words_answer: "Durable Objects give each Cloudflare Workers agent its own persistent SQLite database, co-located with its compute. Each DO instance is addressed by a unique ID — one per user session, one per agent persona, or one per domain entity. State reads have zero network latency because the data lives in the same V8 isolate as your code. No Redis, no external database, no serialization round-trip."
faq:
  - question: "What is a Durable Object in Cloudflare Workers?"
    answer: "A Durable Object is a V8 isolate with a globally unique identity, a built-in SQLite database, and a persistent routing guarantee. It can hibernate to save costs and wake on demand in milliseconds. Each DO instance has its own isolated storage that no other instance can access. ([Cloudflare Durable Objects](https://developers.cloudflare.com/durable-objects/))"
  - question: "How does Durable Object SQLite compare to KV for agent memory?"
    answer: "KV is eventually consistent and best for read-heavy global data. Durable Object SQLite is strongly consistent, co-located with your compute, supports ACID transactions, and lets you run arbitrary SQL queries including JOINs and aggregations. For agent conversation memory that needs ordering, deduplication, and structured queries, SQLite is the correct choice. ([Storage API](https://developers.cloudflare.com/durable-objects/api/storage-api/))"
  - question: "What are Durable Object alarms used for in agents?"
    answer: "Alarms let a Durable Object schedule its own wake-up at a future time, even after hibernating. Agents use alarms for scheduled reminders, periodic memory consolidation, TTL-based context eviction, and background tasks that must run without a live user request triggering them. ([DO Alarms](https://developers.cloudflare.com/durable-objects/api/alarms/))"
howto_schema:
  name: "Add persistent memory to a Cloudflare Workers agent with Durable Objects"
  steps:
    - name: "Declare the Durable Object binding in wrangler.toml"
      text: "Add a `[[durable_objects.bindings]]` section with `name = 'AGENT_MEMORY'` and `class_name = 'AgentMemory'` to your wrangler.toml. Also add a `[[migrations]]` section with `tag = 'v1'` and `new_classes = ['AgentMemory']` so Cloudflare provisions the class on first deploy."
    - name: "Create the DO class with a SQLite memory schema"
      text: "Export a class that extends `DurableObject`. In the constructor, call `this.ctx.storage.sql.exec()` with `CREATE TABLE IF NOT EXISTS messages` — columns for id, role, content, and created_at. This runs on every wake and must be idempotent."
    - name: "Implement the chat and history fetch handlers"
      text: "Add a `fetch(request)` method that routes POST /chat to INSERT both user and assistant messages into SQLite, and GET /history to a SELECT query returning the last 10 rows ordered by created_at DESC."
    - name: "Address the DO from your Worker by session ID"
      text: "In your main Worker, derive a Durable Object ID using `env.AGENT_MEMORY.idFromName(sessionId)`. Obtain a stub with `env.AGENT_MEMORY.get(id)` and forward requests via `stub.fetch(request)`."
    - name: "Verify hibernation and state persistence"
      text: "Send a chat request, wait 15 seconds for hibernation, then send GET /history. The response must include your original message — Cloudflare restores the SQLite state from durable storage before waking the isolate."
inline_assets:
  - type: diagram
    path: ./img/do-lifecycle.svg
    alt: "Durable Object lifecycle diagram showing creation, active, hibernating, and destroyed states with transitions for incoming request, alarm fire, and TTL expiry"
  - type: diagram
    path: ./img/do-facets-pattern.svg
    alt: "DO Facets pattern showing a single AgentMemory class fanning out to multiple instances, each isolated per user session, with no cross-instance access"
last_updated: 2026-06-12
sources:
  - https://developers.cloudflare.com/durable-objects/
  - https://developers.cloudflare.com/durable-objects/api/storage-api/
  - https://developers.cloudflare.com/durable-objects/best-practices/create-durable-object-stubs-and-send-requests/
  - https://developers.cloudflare.com/durable-objects/api/alarms/
  - https://blog.cloudflare.com/sqlite-in-durable-objects/
  - https://developers.cloudflare.com/agents/
tags:
  - cloudflare
  - durable-objects
  - sqlite
  - agents
  - state-management
  - hibernation
  - alarms
  - 2026
---

# Durable Objects 2026: Your Cloudflare Agent's State Model

Durable Objects give each Cloudflare Workers agent its own persistent SQLite database, co-located with its compute. Each DO instance is addressed by a unique ID — one per user session, one per agent persona, or one per domain entity. State reads have zero network latency because the data lives in the same V8 isolate as your code. No Redis, no external database, no serialization round-trip.

This chapter covers the complete Durable Object model as it applies to AI agents in 2026: per-instance addressing, the hibernation lifecycle, SQLite storage and schema design, alarms for scheduled work, and the Facets pattern for per-user isolation at scale. By the end, you'll have refactored a stateless Worker agent into one with persistent memory that survives hibernation.

---

## The mental model: what a Durable Object actually is

Cloudflare Workers are stateless by design. A typical Worker function boots, handles a request, and disappears. There's no memory of the previous request, no shared mutable state between concurrent invocations, and no way to hold an open connection across the network boundary. That's a feature for HTTP APIs, but a fundamental obstacle for AI agents that need to track conversation context, remember user preferences, and resume mid-task after a failure.

A **Durable Object** (DO) is the solution to this problem — but it isn't what most developers initially think it is.

The most common first mental model is "a Worker with a database attached." That's not wrong, but it misses the more important property: a Durable Object has a **globally unique identity that routes all requests for that identity to the same instance, on the same machine, in the same V8 isolate**. There is no load balancer distributing those requests. There is no replica set. When you call `env.AGENT_MEMORY.idFromName("user-session-abc")`, Cloudflare routes every request for that name to exactly one running isolate — guaranteed by the routing layer, not by your application code.

This is why DOs work as agent memory without external coordination. There's only ever one writer for a given agent instance at any point in time. Concurrent writes to the same DO don't need optimistic locking, write-ahead logs, or conflict resolution — they're serialized by the runtime's single-threaded event loop. You get strong consistency with zero infrastructure overhead.[^1]

The second thing to internalize is the **hibernation model**. A DO doesn't stay running permanently. Cloudflare's runtime puts inactive DOs to sleep after a period of inactivity. The V8 isolate is torn down. The SQLite state is written to durable storage. When the next request arrives, the DO wakes: Cloudflare provisions a new V8 isolate, loads the persisted SQLite state, and routes the request to the newly warmed instance — all within milliseconds.[^1]

The practical implication for agent developers: **your DO class constructor runs on every wake, not once per lifetime**. You can't use constructor-level JavaScript state as a cache that persists across hibernations. Anything that needs to survive hibernation must be written to SQLite or transactional storage. Anything stored in JS variables is lost when the isolate hibernates.

This is the single most common source of bugs in first-time DO implementations. The fix is simple but the habit takes time to build: if it matters beyond this request, put it in storage.

---

## Per-instance addressing: one DO per agent, not one DO per class

Durable Objects are defined as classes, but they're used as instances. The class is a template; each instance has its own identity, its own state, and its own isolated lifecycle. The instance is the granular unit you care about as an agent developer.

Cloudflare provides two ways to obtain a DO instance ID:

```typescript
// 1. Deterministic: derived from a string name — same name always → same instance
const id = env.AGENT_MEMORY.idFromName("user-session-abc123");

// 2. Random: brand-new globally unique ID — use for ephemeral one-off agents
const id = env.AGENT_MEMORY.newUniqueId();
```

**`idFromName`** is almost always the right choice for agents. It gives you a stable, reproducible ID for any named entity: user ID, session token, case number, or tenant slug. The same name always maps to the same DO instance, which means you can retrieve an agent's conversation history simply by knowing the user's identifier — no secondary lookup, no mapping table required.

**`newUniqueId`** is better for one-off ephemeral tasks: temporary scratchpads, single-use agents that process one document and then expire, or cases where you explicitly want irreproducibility.

The key insight is that **DO instance addressing IS your agent's identity layer**. You don't need a separate `agent_instances` database table to track "which agent instance belongs to which user." The call `idFromName("user-42")` is the association. The DO instance for `"user-42"` is the canonical location of that user's agent state, full stop.

This collapses a multi-step identity resolution pattern into a single deterministic lookup:

```
Before DOs:  Request → Worker → Query DB for agent_id → Fetch agent state → Process
After DOs:   Request → Worker → idFromName(userId)    → stub.fetch(request) → DO handles its own state
```

The routing indirection and the database lookup disappear. The DO is the database, the process, and the identity — unified in a single addressable entity.

<Callout type="info">
**Namespace isolation:** `idFromName()` is scoped to the Durable Object class binding. Two different DO classes using the same string name produce different instances and will never collide. But within a single class, the string `"user-42"` always resolves to the same instance — design your naming scheme carefully and document it.
</Callout>

---

## The lifecycle in detail: creation, active, hibernating, and destroyed

Understanding the DO lifecycle prevents a class of subtle bugs where your agent seems to "forget" things it should remember, or behaves inconsistently after idle periods.

### Creation

A DO instance is created implicitly the first time you call `env.MY_DO.get(id)` and send a request to the returned stub. There is no explicit "create" call. The instance's constructor runs, `fetch()` is called with the incoming request, and the instance becomes active.

Schema initialization belongs in the constructor using `CREATE TABLE IF NOT EXISTS` — this runs on every wake but is idempotent by design. Cloudflare runs `[[migrations]]` only once per migration tag at deploy time, not per wake.

### Active

While a DO is handling requests, the V8 isolate is live: JS timers work, in-memory state is accessible, and WebSocket connections are held open. Multiple concurrent requests to the same DO are queued and processed serially by the single-threaded event loop. There is no concurrent-write problem to solve.[^1]

### Hibernating

After the last open request closes and no alarm is scheduled, Cloudflare hibernates the DO. The V8 isolate is destroyed, but all SQLite storage and transactional storage persists to Cloudflare's underlying durable storage layer. From the developer's perspective, the instance sleeps — but the data survives indefinitely.[^1]

**WebSocket hibernation** is a first-class feature worth knowing for real-time agents. If you use the Hibernation API with WebSockets, the DO can hibernate even while a WebSocket connection is technically open — it wakes only when a message arrives. This reduces idle costs dramatically for agents maintaining long-lived client connections that spend most of their time waiting for user input.[^2]

### Destroyed

DOs are not automatically destroyed. An instance created via `idFromName` persists indefinitely until you explicitly call `this.ctx.storage.deleteAll()`. For agents, this means you must implement your own TTL or archiving logic. The recommended pattern is an alarm (covered below) that checks session age on a schedule and self-destructs stale instances:

```typescript
async alarm(): Promise<void> {
  const lastActivity = this.ctx.storage.sql.exec(
    `SELECT MAX(created_at) as last FROM messages`
  ).one()?.last as number ?? 0;
  
  const thirtyDaysAgo = Math.floor(Date.now() / 1000) - 30 * 86400;
  
  if (lastActivity < thirtyDaysAgo) {
    // Archive to R2 before deletion if needed, then clean up
    await this.ctx.storage.deleteAll();
    return; // DO will now be destroyed on next hibernation
  }
  
  // Reschedule the TTL check for next month
  await this.ctx.storage.setAlarm(Date.now() + 30 * 86400 * 1000);
}
```

![Durable Object lifecycle diagram showing creation, active, hibernating, and destroyed states with transitions for incoming request, alarm fire, and TTL expiry](./img/do-lifecycle.svg)

---

## SQLite inside your DO: the embedded database

Cloudflare shipped SQLite in Durable Objects and it is now the recommended storage API for any DO that needs structured data.[^5] Before SQLite, developers were limited to a key-value transactional storage API — adequate for simple state but awkward for conversation histories, tool call logs, or anything requiring ordered retrieval or aggregation.

The SQLite API is available at `this.ctx.storage.sql`:

```typescript
import { DurableObject } from "cloudflare:workers";

export class AgentMemory extends DurableObject {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    // Runs on every DO wake — must be idempotent
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id         INTEGER  PRIMARY KEY AUTOINCREMENT,
        role       TEXT     NOT NULL CHECK(role IN ('user', 'assistant', 'tool', 'system')),
        content    TEXT     NOT NULL,
        tool_name  TEXT,
        tokens_in  INTEGER  DEFAULT 0,
        tokens_out INTEGER  DEFAULT 0,
        created_at INTEGER  NOT NULL DEFAULT (unixepoch())
      );

      CREATE TABLE IF NOT EXISTS preferences (
        key        TEXT     PRIMARY KEY,
        value      TEXT     NOT NULL,
        updated_at INTEGER  NOT NULL DEFAULT (unixepoch())
      );

      CREATE TABLE IF NOT EXISTS tool_calls (
        id          INTEGER  PRIMARY KEY AUTOINCREMENT,
        message_id  INTEGER  NOT NULL,
        tool_name   TEXT     NOT NULL,
        input_json  TEXT     NOT NULL,
        output_json TEXT,
        status      TEXT     NOT NULL CHECK(status IN ('pending', 'success', 'error')),
        duration_ms INTEGER,
        created_at  INTEGER  NOT NULL DEFAULT (unixepoch())
      );

      CREATE INDEX IF NOT EXISTS idx_messages_created  ON messages(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_tool_calls_msg    ON tool_calls(message_id);
    `);
  }
}
```

Three things to note about this pattern:

1. **`CREATE TABLE IF NOT EXISTS`** makes the constructor idempotent. It runs on every DO wake, so it must not fail on subsequent executions. `IF NOT EXISTS` is non-negotiable.

2. **`CHECK` constraints on `role` and `status`** enforce schema integrity at the database level. Illegal role strings can't be inserted — you're making invalid states unrepresentable without any application-layer validation code.

3. **Indexes on `created_at DESC` and `message_id`** reflect the two most common queries: "give me the last N messages" and "show me the tool calls for message X." Declare indexes that match your read patterns.

All SQLite writes are automatically persisted as part of hibernation — there is no explicit "flush to disk" call. Every `sql.exec()` that completes before the request returns is durable.[^2]

<Callout type="warn">
**Foreign key enforcement (2026 status):** SQLite in Durable Objects does not currently enforce foreign key constraints. `PRAGMA foreign_keys = ON` has no effect. Design your schema to avoid hard foreign key dependencies, or enforce referential integrity in application code when inserting into `tool_calls`.
</Callout>

---

## Designing a memory schema for agent conversations

The SQLite tables you create define what your agent can remember and how efficiently it can retrieve that memory. This section explains why the schema above is structured the way it is — and why the common alternative fails in production.

### Why a JSON blob is the wrong abstraction

A common first approach stores conversation history as a JSON array in a single KV key or a TEXT column:

```typescript
// Anti-pattern: entire history as a serialized JSON blob
await env.KV.put(`session:${sessionId}`, JSON.stringify(messages));
const history = JSON.parse(await env.KV.get(`session:${sessionId}`) ?? "[]");
```

This pattern has four failure modes for production agents:

1. **Read amplification**: To get the last 5 messages from a 1,000-message history, you deserialize the entire payload. At scale, you're parsing megabytes on every LLM call.
2. **No partial retrieval**: "Show me all tool calls from the last hour" requires loading and filtering the full array in application code.
3. **Concurrency corruption**: If two parallel tool calls both read → modify → write the blob, the second write overwrites the first. This is rare but catastrophic.
4. **No analytics**: "How many tokens did this session consume last week?" is O(n) across the full history.

The table schema handles all four: indexed reads return only the requested rows; `tool_calls` is queryable independently with `WHERE created_at > ?`; SQLite serializes concurrent writes automatically; token consumption is a single `SELECT SUM(tokens_out)` aggregate.

### Fetching context for the LLM

When you're about to call the LLM, you need a recent window of conversation history formatted as the messages array the API expects:

```typescript
getRecentHistory(limit = 20): Array<{role: string; content: string; name?: string}> {
  const cursor = this.ctx.storage.sql.exec(
    `SELECT role, content, tool_name
     FROM messages
     ORDER BY created_at DESC
     LIMIT ?`,
    limit
  );

  // exec returns rows in DESC order (newest first); reverse for chronological LLM input
  const rows = [...cursor.toArray()].reverse();

  return rows.map(row => ({
    role: row.role as string,
    content: row.content as string,
    ...(row.tool_name ? { name: row.tool_name as string } : {})
  }));
}
```

The `.toArray()` call materializes the cursor. For history retrieval limited to 20 rows, this is appropriate — you need all rows anyway. For large analytical queries over thousands of rows, prefer cursor-based iteration to avoid loading the entire result set into memory.

### Persisting a turn

After the LLM responds, persist both sides of the exchange atomically:

```typescript
async persistTurn(
  userMessage: string,
  assistantResponse: string,
  tokensIn: number,
  tokensOut: number
): Promise<void> {
  this.ctx.storage.sql.exec(
    `INSERT INTO messages(role, content, tokens_in) VALUES(?, ?, ?);
     INSERT INTO messages(role, content, tokens_out) VALUES(?, ?, ?);`,
    "user", userMessage, tokensIn,
    "assistant", assistantResponse, tokensOut
  );
}
```

Both inserts happen in the same `exec()` call, which SQLite treats as a transaction. Either both rows are written or neither is — no partial state.

---

## Alarms: your agent's built-in scheduler

Durable Object alarms solve a problem that trips up most agent developers: **how do you run periodic work inside an agent without an external cron service?**

Every DO instance can schedule its own wake-up at a future timestamp using `ctx.storage.setAlarm()`. When the alarm fires, the runtime wakes the DO (from hibernation if necessary) and calls the `alarm()` method.[^4] No external scheduler, no Cloudflare Cron Trigger, no third-party job queue.

Common agent alarm use cases:
- **Memory consolidation**: every 24 hours, summarize the last 1,000 messages into a compact `summaries` entry and delete the originals, keeping the SQLite database small
- **TTL-based eviction**: after 30 days of inactivity, archive the SQLite data to R2 and delete the DO
- **Scheduled reminders**: when an agent promises "I'll remind you at 9am tomorrow," it sets an alarm for that timestamp
- **Retry with backoff**: if a tool call failed, schedule a retry in 60 seconds without blocking the current user response

Here's a minimal but production-correct alarm implementation:

```typescript
export class AgentMemory extends DurableObject {
  // Schedule a one-time alarm. Overwrites any existing alarm.
  async scheduleWork(timestampMs: number, payload: string): Promise<void> {
    // Persist the payload BEFORE setting the alarm —
    // the DO may hibernate between now and fire time
    this.ctx.storage.sql.exec(
      `INSERT OR REPLACE INTO preferences(key, value, updated_at)
       VALUES('pending_alarm_payload', ?, unixepoch())`,
      payload
    );
    await this.ctx.storage.setAlarm(timestampMs);
  }

  // Called by the runtime when the alarm fires
  async alarm(): Promise<void> {
    const row = this.ctx.storage.sql.exec(
      `SELECT value FROM preferences WHERE key = 'pending_alarm_payload'`
    ).one();

    if (!row) return; // Alarm fired with no payload — idempotent exit

    const payload = row.value as string;

    try {
      await this.executeScheduledWork(payload);
    } finally {
      // Always clean up, even on failure, to prevent alarm storm re-entry
      this.ctx.storage.sql.exec(
        `DELETE FROM preferences WHERE key = 'pending_alarm_payload'`
      );
    }
  }

  private async executeScheduledWork(payload: string): Promise<void> {
    const task = JSON.parse(payload) as { type: string; data: unknown };
    if (task.type === "consolidate_memory") {
      await this.consolidateOldMessages();
    }
  }

  private async consolidateOldMessages(): Promise<void> {
    // Example: delete messages older than 30 days, keeping the last 100
    this.ctx.storage.sql.exec(
      `DELETE FROM messages
       WHERE id NOT IN (
         SELECT id FROM messages ORDER BY created_at DESC LIMIT 100
       )
       AND created_at < unixepoch() - 2592000`
    );
  }
}
```

Four invariants to internalize about alarms:

1. **One alarm per DO instance.** Calling `setAlarm()` again before the previous alarm fires overwrites it. If you need multiple scheduled events, store them in a `scheduled_jobs` table and always set the alarm for the earliest pending job.

2. **Alarms survive hibernation.** The alarm timestamp is persisted durably. The DO wakes at the scheduled time regardless of whether it has been hibernating.

3. **The runtime retries failed `alarm()` handlers** with exponential backoff up to a platform-defined ceiling. Design your `alarm()` handler to be idempotent — running it twice must not corrupt state.

4. **`ctx.storage.deleteAll()` clears the pending alarm.** If you delete all storage as part of TTL-based cleanup, the alarm is also cleared automatically.

<Callout type="info">
**Alarm timestamps are absolute Unix milliseconds.** Always compute the target timestamp in your Worker before passing it to the DO. `new Date('tomorrow 9am').getTime()` depends on the runtime's system timezone. Derive absolute timestamps using a known reference (`Date.now() + offsetMs`) and pass them as integers.
</Callout>

---

## The Facets pattern: per-user isolation at scale

The **Facets pattern** is the idiomatic Cloudflare architecture for multi-tenant agent systems. The core idea: instead of one DO instance holding state for all users of a class, create one DO instance per logical entity — user, session, tenant, conversation thread.

This isn't just a stylistic preference. It's enforced by the runtime's access model. There is no DO equivalent of `SELECT * FROM agent_instances`. There's no API to iterate all instances of a class or run a cross-instance aggregation. Each instance is a sealed capsule. You can only access a specific instance if you know its ID.

![DO Facets pattern showing a single AgentMemory class fanning out to multiple instances, each isolated per user session, with no cross-instance access](./img/do-facets-pattern.svg)

The pattern looks like this in a multi-tenant Worker:

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Derive the DO identity from an authenticated session identifier
    // In production, validate the session token before using it as a DO name
    const sessionId = request.headers.get("X-Session-Id");
    if (!sessionId) {
      return new Response("Unauthorized", { status: 401 });
    }

    // The Facets pattern: one DO per session — no tenant lookup, no join
    const id = env.AGENT_MEMORY.idFromName(`session:${sessionId}`);
    const stub = env.AGENT_MEMORY.get(id);

    // The DO routes internally by URL path
    if (url.pathname.startsWith("/chat") || url.pathname.startsWith("/history")) {
      return stub.fetch(request);
    }

    return new Response("Not found", { status: 404 });
  }
} satisfies ExportedHandler<Env>;
```

Inside the DO, all logic is written from the perspective of a single tenant's agent. There's no "which user is this?" conditional — the DO IS a specific user's agent, by construction. This single-tenancy-by-default eliminates entire categories of authorization bugs and simplifies query logic substantially.

**Scaling characteristics of the Facets pattern:**[^1]

| Metric | Platform Limit |
|---|---|
| DO instances per account | Effectively unlimited (billing scales with usage) |
| Per-instance SQLite storage | 10 GB |
| Concurrent active instances | Scales with account tier |
| Cross-instance data access | Not supported by design |

For an agent platform serving millions of users, one DO per user is sustainable. Cloudflare's routing layer handles fan-out. Each user's requests land at their dedicated instance, and each instance's SQLite database contains only that user's data.

The operational payoff: your SQL queries have no `WHERE user_id = ?` clause. There's no row-level security to configure. There's no risk of a missing `WHERE` clause leaking one user's data to another — there's only ever one user's data in the database. Simpler queries, fewer bugs, and a security property enforced by routing rather than application code.

---

<KnowledgeCheck questions={[
  {
    type: "mcq",
    question: "A Durable Object's JavaScript instance variables are lost after hibernation. What is the correct way to persist state that must survive across requests separated by hibernation?",
    options: [
      "Store it in a module-level variable using globalThis to survive isolate teardown",
      "Write it to this.ctx.storage.sql or transactional storage before the handler returns",
      "Use Object.freeze() on the variable to mark it as non-garbage-collectible",
      "Store it in a Workers KV namespace under the DO's ID and re-read it in the constructor"
    ],
    correct: 1,
    explanation: "Module-level and instance-level JavaScript variables are destroyed when the V8 isolate is torn down during hibernation. The only durable storage is ctx.storage — either the SQLite API or the transactional key-value storage. KV is a valid fallback but adds a network hop and eventual consistency; co-located SQLite is strongly consistent with zero extra latency."
  },
  {
    type: "mcq",
    question: "You're building an agent where each user can maintain multiple named workspaces, e.g. 'project-alpha' and 'project-beta'. Which idFromName scheme correctly implements per-workspace isolation?",
    options: [
      "env.AGENT.idFromName(userId) — one DO per user, workspaces are rows in a table",
      "env.AGENT.idFromName(workspaceName) — one DO per workspace name globally",
      "env.AGENT.idFromName(`${userId}:${workspaceName}`) — composite key for uniqueness",
      "env.AGENT.newUniqueId() at workspace creation time, stored in a mapping table"
    ],
    correct: 2,
    explanation: "Keying only by userId collapses all workspaces into a single DO. Keying only by workspaceName causes collision if two users create a workspace with the same name. A composite key `${userId}:${workspaceName}` is globally unique, reproducible, and requires no secondary mapping table — the same user+workspace pair always resolves to the same DO instance."
  },
  {
    type: "freeform",
    question: "Explain why `CREATE TABLE IF NOT EXISTS` in the DO constructor is the correct pattern, and what would go wrong if you used `CREATE TABLE` without the IF NOT EXISTS guard."
  }
]} />

---

<RunPromptCell
  title="Design a SQLite memory schema for a customer support agent"
  description="Paste this prompt into Claude to walk through schema design decisions for a production conversational agent DO."
  prompt={`I'm building a Cloudflare Workers agent backed by a Durable Object that handles customer support tickets. I need to track: (1) the conversation thread with role labels, (2) ticket metadata like priority and resolution status, (3) every tool call the agent made along with its input, output, and latency.

Design a minimal SQLite schema for this Durable Object. For each table:
- Explain why you structured it this way
- Name the indexes you'd add and the specific query they optimize
- Show one representative SELECT query that the agent will run in production

Keep it practical and self-contained — no external DB, no KV, everything in DO SQLite.`}
  expectedOutput="Three-table schema (messages, ticket_metadata, tool_calls) with indexes, CHECK constraints, and example SELECT queries demonstrating efficient retrieval patterns."
/>

---

## Hands-on exercise: refactor the Chapter 1 agent to use Durable Objects

This exercise takes the "Hello World" agent from [[cloudflare-agents-platform-workers-to-production/01-what-the-agents-platform-actually-is|Chapter 1]] — a stateless Worker that calls a model and returns a response — and refactors it to persist conversation history in a Durable Object SQLite table. At the end you'll verify that history survives a hibernation cycle.

### Prerequisites

- Completed Chapter 1 agent deployed to Cloudflare Workers
- Wrangler CLI 3.x installed and authenticated (`wrangler whoami`)
- A Cloudflare account with Durable Objects access enabled

### Step 1: Add the DO binding to wrangler.toml

```toml
[[durable_objects.bindings]]
name = "AGENT_MEMORY"
class_name = "AgentMemory"

[[migrations]]
tag = "v1"
new_classes = ["AgentMemory"]
```

### Step 2: Implement the AgentMemory DO class

Create `src/agent-memory.ts`. This is the canonical DO for all conversation persistence:

```typescript
import { DurableObject } from "cloudflare:workers";

interface Env {}

export class AgentMemory extends DurableObject {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);

    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS messages (
        id         INTEGER  PRIMARY KEY AUTOINCREMENT,
        role       TEXT     NOT NULL CHECK(role IN ('user', 'assistant')),
        content    TEXT     NOT NULL,
        created_at INTEGER  NOT NULL DEFAULT (unixepoch())
      );
      CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
    `);
  }

  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    // POST /chat — persist a user+assistant exchange
    if (request.method === "POST" && url.pathname === "/chat") {
      const { userMessage, assistantResponse } = await request.json<{
        userMessage: string;
        assistantResponse: string;
      }>();

      this.ctx.storage.sql.exec(
        `INSERT INTO messages(role, content) VALUES(?, ?);
         INSERT INTO messages(role, content) VALUES(?, ?);`,
        "user", userMessage,
        "assistant", assistantResponse
      );

      return new Response(JSON.stringify({ ok: true }), {
        headers: { "Content-Type": "application/json" }
      });
    }

    // GET /history — return last 10 exchanges in chronological order
    if (request.method === "GET" && url.pathname === "/history") {
      const cursor = this.ctx.storage.sql.exec(
        `SELECT role, content, created_at
         FROM messages
         ORDER BY created_at DESC
         LIMIT 20`
      );

      const rows = cursor.toArray().reverse(); // chronological order for display

      return new Response(JSON.stringify(rows), {
        headers: { "Content-Type": "application/json" }
      });
    }

    return new Response("Not found", { status: 404 });
  }
}
```

### Step 3: Update your main Worker to address the DO by session

In `src/index.ts`, derive the DO ID from the incoming session header and forward persistence calls to the DO stub:

```typescript
interface Env {
  AGENT_MEMORY: DurableObjectNamespace;
  // ...your existing AI bindings
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Proxy history requests directly to the DO
    if (url.pathname === "/history") {
      const sessionId = request.headers.get("X-Session-Id") ?? "default";
      const id = env.AGENT_MEMORY.idFromName(`session:${sessionId}`);
      return env.AGENT_MEMORY.get(id).fetch(request);
    }

    if (url.pathname === "/chat" && request.method === "POST") {
      const { message } = await request.json<{ message: string }>();
      const sessionId = request.headers.get("X-Session-Id") ?? "default";

      // 1. Call the LLM (your existing Chapter 1 logic)
      const assistantResponse = await callLLM(message, env);

      // 2. Persist the exchange to the DO
      const id = env.AGENT_MEMORY.idFromName(`session:${sessionId}`);
      const stub = env.AGENT_MEMORY.get(id);
      await stub.fetch(new Request("https://do-internal/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userMessage: message, assistantResponse })
      }));

      return new Response(assistantResponse);
    }

    return new Response("Not found", { status: 404 });
  }
} satisfies ExportedHandler<Env>;
```

### Step 4: Deploy and verify

```bash
# Deploy the updated Worker + DO class
wrangler deploy

# Send a chat message using session header
curl -X POST https://your-worker.workers.dev/chat \
  -H "X-Session-Id: test-session-1" \
  -H "Content-Type: application/json" \
  -d '{"message": "What is the capital of Japan?"}'

# Wait 20 seconds for the DO to hibernate
sleep 20

# Fetch history — must still contain your message after hibernation
curl https://your-worker.workers.dev/history \
  -H "X-Session-Id: test-session-1"

# Verify instance isolation: a different session ID returns empty history
curl https://your-worker.workers.dev/history \
  -H "X-Session-Id: test-session-2"
```

### Success criteria

- `GET /history` for `test-session-1` returns the message and response from the previous request, even after the DO hibernated and woke again
- `GET /history` for `test-session-2` returns an empty array (instance isolation confirmed)
- Multiple chat messages appear in the history in chronological order, not reverse

---

<KnowledgeCheck questions={[
  {
    type: "mcq",
    question: "Your agent accumulates 50,000 messages in a DO SQLite database over 6 months. What is the most production-appropriate approach to keep LLM context window consumption manageable?",
    options: [
      "Hard-delete old messages: DELETE FROM messages WHERE created_at < unixepoch() - 7776000",
      "Load only the last 20 rows with a LIMIT clause — older messages are never sent to the LLM",
      "Use a DO alarm to periodically summarize old messages into a summaries table, then delete the originals",
      "Migrate the entire message table to Workers KV after 10,000 rows to avoid DO storage limits"
    ],
    correct: 2,
    explanation: "Hard-deleting loses information permanently, which may be unacceptable for support agents that need long-term context. Loading only the last 20 rows with LIMIT is efficient but loses all older context entirely. Alarm-driven summarization compresses old messages into a compact representation — the agent retains long-term memory without growing the context window linearly. This is the pattern used in production memory-augmented agents."
  },
  {
    type: "freeform",
    question: "Describe a multi-agent system where a coordinator agent delegates subtasks to three specialist DO-backed agents in parallel. How does the coordinator address each specialist, pass context, and collect results?"
  }
]} />

---

<RunPromptCell
  title="Debug a common DO hibernation state-loss bug"
  description="This is the most frequent Durable Object mistake. Run this prompt to understand the root cause and the correct fix pattern."
  prompt={`I'm debugging a Cloudflare Durable Object agent. My code stores conversation history in a JavaScript array on the class instance. After a few minutes of inactivity the history is gone on the next request. Here's the code:

\`\`\`typescript
export class AgentMemory extends DurableObject {
  private history: string[] = [];

  async fetch(request: Request): Promise<Response> {
    const { message } = await request.json();
    this.history.push(message);
    return new Response(JSON.stringify(this.history));
  }
}
\`\`\`

Why does the history disappear, and what is the correct fix using Durable Object SQLite storage? Show me the corrected implementation.`}
  expectedOutput="Clear explanation that V8 isolate teardown during hibernation destroys instance-level JavaScript state. Corrected implementation using ctx.storage.sql.exec() with CREATE TABLE IF NOT EXISTS in constructor and INSERT/SELECT in the fetch handler."
/>

---

## What's next: designing tools for the Workers runtime

You now have a fully persistent agent: each user session maps to a dedicated Durable Object instance with its own SQLite database, conversation history survives hibernation cycles, and the per-instance addressing model gives you tenant isolation for free.

[[cloudflare-agents-platform-workers-to-production/03-designing-tools-for-workers-runtime|Chapter 3]] moves up the stack to **tools** — the bindings your agent can invoke to interact with the rest of Cloudflare's platform. You'll add D1 for knowledge base queries, R2 for artifact storage, and Queues for async task dispatch. The central idea: on Cloudflare Workers, your tools are native platform bindings, not HTTP endpoints. That changes everything about latency, cost, and security. No network hop, no token management, no separate auth layer — the tool is the infrastructure. For a broader view of how DOs fit into production multi-agent deployments, see [[blogs/2026-05-28-cloudflare-agents-workers-production-architecture/draft|Cloudflare Agents Production Architecture]].

---

[^1]: [Cloudflare Durable Objects documentation](https://developers.cloudflare.com/durable-objects/)
[^2]: [Durable Objects Storage API](https://developers.cloudflare.com/durable-objects/api/storage-api/)
[^3]: [Invoke methods — create stubs and send requests](https://developers.cloudflare.com/durable-objects/best-practices/create-durable-object-stubs-and-send-requests/)
[^4]: [Durable Object Alarms API](https://developers.cloudflare.com/durable-objects/api/alarms/)
[^5]: [SQLite in Durable Objects — Cloudflare Blog](https://blog.cloudflare.com/sqlite-in-durable-objects/)
[^6]: [Cloudflare Agents SDK](https://developers.cloudflare.com/agents/)
