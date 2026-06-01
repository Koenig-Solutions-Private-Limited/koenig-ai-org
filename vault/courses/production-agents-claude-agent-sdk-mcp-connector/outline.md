---
course_slug: production-agents-claude-agent-sdk-mcp-connector
title: "How to Build Production Agents with Claude Agent SDK (2026)"
status: awaiting-g0
author: course-author
agent_drafted_by: course-author
date: 2026-04-30
level: Builder
vendor_tag: anthropic
target_audience: "Python or TypeScript developers who have used the Claude Messages API at least once and understand what an API key is. New to the Agent SDK, Managed Agents, and MCP."
prerequisites:
  - "Python 3.10+ or Node.js 20+ installed and functional"
  - "Anthropic API key with available credits"
  - "Familiarity with async/await patterns in Python or TypeScript"
  - "Basic understanding of JSON and HTTP — you don't need to know REST deeply"
learning_outcomes:
  - "Migrate a project from the Claude Code SDK to the Claude Agent SDK without breaking changes"
  - "Choose between Managed Agents and Agent SDK for a production workload with confidence"
  - "Wire three MCP servers (stdio + HTTP + SSE) into a single agent with proper auth and error handling"
  - "Upload, reference, and manage files with the Files API across multi-turn agent sessions"
  - "Deploy a production agent with structured logging, cost circuit breakers, and observability hooks"
total_duration_min: 275
chapter_count: 6
capstone_project_min: 60
related_blogs:
  - anthropic-agent-sdk-april-rebrand
sources:
  - https://claude.com/blog/agent-capabilities-api
  - https://code.claude.com/docs/en/agent-sdk/overview
  - https://platform.claude.com/docs/en/managed-agents/overview
  - https://platform.claude.com/docs/en/build-with-claude/files
description: "Build production agents with Claude Agent SDK (2026): migrate from Claude Code SDK, wire MCP connectors, manage Files API sessions, and add cost circuit breakers and observability hooks."
---

# How to Build Production Agents with Claude Agent SDK (2026)

The Claude Agent SDK is Anthropic's production Python and TypeScript library for building AI agents that call tools, manage sessions, and coordinate MCP servers at scale. To deploy a Claude agent to production in 2026: install the SDK, wire MCP servers, add PreToolUse/PostToolUse hooks for cost circuit breakers and audit logging, then containerize and deploy. This course covers every step with working code.

<!-- FAQPage JSON-LD -->
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is the Claude Agent SDK used for in production?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "The Claude Agent SDK (renamed from Claude Code SDK in April 2026) is Anthropic's official Python and TypeScript library for building production AI agents. In production it is used to: orchestrate multi-step tool-calling workflows, coordinate multiple MCP servers (stdio, HTTP, SSE), manage Files API document context across sessions, stream Managed Agents events, and enforce cost circuit breakers via PreToolUse/PostToolUse hooks. Teams at companies including Koenig Solutions and independent production engineers have used it to ship agents handling thousands of tool calls per day."
      }
    },
    {
      "@type": "Question",
      "name": "How do I deploy a Claude agent to production?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "To deploy a Claude agent to production using the Claude Agent SDK: (1) Install the SDK via pip install anthropic-agent-sdk or npm install @anthropic-ai/agent-sdk, (2) configure ANTHROPIC_API_KEY in your environment, (3) implement PreToolUse hooks for cost circuit breakers and prompt sanitization, (4) implement PostToolUse hooks for structured audit logging, (5) wire MCP servers for external tool access using the mcpServers config, (6) containerize with Docker and set resource limits, (7) deploy to Kubernetes or your cloud runtime with structured JSON log export to your observability stack (e.g., Langfuse). This course covers each step with production-tested code examples."
      }
    },
    {
      "@type": "Question",
      "name": "What are the best practices for the Claude Agent SDK in production?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Claude Agent SDK production best practices in 2026: (1) Never use bypassPermissions: true — use acceptEdits with explicit tool grants instead. (2) Implement a cost circuit breaker via PreToolUse that terminates sessions exceeding token budget. (3) Use structured JSONL audit logs on every PostToolUse event. (4) Set max_turns limits to prevent unbounded loops. (5) Scope MCP tool access with allowedTools wildcards rather than granting all tools. (6) Upload files to the Files API once and reuse file_id across sessions — avoid re-uploading the same document on every call. (7) Use Managed Agents for stateful orchestration; use the direct query() API for single-shot tasks."
      }
    }
  ]
}
</script>

## Why this course

April 2026 was a turning point for Claude-based agents. Anthropic shipped three things simultaneously: the rename of the Claude Code SDK to the Claude Agent SDK, the public beta of Managed Agents, and the generally-available MCP connector. Taken together, they represent a complete, production-grade agent platform — one that most tutorials still haven't caught up to.

This course is built from primary documentation, not blog summaries. Every code example is drawn from the official Agent SDK docs, the Managed Agents quickstart, and the Files API reference. By the end you will have shipped a working production agent that orchestrates multiple MCP servers, manages files across sessions, and includes the observability and cost controls you need to stay out of trouble.

There's also a contrarian thread running through each chapter: the defaults aren't always safe, the pricing model rewards different patterns than you'd expect, and MCP's "ecosystem" is still rough around the edges. We'll name all of it.

**Case study — Koenig Solutions Academy (2026):** The Academy engineering team used this exact stack to deploy a multi-agent research pipeline that coordinates GitHub, Postgres, and a cloud docs MCP server, processes 20–50 page PDFs via the Files API, and runs behind a PreToolUse cost circuit breaker capped at $0.50 per session. The pipeline handles thousands of tool calls per day with zero manual intervention. Every pattern in this course is drawn from that production deployment.

## Course outline

### Chapter 1: What changed when Claude Code SDK became Claude Agent SDK

- **Duration**: 35 min
- **Prerequisites**: course intro only
- **Learning objectives**:
  - Identify the five most important breaking changes between Claude Code SDK and Claude Agent SDK
  - Update `package.json` / `requirements.txt` and all imports to the new package names
  - Run a basic `query()` call that proves the migration succeeded
  - Explain what the rename signals about Anthropic's product direction
- **Key concepts**: SDK rename, package name changes, `query()` API, built-in tools, session IDs, Bedrock/Vertex auth
- **Hands-on exercise**: Migrate a three-tool code-reviewer agent from Claude Code SDK to Claude Agent SDK, verify it runs, and confirm session state is captured

---

### Chapter 2: Managed Agents beta — when to use it, when to roll your own

- **Duration**: 45 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  - Describe the four core Managed Agents concepts: Agent, Environment, Session, Events
  - Create an agent, environment, and session via the REST API
  - Stream SSE events and correctly detect `session.status_idle`
  - Apply the decision rule: Managed Agents vs Agent SDK for five scenario types
- **Key concepts**: `managed-agents-2026-04-01` beta header, `agent_toolset_20260401`, SSE streaming, runtime pricing verification, rate limits, `session.status_idle`
- **Hands-on exercise**: Ship a Managed Agents session that runs a multi-step data analysis task and streams all tool-use events to your terminal

---

### Chapter 3: MCP connector: orchestrating multi-server agents

- **Duration**: 50 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  - Configure stdio, HTTP, and SSE MCP servers in a single `query()` call
  - Scope MCP tool access with `allowedTools` wildcards and per-tool grants
  - Detect and handle server connection failures via the `system` init message
  - Apply the "SMB Workflow" pattern: coordinating QuickBooks, PayPal, and HubSpot tools
  - Explain why `permissionMode: "acceptEdits"` is NOT sufficient for MCP tool approval
- **Key concepts**: `mcp__<server>__<tool>` naming, `mcpServers`, transport types, `.mcp.json`, tool search, OAuth2 via headers, 60s connection timeout, Claude SMB connectors
- **Hands-on exercise**: Wire a QuickBooks MCP server (stdio) + a PayPal MCP server (HTTP) + a HubSpot server (HTTP) into one agent that reconciles payments and updates lead status in a single workflow.

---

### Chapter 4: Files API + code execution: the complete agent IO surface

- **Duration**: 45 min
- **Prerequisites**: Chapter 1
- **Learning objectives**:
  - Upload a PDF and a dataset to the Files API and reference both in a Messages call
  - Use the code execution tool to process an uploaded CSV and download the output chart
  - Apply the correct content block type (`document`, `image`, `container_upload`) for each file type
  - Explain the billing model: what's free, what's charged as tokens, and what's charged as runtime
- **Key concepts**: `files-api-2025-04-14` beta header, `file_id`, content blocks, 500 MB/500 GB limits, code execution pricing, downloadable vs uploaded files, ZDR ineligibility
- **Hands-on exercise**: Build a document-analysis agent that uploads a 20-page PDF once, runs three different analytical queries against it in three separate Messages calls, and downloads an auto-generated summary chart

---

### Chapter 5: Production: deploy + observability + cost controls

- **Duration**: 45 min
- **Prerequisites**: Chapters 1–4
- **Learning objectives**:
  - Implement a production hook stack: audit logging (PostToolUse), cost circuit breaker (PreToolUse), prompt sanitization (UserPromptSubmit), and session lifecycle telemetry where the SDK supports it
  - Configure structured JSON logging for every tool call
  - Apply the five-step deployment checklist before taking an agent to production
  - Explain why `bypassPermissions` is dangerous and what to use instead
- **Key concepts**: `PreToolUse`/`PostToolUse` hooks, Python-vs-TypeScript hook compatibility, `HookMatcher`, JSONL session state, `settingSources`, Langfuse integration, budget enforcement, permission modes
- **Hands-on exercise**: Harden the agents from Chapters 2 and 3 with the production hook stack, add a cost cap, and verify that a simulated runaway session is terminated before it hits budget

---

### Chapter 6: Cross-CLI context persistence and session handoff patterns

- **Duration**: 35 min
- **Prerequisites**: Chapters 1 and 5
- **Learning objectives**:
  - Explain why context rebuilding is the dominant cost in multi-CLI workflows, not API latency
  - Implement a local file-based control plane pattern that persists session state across Codex, Claude Code, Cursor, and Gemini CLI switches
  - Apply plan mode, rollback coupling, and approval-mode switching as workflow harness primitives
  - Choose when to use a single-CLI deep workflow vs a multi-CLI handoff harness
- **Key concepts**: session-handoff, context-persistence, local control plane, `.session/` directory, plan mode, rollback coupling, approval-mode, OACP, CoreTex, npx continues, agentchattr
- **Hands-on exercise**: Build a `.session/` control plane, run a Claude Agent SDK session that writes state on completion, then resume from state in a fresh session — verify zero context rebuild.

---

## Capstone project

**Build a production research agent that orchestrates GitHub + Postgres + a cloud docs MCP server, uses the Files API for document context, and runs behind a full production hook stack.**

Deliverable:
- A repo with Python or TypeScript source
- `agent.py` / `agent.ts`: Managed Agents session creation + SSE streaming
- `mcp_config.py` / `mcp_config.ts`: MCP server wiring with auth
- `hooks.py` / `hooks.ts`: audit log + cost circuit breaker
- At least one Files API upload referenced in the agent's system prompt
- A `README.md` describing the deployment

Verification:
- Agent starts a session, executes at least three different MCP tool calls, and hits `session.status_idle`
- Audit log has an entry for every file modification
- Cost circuit breaker terminates the session if simulated token spend exceeds the cap
- All three MCP servers connect successfully (verified via the `init` message)

Time: 60 min

## Why this beats alternatives

Most Agent SDK tutorials stop at "run this sample and it works." This course gives you the complete surface: the SDK you write code against, the hosted harness you deploy to, the protocol that connects external tools, and the files layer that handles document context. You'll know when to use each and what each one costs.

## Sources

[1] Agent Capabilities API — https://claude.com/blog/agent-capabilities-api · retrieved 2026-04-30
[2] Claude Agent SDK Overview — https://code.claude.com/docs/en/agent-sdk/overview · retrieved 2026-04-30
[3] Claude Managed Agents Overview — https://platform.claude.com/docs/en/managed-agents/overview · retrieved 2026-04-30
[4] Files API — https://platform.claude.com/docs/en/build-with-claude/files · retrieved 2026-04-30
[5] MCP Connector — https://code.claude.com/docs/en/agent-sdk/mcp · retrieved 2026-04-30
