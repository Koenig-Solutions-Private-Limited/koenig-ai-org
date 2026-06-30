---
date: 2026-05-28
author: course-author
ticket: KOEA-6697
status: g3-passed
content_type: course-outline
title: "How to build a production Claude Agent SDK app in 6 chapters"
slug: claude-agent-sdk-zero-to-production
total_duration_min: 360
target_audience: "engineers + tech leads building agent products on the Claude Agent SDK in 2026"
prerequisites:
  - "TypeScript fluency"
  - "Basic familiarity with the Anthropic API"
capstone: "Production-ready TypeScript incident-triage agent with SDK streaming, MCP tools, least-privilege permissions, resumable run artifacts, evals, HTTP/CLI entrypoints, and an operator runbook"
tags:
  - claude-agent-sdk
  - typescript
  - production-agents
sources:
  - https://code.claude.com/docs/en/agent-sdk/typescript
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-permissions
  - https://docs.anthropic.com/en/docs/mcp
---

# How to build a production Claude Agent SDK app in 6 chapters

Course outline persisted by operator on 2026-05-28 (Course Author hit `bwrap: No permissions to create a new namespace` sandboxing failure — outline is intact from the agent's draft). Revised 2026-06-12 for KOEA-8039 (G0 structural blockers from KOEA-8028).

## Chapters

### Chapter 1 — Ship the smallest useful Claude Agent SDK app

**Duration:** 60 min

**Prerequisites:** None

**Learning objectives:**
1. Install and authenticate the Claude Agent SDK against the Anthropic API
2. Implement a minimal five-line agent using `Agent.run()` and explain each parameter
3. Compare streaming vs. blocking response modes and choose the right one for a given use case
4. Select the appropriate model tier (Haiku / Sonnet / Opus 4.7) based on task class and cost

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

---

### Chapter 4 — Preserve context with sessions, artifacts, and resumable runs

**Duration:** 60 min

**Prerequisites:** Chapters 1–3

**Learning objectives:**
1. Implement artifact storage using R2, S3, or local FS and explain the trade-offs between each
2. Configure resumable runs that reconstruct agent state after a crash or process restart
3. Apply prompt caching and cache control headers to reduce per-run token cost by ≥30%
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
3. Configure a cost circuit-breaker that halts the agent when a per-run budget is exceeded
4. Write an operator runbook covering failover, manual override, and on-call escalation procedures

**Topics:**
- Capstone build: incident-triage agent
- HTTP + CLI entrypoints
- Operator runbook (failover, manual override, cost circuit-breaker)
- On-call playbook for agent escalations

**Hands-on exercise:** Wire the incident-triage agent to an Express HTTP endpoint (`POST /triage`), add a `MAX_COST_USD` env guard that returns HTTP 402 when exceeded, and write a one-page operator runbook as `docs/runbook.md` covering restart, rollback, and manual override procedures.

---

## Capstone

A production-ready TypeScript incident-triage agent that:
- Streams via SDK to a thin HTTP shim
- Uses 3 MCP tools (Linear, PagerDuty, GitHub) with least-privilege scopes
- Persists run artifacts to R2 + writes resumable state to Durable Objects
- Has eval suite + Langfuse tracing
- Comes with an operator runbook

## Awaiting G0 (Content Reviewer review)

@content-reviewer please G0 this outline. Revised for KOEA-8039 to address all 7 structural blockers from KOEA-8028.
