---
date: 2026-06-02
agent: course-author
type: course-draft
course_slug: pi-agent-setup-and-usage-2026
title: "Pi Agent: Setup & Usage — Local Models, Claude, and OpenAI"
status: awaiting-g0
author: course-author
ticket: KOEA-7194
level: Intermediate
target_audience: "Developers who already use at least one AI coding tool (Claude Code, Codex CLI, Cursor, or Aider) and want a model-agnostic agent layer that runs locally and routes to frontier models on demand."
prerequisites:
  - "Comfortable in a terminal; basic Git knowledge"
  - "Familiar with at least one AI coding assistant in production use"
  - "Node.js 20+ installed (for Pi) or willingness to install it"
learning_outcomes:
  - "Install and configure Pi agent with a working local-first setup"
  - "Run Pi with Llama 3.1, Qwen 3.6, and DeepSeek V4 via Ollama for sensitive or cost-sensitive code"
  - "Wire Pi to Claude Code with plan-mode handoff and MCP tool servers"
  - "Route Pi to OpenAI GPT-5.5 using Codex CLI–compatible flags and cost-optimized hybrid workflows"
total_duration_min: 480
chapter_count: 4
tags:
  - course/pi-agent-setup-and-usage-2026
sources: []
---

# Course outline: Pi Agent — Setup & Usage (2026)

Pi agent is a provider-agnostic, open-source AI coding agent that routes tasks across local models (via Ollama), Anthropic Claude, and OpenAI — from a single CLI and a single config file. This four-chapter hands-on course gets you from zero to a working multi-provider setup, with production-grade wiring for the two most common frontier integrations.

---

## Chapter 1: What Is Pi Agent + Why It Matters

**Goal:** Understand Pi's design philosophy, architecture, and value proposition before touching any code.

- The model-fragmentation problem: why teams running Claude Code + Codex CLI + Aider end up with three configs, three context models, and three billing dashboards
- Pi's answer: a single agent loop with a provider plugin layer underneath
- Architecture walkthrough: provider adapters → agent loop → plan engine → MCP tool layer
- Installation (Node 20+, npm global; Homebrew tap on macOS)
- Initial config file (`~/.pi/config.toml`) and first `pi chat` run
- Hands-on exercise: install Pi, configure one provider (ollama/llama3.1:8b), run a one-shot code explanation task

**Learning objectives:**
- Explain Pi's architecture in one sentence to a teammate
- Install Pi and confirm it runs against at least one provider
- Identify which provider each Pi invocation will route to

**Duration:** 90 minutes (30 min reading + 60 min hands-on)

**Key diagrams:** Provider plugin stack (Mermaid); first-run sequence diagram

---

## Chapter 2: Pi + Local Models — Ollama Setup, Model Selection, and Workload Routing

**Goal:** Run Pi with three local models and apply a routing rubric to pick the right model per task.

- Why local first: data residency, cost floor, latency on commodity hardware
- Ollama quick-start: install, pull `llama3.1:8b`, `qwen3.6:14b`, `deepseek-v4:14b`
- Pi provider block for ollama: base URL, model aliases, timeout tuning
- Model comparison across three workload types: boilerplate generation, large-context refactor, reasoning-heavy debugging
- Workload routing rubric: when local is enough vs. when to escalate to a frontier model
- Plan-mode with local models: generating PLAN.md from a spec prompt
- Hands-on exercise: three parallel tasks (one per model), interpret Pi's token counters, write your own routing rules

**Learning objectives:**
- Pull and verify all three models in Ollama
- Configure Pi's ollama provider block with model aliases
- Apply the workload routing rubric to route a real task to the correct local model

**Duration:** 120 minutes (40 min reading + 80 min hands-on)

**Key diagrams:** Workload routing rubric (Mermaid decision tree); token-cost comparison table

---

## Chapter 3: Pi + Anthropic Claude — Claude Code Interop, Plan-Mode Handoff, MCP Wiring

**Goal:** Connect Pi to Claude (both direct API and Claude Code) and use plan-mode handoff and MCP tools.

- Anthropic provider block: API key, model ID (claude-sonnet-4-6 recommended), rate-limit handling
- Pi plan-mode vs. Claude Code plan-mode: what each owns; when to delegate
- Plan-mode handoff pattern: Pi generates PLAN.md → Claude Code picks it up via `--plan` flag
- MCP tool wiring: Pi as MCP client consuming an existing Claude MCP server (filesystem, browser-use, search)
- Running a Pi + Claude Code joint session: trace a real multi-step coding task end-to-end
- Hands-on exercise: implement a small feature using Pi plan-mode → Claude Code execution → Pi verification loop

**Learning objectives:**
- Configure the anthropic provider block with the correct model and API key
- Explain the difference between Pi plan-mode and Claude Code plan-mode
- Wire at least one MCP tool server and verify Pi can invoke it

**Duration:** 120 minutes (40 min reading + 80 min hands-on)

**Key diagrams:** Plan-mode handoff sequence (Mermaid); MCP connection topology

---

## Chapter 4: Pi + OpenAI — Codex CLI Compatibility, GPT-5.5 Routing, Cost-Optimized Hybrid Workflows

**Goal:** Wire Pi to OpenAI, exploit Codex CLI flag compatibility, and build a hybrid local ↔ frontier routing strategy that minimises cost without sacrificing quality.

- OpenAI provider block: API key, base URL override, organisation ID
- Codex CLI flag compatibility: how Pi maps `--model`, `--temperature`, `--max-tokens` to its provider layer
- GPT-5.5 routing: which task types benefit from GPT-5.5's extended context vs. a cheaper local model
- Cost-optimized hybrid strategy: budget per session (`pi budget set 0.50`), auto-escalation rules
- Auditing spend: Pi's `pi cost` command and the COST.log format
- Capstone workflow: full feature request — local plan → local draft → GPT-5.5 review → local patch
- Hands-on exercise: implement a database schema migration with the hybrid workflow; hit the budget cap intentionally and observe escalation behaviour

**Learning objectives:**
- Configure the openai provider block and verify Codex CLI flag passthrough
- Set a session budget and trigger auto-escalation from local to GPT-5.5
- Read Pi's COST.log and identify where spend is concentrated

**Duration:** 150 minutes (50 min reading + 100 min hands-on)

**Key diagrams:** Hybrid routing strategy (Mermaid flowchart); spend-by-provider table

---

## Capstone project

Implement a complete CRUD REST API (chosen language/framework by the learner) using Pi's hybrid workflow:

1. Local plan-mode (Llama 3.1 or Qwen 3.6) for the initial spec → PLAN.md
2. Claude Code for implementation (pi plan handoff)
3. GPT-5.5 for security review of the generated endpoints
4. Local model for test generation

Deliverable: working API + `COST.log` showing spend-by-provider breakdown. Total budget cap: $0.75.
