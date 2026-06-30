---
chapter_num: 6
course_slug: cloudflare-agents-platform-workers-to-production
title: "MCP: Turning Your Cloudflare Workers Agent into a Peer (2026)"
status: g3-passed
author: course-author
ticket: KOEA-6699
learning_objectives:
  - "Expose your Workers agent's tools as an MCP server endpoint"
  - "Test the MCP surface with Claude Desktop or a local MCP client"
  - "Combine MCP (tool-sharing) with A2A (agent-to-agent delegation) for cross-vendor workflows"
  - "Apply access control to your MCP endpoint using Cloudflare Access"
prerequisites_chapters:
  - "03-tool-design-for-workers-runtime"
duration_min: 40
level: Intermediate-Advanced
positions:
  - id: mcp-as-agent-peer-protocol
    engagement: defends
  - id: cloudflare-access-for-mcp-auth
    engagement: defends
chapter_primary_query: "How do you expose a Cloudflare Workers agent as an MCP server in 2026?"
first_60_words_answer: "A Cloudflare Workers agent can expose its tools as an MCP server by adding a `/mcp` route handler that implements the Model Context Protocol. The Agents SDK includes an `McpAgent` base class that wires the MCP JSON-RPC protocol to your existing `@tool` methods automatically. Claude Desktop, Cursor, and other MCP clients can then invoke your agent's tools directly — same codebase, same global edge deployment, no separate MCP microservice required."
faq:
  - question: "What is MCP and why does it matter for Cloudflare agents?"
    answer: "The Model Context Protocol (MCP) is an open standard for exposing tools and resources from any server to any LLM client. For Cloudflare agents, MCP means your agent's tools (D1 queries, R2 lookups, Queue dispatches) are callable from Claude Desktop, Cursor, other agents, or any MCP-compatible client — without building a separate API. The agent becomes a peer in a multi-agent network, not just a chat endpoint. ([MCP spec](https://spec.modelcontextprotocol.io/))"
  - question: "How does McpAgent differ from a regular Cloudflare Workers Agent?"
    answer: "`McpAgent` extends `Agent` and adds MCP protocol handling: tool listing (`tools/list`), tool execution (`tools/call`), and resource listing (`resources/list`). Methods decorated with `@tool` are automatically exposed via the MCP protocol. `McpAgent` also handles the Streamable HTTP transport that modern MCP clients expect, including Server-Sent Events for streaming responses. ([Cloudflare Agents MCP](https://developers.cloudflare.com/agents/api-reference/mcp/))"
  - question: "How do you secure an MCP endpoint on Cloudflare Workers?"
    answer: "Use Cloudflare Access to protect the `/mcp` route. Add an Access policy that requires a service token (for machine-to-machine clients) or a user identity (for human-operated clients like Claude Desktop). The Access middleware runs at the Cloudflare edge before the request reaches your Worker — unauthenticated requests receive a 401 without ever touching your agent code. ([Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/))"
  - question: "Can an MCP server on Workers handle multiple concurrent MCP clients?"
    answer: "Yes. Each MCP client connection is routed to a Durable Object instance (because `McpAgent` extends `Agent`, which extends `DurableObject`). Multiple clients connecting with different session IDs get their own isolated DO instances. Cloudflare's routing handles the fan-out transparently. ([Cloudflare Agents MCP](https://developers.cloudflare.com/agents/api-reference/mcp/))"
howto_schema:
  name: "Expose a Cloudflare Workers agent as an MCP server with Cloudflare Access auth"
  steps:
    - name: "Replace Agent with McpAgent in your agent class"
      text: "Change `extends Agent<Env>` to `extends McpAgent<Env>` in your agent class definition. Import `McpAgent` from `@cloudflare/agents`. All existing `@tool` decorated methods are automatically exposed via the MCP protocol without further changes."
    - name: "Add the MCP route to your Worker's fetch handler"
      text: "In `src/index.ts`, add a route check: if the URL path starts with `/mcp`, call `routeAgentRequest(request, env)` with the McpAgent class. The Agents SDK handles the MCP handshake, session management, and Streamable HTTP transport."
    - name: "Test the MCP endpoint with the MCP Inspector"
      text: "Run `npx @modelcontextprotocol/inspector` and connect to `https://your-worker.workers.dev/mcp`. The Inspector lists all exposed tools, lets you invoke them with test arguments, and shows the raw JSON-RPC response. Verify each tool returns the expected output before connecting a real client."
    - name: "Connect Claude Desktop to the MCP endpoint"
      text: "Add the MCP server to Claude Desktop's config at `~/Library/Application Support/Claude/claude_desktop_config.json`: `{ \"mcpServers\": { \"case-agent\": { \"url\": \"https://your-worker.workers.dev/mcp\" } } }`. Restart Claude Desktop. Your agent's tools appear in the Claude Desktop tool panel and can be invoked from any conversation."
    - name: "Protect the endpoint with a Cloudflare Access service token"
      text: "Create an Access policy in the Cloudflare dashboard targeting `your-worker.workers.dev/mcp*`. Add a service token as the allowed principal. Add the token credentials to Claude Desktop's MCP config as Authorization headers. The Access policy blocks all requests without a valid token at the edge."
inline_assets:
  - type: diagram
    path: ./img/mcp-agent-architecture.svg
    alt: "MCP agent architecture diagram showing Claude Desktop and a second agent (Agent B) both connecting to the Cloudflare Workers MCP endpoint at /mcp, the McpAgent DO routing tool calls to Workers bindings (D1, R2, Queue), and Cloudflare Access intercepting unauthenticated requests at the edge"
  - type: diagram
    path: ./img/a2a-mcp-combined-flow.svg
    alt: "A2A + MCP combined flow diagram: Orchestrator Agent issues a task to the Workers agent via A2A protocol, Workers agent executes tools via Workers bindings, and can also expose those tools as MCP for direct access by Claude Desktop"
last_updated: 2026-06-14
sources:
  - https://spec.modelcontextprotocol.io/
  - https://developers.cloudflare.com/agents/api-reference/mcp/
  - https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/
  - https://developers.cloudflare.com/cloudflare-one/identity/service-tokens/
  - https://blog.cloudflare.com/remote-model-context-protocol-servers-mcp/
tags:
  - cloudflare
  - mcp
  - model-context-protocol
  - agents
  - a2a
  - cloudflare-access
  - tool-sharing
  - 2026
---

# MCP: Turning Your Cloudflare Workers Agent into a Peer (2026)

A Cloudflare Workers agent can expose its tools as an MCP server by adding a `/mcp` route handler that implements the Model Context Protocol. The Agents SDK includes an `McpAgent` base class that wires the MCP JSON-RPC protocol to your existing `@tool` methods automatically. Claude Desktop, Cursor, and other MCP clients can then invoke your agent's tools directly — same codebase, same global edge deployment, no separate MCP microservice required.

This chapter adds an MCP endpoint to the Chapter 3 case agent, tests it with the MCP Inspector and Claude Desktop, and secures it with a Cloudflare Access service token.

---

## What MCP is and why it changes the agent architecture

The Model Context Protocol is an open standard that defines how a tool-providing server communicates with an LLM client. It specifies a JSON-RPC protocol for tool listing (`tools/list`), tool invocation (`tools/call`), resource exposure (`resources/list`), and prompt injection (`prompts/get`).

Before MCP, if you wanted two agents to share tools, you built an API contract between them: define an endpoint, document the schema, handle auth, version the interface. MCP replaces this with a standard protocol both agents understand natively.

For Cloudflare agents specifically, MCP enables two scenarios that would otherwise require significant infrastructure work:

**External client access**: Claude Desktop, Cursor, Continue.dev, and dozens of other MCP-compatible clients can call your agent's tools directly. A user in Claude Desktop can say "look up case CASE-001 for me" and Claude calls your `searchCaseDb` tool via MCP — even though Claude Desktop has no knowledge of your D1 database schema.

**Agent-to-agent tool sharing**: an orchestrator agent (running anywhere — another Worker, a Lambda, a local script) can discover your agent's tools via `tools/list` and invoke them as part of its own reasoning loop. Your Cloudflare agent becomes a capability provider in a multi-agent network.

---

## McpAgent: the Agents SDK's MCP server primitive

The Agents SDK's `McpAgent` class extends `Agent` with MCP protocol handling. The migration from a regular agent to an MCP-capable agent is minimal:

```typescript
// Before: regular agent
import { Agent } from "@cloudflare/agents";
export class CaseAgent extends Agent<Env> { ... }

// After: MCP-capable agent
import { McpAgent } from "@cloudflare/agents";
export class CaseAgent extends McpAgent<Env, {}, {}> { ... }
```

All `@tool` decorated methods are automatically exposed via MCP. `McpAgent` handles:
- **MCP handshake**: the `initialize` / `initialized` JSON-RPC exchange
- **Tool listing**: `tools/list` returns all `@tool` methods with their names, descriptions, and JSON schemas
- **Tool invocation**: `tools/call` validates arguments, calls the method, and returns the result
- **Streamable HTTP transport**: Server-Sent Events stream for clients that support streaming tool output

---

## Step 1: Convert to McpAgent

In `src/agent.ts`, change the base class:

```typescript
import { McpAgent, tool } from "@cloudflare/agents";
import { z } from "zod";

export class CaseAgent extends McpAgent<Env, {}, {}> {
  // All @tool methods from Chapter 3 remain unchanged
  @tool({
    description: "Search the case database for cases matching a category.",
    parameters: z.object({
      category: z.enum(["billing", "technical", "feature_request", "other"]),
      status: z.enum(["open", "in_progress", "resolved", "closed"]).optional(),
      limit: z.number().int().min(1).max(10).default(5),
    }),
  })
  async searchCaseDb({ category, status, limit }: {
    category: string;
    status?: string;
    limit: number;
  }): Promise<string> {
    // Identical to Chapter 3 implementation
    const query = status
      ? "SELECT id, summary, status FROM cases WHERE category = ?1 AND status = ?2 LIMIT ?3"
      : "SELECT id, summary, status FROM cases WHERE category = ?1 LIMIT ?2";

    const params = status ? [category, status, limit] : [category, limit];
    const result = await this.env.CASE_DB.prepare(query)
      .bind(...params)
      .all<{ id: string; summary: string; status: string }>();

    if (!result.results.length) return `No ${category} cases found.`;
    return result.results.map(r => `[${r.id}] ${r.summary} (${r.status})`).join("\n");
  }

  @tool({
    description: "Retrieve a document from the knowledge base by its key.",
    parameters: z.object({
      documentKey: z.string().min(1).describe("R2 object key, e.g. 'runbooks/billing-faq.md'"),
    }),
  })
  async retrieveDocument({ documentKey }: { documentKey: string }): Promise<string> {
    const safeKey = documentKey.replace(/\.\.\//g, "").replace(/^\//, "");
    const object = await this.env.DOCS.get(safeKey);
    if (!object) return `Document '${safeKey}' not found.`;
    const text = await object.text();
    return text.length > 4000 ? text.slice(0, 4000) + "\n[...truncated]" : text;
  }

  @tool({
    description: "Escalate a case to the human support team.",
    parameters: z.object({
      caseId: z.string().regex(/^CASE-\d+$/),
      reason: z.string().min(10).max(500),
    }),
  })
  async escalateCase({ caseId, reason }: { caseId: string; reason: string }): Promise<string> {
    await this.env.ESCALATION_QUEUE.send({
      caseId,
      reason,
      agentSessionId: this.ctx.id.toString(),
      timestamp: new Date().toISOString(),
    });
    await this.env.CASE_DB.prepare("UPDATE cases SET status = 'in_progress' WHERE id = ?1")
      .bind(caseId).run();
    return `Escalated ${caseId}. Reason: "${reason}". Status updated to 'in_progress'.`;
  }
}
```

---

## Step 2: Add the MCP route to the Worker

Update `src/index.ts` to route `/mcp` requests to the `McpAgent`:

```typescript
import { routeAgentRequest } from "@cloudflare/agents";
import { CaseAgent } from "./agent";

export { CaseAgent };

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // Route all /mcp paths to the McpAgent
    if (url.pathname.startsWith("/mcp")) {
      return routeAgentRequest(request, env, { agent: env.CASE_AGENT });
    }

    // Regular WebSocket chat route
    const agentResponse = await routeAgentRequest(request, env);
    if (agentResponse) return agentResponse;

    return new Response("Case Agent — chat via WebSocket or MCP at /mcp", {
      status: 200,
    });
  },
};
```

Deploy:
```bash
wrangler deploy
```

---

## Step 3: Test with the MCP Inspector

The MCP Inspector is a browser-based tool for testing MCP servers:

```bash
npx @modelcontextprotocol/inspector
```

Connect to: `https://case-agent.<subdomain>.workers.dev/mcp`

In the Inspector:
1. Click **List Tools** — verify `searchCaseDb`, `retrieveDocument`, and `escalateCase` appear with their descriptions and schemas.
2. Click **searchCaseDb** → set `category: "billing"` → **Run Tool** — verify it returns the D1 query results.
3. Click **retrieveDocument** → set `documentKey: "runbooks/billing-faq.md"` → **Run Tool** — verify the R2 fetch (or "not found" if the document doesn't exist yet).

The Inspector shows raw JSON-RPC request/response pairs — useful for debugging schema issues before connecting a production client.

---

## Step 4: Connect Claude Desktop

Add the MCP server to Claude Desktop's configuration:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "case-agent": {
      "url": "https://case-agent.<subdomain>.workers.dev/mcp",
      "transport": "streamable-http"
    }
  }
}
```

Restart Claude Desktop. In any conversation, you'll see the case-agent tools in the tool panel. Test with:

```
"Look up all open billing cases in the case database"
```

Claude calls `searchCaseDb({ category: "billing", status: "open", limit: 5 })` via MCP and returns the results inline in the conversation — the D1 query runs on your Workers agent, the result surfaces in Claude Desktop.

---

## Step 5: Secure with Cloudflare Access service tokens

An unprotected MCP endpoint is a direct path to your D1 database and Queue. Protect it with Cloudflare Access:

**1. Create an Access Application**

In the Cloudflare dashboard → Zero Trust → Access → Applications → Add Application:
- Type: **Self-hosted**
- Application Domain: `case-agent.<subdomain>.workers.dev`
- Path: `/mcp*`
- Policy: allow **Service Auth** only

**2. Create a Service Token**

Zero Trust → Access → Service Auth → Service Tokens → Create Service Token. Note the **Client ID** and **Client Secret**.

**3. Update Claude Desktop config with token**

```json
{
  "mcpServers": {
    "case-agent": {
      "url": "https://case-agent.<subdomain>.workers.dev/mcp",
      "transport": "streamable-http",
      "headers": {
        "CF-Access-Client-Id": "YOUR_CLIENT_ID.access",
        "CF-Access-Client-Secret": "YOUR_CLIENT_SECRET"
      }
    }
  }
}
```

Requests without the Access headers now receive a 401 at the Cloudflare edge — your Worker code never executes, and no binding access occurs. The token can be rotated without changing your Worker code.

---

## Combining MCP with A2A for multi-agent workflows

MCP handles tool-sharing (one agent exposes tools, another uses them). The Agent-to-Agent (A2A) protocol handles task delegation (one agent assigns a complete task to another agent). These are complementary, not competing.

A practical combined architecture for production:

```
Orchestrator Agent (external)
  │
  ├─── MCP: invoke searchCaseDb directly for quick lookups
  │         (no overhead of a full A2A task)
  │
  └─── A2A: delegate "Handle case CASE-001 end-to-end"
            (triggers Workflow, escalation, status update)
            returns structured result when Workflow completes
```

The `McpAgent` supports this because it's also an `Agent` — it handles WebSocket connections for conversational interaction AND MCP tool calls in the same codebase. The distinction is in the client: a direct user uses the WebSocket interface; another agent uses MCP for tool calls or sends a task via A2A protocol.

To expose the agent as an A2A endpoint alongside MCP:

```typescript
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname.startsWith("/mcp")) {
      return routeAgentRequest(request, env, { agent: env.CASE_AGENT });
    }

    // A2A task endpoint — accepts structured task assignments from orchestrators
    if (url.pathname === "/tasks" && request.method === "POST") {
      const task = await request.json();
      const instance = await env.CASE_WORKFLOW.create({
        params: {
          caseId: task.caseId,
          userMessage: task.instruction,
          sessionId: task.taskId,
        },
      });
      return Response.json({ taskId: task.taskId, workflowInstanceId: instance.id });
    }

    const agentResponse = await routeAgentRequest(request, env);
    if (agentResponse) return agentResponse;

    return new Response("Case Agent", { status: 200 });
  },
};
```

---

## The contrarian take: MCP servers as routes, not microservices

The conventional architecture for MCP is a separate microservice: a dedicated Node.js or Python server that runs the MCP protocol, connects to your databases, and deploys separately from your main application.

This makes sense when your tools live in an existing application that isn't Workers-native. But if you're building a Cloudflare agent from scratch, the `McpAgent` base class gives you MCP as a route handler — not a service. Your D1 queries, R2 fetches, and Queue dispatches are already Workers bindings. Adding MCP is adding a route prefix, not adding infrastructure.

The operational consequence: your MCP server has the same global presence (330+ PoPs), the same deployment lifecycle (one `wrangler deploy`), and the same cost model (pay per request) as your agent. There's no MCP server to operate separately, no additional scaling configuration, no separate monitoring setup. The MCP surface is just your agent, seen from a different protocol.

---

## Chapter summary

- `McpAgent` extends `Agent` and adds MCP protocol handling. All `@tool` decorated methods are automatically exposed via `tools/list` and `tools/call`.
- Add a `/mcp` route in your Worker's fetch handler, routing to the McpAgent via `routeAgentRequest()`.
- Test with `npx @modelcontextprotocol/inspector` before connecting production clients.
- Secure the `/mcp` endpoint with a Cloudflare Access service token — the edge blocks unauthenticated requests without your Worker code executing.
- MCP (tool-sharing) and A2A (task delegation) are complementary. A McpAgent can serve both protocols from the same codebase.
- In the final chapter, you'll add production observability: distributed trace IDs across Worker/Workflow/DO, memory budgets, cost dashboards, and prompt injection defenses.
