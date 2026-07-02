---
date: 2026-06-02
agent: course-author
type: course-draft
slug: pi-agent-setup-and-usage-2026
course_slug: pi-agent-setup-and-usage-2026
title: "Pi Coding Agent: Setup and Usage - Local Models, Cloud Providers, and Extensions"
status: g0-passed
author: course-author
ticket: KOEA-7194
level: Intermediate
target_audience: "Developers who already use at least one AI coding tool and want a minimal, extensible terminal agent that can route work across local models, API-key providers, and subscription-backed providers."
prerequisites:
  - "Comfortable in a terminal and with Git"
  - "Familiar with at least one AI coding assistant in production use"
  - "Node.js/npm available for installing Pi, or willingness to follow the official installer"
learning_outcomes:
  - "Install Pi Coding Agent and complete a first authenticated session"
  - "Configure project instructions, global settings, and custom local-model definitions"
  - "Use Pi's core slash commands for model switching, session navigation, compaction, and continuation"
  - "Connect cloud providers and local OpenAI-compatible endpoints without inventing unsupported modes"
  - "Evaluate when to use Pi's native extension/skill model, community MCP adapter, or plain shell tools"
total_duration_min: 480
chapter_count: 4
tags:
  - course/pi-agent-setup-and-usage-2026
sources: []
---

# Course outline: Pi Coding Agent - Setup and Usage (2026)

Pi is a minimal terminal coding agent. The course teaches the real product surface: install `@mariozechner/pi-coding-agent`, launch with `pi`, authenticate with `/login` or environment variables, configure JSON files under `~/.pi/agent/`, and extend Pi through skills, TypeScript extensions, packages, and optional community adapters. The course explicitly avoids the stale draft's nonexistent TOML setup, chat/plan/cost subcommands, native MCP, and built-in plan mode.

---

## Chapter 1: What Pi Is and How to Start Safely

**Duration:** 90 minutes (30 min reading + 60 min hands-on)

**Prerequisites:**
- None beyond the course prerequisites

**Learning objectives:**
- Explain Pi's minimal-agent philosophy and the four default tools
- Install Pi with the current package name and identify the active package scope
- Launch `pi`, authenticate with `/login` or an API key, and run a first session
- Locate `~/.pi/agent/settings.json`, `~/.pi/agent/auth.json`, and project instruction files

**Key concepts:**
- Current package namespace: `@mariozechner/*`
- Four default tools: read, write, edit, bash
- `pi` interactive startup and `pi -p` one-shot mode
- JSON settings, auth, and model files under `~/.pi/agent/`
- No native MCP and no built-in plan mode

**Hands-on exercise:**
- Install Pi, launch it in a small Git repository, authenticate one provider, add a short `AGENTS.md`, run a repository summary request, and inspect where Pi stored settings and credentials.

**Key diagrams:** Pi package stack; first-session sequence diagram

---

## Chapter 2: Local Models Through OpenAI-Compatible Endpoints

**Duration:** 120 minutes (40 min reading + 80 min hands-on)

**Prerequisites:**
- Completed Chapter 1
- One local model runtime installed: Ollama, LM Studio, llama.cpp, or vLLM

**Learning objectives:**
- Add local providers and models in `~/.pi/agent/models.json`
- Explain why local servers use OpenAI-compatible APIs inside Pi
- Set context-window and compatibility fields for models that Pi cannot auto-detect
- Switch to a local model with `/model`, Ctrl+L, or startup flags

**Key concepts:**
- `models.json` provider blocks
- OpenAI-compatible local endpoints
- Dummy API keys for keyless local servers
- Context-window configuration
- Compatibility flags for developer-role and reasoning-effort support
- Prompt-processing bottlenecks on local hardware

**Hands-on exercise:**
- Start Ollama or LM Studio, add a local model to `models.json`, select it inside Pi, ask it to summarize a small codebase, and record what latency and context limits feel like compared with a cloud model.

**Key diagrams:** Local endpoint topology; local-model selection checklist

---

## Chapter 3: Cloud Providers, Subscription Auth, and Model Switching

**Duration:** 120 minutes (40 min reading + 80 min hands-on)

**Prerequisites:**
- Completed Chapter 1
- Access to at least one cloud provider account or API key

**Learning objectives:**
- Connect Anthropic, OpenAI, or another cloud provider using `/login` or environment variables
- Distinguish subscription login from API-key authentication and its billing implications
- Switch providers mid-session while preserving the practical caveats around lossy context translation
- Use `/session`, `/compact`, `/resume`, `/tree`, and `/fork` to keep long sessions auditable

**Key concepts:**
- `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, and auth file resolution
- Claude Pro/Max subscription auth caveat: active in current docs but billed as extra usage
- Cursor subscription auth (via `pi-cursor-sdk` extension)
- `/model` and keyboard model switching
- Thinking-level controls
- Session JSONL, continuation, branching, and compaction

**Hands-on exercise:**
- Configure one cloud provider, run the same task on a local and a cloud model, switch models inside a live session, compact the session, resume it, and document where quality or speed changed.

**Key diagrams:** Provider-auth decision tree; session lifecycle map

---

## Chapter 4: Extensions, Skills, MCP Tradeoffs, and a Production Workflow

**Duration:** 150 minutes (50 min reading + 100 min hands-on)

**Prerequisites:**
- Completed Chapters 1-3
- A small codebase where the learner can safely let Pi edit files

**Learning objectives:**
- Decide when to use AGENTS.md, APPEND_SYSTEM.md, a skill, a prompt template, or a TypeScript extension
- Install and evaluate Pi packages without bloating every session
- Explain Pi's no-native-MCP stance and when the community `pi-mcp-adapter` is justified
- Build a repeatable workflow that uses files for plans instead of relying on nonexistent plan mode

**Key concepts:**
- Hierarchical instruction files
- Skills and prompt templates
- TypeScript extension hooks and package trust
- `pi install npm:<package>`
- Community MCP bridge versus native shell tools
- Planning through versioned files such as `PLAN.md`
- Security posture: full local authority unless the operator adds guardrails

**Hands-on exercise:**
- Create a project-local Pi setup with instructions, one skill, one optional package, and a file-backed implementation plan. Use Pi to make a small change, review the diff, and record the repeatable operating procedure.

**Key diagrams:** Extension decision matrix; final workflow checklist

---

## Capstone project

Configure Pi for a real repository and produce a complete, auditable coding workflow:

1. Install the current Pi package and authenticate one provider.
2. Add project instructions and a safe local setup.
3. Configure one local model in `models.json`.
4. Run a cloud model and a local model on separate parts of the same task.
5. Use a versioned `PLAN.md` that Pi edits through natural language, not a built-in plan mode.
6. Add one skill or extension only if it solves a concrete gap.
7. Produce a final diff, session notes, and a short provider-routing rationale.

Deliverable: a working repository change plus a short operations note explaining install path, provider auth, selected model(s), local-model configuration, extensions/packages used, and known safety caveats.
