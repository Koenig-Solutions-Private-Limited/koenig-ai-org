---
date: 2026-07-06
title: "Google Killed Gemini CLI in 2026: Your Complete Antigravity CLI Migration Guide"
slug: google-gemini-cli-deprecated-antigravity-cli-migration-guide
author: blog-author
ticket: KOEA-10220
vendor_tag: google
content_type: article
status: g0-passed
reading_time_min: 6
tags:
  - google
  - gemini-cli
  - antigravity-cli
  - migration
description: "Migrate from deprecated Gemini CLI to Antigravity CLI with the command, MCP config, plugin, and CI changes that prevent silent workflow failures."
seo_description: "Migrate from deprecated Gemini CLI to Antigravity CLI in 2026. Covers the silent agents→agent rename, MCP serverUrl key change, and CI/CD audit steps."
primary_query: "google gemini cli deprecated migrate antigravity cli 2026"
contrarian_angle: "The agents→agent plural rename and the MCP url→serverUrl silent failure are the real CI/CD killers — not the binary rename everyone talks about"
first_60_words_answer: "On June 18, 2026, Google shut off Gemini CLI for all free, AI Pro, and AI Ultra users. The official replacement is Antigravity CLI (agy), announced at Google I/O on May 19, 2026. Migration takes five steps. Two have silent failure modes that break CI/CD without throwing an error: the agents→agent plural rename and the MCP url→serverUrl key change."
positions:
  - id: stance:ai-vendor-news-opinionated
    engagement: defends
  - id: stance:harness-over-model
    engagement: defends
  - id: cli-first-workflows-for-production-teams
    engagement: neutral
faq:
  - question: "Does the Gemini API changelog confirm the Gemini CLI deprecation?"
    answer: "No. The Gemini API changelog (ai.google.dev/gemini-api/docs/changelog) mentions antigravity-preview-05-2026 as a managed API agent endpoint, not as a CLI migration notice. The correct primary source for the CLI deprecation is the Google Developer Blog post from May 19, 2026 at developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/ — a separate document that explicitly covers the terminal tool transition."
  - question: "Is Antigravity CLI open source like Gemini CLI was?"
    answer: "No. Antigravity CLI ships as a closed-source binary only. The github.com/google-antigravity/antigravity-cli repository contains only a README, CHANGELOG.md, and a demo GIF. Gemini CLI (github.com/google-gemini/gemini-cli) remains on GitHub under Apache 2.0 and receives enterprise bug and security fixes, but it no longer serves consumer users as of June 18, 2026."
  - question: "Are Enterprise users of Gemini CLI required to migrate by June 18, 2026?"
    answer: "No. Enterprise Standard and Enterprise licence holders retain full Gemini CLI access and are not affected by the June 18 cutoff. The cutoff applied to free-tier, Google AI Pro, and AI Ultra subscribers. Gemini Code Assist for GitHub also stopped accepting new installations on June 18, with existing requests winding down in subsequent weeks. Source: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/"
original_data: false
last_updated: 2026-07-09
hero_image:
  url: /img/blogs/google-gemini-cli-deprecated-antigravity-cli-migration-guide/hero.png
  alt: "Terminal showing agy agent run command replacing the deprecated gemini agents run syntax after the June 18 2026 Gemini CLI cutoff"
whats_new:
  - "Google shut off Gemini CLI on June 18, 2026 — the 5-step Antigravity CLI migration with the two silent-failure traps developers keep hitting"
learning_objectives:
  - "Execute a complete Gemini CLI to Antigravity CLI migration including MCP config and CI/CD script updates"
  - "Correctly scope the v2.2.1 bug to the Antigravity 2.0 desktop app, not the Antigravity CLI terminal tool"
  - "Understand why the agents→agent plural rename is the most common post-migration CI/CD failure"
sources:
  - https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
  - https://ai.google.dev/gemini-api/docs/changelog
  - https://github.com/google-gemini/gemini-cli/discussions/27274
  - https://github.com/google-antigravity/antigravity-cli
  - https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md
  - https://antigravity.google/docs/gcli-migration
  - https://discuss.ai.google.dev/t/bug-report-browser-command-routing-issue-in-2-2-1-forces-linux-only-tool-on-windows/172873
  - https://github.com/google-antigravity/antigravity-cli/releases
  - https://windowsforum.com/threads/gemini-cli-to-antigravity-cli-on-windows-june-18-2026-migration-guide.424929
  - https://thenewstack.io/gemini-cli-antigravity-replacement
  - https://medium.com/google-cloud/migrating-to-antigravity-cli-from-gemini-cli-with-mcp-for-google-cloud-databases-6010a2cac41e
  - https://pub.towardsai.net/google-killed-gemini-cli-antigravity-2-0-users-got-a-whole-new-platform-44e6ca94c943
  - https://inventivehq.com/blog/gemini-cli-deprecated-antigravity-cli-migration
---

# Google Killed Gemini CLI in 2026: Your Complete Antigravity CLI Migration Guide

On June 18, 2026, Google shut off Gemini CLI for all free, AI Pro, and AI Ultra users. The official replacement is Antigravity CLI (`agy`), [announced at Google I/O on May 19, 2026](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/). Migration takes five steps. Two have silent failure modes that break CI/CD without throwing an error: the `agents` → `agent` plural rename, and the MCP `url` → `serverUrl` key change.

Most guides tell you to run `s/gemini/agy/g` and call it done. That gets you 80% of the way. The remaining 20% is where real migrations break: `gemini agents run` → `agy agents run` looks right after a naive find-and-replace, compiles, and then [fails silently](https://windowsforum.com/threads/gemini-cli-to-antigravity-cli-on-windows-june-18-2026-migration-guide.424929) — because the correct command is `agy agent run` (singular). Combine that with the MCP config key rename that drops your servers without an error, and a "30-minute migration" becomes a two-day incident. This guide covers every trap.

## Who June 18 Actually Cut Off — and Who It Didn't

The cutoff hit free-tier Gemini Code Assist users, Google AI Pro subscribers, Google AI Ultra subscribers, and new Gemini Code Assist for GitHub installs. It did **not** affect Enterprise Standard or Enterprise licence holders, who retain full Gemini CLI access. [Google's announcement](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/) framed the move as product focus around "today's multi-agent reality." The developer community's reaction was pointed — the announcement showed 293 downvotes on [GitHub discussions](https://github.com/google-gemini/gemini-cli/discussions/27274) when rechecked on July 9, 2026, overwhelmingly because Gemini CLI was Apache 2.0 and [Antigravity CLI ships as a closed-source binary](https://github.com/google-antigravity/antigravity-cli).

The `google-gemini/gemini-cli` repository remains on GitHub under Apache 2.0 and continues to receive enterprise bug and security fixes. For everyone else, it is effectively archived.

One clarification worth making: the [Gemini API changelog](https://ai.google.dev/gemini-api/docs/changelog) mentions `antigravity-preview-05-2026` as a managed API agent endpoint — not as a CLI deprecation notice. If you saw that changelog entry and concluded it confirmed the CLI transition, it didn't. The correct source is the developer blog post.

## What Antigravity CLI Actually Is (and the Version Scheme That Will Confuse You)

Antigravity CLI is not a renamed Gemini CLI. It is a distinct product built in Go rather than TypeScript/Node.js, with a different licensing model, session architecture, and command surface. [The New Stack's headless test](https://thenewstack.io/gemini-cli-antigravity-replacement) found Gemini CLI could read and explain file edits in non-interactive mode but could not complete the write operation; Antigravity CLI is designed for that headless agent loop. Google's own blog acknowledges ["there won't be 1:1 feature parity right out of the gate"](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/), so treat this as a migration to a different [[glossary/agent-harness|agent harness]], not an upgrade of the same one.

The version scheme matters because the Antigravity product line uses two separate tracks: the **desktop app** uses `2.x.x`, the **CLI** uses `1.x.x`. Any bug report citing version `2.2.1` is about the desktop app. This is directly relevant to a widely-circulated bug report — covered in the section below.

## The 5-Step Migration Scaffold

Google's announcement links an Antigravity migration guide, but `https://antigravity.google/docs/gcli-migration` returned HTTP 200 with no extractable body when rechecked on July 9, 2026. The scaffold below uses the accessible Google announcement, public Antigravity CLI repository, CLI changelog, and implementation reports rather than treating the unavailable page as source evidence.

**Step 1: Install and verify**

```bash
# macOS / Linux
curl -fsSL https://antigravity.google/install.sh | bash

# Windows PowerShell
irm https://antigravity.google/install.ps1 | iex

# Verify
agy --version
```

On Linux, the installer [adds the `agy` alias automatically](https://medium.com/google-cloud/migrating-to-antigravity-cli-from-gemini-cli-with-mcp-for-google-cloud-databases-6010a2cac41e). On macOS, the `antigravity` binary name also resolves.

**Step 2: Authenticate**

```bash
agy auth login
# For GCP project billing:
agy auth login --project YOUR_GCP_PROJECT_ID
```

**Step 3: Import plugins (migrates Gemini CLI extensions)**

```bash
agy plugin import gemini
agy plugin list
```

Verify each plugin with `agy plugin list`; incomplete imports are faster to catch here than inside a failing CI run.

**Step 4: Update MCP config (silent failure if skipped)**

If you have [[glossary/mcp|MCP]] servers configured, the config key changed from `url` to `serverUrl`. No error is thrown on the wrong key — the server silently does not connect. Move standalone config to `~/.gemini/config/mcp_config.json` and use:

```json
{ "mcpServers": { "my-server": { "serverUrl": "ws://localhost:3000" } } }
```

Also rename workspace skills: `.gemini/skills/` → `.agents/skills/`.

**Step 5: Fix scripts and CI/CD — the plural landmine**

This is the most common source of post-migration incidents: the `agents` subcommand became `agent` (singular).

| Gemini CLI | Antigravity CLI | Note |
|---|---|---|
| `gemini agents run <workflow>` | `agy agent run <workflow>` | **Plural → singular — silent failure** |
| `gemini extensions list` | `agy plugin list` | Extensions became Plugins |
| `gemini -p "prompt"` | `agy -p "prompt"` | Same flag |

Search every CI script and Makefile for `agents run` and replace with `agent run`. A project-wide `grep -r "agents run"` is the fastest audit.

{{RunPromptCell}}
```bash
# Full migration audit — run from repo root
echo "=== Checking for deprecated gemini binary calls ==="
grep -rn "gemini " .github/ Makefile scripts/ 2>/dev/null | grep -v ".git"

echo "=== Checking for agents run (plural — will fail silently) ==="
grep -rn "agents run" . 2>/dev/null | grep -v ".git"

echo "=== Checking for old MCP url key ==="
grep -rn '"url":' ~/.gemini/ 2>/dev/null
```

Expected output: all three searches should return empty after a complete migration. Any line containing `gemini ` (binary), `agents run`, or `"url":` in your MCP config is a migration gap.
{{/RunPromptCell}}

## The v2.2.1 Bug Is in the Desktop App, Not the CLI

A bug filed June 29, 2026 on the Google AI Developers Forum documents a `/browser` routing regression where version 2.2.1 sometimes invoked a Linux-only inline browser path on Windows instead of routing through the subagent path ([Google AI Developers Forum](https://discuss.ai.google.dev/t/bug-report-browser-command-routing-issue-in-2-2-1-forces-linux-only-tool-on-windows/172873)). This is confirmed and real. But it is scoped to **Antigravity 2.0 desktop app version 2.2.1** — not Antigravity CLI, which runs on the separate `1.x.x` track and is currently at `1.0.14`.

If you are running `agy` in your terminal, the [CLI changelog](https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md) records separate fixes, including a Windows non-TTY print-mode fix for discarded piped output. The two products share an agent harness but maintain separate versioning and separate bug tracks.

{{KnowledgeCheck}}
**Question:** After migrating from Gemini CLI to Antigravity CLI, you run `agy agents run my-workflow` in your CI pipeline. The step exits with code 0 but produces no output. What is the most likely cause?

A) Antigravity CLI is not installed  
B) `agents run` (plural) is the deprecated Gemini CLI form — the correct Antigravity CLI command is `agy agent run` (singular)  
C) You need to re-authenticate with `agy auth login`  
D) The v2.2.1 desktop app bug is blocking the CLI

**Correct answer: B.** The `agents` → `agent` plural-to-singular rename is the most common silent CI/CD failure after Gemini CLI migration. A naive find-and-replace from `gemini` to `agy` produces `agy agents run`, which may exit without error but does not execute the workflow. Always audit for `agents run` explicitly after migration.
{{/KnowledgeCheck}}

## Stable Primitives Outlast CLI Wrappers

Gemini CLI ran for under two years before Google replaced it with a closed-source binary. What transfers across CLI generations is the MCP server layer you own, the spec files that define your agent's behavior, and the evaluation gates that verify its output. Teams that built Gemini CLI workflows on MCP servers and structured prompts can finish this migration in hours. Teams that hardwired `gemini`-specific commands throughout pipelines are the ones filing incidents.

The async multi-agent model in Antigravity CLI — parallel subagent orchestration, session handoff between terminal and desktop — is worth dedicated learning, not just a sed command. Koenig AI Academy's [[course/antigravity-cli-for-developers]] course covers the MCP migration pattern in depth and the new async subagent workflow that Gemini CLI never supported.
