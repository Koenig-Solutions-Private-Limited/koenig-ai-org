---
date: 2026-05-28
author: course-author
ticket: KOEA-6697
status: g3-passed
content_type: course-outline
title: "How to build a production Claude Agent SDK app in 7 chapters"
slug: claude-agent-sdk-zero-to-production
total_duration_min: 415
target_audience: "engineers + tech leads building agent products on the Claude Agent SDK in 2026"
prerequisites:
  - "TypeScript fluency"
  - "Basic familiarity with the Anthropic API"
capstone: "Production-ready TypeScript incident-triage agent with SDK streaming, MCP tools, least-privilege permissions, resumable run artifacts, evals, HTTP/CLI entrypoints, channel-scoped collaboration, admin audit logs, and an operator runbook"
tags:
  - claude-agent-sdk
  - typescript
  - production-agents
sources:
  - https://code.claude.com/docs/en/agent-sdk/typescript
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-permissions
  - https://docs.anthropic.com/en/docs/mcp
  - https://www.anthropic.com/news/claude-sonnet-5
  - https://platform.claude.com/docs/en/about-claude/models/whats-new-sonnet-5
  - https://www.anthropic.com/news/introducing-claude-tag
---

# How to build a production Claude Agent SDK app in 7 chapters

Course outline persisted by operator on 2026-05-28 (Course Author hit `bwrap: No permissions to create a new namespace` sandboxing failure — outline is intact from the agent's draft). Revised 2026-06-12 for KOEA-8039 (G0 structural blockers from KOEA-8028). Revised 2026-07-01 for KOEA-9865, using KOEA-9823 engineering handoff and KOEA-9837 research memo, to isolate Claude Sonnet 5 migration breakages: ch 3 owns sampling-parameter removal; ch 6 owns adaptive thinking, tokenizer, `max_tokens`, and pricing-window migration. Revised 2026-07-02 for KOEA-9200 to append a G3-passed Claude Tag-inspired channel-scoped agents module without restructuring chapters 1-6.

## Chapters

### Chapter 1 — Ship the smallest useful Claude Agent SDK app

**Duration:** 60 min

**Prerequisites:** None

**Learning objectives:**
1. Install and authenticate the Claude Agent SDK against the Anthropic API
2. Implement a minimal five-line agent using `Agent.run()` and explain each parameter
3. Compare streaming vs. blocking response modes and choose the right one for a given use case
4. Select the appropriate model tier (Haiku / Sonnet / Opus 4.7) based on task class and cost

> **Sonnet 5 migration note (2026-Q3):** If you are running these exercises on Claude Sonnet 5, omit temperature, top_p, and top_k (Sonnet 5 returns HTTP 400 for non-default values). Sonnet 5 also enables adaptive thinking by default — pass `thinking: {type: "disabled"}` if you need concise, non-extended responses. The Sonnet 5 tokenizer produces ~30% more tokens for equivalent text, so rebaseline your `max_tokens` budgets. Manual `thinking: {type: "enabled", budget_tokens: N}` syntax is rejected on Sonnet 5.

**Topics:**
- Install + auth (Anthropic API + Claude subscription)
- The smallest possible agent (5-line example with `Agent.run()`)
- Streaming vs blocking responses
- Picking the right model tier (Haiku / Sonnet / Opus 4.7) for your task class

**Hands-on exercise:** Build a command-line weather-summary agent that calls `Agent.run()` with a streaming response, prints tokens as they arrive, and exits with a non-zero code on API errors.

---

### Chapter 2 — Turn a prompt script into a controllable agent harness

**Duration:** 60 min

**Prerequisites:** Chapter 1

**Learning objectives:**
1. Implement session resume using the SDK's session ID and state model
2. Configure dynamic system prompts via environment-driven persona swap
3. Compare the Agent SDK harness pattern against the raw Anthropic SDK and explain when each is appropriate
4. Build a configurable harness that supports multiple agent personas from a single codebase

**Topics:**
- Session resume + state model
- System prompts + dynamic instructions
- Configurable agent harness pattern (env-driven persona swap)
- When to use Agent SDK vs raw Anthropic SDK

**Hands-on exercise:** Extend the Chapter 1 agent into a persistent harness that reads `AGENT_PERSONA` from the environment, resumes a previous session when a `--session` flag is passed, and logs each run's session ID to a local JSON file.

---

### Chapter 3 — Add safe tools with MCP and explicit permissions

**Duration:** 60 min

**Prerequisites:** Chapters 1–2

**Learning objectives:**
1. Configure an MCP server and wire it to an Agent SDK agent
2. Design tool schemas that are idempotent, narrowly scoped, and clearly named
3. Implement explicit permission boundaries distinguishing read-only from write-allowed tools
4. Deploy a sandboxed tool execution environment that prevents credential leakage

**Topics:**
- MCP server basics
- Tool design patterns (idempotent, narrow, named)
- Permission boundaries (read-only vs write-allowed tools)
- Sandboxed execution

**Hands-on exercise:** Add a `search_linear_issues` MCP tool (read-only) and a `create_linear_comment` tool (write-allowed) to the Chapter 2 harness; implement permission checks that block the write tool unless `ALLOW_WRITES=true` is set.

> **Sonnet 5 migration note:** When migrating this chapter's tool-agent request examples to `claude-sonnet-5`, remove `temperature`, `top_p`, and `top_k` entirely. Sonnet 5 returns HTTP 400 for non-default sampling parameters; use system prompt wording, tool schemas, permission gates, and evals for behavior control instead of sampling knobs.

---

### Chapter 4 — Preserve context with sessions, artifacts, and resumable runs

**Duration:** 60 min

**Prerequisites:** Chapters 1–3

**Learning objectives:**
1. Implement artifact storage using R2, S3, or local FS and explain the trade-offs between each
2. Configure resumable runs that reconstruct agent state after a crash or process restart
3. Apply prompt caching and cache control headers to reduce per-run token cost by ≥30% *(Sonnet 5 note: the tokenizer produces ~30% more tokens for the same text — recount your cached prompt lengths and cost estimates when migrating from 4.x)*
4. Explain the SDK's session ID + run ID model and how it maps to external storage keys

**Topics:**
- Session ID + run ID model
- Artifact storage patterns (R2 / S3 / local FS)
- Resumable runs — picking up from a crash
- Cache control + prompt caching for cost

**Hands-on exercise:** Instrument the Chapter 3 agent to persist its tool-call history as a JSON artifact to local FS on every run, and implement a `--resume <run-id>` flag that reloads state from disk and continues from the last checkpoint.

---

### Chapter 5 — Evaluate, observe, and debug the agent before users do

**Duration:** 60 min

**Prerequisites:** Chapters 1–4

**Learning objectives:**
1. Build a synthetic eval suite with ≥5 golden test cases that gate PRs in CI
2. Integrate Langfuse and OTEL to trace every tool call and model invocation
3. Configure cost attribution per run and per tool call and export a cost report
4. Implement the run inspector pattern to examine mid-run state without re-executing

**Topics:**
- Evals: synthetic + golden + canary
- Langfuse + OTEL integration
- Cost attribution per run + per tool call
- Debugging mid-run state (run inspector pattern)

**Hands-on exercise:** Write five golden evals for the incident-triage agent using the SDK's test harness; configure Langfuse to record traces locally; add a `pnpm eval` script that fails CI if any golden case regresses.

---

### Chapter 6 — Deploy the incident-triage agent with production guardrails

**Duration:** 60 min

**Prerequisites:** Chapters 1–5

**Learning objectives:**
1. Build the capstone incident-triage agent that integrates all prior chapters into a deployable artifact
2. Deploy HTTP and CLI entrypoints and verify liveness under simulated load
3. Configure a cost circuit-breaker that halts the agent when a per-run budget is exceeded *(Sonnet 5 note: adaptive thinking adds text-only decision turns that accumulate cost; if migrating to Sonnet 5, rebaseline circuit-breaker thresholds and account for the ~30% tokenizer uplift)*
4. Write an operator runbook covering failover, manual override, and on-call escalation procedures

**Topics:**
- Capstone build: incident-triage agent
- HTTP + CLI entrypoints
- Operator runbook (failover, manual override, cost circuit-breaker)
- On-call playbook for agent escalations

**Hands-on exercise:** Wire the incident-triage agent to an Express HTTP endpoint (`POST /triage`), add a `MAX_COST_USD` env guard that returns HTTP 402 when exceeded, and write a one-page operator runbook as `docs/runbook.md` covering restart, rollback, and manual override procedures.

> **Sonnet 5 migration note:** Replace manual extended-thinking calls such as `thinking: {type: "enabled", budget_tokens: N}` with adaptive thinking (`thinking: {type: "adaptive"}`) and `output_config.effort` when the capstone needs deeper reasoning. Omit `thinking` only if adaptive thinking is intended; set `thinking: {type: "disabled"}` for concise routing, liveness, and low-latency guardrail turns. Recount prompts with the Sonnet 5 tokenizer before setting `MAX_COST_USD` or `max_tokens`: Anthropic's migration guide says equivalent text produces about 30% more tokens, and the launch pricing is $2/$10 per million input/output tokens through August 31, 2026 before standard $3/$15 pricing takes effect on September 1, 2026.

---

### Chapter 7 — Build channel-scoped agents for multi-user teams

**Duration:** 55 min

**Prerequisites:** Chapters 1–6

**Learning objectives:**
1. Distinguish per-task runs, per-user sessions, and channel-scoped shared context and choose the right model for a given team workflow
2. Map Slack-style workspace, channel, thread, user, task, session, run, and artifact IDs to SDK primitives
3. Enforce channel memory isolation using explicit tool permissions, channel-scoped namespaces, and stable session IDs
4. Instrument an admin audit log with full requester attribution for reads, decisions, tool calls, writes, and spend

**Topics:**
- Claude Tag as the production reference pattern for channel-scoped Claude agents
- Shared channel context vs. private direct-message context
- Identity mapping: workspace, channel, thread, user, task, session, run, and artifact IDs
- Channel-scoped memory boundaries and permission inheritance
- Admin audit log schema for reads, decisions, tool calls, writes, spend, and requester attribution
- Failure modes: cross-channel leakage, stale shared memory, ambiguous requester authority, and missing audit evidence

**Hands-on exercise:** Extend the Chapter 6 incident-triage agent with a Slack-style channel adapter that keeps a channel-scoped context store, accepts requests from multiple users in one channel, records every read/decision/tool/write event to an admin query log, and proves through tests that private-channel or unrelated-channel data cannot appear in the shared context.

---

## Capstone

A production-ready TypeScript incident-triage agent that:
- Streams via SDK to a thin HTTP shim
- Uses 3 MCP tools (Linear, PagerDuty, GitHub) with least-privilege scopes
- Persists run artifacts to R2 + writes resumable state to Durable Objects
- Has eval suite + Langfuse tracing
- Supports Slack-style channel-scoped collaboration without cross-channel memory leakage
- Emits admin-queryable audit logs for reads, decisions, tool calls, writes, requester attribution, and spend
- Comes with an operator runbook

## G3 Status

Chapter 7 delta G3 passed via KOEA-9539 after G0 review and blocker resolution. Chapters 1-6 remain covered by the prior course outline and the 2026-07-01 Sonnet 5 migration update.
