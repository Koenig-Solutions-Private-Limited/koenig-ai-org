---
date: 2026-05-28
author: course-author
ticket: KOEA-6697
status: awaiting-g0
content_type: course-outline
title: "How to build a production Claude Agent SDK app in 6 chapters"
slug: claude-agent-sdk-zero-to-production
duration_min: 360
target_audience: "engineers + tech leads building agent products on the Claude Agent SDK in 2026"
prereq: "TypeScript fluency, basic familiarity with the Anthropic API"
capstone: "Production-ready TypeScript incident-triage agent with SDK streaming, MCP tools, least-privilege permissions, resumable run artifacts, evals, HTTP/CLI entrypoints, and an operator runbook"
sources:
  - https://code.claude.com/docs/en/agent-sdk/typescript
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-mcp
  - https://docs.anthropic.com/en/docs/claude-code/sdk/sdk-permissions
  - https://docs.anthropic.com/en/docs/mcp
---

# How to build a production Claude Agent SDK app in 6 chapters

Course outline persisted by operator on 2026-05-28 (Course Author hit `bwrap: No permissions to create a new namespace` sandboxing failure — outline is intact from the agent's draft).

## Chapters

### Chapter 1 — Ship the smallest useful Claude Agent SDK app
- Install + auth (Anthropic API + Claude subscription)
- The smallest possible agent (5-line example with `Agent.run()`)
- Streaming vs blocking responses
- Picking the right model tier (Haiku / Sonnet / Opus 4.7) for your task class

### Chapter 2 — Turn a prompt script into a controllable agent harness
- Session resume + state model
- System prompts + dynamic instructions
- Configurable agent harness pattern (env-driven persona swap)
- When to use Agent SDK vs raw Anthropic SDK

### Chapter 3 — Add safe tools with MCP and explicit permissions
- MCP server basics
- Tool design patterns (idempotent, narrow, named)
- Permission boundaries (read-only vs write-allowed tools)
- Sandboxed execution

### Chapter 4 — Preserve context with sessions, artifacts, and resumable runs
- Session ID + run ID model
- Artifact storage patterns (R2 / S3 / local FS)
- Resumable runs — picking up from a crash
- Cache control + prompt caching for cost

### Chapter 5 — Evaluate, observe, and debug the agent before users do
- Evals: synthetic + golden + canary
- Langfuse + OTEL integration
- Cost attribution per run + per tool call
- Debugging mid-run state (run inspector pattern)

### Chapter 6 — Deploy the incident-triage agent with production guardrails
- Capstone build: incident-triage agent
- HTTP + CLI entrypoints
- Operator runbook (failover, manual override, cost circuit-breaker)
- On-call playbook for agent escalations

## Capstone

A production-ready TypeScript incident-triage agent that:
- Streams via SDK to a thin HTTP shim
- Uses 3 MCP tools (Linear, PagerDuty, GitHub) with least-privilege scopes
- Persists run artifacts to R2 + writes resumable state to Durable Objects
- Has eval suite + Langfuse tracing
- Comes with an operator runbook

## Awaiting G0 (Content Reviewer review)

@content-reviewer please G0 this outline. If approved, ch01 draft follows.
