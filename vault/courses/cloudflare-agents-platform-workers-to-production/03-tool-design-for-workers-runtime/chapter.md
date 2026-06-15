---
chapter_num: 3
course_slug: cloudflare-agents-platform-workers-to-production
title: "Designing Tools for the Cloudflare Workers Runtime (2026)"
status: awaiting-g0
author: course-author
ticket: KOEA-6699
learning_objectives:
  - "Implement Workers AI bindings and external LLM calls as agent tools"
  - "Design tool schemas that the Agents SDK can auto-discover and execute"
  - "Use Workers bindings (KV, R2, D1, Queues) as first-class agent tools"
  - "Apply tool sandboxing to prevent agents from accessing bindings they did not declare"
prerequisites_chapters:
  - "02-durable-objects-state-model"
duration_min: 50
level: Intermediate-Advanced
positions:
  - id: platform-bindings-beat-http-tools
    engagement: defends
  - id: tool-sandboxing-by-default
    engagement: defends
chapter_primary_query: "How do you design tools for a Cloudflare Workers agent in 2026?"
first_60_words_answer: "On Cloudflare Workers, agent tools are platform bindings — D1 databases, R2 buckets, Queues, and KV namespaces — declared in wrangler.toml and accessed as `env.*` properties inside your agent class. The Agents SDK dispatches tool calls by matching the LLM's JSON tool-call output to a method name on your agent class. No HTTP endpoints, no auth tokens, no network hop between tool call and execution."
faq:
  - question: "How do you add tools to a Cloudflare Workers agent?"
    answer: "Define methods on your `Agent` subclass decorated with `@tool()` from `@cloudflare/agents`. Each method receives typed arguments derived from the JSON schema you provide to the decorator. The SDK maps the LLM's tool-call output to the correct method and executes it with the parsed arguments. Workers bindings (D1, R2, KV, Queue) are available via `this.env` inside the method. ([Agents tool use](https://developers.cloudflare.com/agents/api-reference/tool-use/))"
  - question: "What is the difference between using D1 and KV as agent tools?"
    answer: "D1 is Cloudflare's managed SQLite database for relational, strongly-consistent data — ideal for structured records you need to query, join, or aggregate across users. KV is a globally distributed key-value store with eventual consistency — ideal for read-heavy, low-latency lookups where you can tolerate stale data by up to 60 seconds. Use D1 for case records, user profiles, and inventory. Use KV for feature flags, configuration, and cached read-through data."
  - question: "How do you prevent an agent from calling bindings it should not access?"
    answer: "Declare only the bindings your agent legitimately needs in wrangler.toml and pass only the required subset to the agent class via a typed `Env` interface. Do not include sensitive bindings (like Hyperdrive database connections or secrets) in the same env object accessible to the agent's tool methods. At the Workers level, bindings are isolated by worker — a Worker cannot access another Worker's bindings."
  - question: "Can a Cloudflare Workers agent call external APIs as tools?"
    answer: "Yes. Any `fetch()` call inside a tool method reaches the public internet. Wrap external API calls in tool methods that handle authentication (using a secret from `env`), error handling, and response normalization. The advantage over HTTP-based tool frameworks is that secrets stay in the Workers runtime environment — they are never sent to the LLM or exposed in tool schemas."
howto_schema:
  name: "Add D1, R2, and Queue tools to a Cloudflare Workers agent"
  steps:
    - name: "Declare D1, R2, and Queue bindings in wrangler.toml"
      text: "Add `[[d1_databases]]` with `binding = 'CASE_DB'` and `database_id`, `[[r2_buckets]]` with `binding = 'DOCS'`, and `[[queues.producers]]` with `binding = 'ESCALATION_QUEUE'` and `queue = 'escalations'` to wrangler.toml. Run `wrangler d1 create case-db` to provision the D1 database if it does not exist."
    - name: "Extend the typed Env interface to include new bindings"
      text: "In your TypeScript env interface, add `CASE_DB: D1Database`, `DOCS: R2Bucket`, and `ESCALATION_QUEUE: Queue<EscalationMessage>`. The Agents SDK passes this env to your agent class as `this.env`, making all bindings available inside tool methods."
    - name: "Define tool methods with the @tool decorator"
      text: "Annotate each tool method with `@tool({ description: '...', parameters: zodSchema })`. The SDK extracts the tool name from the method name, the description from the decorator, and the JSON schema from the Zod schema. The LLM receives these definitions and returns a tool-call object when it decides to invoke one."
    - name: "Implement D1 lookup, R2 retrieval, and Queue dispatch methods"
      text: "In `searchCaseDb`, call `this.env.CASE_DB.prepare('SELECT * FROM cases WHERE ...').bind(...).all()`. In `retrieveDocument`, call `this.env.DOCS.get(key)` and return the text body. In `escalateCase`, call `this.env.ESCALATION_QUEUE.send({ caseId, reason })` and return a confirmation string."
    - name: "Validate tool arguments before executing"
      text: "The `@tool` decorator's Zod schema validates incoming arguments automatically. Add explicit business-logic guards inside the method body for invariants the schema cannot express — e.g., that a `caseId` is a valid UUID format and not an empty string. Return a descriptive error string (not a thrown exception) so the LLM can recover and retry."
inline_assets:
  - type: diagram
    path: ./img/tool-dispatch-flow.svg
    alt: "Tool dispatch flow diagram: user message → LLM (tool schema in system prompt) → tool-call JSON → Agents SDK dispatch → agent method execution → binding call → result returned to LLM → final response to user"
  - type: diagram
    path: ./img/binding-isolation.svg
    alt: "Binding isolation diagram showing wrangler.toml bindings scoped to a single Worker, with D1, R2, and Queue bindings accessible inside the agent class but not accessible across Worker boundaries"
last_updated: 2026-06-14
sources:
  - https://developers.cloudflare.com/agents/api-reference/tool-use/
  - https://developers.cloudflare.com/d1/
  - https://developers.cloudflare.com/r2/
  - https://developers.cloudflare.com/queues/
  - https://developers.cloudflare.com/kv/
  - https://developers.cloudflare.com/workers/runtime-apis/bindings/
tags:
  - cloudflare
  - workers
  - agents
  - tools
  - d1
  - r2
  - queues
  - bindings
  - 2026
---

# Designing Tools for the Cloudflare Workers Runtime (2026)

On Cloudflare Workers, agent tools are platform bindings — D1 databases, R2 buckets, Queues, and KV namespaces — declared in wrangler.toml and accessed as `env.*` properties inside your agent class. The Agents SDK dispatches tool calls by matching the LLM's JSON tool-call output to a method name on your agent class. No HTTP endpoints, no auth tokens, no network hop between tool call and execution.

This chapter covers the complete tool model for Workers agents: the `@tool` decorator and Zod schema pattern, wiring Workers bindings as tools, sandbox isolation by wrangler.toml scope, and the three tools you'll add to make the Chapter 2 agent useful in production.

---

## The Workers tool model vs. HTTP tools

Most agent frameworks treat tools as HTTP endpoints. You define a URL, the agent calls it with a JSON body, the endpoint does something, and returns JSON. This works, but it introduces latency, authentication complexity, and operational overhead: you need to host the endpoint, manage TLS, handle auth tokens, and ensure the endpoint is up when your agent needs it.

On Cloudflare Workers, tools are methods. A Workers binding is a first-class object your agent code calls directly — no HTTP request, no network hop, no auth token:

```typescript
// HTTP tool call (typical agent framework)
const result = await fetch("https://api.internal/search", {
  method: "POST",
  headers: { Authorization: `Bearer ${apiKey}` },
  body: JSON.stringify({ query }),
});

// Workers binding call (Cloudflare agent)
const result = await this.env.CASE_DB
  .prepare("SELECT * FROM cases WHERE category = ?1")
  .bind(category)
  .all();
```

The binding version:
- Has zero additional network latency (the D1 call goes to a nearby Cloudflare data center, not through the public internet)
- Requires no authentication (the binding is scoped to your Worker — only your code can call it)
- Has no hosted endpoint to maintain (D1 exists as long as you provisioned it)
- Costs less (D1 reads are cheaper than managing a separate API service)

This isn't a minor convenience. For agents that call tools in a loop (tool → result → next tool → result → …), cutting per-tool latency from 50–100ms (HTTP) to 5–10ms (binding) reduces the total latency of a 5-tool agent chain by 250–500ms. At scale, it reduces costs proportionally.

---

## Tool dispatch in the Agents SDK

The Agents SDK handles tool dispatch transparently when you use the `@tool` decorator. Here's how the flow works:

1. At initialization, the SDK scans your agent class for methods decorated with `@tool` and builds a tool schema list.
2. On each `onMessage` call, the SDK sends the conversation history plus the tool schema to the LLM.
3. The LLM returns either a plain-text response or a tool-call object (the tool name and JSON arguments).
4. If it's a tool call, the SDK validates the arguments against the Zod schema in the decorator, then calls the corresponding method.
5. The method result is appended to the conversation as a `tool` role message.
6. The LLM is called again with the updated history, which may produce another tool call or a final response.

This loop continues until the LLM produces a non-tool-call response. The SDK handles the loop automatically when you use `this.run()` instead of calling the LLM directly.

---

## Defining tools with `@tool` and Zod

The `@tool` decorator takes a configuration object with a description (what the tool does, written for the LLM to understand) and a Zod schema defining the expected arguments:

```typescript
import { Agent, tool } from "@cloudflare/agents";
import { z } from "zod";

export class CaseAgent extends Agent<Env> {
  @tool({
    description:
      "Search the case database for cases matching a category and optional status filter. " +
      "Returns up to 10 matching cases with their IDs, summaries, and current status.",
    parameters: z.object({
      category: z
        .enum(["billing", "technical", "feature_request", "other"])
        .describe("The case category to filter by"),
      status: z
        .enum(["open", "in_progress", "resolved", "closed"])
        .optional()
        .describe("Optional status filter — omit to return all statuses"),
      limit: z
        .number()
        .int()
        .min(1)
        .max(10)
        .default(5)
        .describe("Maximum number of results to return"),
    }),
  })
  async searchCaseDb({
    category,
    status,
    limit,
  }: {
    category: string;
    status?: string;
    limit: number;
  }): Promise<string> {
    const query = status
      ? "SELECT id, summary, status FROM cases WHERE category = ?1 AND status = ?2 LIMIT ?3"
      : "SELECT id, summary, status FROM cases WHERE category = ?1 LIMIT ?2";

    const params = status ? [category, status, limit] : [category, limit];
    const result = await this.env.CASE_DB.prepare(query)
      .bind(...params)
      .all<{ id: string; summary: string; status: string }>();

    if (!result.results.length) {
      return `No ${category} cases found${status ? ` with status ${status}` : ""}.`;
    }

    return result.results
      .map((r) => `[${r.id}] ${r.summary} (${r.status})`)
      .join("\n");
  }
}
```

Key design choices in the schema:
- **Enum types over free strings**: `z.enum(["billing", "technical", ...])` constrains the LLM to valid values. Free strings let the LLM hallucinate category names that don't exist in your database.
- **Descriptions on every field**: The `.describe()` call injects the description into the JSON schema the LLM sees. Without it, the LLM guesses what each field means.
- **Return strings, not objects**: Tool method return values are appended to the conversation as text. JSON objects work, but plain English descriptions of results are often more useful to the LLM than structured JSON it needs to parse again.
- **Explicit limit cap**: Prevent the LLM from requesting 1000 results by bounding the limit in the Zod schema. The SDK rejects values outside `min(1).max(10)` before calling the method.

---

## Wiring the three core Workers tools

You'll add three tools to your Chapter 2 agent: `searchCaseDb` (D1 query), `retrieveDocument` (R2 fetch), and `escalateCase` (Queue dispatch).

### Step 1: Update wrangler.toml

```toml
name = "case-agent"
main = "src/index.ts"
compatibility_date = "2025-01-01"

[ai]
binding = "AI"

[[d1_databases]]
binding = "CASE_DB"
database_name = "case-db"
database_id = "YOUR_D1_DATABASE_ID"  # from: wrangler d1 create case-db

[[r2_buckets]]
binding = "DOCS"
bucket_name = "case-documents"       # from: wrangler r2 bucket create case-documents

[[queues.producers]]
binding = "ESCALATION_QUEUE"
queue = "escalations"                # from: wrangler queues create escalations

[[durable_objects.bindings]]
name = "CASE_AGENT"
class_name = "CaseAgent"

[[migrations]]
tag = "v1"
new_classes = ["CaseAgent"]
```

Provision the resources:

```bash
wrangler d1 create case-db
wrangler r2 bucket create case-documents
wrangler queues create escalations
```

Seed the D1 database with a schema:

```bash
wrangler d1 execute case-db --local --command="
CREATE TABLE IF NOT EXISTS cases (
  id TEXT PRIMARY KEY,
  summary TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
INSERT OR IGNORE INTO cases VALUES
  ('CASE-001', 'Payment failed on renewal', 'billing', 'open', datetime('now')),
  ('CASE-002', 'API returning 500 on /search', 'technical', 'in_progress', datetime('now')),
  ('CASE-003', 'Request for bulk export feature', 'feature_request', 'open', datetime('now'));
"
```

### Step 2: Define all three tools

```typescript
import { Agent, tool } from "@cloudflare/agents";
import { z } from "zod";

interface Env {
  AI: Ai;
  CASE_AGENT: DurableObjectNamespace;
  CASE_DB: D1Database;
  DOCS: R2Bucket;
  ESCALATION_QUEUE: Queue<EscalationMessage>;
}

interface EscalationMessage {
  caseId: string;
  reason: string;
  agentSessionId: string;
  timestamp: string;
}

export class CaseAgent extends Agent<Env> {
  @tool({
    description:
      "Search the case database for cases matching a category and optional status filter. " +
      "Call this when the user asks about existing cases, case status, or case history.",
    parameters: z.object({
      category: z.enum(["billing", "technical", "feature_request", "other"]),
      status: z.enum(["open", "in_progress", "resolved", "closed"]).optional(),
      limit: z.number().int().min(1).max(10).default(5),
    }),
  })
  async searchCaseDb({
    category,
    status,
    limit,
  }: {
    category: string;
    status?: string;
    limit: number;
  }): Promise<string> {
    const query = status
      ? "SELECT id, summary, status FROM cases WHERE category = ?1 AND status = ?2 LIMIT ?3"
      : "SELECT id, summary, status FROM cases WHERE category = ?1 LIMIT ?2";

    const params = status ? [category, status, limit] : [category, limit];
    const result = await this.env.CASE_DB.prepare(query)
      .bind(...params)
      .all<{ id: string; summary: string; status: string }>();

    if (!result.results.length) {
      return `No ${category} cases found${status ? ` with status ${status}` : ""}.`;
    }

    return result.results
      .map((r) => `[${r.id}] ${r.summary} (${r.status})`)
      .join("\n");
  }

  @tool({
    description:
      "Retrieve a support document or knowledge base article by its key. " +
      "Use this to fetch reference material, runbooks, or policy documents relevant to a case.",
    parameters: z.object({
      documentKey: z
        .string()
        .min(1)
        .describe(
          "The R2 object key for the document, e.g. 'runbooks/billing-faq.md'"
        ),
    }),
  })
  async retrieveDocument({
    documentKey,
  }: {
    documentKey: string;
  }): Promise<string> {
    // Sanitize key to prevent path traversal
    const safeKey = documentKey.replace(/\.\.\//g, "").replace(/^\//, "");
    const object = await this.env.DOCS.get(safeKey);

    if (!object) {
      return `Document '${safeKey}' not found in the knowledge base.`;
    }

    const text = await object.text();
    // Truncate to prevent context overflow
    return text.length > 4000 ? text.slice(0, 4000) + "\n[...truncated]" : text;
  }

  @tool({
    description:
      "Escalate a case to the human support team by dispatching an escalation message. " +
      "Use this when the case is urgent, the user is upset, or automated resolution is not possible. " +
      "Always confirm with the user before escalating.",
    parameters: z.object({
      caseId: z
        .string()
        .regex(/^CASE-\d+$/)
        .describe("The case ID to escalate, e.g. 'CASE-001'"),
      reason: z
        .string()
        .min(10)
        .max(500)
        .describe(
          "Clear explanation of why this case needs human review (10-500 chars)"
        ),
    }),
  })
  async escalateCase({
    caseId,
    reason,
  }: {
    caseId: string;
    reason: string;
  }): Promise<string> {
    const sessionId = this.ctx.id.toString();

    await this.env.ESCALATION_QUEUE.send({
      caseId,
      reason,
      agentSessionId: sessionId,
      timestamp: new Date().toISOString(),
    });

    // Update case status in D1
    await this.env.CASE_DB.prepare(
      "UPDATE cases SET status = 'in_progress' WHERE id = ?1"
    )
      .bind(caseId)
      .run();

    return `Escalated ${caseId} to the human support team. Reason recorded: "${reason}". The case status has been updated to 'in_progress'.`;
  }

  async onMessage(connection: Connection, message: WSMessage) {
    const text = typeof message === "string" ? message : message.toString();
    // this.run() handles the tool-call loop automatically
    const response = await this.run(text);
    connection.send(response);
  }
}
```

### Step 3: Test tool dispatch

Deploy and test with wscat:

```bash
wrangler deploy
wscat -c "wss://case-agent.<subdomain>.workers.dev/agents/case-agent/session-1"
```

Test each tool path:

```
> What billing cases are currently open?
Agent calls: searchCaseDb({ category: "billing", status: "open", limit: 5 })
Agent: I found 1 open billing case: [CASE-001] Payment failed on renewal (open).

> Can you get me the billing FAQ document?
Agent calls: retrieveDocument({ documentKey: "runbooks/billing-faq.md" })
Agent: [returns document content or "not found"]

> Please escalate CASE-001 to the human team — the customer has been waiting 3 days.
Agent calls: escalateCase({ caseId: "CASE-001", reason: "Customer has been waiting 3 days with a payment failure on renewal" })
Agent: Escalated CASE-001 to the human support team...
```

---

## Tool sandboxing: what Workers gives you by default

"Sandboxing" in most agent frameworks means writing extra middleware to check which tools an agent is allowed to call. On Cloudflare Workers, the binding scoping gives you sandboxing by construction.

A Worker can only access the bindings declared in its own `wrangler.toml`. There is no ambient access to other Workers' bindings, other D1 databases, or other R2 buckets. If `CASE_AGENT` only has `CASE_DB`, `DOCS`, and `ESCALATION_QUEUE` declared, it is physically incapable of accessing a `PAYMENTS_DB` binding that belongs to a different Worker, regardless of what the LLM outputs in its tool call.

This means:
- **No cross-Worker tool injection**: an LLM cannot be tricked into calling a binding it doesn't have
- **No credential exposure**: secrets in other Workers' environment variables are not accessible to your agent
- **No accidental cross-environment access**: your staging agent cannot accidentally write to production bindings because they're registered in different wrangler configurations

The caveat: within a single Worker, all bindings in the `Env` interface are accessible to all tool methods. If you have `CASE_DB` and `PAYMENTS_DB` both declared in the same Worker, your `searchCaseDb` tool *could* access `PAYMENTS_DB` via `this.env.PAYMENTS_DB`. The right practice is **one Worker per security domain**: keep sensitive bindings in their own Worker and communicate via Queue messages or internal API calls, not by co-locating bindings.

---

## Handling tool errors gracefully

Tool methods should return descriptive error strings rather than throwing exceptions. When a method throws, the Agents SDK catches the error and returns a generic "Tool execution failed" message — the LLM can't reason about what went wrong and often halts.

When a method returns a descriptive string, the LLM can try an alternative approach:

```typescript
// Bad: throws on error
async searchCaseDb({ category }: { category: string }) {
  const result = await this.env.CASE_DB.prepare("...").all();
  return result.results; // throws if DB is unavailable
}

// Good: returns descriptive error string
async searchCaseDb({ category }: { category: string }) {
  try {
    const result = await this.env.CASE_DB.prepare("...").bind(category).all();
    if (!result.results.length) return "No cases found for this category.";
    return result.results.map(r => `[${r.id}] ${r.summary}`).join("\n");
  } catch (e) {
    return `Database lookup failed: ${(e as Error).message}. Try a different search.`;
  }
}
```

With the error string version, the LLM might respond: "I wasn't able to search the database right now. Based on what I know about your account, let me try the escalation path instead." That's a meaningful recovery. A thrown exception gives no such option.

---

## The contrarian take: tools as infrastructure, not integrations

Most agent tool tutorials show you how to call the Stripe API, the Slack API, the Salesforce API. You get a list of HTTP endpoints wrapped in tool functions. The integration overhead — auth tokens, retry logic, rate limit handling, schema versioning — ends up being more code than the actual agent logic.

The Workers binding model flips this. Your tools aren't integrations to external services — they *are* your infrastructure. D1 is your database. R2 is your file store. Queues is your async dispatch layer. These aren't services you connect to; they're capabilities your Worker already has.

The implication is that well-designed Workers agents have fewer external dependencies than agents built on HTTP-tool frameworks. The agent that can search a D1 database, retrieve from R2, and dispatch a Queue message doesn't need to call three external APIs to do those things. It handles them internally, with the performance and reliability characteristics of the Cloudflare network rather than the public internet.

External tools (Slack notifications, Stripe refunds, CRM updates) still exist — but they're a smaller portion of the total tool surface, and they benefit from Cloudflare's egress path rather than the cold start path of a Lambda function.

---

## Chapter summary

- Workers tools are platform bindings (D1, R2, KV, Queues) declared in wrangler.toml and called directly from agent methods — no HTTP endpoints, no auth tokens, no network hop.
- The `@tool` decorator registers a method as an agent tool. The Zod schema in the decorator validates arguments, constrains LLM output to valid values, and generates the JSON schema the LLM sees.
- Return descriptive strings from tool methods (not JSON objects, not thrown exceptions) so the LLM can reason about results and recover from failures.
- Binding scoping provides tool sandboxing by construction — a Worker can only access bindings declared in its own wrangler.toml, with no cross-Worker ambient access.
- Keep sensitive bindings in separate Workers to maintain security domain separation within a single Cloudflare account.
- In the next chapter, you'll convert the agent's multi-tool flow into a Cloudflare Workflow with automatic checkpointing — making the full case-handling sequence durable and resumable across failures.
