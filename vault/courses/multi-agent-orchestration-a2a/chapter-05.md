---
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8548
course: multi-agent-orchestration-a2a
chapter_num: 5
chapter_title: "Tool-Sharing & Resource Injection with MCP"
slug: multi-agent-orchestration-a2a-chapter-05
description: "MCP and A2A are not alternatives — they are protocol layers that compose. This chapter teaches the Tool Proxy and Resource Injection patterns that let specialist agents share tools and context across an A2A network, explains the MCP-to-A2A translation mismatches that break production systems, and walks through a FastMCP SQLite server exposed as a tool-sharing endpoint for a remote Researcher agent."
vendor_tag: anthropic
content_type: article
level: Advanced
duration_min: 55
reading_time_min: 14
last_updated: 2026-06-15
chapter_primary_query: "how to share MCP tools and inject resources between A2A agents"
first_60_words_answer: "MCP handles the vertical agent-to-tool connection; A2A handles horizontal agent-to-agent delegation. Tool Proxying lets Agent A invoke Agent B's MCP-backed capabilities over A2A without ever touching Agent B's MCP server. Resource Injection lets an orchestrator supply context to a specialist via a shared MCP resource URI, preserving role boundaries on both sides. Production systems need both protocols — they compose, not compete."
prerequisites_chapters: [2]
learning_objectives:
  - Integrate an MCP server into an A2A agent's capability set without claiming MCP is A2A-native
  - Implement Tool Proxying so Agent A invokes Agent B's MCP-backed skills via the A2A protocol
  - Design a Resource Injection flow where an orchestrator supplies context to a specialist via MCP Resources
  - Map the four structural MCP-to-A2A mismatches and their production failure modes
positions:
  - id: mcp-as-interoperability-moat
    engagement: defends
tags: [A2A, MCP, tool-sharing, resource-injection, multi-agent, orchestration, tool-proxy, protocol-composition]
status: g3-passed
sources:
  - https://arxiv.org/html/2603.05637v1 # retrieved 2026-06-15
  - https://www.anthropic.com/engineering/code-execution-with-mcp # retrieved 2026-06-15
  - https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp # retrieved 2026-06-15
  - https://subhadipmitra.com/blog/2026/agent-protocol-stack # retrieved 2026-06-15
  - https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI # retrieved 2026-06-15
  - https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02 # retrieved 2026-06-15
  - https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1 # retrieved 2026-06-15
  - https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one # retrieved 2026-06-15
  - https://www.augmentcode.com/guides/a2a-vs-mcp # retrieved 2026-06-15
  - https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a # retrieved 2026-06-15
faq:
  - question: "What is the difference between MCP and A2A at the architecture level?"
    answer: "MCP is a vertical protocol — one agent, many tools. The agent is the active party; the tool is a passive capability provider with no autonomy, no independent task state, and no peer authentication context. A2A is a horizontal protocol — many agents, each autonomous. Agents maintain their own task lifecycle, authentication context, and failure-recovery logic. The correct production stack runs MCP within each specialist's own scope (agent-to-tool) and A2A across specialist boundaries (agent-to-agent). Mixing the two — for example, giving an orchestrator direct MCP access to a specialist's tools — breaks both protocols' trust models. ([AI Agent Protocol Ecosystem Map 2026, digitalapplied.com](https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp))"
  - question: "What is the confused-deputy problem in tool proxying, and how do you prevent it?"
    answer: "The confused-deputy problem occurs when Agent B proxies an MCP tool call on behalf of an orchestrator using its own standing MCP credential — granting the originating task privileges it was never given. Agent B may execute a database write or an API call that the orchestrator's user or task scope never authorized. The mitigation is threefold: mint a fresh, narrowly scoped OAuth 2.1 token per proxied call (scoped to the specific MCP tool, not Agent B's full MCP access); place an MCP gateway proxy (Gravitee, Pomerium) between agents and MCP servers to enforce per-tool authorization at the network layer; use short-lived signed identity assertions rather than long-lived credentials in agent processes. ([MCP Proxy: How It Works and Why Architects Need One, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one))"
  - question: "Why should large context be injected as an MCP Resource rather than embedded in an A2A task message?"
    answer: "For large payloads — database schemas, historical datasets, long reference documents — embedding context in the A2A task message body inflates the payload and forces the specialist to load that content into its context window immediately on arrival, regardless of whether it needs all of it. Resource injection externalizes the data to a URI the specialist resolves on demand via resources/read. The specialist loads only what it needs, when it needs it. As an additional benefit, the upcoming MCP resources/subscribe extension (RC for the 2026-07-28 spec) enables the specialist to receive updates when context changes without polling. ([Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI))"
---

# Tool-Sharing & Resource Injection with MCP

> **Chapter 5 of 10 · 55 min (prose ~14 min + 25 min hands-on exercise)**

MCP handles the vertical agent-to-tool connection; A2A handles horizontal agent-to-agent delegation. Tool Proxying lets Agent A invoke Agent B's MCP-backed capabilities over A2A without ever touching Agent B's MCP server. Resource Injection lets an orchestrator supply context to a specialist via a shared MCP resource URI, preserving role boundaries on both sides. Production systems need both protocols — they compose, not compete.

---

## The Local Bus and the Network Protocol

MCP is USB. A2A is HTTP. Both move data. Both are protocols. But they operate at different architectural layers, and confusing them breaks multi-agent systems in ways that are hard to diagnose.

MCP (Model Context Protocol) handles the vertical connection between an agent and its tools. The agent is the active party; the tool is passive. When your specialist queries a database, calls an API, or reads a file through an MCP server, MCP is the correct abstraction. The tool has no autonomy, no independent state, and no understanding of why it was called.

A2A handles horizontal coordination between autonomous agents. When an orchestrator delegates a sub-task to a specialist that has its own reasoning, its own tools, and its own task lifecycle, A2A is the correct abstraction. The peer agent is not passive — it can pause, push back, fail, and recover independently.

> "The critical distinction most people miss: MCP treats external systems as tools for agents to use. A2A treats other agents as peers to collaborate with. An agent using MCP to query a database is fundamentally different from an agent using A2A to delegate a sub-task to a specialist agent. The trust models are different. The failure modes are different. The security boundaries are different." — [The Agent Protocol Stack, subhadipmitra.com](https://subhadipmitra.com/blog/2026/agent-protocol-stack)

In production, these protocols compose rather than compete. Each specialist maintains its own MCP connections to its own tools. Inter-agent coordination flows over A2A exclusively. That clean boundary is the subject of this chapter. For the Agent Silo problem that makes this boundary necessary, see [[multi-agent-orchestration-a2a/chapter-01|Chapter 1: Why Your Best Agents Can't Talk to Each Other — and How A2A Fixes That]]. For the A2A wire format and task lifecycle that underpins every pattern in this chapter, see [[multi-agent-orchestration-a2a/chapter-02|Chapter 2: A2A Protocol Architecture — The Message Flow (2026)]].

> "A2A expands agent-to-agent collaboration, while MCP is growing into a foundational layer for context sharing, tool interoperability, and cross-framework coordination." — [Azure Blog, Microsoft](https://azure.microsoft.com/en-us/blog/agent-factory-connecting-agents-apps-and-data-with-new-open-standards-like-mcp-and-a2a)

---

## MCP Primitives: A Quick Primer

Before composing MCP with A2A, you need to know which MCP primitive to reach for. The spec defines three distinct server-side constructs with different execution models and trust surfaces.

**Tools** are callable functions with JSON Schema inputs. They execute actions — database reads, API calls, file writes — and return structured output via `tools/call`. They carry the highest security surface because they modify world state.

**Resources** are read-only data identified by URI. Exposed via `resources/list` and `resources/read`, they never modify state. Think of them as the context an agent pulls into its reasoning before acting: schemas, documentation, configuration, historical data.

> "Resources are read-only reference material — documentation, schemas, configuration, templates. They provide context that helps agents make better decisions. Where tools perform actions and prompts orchestrate workflows, resources serve information on request." — [MCP Prompts and Resources: The Primitives You're Not Using, dev.to](https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1)

**Prompts** are server-supplied templates with typed arguments for standardizing how tools are invoked across agent implementations — useful for enforcing consistent call patterns at scale, though rare in current production deployments.

Most community MCP servers only implement tools. Resources are underused. This quality gap matters: tool-only agents spend context-window tokens on intermediate tool results that could be externalized as resources and resolved on demand. The Resource Injection pattern in this chapter closes that gap.

<KnowledgeCheck
  question="Which MCP primitive is the correct choice for supplying a database schema to a specialist before it runs queries?"
  answers={[
    "A Tool, because the orchestrator needs to call into the specialist's MCP server to push the schema",
    "A Resource, because schemas are read-only reference data that the specialist resolves by URI when needed",
    "A Prompt, because the schema defines how the specialist should structure its tool invocations",
    "None — schema context should always be embedded directly in the A2A task message body"
  ]}
  correct={1}
/>

---

## Advertising MCP-Backed Capabilities Without Misrepresenting MCP

When a specialist has MCP-backed capabilities, it must tell the network what it can do via its A2A Agent Card — without implying that orchestrators can directly access its MCP server. The correct framing is outcome-based, not implementation-based:

```json
{
  "skills": [
    {
      "id": "equity_price_history",
      "name": "Equity Price History",
      "description": "Returns OHLCV data for a given ticker and date range. Backed by local SQL database via MCP.",
      "tags": ["market-data", "sql", "time-series"],
      "inputModes": ["text/plain", "application/json"],
      "outputModes": ["application/json"]
    }
  ]
}
```

The `description` field may note MCP backing as a transparency signal — "Backed by local SQL database via MCP" tells orchestrators this is a fast local source rather than a slow external API. But the `url` in the Agent Card points to the agent's A2A endpoint, never to its MCP server. The MCP connection is the agent's private implementation. Orchestrators must not depend on it. Scoping MCP servers to their owning specialist agents also prevents a common context-rot failure: loading every tool from every agent into every agent's context window.

> "For multi-agent coding workspaces, scoping MCP servers to specialist agents avoids loading every tool into every agent's context window." — [A2A vs MCP, Augment Code](https://www.augmentcode.com/guides/a2a-vs-mcp)

---

## Tool Proxying: Agent A Uses Agent B's MCP-Backed Skills

Tool proxying is the pattern where an orchestrator (Agent A) needs a capability it does not own and obtains it by delegating over A2A to a specialist (Agent B). Agent B fulfils the request using its own MCP server. Agent A never holds Agent B's database credentials or MCP server address.

> "the agent does not need custom scraping code – it just 'calls the tool by name'" — [A2A+MCP Practical Guide, medium.com/fossible](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02)

The complete call chain: Orchestrator sends an A2A task → Agent B's A2A handler receives it → Agent B invokes `tools/call` on its local MCP server → SQLite returns rows → Agent B packages the result as an A2A artifact → Orchestrator receives it and forwards it downstream. Agent B's MCP invocation is opaque to the caller at every step.

```python
# Agent B (Market Data Specialist) — A2A handler that wraps an MCP tool call
async def handle_task(task: A2ATask) -> A2AArtifact:
    params = task.message.parts[0].data  # {"ticker": "AAPL", "start": "...", "end": "..."}
    results = await mcp_client.call_tool("query_price_history", params)
    return A2AArtifact(mimeType="application/json", data=results)
```

The reason to route through A2A rather than allowing direct MCP access is correctness, not convenience. Agent B maintains its own task lifecycle, authentication context, and failure-handling logic. An orchestrator that reaches directly into Agent B's MCP server bypasses Agent B's domain logic, couples itself to Agent B's internal implementation, and creates an authorization surface that neither agent owns cleanly. The A2A boundary prevents exactly this coupling.

<KnowledgeCheck
  question="Why does the orchestrator send an A2A task to Agent B rather than calling Agent B's MCP server directly?"
  answers={[
    "Because MCP operates on a different network port that firewall rules typically block at the agent boundary",
    "Because A2A maintains Agent B's task lifecycle and auth context — direct MCP access bypasses Agent B's domain logic and couples the orchestrator to its implementation",
    "Because A2A has lower latency than MCP for the short synchronous calls typical in tool proxying",
    "Because the MCP specification prohibits multiple clients from connecting to the same server simultaneously"
  ]}
  correct={1}
/>

---

## Resource Injection: Sharing Context Without Breaking Role Boundaries

Resource injection is the pattern where an orchestrator supplies context to a specialist — a schema, a constraint set, a prior research artifact — before the A2A task begins. The orchestrator cannot directly populate the specialist's context window; that would require knowledge of the specialist's internal structure. Instead, it writes context to a shared MCP server as a resource URI, and the specialist reads it on task start.

```python
# Orchestrator: store context before dispatching the A2A task
@server.tool()
async def store_research_context(task_id: str, schema: dict, constraints: dict) -> str:
    shared_state[task_id] = {"schema": schema, "constraints": constraints}
    return f"docs://{task_id}/context"
```

```python
# Specialist: read injected context before running tools
context = await mcp_client.read_resource(f"docs://{task_id}/context")
schema = context["schema"]
# validate query scope against schema, then invoke tools
```

> "your agents do not need to talk to each other, but should coordinate through shared infrastructure instead." — [Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI)

Role boundaries hold on both sides: the specialist does not know who wrote the context; the orchestrator does not know how the specialist will use it. Both interact with a canonical URI. The specialist remains autonomous; the orchestrator remains decoupled. Embedding large context directly in the A2A task message body inflates the payload and forces the specialist to load all of it into its context window immediately. Resource injection externalizes that data to a URI the specialist resolves on demand, with the option to cache repeated reads.

---

## The MCP-to-A2A Translation Layer

Four structural mismatches between MCP and A2A produce predictable failures when you compose them without deliberate handling:

| Mismatch | MCP assumption | A2A assumption | Production failure |
|----------|---------------|----------------|-------------------|
| **Latency** | Short synchronous calls (<2s) | Can be long-running and async | Wrapping a slow MCP call as a synchronous A2A response times out |
| **Error semantics** | JSON-RPC error: code + message | Structured `TaskFailedEvent` | Unhandled MCP errors surface as opaque A2A failures the orchestrator cannot recover from |
| **Cancellation** | No cancellation primitive | `tasks/cancel` | A long-running MCP tool call cannot be cancelled mid-flight; the A2A layer must manage timeouts externally |
| **Token scope** | Bearer token bound to MCP server | DPoP-bound per-agent identity | Agent B must never forward its MCP access token to Agent A — that grants the orchestrator direct MCP access under Agent B's identity |

<Callout type="warning">
  The token scope mismatch is the most dangerous failure mode. When Agent B proxies an MCP tool call on behalf of an orchestrator, it must mint a new, narrowly scoped OAuth 2.1 token per call — scoped to the specific MCP tool, not Agent B's full MCP access. An MCP gateway proxy (Gravitee, Pomerium, Kong AI Gateway) sitting between agents and MCP servers enforces per-agent, per-tool authorization at the network layer, independently of agent code. Direct tool calls also consume context tokens for every definition and result; agents that write code to call tools instead scale significantly better. ([Code execution with MCP, Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp) · [MCP Proxy: How It Works, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one))
</Callout>

---

## Hands-On Exercise: Connect a Local MCP SQLite Server to an A2A Agent

**Time estimate:** 25 minutes

You will build a Market Data Specialist that wraps a local SQLite database as an MCP server, exposes an A2A endpoint for incoming tasks, and allows a remote Researcher agent to query the database through the specialist — without the Researcher ever touching the MCP server directly.

**Step 1 — Build the MCP server with FastMCP.**

```python
from mcp.server.fastmcp import FastMCP
import sqlite3

mcp = FastMCP("market-data-mcp")

@mcp.tool()
def query_price_history(ticker: str, start_date: str, end_date: str) -> list[dict]:
    """Fetch OHLCV data for a ticker and date range."""
    conn = sqlite3.connect("market_data.db")
    rows = conn.execute(
        "SELECT date, open, high, low, close, volume FROM prices "
        "WHERE ticker=? AND date BETWEEN ? AND ? ORDER BY date",
        (ticker, start_date, end_date)
    ).fetchall()
    return [dict(zip(["date","open","high","low","close","volume"], r)) for r in rows]

@mcp.resource("docs://schema")
def db_schema() -> str:
    """Exposes the database schema for Resource Injection."""
    return "Table: prices(ticker TEXT, date TEXT, open REAL, high REAL, low REAL, close REAL, volume INT)"
```

**Step 2 — Wrap the MCP tool call in an A2A task handler.**

```python
async def handle_task(task: A2ATask) -> A2AArtifact:
    params = task.message.parts[0].data
    results = await mcp_client.call_tool("query_price_history", params)
    return A2AArtifact(mimeType="application/json", data=results)
```

**Step 3 — From the Researcher agent, dispatch the A2A task.**

The Researcher has no direct MCP connection to the Specialist. The Agent Card's description field ("Backed by local SQL database via MCP") already tells the Researcher what capability it is delegating to. The Researcher passes only task parameters in the A2A message body.

```python
# Researcher: dispatch via A2A — no direct MCP connection to the Specialist's server
# The Agent Card description ("Backed by local SQL database via MCP") supplies all
# capability context; the Specialist resolves its own MCP resources internally.
task = await a2a_client.send_task(
    agent_url="http://localhost:8001",
    message=A2AMessage(parts=[DataPart(data={
        "ticker": "AAPL",
        "start_date": "2024-01-01",
        "end_date": "2024-12-31"
    })])
)
artifact = await a2a_client.await_task(task.id)
```

**Success criteria:**
- The Researcher's `a2a_client.send_task` call succeeds and returns a task ID
- The artifact contains a JSON array of OHLCV rows (not an error object)
- The Researcher holds no SQLite connection — all database access is via the Specialist's A2A endpoint
- Replacing the SQLite database with mock data on the Specialist side produces a correct artifact without any change to the Researcher's code

---

## What's Next

You now have tool-sharing and resource injection working across two A2A agents. The next challenge is choosing the right topology for orchestrating three or more of them — chains, hubs, and meshes each make different tradeoffs in bottleneck risk and coordination overhead.

[[multi-agent-orchestration-a2a/chapter-06|Chapter 6: Orchestration Patterns — Chains, Hubs, and Meshes]] maps those topologies, shows the Orchestrator Bottleneck failure mode in hub-and-spoke systems, and implements a peer-to-peer delegation pattern where agents hand off directly without routing back through a central coordinator.

---

*Sources: [AI Agent Protocol Ecosystem Map 2026, DigitalApplied](https://www.digitalapplied.com/blog/ai-agent-protocol-ecosystem-map-2026-mcp-a2a-acp-ucp) · [MCP Prompts and Resources, dev.to](https://dev.to/aws-heroes/mcp-prompts-and-resources-the-primitives-youre-not-using-3oo1) · [A2A+MCP Practical Guide, Fossible](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) · [Multi-agent systems with MCP, Pluralsight](https://www.pluralsight.com/resources/blog/ai-and-data/multi-agent-systems-mcp-AI) · [Code execution with MCP, Anthropic Engineering](https://www.anthropic.com/engineering/code-execution-with-mcp) · [MCP Proxy: How It Works, Gravitee](https://www.gravitee.io/blog/mcp-proxy-how-it-works-and-why-architects-need-one) · [A2A vs MCP, Augment Code](https://www.augmentcode.com/guides/a2a-vs-mcp)*
