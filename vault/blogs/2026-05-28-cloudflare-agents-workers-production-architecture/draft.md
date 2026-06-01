---
date: 2026-05-28
author: blog-author
ticket: KOEA-6694
vendor_tag: community
content_type: article
status: draft-for-review
reading_time_min: 7
title: "How to Architect Cloudflare Agents on Workers Around Durable Objects (2026 Production Guide)"
description: "A production architecture guide for Cloudflare Agents on Workers, Durable Objects, AI Gateway, R2, Vectorize, and Workflows: where the stack wins, where it breaks, and what to build first."
slug: 2026-05-28-cloudflare-agents-workers-production-architecture
tags: [cloudflare, agents, workers, durable-objects, ai-gateway, production-architecture]
howto:
  name: "How to architect a Cloudflare Agents deployment around Durable Objects"
  description: "Architect Cloudflare Agents as a Durable Object control plane, not a Lambda clone. The Durable Object Agent owns identity, session state, tool-routing decisions, WebSocket continuity, and scheduling — everything else is delegated to platform primitives: R2 for blobs, Vectorize for embeddings, AI Gateway for model traffic, Workflows or Project Think for long-running steps. Design for hibernation from day one or idle WebSockets will blow up cost. The stack wins on stateful, event-driven, mostly-idle workloads; it loses on sustained CPU or large local dependencies."
  totalTime: "PT60M"
  steps:
    - name: "Step 1: Decide if Cloudflare Agents fits the workload shape"
      text: "Cloudflare Agents is a fit for stateful, event-driven AI workloads — per-user state, WebSockets, scheduled tasks, tool calls, edge-close model traffic. It is wrong for sustained CPU, large local dependencies, or always-on conventional processes. If you need minutes of CPU per request, choose a container runtime instead."
    - name: "Step 2: Model each Agent as a Durable Object with its own SQL DB"
      text: "Define a TypeScript Agent class running on a Durable Object. Each Agent gets its own SQL database, WebSocket support, and scheduling. Respect the platform limits: 1 GB state per Agent, 30 seconds compute per HTTP/WebSocket message refresh."
    - name: "Step 3: Put coordination in the Agent, heavy work outside it"
      text: "Store conversation pointers, task status, retry count, approval state, and compact summaries inside the Durable Object. Push documents, generated files, logs, and exports to R2. Push semantic retrieval to Vectorize. Hand multi-step long-running work to Workflows or Project Think."
    - name: "Step 4: Route all model traffic through AI Gateway"
      text: "Configure AI Gateway in front of every LLM call. Get request logging, analytics, response caching, rate limiting, retries, and fallback routing for free. Add application-level task and tenant metadata at the Worker layer."
    - name: "Step 5: Design WebSockets for hibernation from day one"
      text: "100 always-on WebSocket Durable Objects cost roughly $416/month; the same workload with hibernation can land near $10/month. Use the hibernation API, persist conversation state to SQL, and let the platform park idle Agents. Without this, your bill scales with duration, not requests."
    - name: "Step 6: Pick the right execution surface for each tool"
      text: "Use Project Think's execution ladder — workspace, isolate, npm, browser, sandbox — for sub-agents and sandboxed code execution. Do not stuff browser automation, npm installs, or long-running research into the Agent itself."
    - name: "Step 7: Spot the production cases where Workers loses"
      text: "If a single task needs minutes of CPU, large GPU access, conventional process supervision, or massive local node_modules, Cloudflare Agents is the wrong runtime. Move that workload to a container or VM and keep the Agent as the stateful coordinator that calls it."
primary_query: "Cloudflare Agents Workers production architecture"
contrarian_angle: "Cloudflare Agents is strongest when you stop treating Workers as cheap Lambda and use Durable Objects as the stateful control plane; it loses when you force CPU-heavy jobs into the Agent itself."
research_source: vault/research/_synthesis/cloudflare-agents-week-2026-build-deep-dive.md
sources:
  - https://developers.cloudflare.com/agents/
  - https://developers.cloudflare.com/agents/platform/limits/
  - https://blog.cloudflare.com/project-think/
  - https://developers.cloudflare.com/durable-objects/platform/pricing/
  - https://developers.cloudflare.com/ai-gateway/
  - https://developers.cloudflare.com/vectorize/platform/limits/
  - https://developers.cloudflare.com/r2/pricing/
  - https://developers.cloudflare.com/workflows/get-started/durable-agents/
references:
  - n: 1
    title: "Cloudflare Agents overview"
    url: https://developers.cloudflare.com/agents/
    retrieved: 2026-05-28
  - n: 2
    title: "Cloudflare Agents limits"
    url: https://developers.cloudflare.com/agents/platform/limits/
    retrieved: 2026-05-28
  - n: 3
    title: "Project Think"
    url: https://blog.cloudflare.com/project-think/
    retrieved: 2026-05-28
  - n: 4
    title: "Durable Objects pricing"
    url: https://developers.cloudflare.com/durable-objects/platform/pricing/
    retrieved: 2026-05-28
  - n: 5
    title: "AI Gateway overview"
    url: https://developers.cloudflare.com/ai-gateway/
    retrieved: 2026-05-28
  - n: 6
    title: "Vectorize limits"
    url: https://developers.cloudflare.com/vectorize/platform/limits/
    retrieved: 2026-05-28
  - n: 7
    title: "R2 pricing"
    url: https://developers.cloudflare.com/r2/pricing/
    retrieved: 2026-05-28
  - n: 8
    title: "Build a Durable AI Agent with Workflows"
    url: https://developers.cloudflare.com/workflows/get-started/durable-agents/
    retrieved: 2026-05-28
whats_new:
  - "Cloudflare Agents is not a cheaper Lambda for AI; it is a Durable Object control plane that becomes production-grade only when you split state, model calls, artifacts, and long-running work into separate platform primitives."
learning_objectives:
  - "Design the Durable Object Agent as the stateful coordinator, not the whole workload."
  - "Choose when to add AI Gateway, R2, Vectorize, Workflows, or Sandboxes around a Worker-based agent."
  - "Spot the production cases where Cloudflare Workers loses to container or VM runtimes."
faq:
  - question: "Is Cloudflare Agents a good production architecture for AI agents?"
    answer: "Yes, when the agent is event-driven, stateful, WebSocket-heavy, or cost-sensitive at idle. It is weaker for sustained CPU work, large local dependencies, or workloads that require a conventional always-on process."
  - question: "What should own state in a Cloudflare Agents deployment?"
    answer: "The Durable Object should own short-lived coordination state, user/session state, scheduling, and WebSocket continuity. Large blobs belong in R2, retrieval memory in Vectorize, and long-running steps in Workflows or Project Think primitives."
  - question: "Where does observability belong?"
    answer: "Put model traffic behind AI Gateway for request logging, analytics, caching, rate limiting, retries, and fallback; add application-level task and tenant metadata from the Worker or Agent."
---

# How to Architect Cloudflare Agents on Workers Around Durable Objects (2026 Production Guide)

To architect a production Cloudflare Agents deployment: define each Agent as a Durable Object that owns identity, session state, tool routing, WebSocket continuity, and scheduling — then delegate everything else. Put blobs in R2, retrieval in Vectorize, model calls behind AI Gateway, and long-running steps in Workflows or Project Think. Design WebSockets for hibernation from day one or idle Agents will dominate cost. The platform wins on millions of mostly-idle stateful coordinators and loses on sustained CPU. Cloudflare Agents is a production fit when you need stateful, event-driven AI workloads on Workers: durable per-user state, WebSockets, scheduled tasks, tool calls, and model traffic close to the edge. The clean architecture is a Durable Object Agent as the coordinator, AI Gateway for model observability, R2 for large artifacts, Vectorize for retrieval memory, and Workflows or Project Think for long-running steps. Cloudflare's Agents docs describe each Agent as a TypeScript class running on a Durable Object with its own SQL database, WebSockets, and scheduling [1].

The mistake is treating this as cheaper AWS Lambda for AI. A Lambda mental model asks, "How much code can I fit in one invocation?" The Workers + Agents model asks, "Which named stateful object should wake up, coordinate a step, persist just enough, and go back to sleep?" That is a better fit for millions of mostly-idle agents than for one agent doing minutes of CPU-bound work. The architecture win is state placement, not raw compute bravado.

## How to Put Coordination in the Agent and Heavy Work Outside It

The Durable Object Agent should own identity, session state, tool-routing decisions, WebSocket continuity, and scheduling. It should not own every blob, embedding, browser action, build job, or long-running research workflow. Cloudflare's current Agents limits list tens of millions of concurrent running Agents per account, 1 GB of state per unique Agent, and 30 seconds of compute time per Agent refreshed by HTTP requests or incoming WebSocket messages [2]. That shape is telling: the platform wants many small stateful coordinators, not a few overloaded workers.

Use the Agent as the control plane. Store a conversation pointer, task status, retry count, approval state, and a compact summary in the Durable Object database. Put documents, generated files, logs, exports, and artifacts in R2. Put semantic retrieval chunks in Vectorize. Route model calls through AI Gateway. Hand durable multi-step work to Workflows or Project Think primitives when a step may outlive a request.

Project Think makes the separation explicit. Cloudflare describes it as primitives for durable execution, sub-agents, persistent sessions, sandboxed code execution, and an execution ladder that ranges from workspace to isolate, npm, browser, and sandbox [3]. That is not a single bigger Worker. It is an admission that production agents need tiered execution surfaces.

## Use Durable Objects for cost shape, but design for hibernation

Workers can be unusually attractive for agent workloads because idle agents should not look like idle containers. Durable Objects pricing shows how much that matters. In Cloudflare's own pricing example, 100 Durable Objects that keep WebSockets active all month without hibernation estimate at $416.51/month; a hibernatable WebSocket example with much less active compute estimates at $10.00/month [4]. The difference is not request count. It is duration.

That is the core production budget rule: keep the Agent awake only while it handles events. WebSocket-heavy support agents, tutors, notification bots, and workflow monitors fit because they spend most of their life waiting. A design that keeps a Durable Object busy like a daemon is fighting the platform's economics.

## Route model calls through AI Gateway before the first incident

AI Gateway is the production boundary for model calls, not an add-on dashboard. Cloudflare's AI Gateway docs position it as visibility and control for AI apps, with analytics, logging, caching, rate limiting, request retries, and model fallback across providers such as Workers AI, Anthropic, Google Gemini, and OpenAI [5]. That is exactly where agent systems fail first: unknown prompt growth, tool-result bloat, provider errors, model fallback gaps, and tenant-level cost spikes.

Wire the Agent so every model request carries application metadata: `tenant_id`, `agent_id`, `task_id`, `conversation_id`, `tool_name`, and `workflow_step`. The Durable Object can keep the state machine, but AI Gateway should see the LLM traffic. This also keeps provider choice from leaking into the rest of the architecture. A support agent can start with Workers AI, route premium tenants to Anthropic or OpenAI through Gateway, and apply rate limits before a runaway loop becomes a bill.

Do not mistake Gateway logs for full agent observability. You still need application events for tool inputs, approval gates, retries, user-visible state, and failure reasons.

## Store retrieval memory in Vectorize and blobs in R2

Do not put your knowledge base in the Agent's local state because it is convenient. Cloudflare Vectorize is the better fit for retrieval memory: the current limits list 10,000,000 vectors per index and 50,000 namespaces per index on Workers Paid [6]. That supports a natural production pattern: namespace by tenant, user, workspace, or agent, then retrieve only the top few chunks for each turn.

R2 is the artifact layer. Its pricing page says there are no egress bandwidth charges for any storage class, with Standard storage priced at $0.015 per GB-month and a monthly free tier of 10 GB-month, 1 million Class A operations, and 10 million Class B operations [7]. That makes it a sensible place for uploaded PDFs, generated reports, screenshots, crawl outputs, transcripts, and sandbox artifacts.

The reliable pattern is:

1. Upload the source file or generated artifact to R2.
2. Chunk and embed only the text that should be searchable.
3. Store vectors and compact metadata in Vectorize.
4. Store the task pointer and retrieval policy in the Agent.
5. Return short ranked passages to the model, not raw files.

## Use Workflows when correctness needs checkpoints

Any agent step that must survive deploys, crashes, retries, or human waiting belongs outside the single Agent turn. Cloudflare's durable agent guide uses the Agents SDK with Workflows for a repository-research agent and describes real-time progress updates from a durable workflow [8]. That is the right pattern for tasks like crawling a site, evaluating many documents, waiting for human approval, generating reports, or retrying tool calls.

The production rule is simple: if replaying the step would be expensive, harmful, or confusing, checkpoint it. Let the Agent start the workflow, stream progress, and maintain the user-facing state. Let Workflows own the durable step sequence.

Here is the smallest runnable architecture probe: create an Agent project, then test that a request can carry the shape you need before adding model calls.

<RunPromptCell language="bash">
```bash
npx create-cloudflare@latest --template cloudflare/agents-starter cloudflare-agent-pilot
cd cloudflare-agent-pilot
npm install
npm run dev

curl -s https://your-worker.workers.dev/ | head
```

Expected output:

```text
The dev server responds from the Workers/Agents starter. Your next production check is not "does chat work"; it is whether task_id, tenant_id, model route, and artifact pointers flow through the Agent boundary.
```
</RunPromptCell>

## Choose Workers when agents are event-driven; choose containers when work is continuous

Cloudflare Agents wins when the workload is stateful, bursty, globally accessed, WebSocket-driven, and idle most of the time. It is a strong default for support copilots, learning tutors, notification agents, workflow monitors, MCP tools, and stateful chat over shared business data.

It loses when the workload is a conventional long-running process wearing an agent label. If you need sustained CPU, large native dependencies, GPU control, local daemons, custom networking, long filesystem-heavy jobs, or opaque third-party binaries, a container or VM runtime may be simpler. Cloudflare's own Project Think execution ladder points in the same direction: isolate the coordinator from the heavier execution tier [3].

The 30-day evaluation should be concrete. Build one Durable Object Agent with a stable tenant/session name. Put model calls behind AI Gateway. Store uploaded and generated files in R2. Put retrieval chunks in Vectorize. Move one long-running path into Workflows. Then inspect four numbers: active duration per task, model cost per tenant, retrieval payload size per turn, and failed-step retry rate.

If those numbers look clean, Workers is probably a better agent control plane than a container fleet. If the Agent spends most of its life doing continuous compute or shuffling large artifacts through memory, move the heavy work out before you scale.

<KnowledgeCheck>
Question: A team wants a Cloudflare-based research agent that chats with users over WebSockets, searches uploaded PDFs, calls Anthropic through a fallback route, and generates a 20-page report that may take several minutes. Which architecture is the best first cut?

A. Put chat state, PDFs, embeddings, model calls, and report generation inside one Durable Object Agent.
B. Use a Durable Object Agent for session state and WebSockets, AI Gateway for model routing, R2 for PDFs/reports, Vectorize for retrieval, and Workflows for the multi-minute report job.
C. Use Vectorize as the primary database for all user state and skip Durable Objects.
D. Keep one always-on Worker polling for every user's jobs so no separate workflow system is needed.

Correct answer: B. The Durable Object coordinates state and live interaction; the surrounding Cloudflare services own model observability, artifacts, retrieval, and durable long-running execution.
</KnowledgeCheck>

For Koenig Academy readers, the upgrade path is to stop learning "agent frameworks" as chat wrappers and start learning runtime boundaries: state, model traffic, retrieval, artifacts, and durable execution. Continue with [[course/mcp-from-first-principles-to-production]] to connect this Cloudflare architecture to tool surfaces, authorization, and production MCP design.

## Related from the academy

- [[blog/2026-05-13-cloudflare-agents-week-2026-build-deep-dive]]
- [[blog/cloudflare-agents-week-2026-explained]]

