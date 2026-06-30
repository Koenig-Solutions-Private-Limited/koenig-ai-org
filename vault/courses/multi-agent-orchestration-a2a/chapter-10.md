---
date: 2026-06-15
author: chapter-author-1
ticket: KOEA-8578
course: multi-agent-orchestration-a2a
chapter_num: 10
title: "Capstone — Building the Sovereign Agent Network"
slug: multi-agent-orchestration-a2a-chapter-10
description: "Every building block from the course converges here: four A2A agents form a runnable Cross-Vendor Investment Researcher network. This capstone wires AgentCard discovery, MCP-backed tool proxying, DPoP-hardened OAuth auth, task resumability across agent failures, and a single distributed trace linking all four handoffs into one production-testable system."
vendor_tag: google
content_type: article
level: Advanced
duration_min: 70
reading_time_min: 18
last_updated: 2026-06-15
chapter_primary_query: "how to build a four-agent A2A sovereign network with MCP tool proxying, DPoP auth, resumability, and distributed tracing"
first_60_words_answer: "Start four Docker containers — Orchestrator, Market Data Specialist (MCP-backed SQLite), Sentiment Analyst, Financial Writer. The orchestrator discovers all three via AgentCards, dispatches sequential A2A tasks, and enforces DPoP-bound OAuth at every handoff. One docker compose up starts the network; one curl proves DPoP rejection; one SIGTERM + resume proves the Writer restarts without re-running Market Data."
prerequisites_chapters: [1, 2, 5, 8, 9]
learning_objectives:
  - Assemble a four-agent A2A network with AgentCard-based capability discovery and sequential task delegation
  - Wire an MCP-backed specialist so the orchestrator consumes its output without holding database credentials
  - Validate DPoP rejection correctly framed as OAuth 2.0 hardening layered on A2A, not an A2A-native feature
  - Prove Writer resumability — the Market Data Specialist is invoked exactly once per root contextId even after Writer failure and re-dispatch
  - Connect all four agents under a single OpenTelemetry trace and inspect the full timeline in Langfuse
tags: [A2A, capstone, sovereign-agent, MCP, DPoP, OAuth, resumability, OpenTelemetry, Langfuse, multi-agent]
status: g3-passed
positions: []  # capstone synthesis — no adversarial stance declared
sources:
  - url: "https://a2a-protocol.org"
    title: "A2A Protocol Specification"
    retrieved: "2026-05-12"
  - url: "https://github.com/a2aproject/A2A"
    title: "A2A GitHub Repository"
    retrieved: "2026-05-12"
  - url: "https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02"
    title: "Part 2: A2A+MCP Practical Guide (Fossible)"
    retrieved: "2026-06-15"
  - url: "https://datatracker.ietf.org/doc/html/rfc9449"
    title: "RFC 9449: OAuth 2.0 Demonstrating Proof of Possession (DPoP)"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/dpop-rfc-9449-explained"
    title: "WorkOS: DPoP (RFC 9449) Explained"
    retrieved: "2026-06-15"
  - url: "https://workos.com/blog/ai-agent-credentials"
    title: "WorkOS: Securing Agentic Apps — AI Agent Credentials"
    retrieved: "2026-06-15"
  - url: "https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security"
    title: "Red Hat Developer: How to Enhance A2A Security"
    retrieved: "2026-06-15"
  - url: "https://langfuse.com/docs/observability/overview"
    title: "Langfuse Observability Overview"
    retrieved: "2026-05-12"
  - url: "https://langfuse.com/self-hosting"
    title: "Langfuse Self-Hosting"
    retrieved: "2026-05-12"
quiz:
  - question: "Why does the orchestrator in the Sovereign Agent Network never call the Market Data Specialist's MCP server directly?"
    options:
      - "The A2A spec prohibits orchestrators from initiating MCP connections to agents they do not own"
      - "Direct MCP access bypasses the specialist's task lifecycle, role logic, and resumability guarantees"
      - "MCP servers only accept connections from the same Docker network namespace as the specialist agent"
      - "The orchestrator lacks the OAuth scope required to call the specialist's tools/call MCP endpoint"
    correct_idx: 1
    explanation: "Tool-proxying over A2A exists for architectural reasons, not protocol restrictions. The specialist owns its own task lifecycle, authentication context, and failure-handling logic. If the orchestrator reached the MCP server directly, it would bypass the specialist's domain logic, lose the task-ID bookkeeping that enables resumability, and couple itself to the specialist's implementation — exactly the anti-pattern A2A was designed to prevent."
    section_anchor: wiring-the-mcp-backed-market-data-specialist

  - question: "A test sends a valid OAuth bearer token to the Market Data Specialist with no DPoP proof header. The correct outcome is:"
    options:
      - "The specialist accepts the request because DPoP is optional per the A2A v1.0 spec and the bearer token is valid"
      - "The request returns 401 Unauthorized from the security middleware before the task reaches the agent handler"
      - "The A2A protocol rejects the request at the JSON-RPC layer with error code -32600 invalid request"
      - "The specialist generates a new DPoP proof on the caller's behalf using its own key and completes the task"
    correct_idx: 1
    explanation: "DPoP rejection fires in the security middleware — the validate_inbound_task chain from Chapter 8 — before the task reaches the agent's LLM core. DPoP is an OAuth 2.0 hardening extension layered on top of A2A's securitySchemes declaration, not an A2A-native feature. The A2A spec endorses it but mandates nothing; the 401 is the middleware implementer's enforcement, not the protocol's."
    section_anchor: oauth-hardening-rejecting-unauthorized-requests

  - question: "After the Financial Writer is killed mid-run and then re-dispatched, the Market Data Specialist's log shows exactly one request. What guarantees this?"
    options:
      - "The A2A spec mandates at-most-once delivery semantics for all tasks sharing the same contextId"
      - "The orchestrator persists the Market Data artifact in task state and injects it into the Writer's resumed task without re-dispatching"
      - "The Market Data Specialist caches results by ticker symbol and returns the cached value without re-querying SQLite"
      - "DPoP token replay protection prevents the orchestrator from issuing a second request within the 300-second replay window"
    correct_idx: 1
    explanation: "Resumability depends on the orchestrator persisting the completed specialist's artifact in its task state store. When the Writer is re-dispatched, the orchestrator injects the already-stored Market Data artifact into the new task's message payload — the specialist is never contacted again. Re-running it would risk data-consistency violations if prices changed between the original run and the resume."
    section_anchor: crash-resumability-without-re-running-market-data

  - question: "What confirms that all four agents' spans belong to the same distributed trace in Langfuse?"
    options:
      - "All four agents share the same Langfuse API key and project ID, grouping their spans under one dashboard view"
      - "The orchestrator injects traceparent into every outbound A2A task; each specialist propagates the same trace_id in child spans"
      - "A2A's contextId field doubles as an OpenTelemetry trace_id when Langfuse OTLP ingestion is enabled"
      - "Langfuse auto-joins spans from agents on the same Docker network by correlating their request timestamps"
    correct_idx: 1
    explanation: "The W3C traceparent header carries the root trace_id from the orchestrator into each specialist's span context. Without explicit traceparent injection at each A2A task dispatch, every agent generates an isolated trace island and the inter-agent latency gaps become invisible. Langfuse renders all linked spans under the same trace_id in its agent graph view."
    section_anchor: one-trace-four-agents
faq:
  - question: "What happens if a specialist's AgentCard goes stale between orchestrator startup and task dispatch?"
    answer: "The orchestrator's routing table was built from the card fetched at startup. If the specialist updated its skills or required scopes since then, the orchestrator may request a scope that no longer exists or omit one now required. Production deployments should re-fetch and re-validate cards before each task dispatch or subscribe to a registry-change notification pattern. ([A2A Protocol Specification](https://a2a-protocol.org))"
  - question: "Why is an in-process dictionary insufficient for the orchestrator's task state store in production?"
    answer: "An in-process store is lost when the orchestrator process restarts. If the orchestrator dies after receiving the Market Data artifact but before the Writer completes, a cold restart loses the artifact and forces a Market Data re-run — violating the resumability invariant. Redis or a Postgres-backed task table persists artifacts across orchestrator failures independently of specialist failures, keeping the exactly-once Market Data guarantee intact. ([WorkOS: AI Agent Credentials](https://workos.com/blog/ai-agent-credentials))"
  - question: "Can the Sentiment Analyst and Financial Writer run in parallel?"
    answer: "Yes. Sentiment Analysis does not depend on Financial Writing outputs. Once the Market Data artifact is available, the orchestrator can dispatch both tasks in the same batch and wait on both COMPLETED events before assembling the final report. The only hard serialization constraint is that Market Data must complete before either downstream specialist receives its task payload. Parallelizing reduces total wall-clock time at no consistency cost. ([A2A Protocol Specification](https://a2a-protocol.org))"
---

# Capstone — Building the Sovereign Agent Network

> **Chapter 10 of 10 · 70 min (prose ~18 min + 40 min hands-on)**

---

## The Four-Agent Architecture

Start four Docker containers — Orchestrator, Market Data Specialist (MCP-backed SQLite), Sentiment Analyst, Financial Writer. The orchestrator discovers all three via their AgentCards at `/.well-known/agent.json`, dispatches sequential A2A tasks, and enforces DPoP-bound OAuth at every handoff. One `docker compose up` starts the network; one `curl` proves DPoP rejection; one `SIGTERM` + resume proves the Writer restarts without re-running Market Data. This is the hub-and-spoke pattern from [[chapter-06.md]] at full resolution — one orchestrator delegates to three domain specialists, each independently discoverable, authenticated, and observable.

The orchestrator receives a user investment query, serializes work as three sequential A2A tasks: Market Data first (a blocking upstream dependency), then Sentiment Analysis and Financial Writing once the price artifact is available. The MCP-to-A2A boundary from [[chapter-05.md]] sits entirely inside the Market Data Specialist: the specialist wraps a local SQLite database as a FastMCP server, invokes `query_price_history` internally, and delivers the result as an A2A artifact. The orchestrator never holds the database credentials or the MCP server address. [A2A Protocol v1.0.0](https://a2a-protocol.org) defines the task lifecycle states — `SUBMITTED`, `WORKING`, `COMPLETED`, `FAILED` — the orchestrator polls to sequence the handoffs.

---

## Publishing and Consuming AgentCards

Each specialist serves a `/.well-known/agent.json` card declaring the skills it accepts and the OAuth scopes those skills require. The Market Data Specialist's card advertises an `equity_price_history` skill requiring scope `mcp:market_data:read`. The Sentiment Analyst advertises `sentiment_analysis` scoped to `sentiment:read`. The Financial Writer advertises `report_generation` scoped to `report:write`.

The orchestrator fetches all three cards at startup and builds a routing table mapping skill identifiers to agent URLs and required scopes. A task routed to the wrong specialist — one whose card does not declare the required skill — fails during the orchestrator's pre-dispatch scope check rather than silently producing a wrong-domain response. [Red Hat's A2A security analysis](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security) notes that card endpoints must be access-controlled; in this network, every `/.well-known/agent.json` endpoint requires the same OAuth bearer token as the task endpoint to prevent capability-surface leakage to anonymous callers.

<KnowledgeCheck question="The orchestrator fetches all three AgentCards at startup. What is the primary failure mode if it never re-fetches them?" options={["The orchestrator uses stale skill declarations and may request scopes that no longer exist or omit scopes now required", "The orchestrator cannot generate valid DPoP proofs once the specialists rotate their asymmetric key pairs", "The A2A spec mandates card refresh on every task dispatch and rejects tasks built from stale routing tables", "Stale cards cause Langfuse to mismatch span attributes and produce orphaned trace islands in the timeline"]} correctIdx={0} explanation="AgentCards are the orchestrator's only source of truth about what skills a specialist accepts and which scopes it requires. A stale card may describe a skill that has been renamed, scoped differently, or removed. The safe production pattern is to re-validate cards before each task dispatch or subscribe to registry-change notifications." />

---

## Wiring the MCP-Backed Market Data Specialist

The Market Data Specialist's A2A handler follows the tool-proxying pattern: receive A2A task → invoke `query_price_history` on the local FastMCP server → package OHLCV rows as a JSON artifact → return as the A2A task output. The orchestrator then passes this artifact to the Financial Writer as a resource injection embedded in the next task's message payload. The Writer never touches the MCP server.

The constraint [the Fossible A2A+MCP guide](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) makes explicit: the orchestrator gains role isolation, specialist-managed failure handling, and clean resumability by respecting the protocol boundary. If the orchestrator reached the MCP server directly, it would bypass the specialist's domain logic and lose the task-lifecycle bookkeeping that resumability depends on.

<Callout type="warning">
Wrapping every MCP tool call as a separate A2A task is an anti-pattern. A2A overhead is justified only when the delegated work requires autonomous state, failure isolation, or independent authentication. For fast, synchronous internal tool calls — a SQLite read that completes in milliseconds — MCP is the correct abstraction; A2A is the boundary between agents, not between an agent and its own tools.
</Callout>

---

## Validating the Handshake End to End

With all four agents running (`docker compose up`), the end-to-end handshake validation is deterministic. POST a task to the Orchestrator's `POST /a2a/` endpoint with a ticker symbol and date range. The orchestrator's task log should show three sequential subtask dispatches: Market Data (`COMPLETED`) → then Sentiment Analysis and Financial Writing dispatched in parallel once the artifact is available, both reaching `COMPLETED` before the orchestrator marks its root task done. Any specialist returning `FAILED` halts the root task chain and surfaces the upstream `contextId` for trace inspection in Langfuse.

<KnowledgeCheck question="The Sentiment Analyst returns FAILED while the Financial Writer is still in WORKING state. What should the orchestrator do?" options={["Cancel the Financial Writer's task and surface the contextId for trace inspection — all downstream specialists must succeed", "Allow the Financial Writer to complete independently and assemble the report with an absent sentiment section", "Retry the Sentiment Analyst up to three times using the same task ID before propagating failure to the root task", "Promote the Financial Writer to orchestrator role so it can re-dispatch the Sentiment Analyst task autonomously"]} correctIdx={0} explanation="The Sentiment Analyst's output is a required input to the final report assembly. A FAILED specialist propagates as a FAILED root task. The correct response is to cancel any in-flight downstream tasks, log the contextId, and surface the failure with the Langfuse trace link so a developer can inspect exactly where and why the specialist failed." />

---

## OAuth Hardening: Rejecting Unauthorized Requests

[DPoP (RFC 9449)](https://datatracker.ietf.org/doc/html/rfc9449) is not an A2A-native feature — it is an OAuth 2.0 hardening extension layered on top of A2A's `securitySchemes` declaration. The A2A spec endorses sender-constraining tokens but mandates nothing; the enforcement happens in the security middleware from [[chapter-08.md]], not in the A2A protocol itself.

The hardening test is a single `curl`: send a valid bearer token with no `DPoP` header to any specialist that requires DPoP. The expected `401 Unauthorized` with a `WWW-Authenticate: DPoP` challenge proves the middleware fires before the task reaches the agent handler. [WorkOS](https://workos.com/blog/dpop-rfc-9449-explained) describes the standard challenge: the resource server returns `error="use_dpop_nonce"` in `WWW-Authenticate` when a nonce is required. Framing matters for production documentation: this is OAuth 2.0 hardening on top of A2A, not a capability of the protocol layer.

---

## Crash Resumability Without Re-Running Market Data

Halt the Financial Writer mid-run by sending `SIGTERM` after it receives the market data artifact but before it returns `COMPLETED`. Then re-dispatch the Writer's task using the same `contextId`. The resumability invariant: the orchestrator injects the already-stored Market Data artifact into the new task's message payload. The Market Data Specialist is never re-invoked.

Re-running the specialist would violate data consistency — prices at T+5 minutes may differ from prices at T. The orchestrator's task state store (Redis or equivalent) persists the artifact across the Writer's failure so the exactly-once Market Data guarantee holds regardless of Writer restarts. Verify by reading the Market Data Specialist's request log: it must show exactly one `POST /a2a/` for the original `contextId`, even after multiple Writer retries. [WorkOS](https://workos.com/blog/ai-agent-credentials) articulates the scope-attenuation invariant that motivates this: data sourced during a delegation must not silently re-expand or change when a downstream step retries.

---

## One Trace, Four Agents

The `traceparent` header from [[chapter-09.md]] ties the entire run into one timeline. The orchestrator generates the root span and injects `traceparent` into every outbound A2A task. Each specialist extracts the propagated context on receipt and creates child spans under the same `trace_id`. All four agents' spans arrive at Langfuse via OTLP and render as a directed agent graph with latency and token cost annotated per edge. ([Langfuse Observability Overview](https://langfuse.com/docs/observability/overview))

Four observable signals confirm the full network is wired: one `trace_id` spans all four agents; protocol latency gaps appear between each specialist's child span start and the preceding agent's send span end; Langfuse annotates per-agent token cost automatically from span usage attributes; filtering by the root `contextId` returns every span with no orphaned islands.

---

## Production-Readiness Checklist and ADRs

Three architecture decisions close the production gaps that the capstone leaves open.

**ADR-01 — Agent Card Signing.** Cards are served unsigned in this capstone. Production deployments must sign cards or serve them exclusively over mTLS-authenticated endpoints — an unsigned card on a compromised CDN can redirect callers to a malicious agent with a fabricated capability set. ([Red Hat](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security))

**ADR-02 — Scope Attenuation at Every Hop.** Every token the orchestrator mints for a sub-agent task must be scoped to the intersection of the orchestrator's own scope and the specialist's declared skill scope. Permissions only narrow at each delegation hop — a specialist token that exceeds the orchestrator's grant is a security violation, not a configuration choice. ([WorkOS scope attenuation](https://workos.com/blog/ai-agent-credentials))

**ADR-03 — Durable Task State Store.** The capstone uses an in-process state dictionary. That store is lost when the orchestrator restarts. Production requires Redis or a Postgres-backed task table so artifact persistence — and therefore the resumability invariant — survives orchestrator failures independently of specialist failures.

---

## Hands-On: Launch, Test, and Trace the Full Network

**Goal:** All four success criteria pass before the exercise is complete.

```bash
# Start the full network
docker compose up --build

# 1. DPoP rejection test — bearer token, no DPoP proof
curl -X POST http://localhost:8001/a2a/ \
     -H "Authorization: Bearer <valid_token>" \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"tasks/send","id":1,"params":{"task":{"skill":"equity_price_history","message":{"parts":[{"type":"text","text":"AAPL 2024-01-01 2024-12-31"}]}}}}'
# Expected: HTTP 401 — WWW-Authenticate: DPoP header present

# 2. Submit a full investment research task via orchestrator
curl -X POST http://localhost:8000/a2a/ \
     -H "Authorization: DPoP <access_token>" \
     -H "DPoP: <proof_jwt>" \
     -H "Content-Type: application/json" \
     -d '{"query":"AAPL vs MSFT 2024 annual performance","tickers":["AAPL","MSFT"]}'
# Save the contextId from the response.

# 3. Resume test — kill the Writer container after it logs "Market Data artifact received"
docker stop sovereign-agent-writer
# Re-dispatch the Writer with the original contextId (orchestrator retries automatically on FAILED)
docker start sovereign-agent-writer
```

**Success criteria — all four must pass:**

1. **DPoP rejection:** The request with a valid bearer token and no `DPoP` header returns `401` with `WWW-Authenticate: DPoP` — not `403`, not `200`.
2. **End-to-end COMPLETED:** The orchestrator's root task reaches `COMPLETED` with a Financial Writer artifact in its output containing both market data and sentiment sections.
3. **Resume without re-run:** After the Writer is killed and restarted, the Market Data Specialist's request log shows exactly one `POST /a2a/` for the original `contextId`, regardless of how many times the Writer retried.
4. **One trace:** Open Langfuse (`http://localhost:3000`), filter by `contextId`. One trace shows all four agents' spans under the same `trace_id` with no orphaned islands and protocol latency gaps visible between each specialist handoff.

---

You've built the Sovereign Agent Network. Every primitive from this course now operates at full resolution: A2A handshakes from [[chapter-02.md]], AGNTCY-style discovery from [[chapter-03.md]], MCP tool proxying from [[chapter-05.md]], hub-and-spoke orchestration from [[chapter-06.md]], resilience patterns from [[chapter-07.md]], DPoP auth hardening from [[chapter-08.md]], and the distributed trace from [[chapter-09.md]]. The production gaps — card signing, durable state storage, scope attenuation at every delegation hop — are documented as ADRs you own.

---

*Sources: [A2A Protocol Specification](https://a2a-protocol.org) · [A2A GitHub Repository](https://github.com/a2aproject/A2A) · [Fossible A2A+MCP Practical Guide](https://medium.com/fossible/part-2-a2a-mcp-a-practical-guide-to-the-future-of-ai-agent-workflows-7ab38a013f02) · [RFC 9449: DPoP](https://datatracker.ietf.org/doc/html/rfc9449) · [WorkOS: DPoP Explained](https://workos.com/blog/dpop-rfc-9449-explained) · [WorkOS: AI Agent Credentials](https://workos.com/blog/ai-agent-credentials) · [Red Hat: Enhance A2A Security](https://developers.redhat.com/articles/2025/08/19/how-enhance-agent2agent-security) · [Langfuse Observability Overview](https://langfuse.com/docs/observability/overview) · [Langfuse Self-Hosting](https://langfuse.com/self-hosting)*
