---
slug: cloudflare-agents-platform-workers-to-production
title: "Cloudflare Agents Tutorial 2026: From Workers to Production"
seo_title: "Cloudflare Agents Tutorial 2026: Build Production Workers Agents Step by Step"
last_updated: 2026-06-01
status: outline-draft-for-review
author: course-author
ticket: KOEA-6699
level: Intermediate-Advanced
tags: [Cloudflare, Workers, Agents, Durable-Objects, AI-Gateway, MCP, Workflows, Edge-AI, 2026]
howto_steps:
  - name: "Set up your Cloudflare Workers agent environment"
    text: "Deploy a minimal Workers agent using the Agents SDK that accepts chat messages, calls a model via Workers AI, and persists conversation history across requests."
    url: "#chapter-1-what-the-agents-platform-actually-is-and-isnt"
  - name: "Add persistent memory with Durable Objects"
    text: "Refactor your agent to store conversation history in a Durable Object SQLite table and expose a history endpoint without re-running the LLM."
    url: "#chapter-2-durable-objects-your-agents-brain"
  - name: "Design Workers-native tools using platform bindings"
    text: "Add D1, R2, and Queue bindings as agent tools and configure the Agents SDK to auto-discover and execute them based on user intent."
    url: "#chapter-3-designing-tools-for-the-workers-runtime"
  - name: "Build durable multi-step workflows that survive failures"
    text: "Convert your agent's multi-tool flow into a Cloudflare Workflow with automatic checkpointing and implement retry-with-backoff for transient failures."
    url: "#chapter-4-durable-workflows-agents-that-survive-failures"
  - name: "Route LLM calls through AI Gateway for production"
    text: "Proxy all model calls through AI Gateway, enable semantic caching, configure per-model rate limits, and measure cost savings via analytics."
    url: "#chapter-5-ai-gateway-llm-routing-for-production"
  - name: "Expose your agent as an MCP server"
    text: "Add an MCP endpoint to your Workers agent, test it with Claude Desktop, and protect it with a Cloudflare Access service token."
    url: "#chapter-6-mcp-turning-your-agent-into-a-peer"
  - name: "Operate and harden your agent in production"
    text: "Instrument trace IDs across Worker/Workflow/DO, set memory budgets, build a cost dashboard, and apply prompt injection defenses."
    url: "#chapter-7-production-operations-observability-cost-and-hardening"
target_audience: "Backend engineers and AI developers who know Workers basics and want to build stateful, production-grade AI agents on Cloudflare's edge infrastructure."
prerequisites:
  - "Working knowledge of Cloudflare Workers (routing, fetch handlers, KV)"
  - "Familiarity with async JavaScript/TypeScript"
  - "Basic understanding of LLM APIs (OpenAI or compatible)"
  - "No prior agent framework experience required"
learning_outcomes:
  - "Build a stateful AI agent on Cloudflare Workers using Durable Objects for persistent memory"
  - "Design multi-step workflows with Cloudflare Workflows v2 for durable, resumable agent execution"
  - "Integrate Workers AI and external LLMs through AI Gateway for cost tracking, caching, and rate limiting"
  - "Expose MCP-compatible tool surfaces from your Workers agent for cross-agent interoperability"
  - "Deploy, monitor, and cost-optimize a production agent on Cloudflare's global edge network"
total_duration_min: 375
chapter_count: 7
capstone_project_min: 90
description: "Build stateful AI agents on Cloudflare Workers with Durable Objects, Workflows v2 for durable execution, AI Gateway, and MCP-compatible tool surfaces."
faq_schema:
  - question: "What is Cloudflare Agents Week 2026?"
    answer: "Cloudflare Agents Week 2026 was Cloudflare's developer event launching the Agents Platform: Durable Objects for persistent agent memory, Workflows v2 for durable multi-step execution, AI Gateway for LLM routing, and native MCP server support — all from a single Workers codebase."
  - question: "How do I build a Cloudflare agent with Durable Objects?"
    answer: "Use the Cloudflare Agents SDK to create a stateful Workers agent backed by a Durable Object for per-session SQLite storage. Store conversation history in a SQLite table, wrap multi-step flows in a Cloudflare Workflow for automatic checkpointing, and route all LLM calls through AI Gateway for production observability."
---

# Cloudflare Agents Tutorial 2026: from Workers to Production

This tutorial teaches you how to build Cloudflare agents in 2026 using the Cloudflare Agents Platform — Workers, Durable Objects, Workflows v2, and AI Gateway. You'll go from a blank Workers project to a deployed, production-hardened agent that handles persistent state, native platform tools, and cost monitoring on Cloudflare's global edge across 330+ points of presence.

## Why this course

Lambda functions forget everything. Cloud Run containers boot slowly. But AI agents need state, long-running execution, and global presence — all at once.

Cloudflare's Agents Platform is the only edge infrastructure that gives you all three natively: **Durable Objects** for per-agent persistent memory, **Workflows v2** for durable multi-step execution, and **AI Gateway** for production LLM routing — without managing a single server. Your agent runs in 330+ PoPs globally, wakes from hibernation in milliseconds, and can handle 50,000 concurrent workflows out of the box.

This course takes you from a blank Workers project to a deployed, observable, production-hardened agent. Every chapter is hands-on. By the end, you will have shipped a real multi-tool agent that handles state, tools, escalation, and cost monitoring — the full stack, edge-native.

## Course outline

### Chapter 1: What the Agents Platform Actually Is — and Isn't
- **Duration**: 40 min
- **Prerequisites**: course intro only
- **Learning objectives**:
  1. Explain the four primitives of the Cloudflare Agents Platform: Workers, Durable Objects, Workflows, AI Gateway
  2. Map the difference between a stateless Worker function and a stateful agent instance
  3. Identify when to choose Cloudflare Agents over Lambda, Cloud Run, or self-hosted containers
  4. Deploy a "Hello World" agent that responds to a user message and persists the exchange
- **Key concepts**: Edge-native agents, Durable Object instances, hibernation model, global PoP deployment
- **Hands-on exercise**: Deploy a minimal Workers agent (`new Agent()` from the Agents SDK) that accepts a chat message, calls a model via Workers AI, and returns a streamed response. Verify it persists conversation history across requests.
- **Contrarian angle**: "Serverless" is often marketed as stateless. The Cloudflare Agents Platform is serverless AND stateful. The distinction matters: your agent isn't re-hydrated from a database on every call — it wakes from hibernation with its SQLite state intact.

---

### Chapter 2: Durable Objects — Your Agent's Brain
- **Duration**: 55 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  1. Explain the Durable Object lifecycle: creation, hibernation, wake, destruction
  2. Implement per-session agent state using Durable Object SQLite storage
  3. Design a "memory schema" that stores conversation history, user preferences, and tool call logs
  4. Apply the Durable Object Facets pattern to give each dynamic agent its own isolated database
- **Key concepts**: Durable Object facets, SQLite-backed state, hibernation cycles, instance isolation, automatic persistence
- **Hands-on exercise**: Refactor the Chapter 1 agent to store conversation history in a Durable Object SQLite table. Add a `GET /history` endpoint that retrieves the last 10 exchanges without re-running the LLM.
- **Contrarian angle**: Redis is the default answer for agent memory. But Redis requires a separate service, network hop, and serialization layer. Durable Object SQLite is co-located with your agent's compute — zero network latency for state reads, zero ops overhead.

---

### Chapter 3: Designing Tools for the Workers Runtime
- **Duration**: 50 min
- **Prerequisites**: Chapter 2
- **Learning objectives**:
  1. Implement Workers AI bindings and external LLM calls (OpenAI-compatible) as agent tools
  2. Design tool schemas that the Agents SDK can auto-discover and execute
  3. Use Workers bindings (KV, R2, D1, Queues) as first-class agent tools
  4. Apply "tool sandboxing" to prevent agents from accessing bindings they didn't declare
- **Key concepts**: Workers bindings as tools, tool schema design, binding isolation, KV/R2/D1 integration, Queues for async task dispatch
- **Hands-on exercise**: Add three tools to your agent: `search_knowledge_base` (D1 query), `store_artifact` (R2 upload), and `enqueue_task` (Queue message). Have the agent autonomously decide which tool to call based on the user's intent.
- **Contrarian angle**: Most agent frameworks treat "tools" as HTTP endpoints. On Cloudflare Workers, your tools are native platform bindings — no network hop, no latency, no auth token management. The tool IS the infrastructure.

---

### Chapter 4: Durable Workflows — Agents That Survive Failures
- **Duration**: 55 min
- **Prerequisites**: Chapter 3
- **Learning objectives**:
  1. Model a multi-step agent task as a Cloudflare Workflow with automatic checkpointing
  2. Implement retry-with-backoff for tool calls that may fail transiently
  3. Design a "human-in-the-loop" escalation step that pauses the workflow pending approval
  4. Handle the `INPUT_REQUIRED` state for long-running research tasks
- **Key concepts**: Cloudflare Workflows v2, step checkpointing, durable execution, escalation patterns, 50k concurrent workflow limit
- **Hands-on exercise**: Convert the Chapter 3 agent's multi-tool flow into a Cloudflare Workflow. Simulate a tool failure mid-workflow and verify the Workflow resumes from the last successful step rather than restarting from scratch.
- **Contrarian angle**: "Fire-and-forget" is fine for webhooks. For AI agents, every step must be resumable or your user loses work every time a downstream API blips. Cloudflare Workflows makes resumability the default, not the exception.

---

### Chapter 5: AI Gateway — LLM Routing for Production
- **Duration**: 45 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  1. Route all LLM calls through AI Gateway for unified logging and cost tracking
  2. Configure per-model rate limits and caching policies to cut repeat-query costs
  3. Implement fallback routing: primary model → fallback model on failure
  4. Read AI Gateway analytics to identify your top cost drivers and optimize them
- **Key concepts**: AI Gateway routing, token-level caching, rate limiting, model fallback, cost attribution, 241B token scale
- **Hands-on exercise**: Proxy your agent's Workers AI calls through AI Gateway. Enable semantic caching for the top 5 most common queries. Measure the cache hit rate after 50 requests and calculate the token cost saved.
- **Contrarian angle**: Developers reach for LangSmith or Helicone for LLM observability. If you're already on Cloudflare, AI Gateway gives you token counts, latency, cost, and caching for free — no third-party account required, no data leaves your account.

---

### Chapter 6: MCP — Turning Your Agent into a Peer
- **Duration**: 40 min
- **Prerequisites**: Chapter 3
- **Learning objectives**:
  1. Expose your Workers agent's tools as an MCP server endpoint
  2. Test the MCP surface with Claude Desktop or a local MCP client
  3. Combine MCP (tool-sharing) with A2A (agent-to-agent delegation) for cross-vendor workflows
  4. Apply access control to your MCP endpoint using Cloudflare Access
- **Key concepts**: MCP server on Workers, tool exposure, Cloudflare Access auth, A2A + MCP stack, cross-vendor interoperability
- **Hands-on exercise**: Add an MCP endpoint to your Chapter 3 agent. Connect it to Claude Desktop and invoke your `search_knowledge_base` tool from the Claude UI. Protect the endpoint behind a Cloudflare Access service token.
- **Contrarian angle**: Most teams build MCP servers as a separate microservice. A Cloudflare Workers agent can BE an MCP server — same codebase, same deployment, same global presence. The MCP surface is just another route handler.

---

### Chapter 7: Production Operations — Observability, Cost, and Hardening
- **Duration**: 50 min
- **Prerequisites**: Chapters 4, 5
- **Learning objectives**:
  1. Implement structured logging with trace IDs that follow a request across Worker → Workflow → Durable Object
  2. Set Durable Object per-instance memory budgets and alarm on excess storage
  3. Design a cost dashboard using AI Gateway analytics + Workers Analytics Engine
  4. Apply input sanitization to prevent prompt injection via user-controlled inputs
- **Key concepts**: Distributed trace propagation, Workers Analytics Engine, DO memory budgets, cost dashboards, prompt injection defense
- **Hands-on exercise**: Instrument the full Chapter 4 workflow with trace IDs. Write a one-page runbook for the three most likely production failures: token budget exhaustion, Durable Object storage overflow, and Workflow step timeout.
- **Contrarian angle**: "Observability" for agents usually means logging LLM output. Real production observability means tracing the gap between intent (what the user asked) and execution (what the agent actually did). If your traces don't capture the agent's reasoning, you're logging, not observing.

---

## Capstone project

**Build `CaseOps Agent` — a production-hardened customer support triage agent.**

### Deliverable

A deployed Cloudflare Workers agent that:

1. **Accepts support tickets** via HTTP POST, classifies intent (billing / technical / feature request), and routes to the appropriate response workflow.
2. **Persists case history** in a Durable Object SQLite table — each customer has their own DO instance with isolated case memory.
3. **Uses three Workers bindings as tools**: D1 (case database lookup), R2 (document retrieval), Queue (escalation dispatch for human review).
4. **Implements a Cloudflare Workflow** for multi-step cases: classify → retrieve context → draft response → await human approval → send.
5. **Routes all LLM calls through AI Gateway** with semantic caching and a fallback model.
6. **Exposes an MCP surface** listing the agent's tools, protected by a Cloudflare Access service token.

### Verification criteria

- `State persistence`: Case history survives a 10-minute hibernation and is restored correctly on next request.
- `Workflow resumability`: Simulated tool failure at step 3 → Workflow resumes from step 3, not step 1.
- `AI Gateway caching`: Cache hit rate ≥ 30% after 100 test requests with common queries.
- `MCP integration`: Claude Desktop can invoke `lookup_case` via the MCP endpoint.
- `Prompt injection defense`: Malformed user input containing instruction-injection strings is sanitized before reaching the LLM.

---

## Why this beats alternatives

Competing courses teach LangGraph or AutoGen on cloud VMs. Those stacks require you to manage servers, set up Redis for state, configure task queues, and operate separate observability pipelines. This course gives you all of that from a single Workers codebase, deployed globally in one `wrangler deploy`. You're not learning a framework — you're learning how to build edge-native agents that run closer to your users, cost less to operate, and fail more gracefully than anything running on a centralized cloud VM.
