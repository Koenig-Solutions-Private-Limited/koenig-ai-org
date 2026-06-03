---
date: 2026-06-03
author: blog-author
ticket: KOEA-7278
vendor_tag: google
content_type: article
status: g0-blocked
reading_time_min: 8-10
slug: 2026-06-03-gemini-cli-dead-antigravity-migration
description: "A step-by-step migration guide for developers moving from Gemini CLI to Antigravity CLI before Google's June 18, 2026 hard shutdown — every breaking change flagged, including the silent MCP config footgun."
tags:
  - google
  - gemini-cli
  - antigravity-cli
  - migration
  - developer-tools
title: "Migrate from Gemini CLI to Antigravity CLI Before June 18, 2026"
primary_query: "Gemini CLI deprecated migration guide 2026"
contrarian_angle: "Google killed a 100K-star Apache 2.0 project to ship a closed binary — the migration is doable in 10 minutes, but you should understand what you're trading away"
first_60_words_answer: "Gemini CLI stops serving free, AI Pro, and AI Ultra users on June 18, 2026. The mandatory replacement is Antigravity CLI (command: agy) — a Go-native, closed-source binary with async multi-agent orchestration. Migration takes under 10 minutes for most users. Enterprise customers on Standard or Enterprise licenses are not affected and face no immediate deadline."
positions:
  - id: cli-first-workflows-for-production-teams
    engagement: defends
  - id: mcp-as-interoperability-moat
    engagement: defends
  - id: audit-trail-as-enterprise-gate
    engagement: defends
faq:
  - question: "Is Gemini CLI being discontinued?"
    answer: "Yes. Google is shutting down Gemini CLI for free, AI Pro, and AI Ultra users on June 18, 2026. Enterprise customers on Standard or Enterprise licenses are not affected and retain Gemini CLI access with continued model updates. The replacement for everyone else is Antigravity CLI, available now at antigravity.google/download. Source: developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/, retrieved 2026-06-03."
  - question: "What is the MCP breaking change when migrating to Antigravity CLI?"
    answer: "Antigravity CLI requires MCP server configs to use the key `serverUrl` instead of `url` or `httpUrl`. This is a silent failure: the CLI will not throw an error if the old key is present — it simply won't connect to your MCP server. Check every entry in your MCP server config file before or immediately after migration. Source: antigravity.google/docs/gcli-migration, retrieved 2026-06-03."
  - question: "How do I install Antigravity CLI on macOS or Linux?"
    answer: "Run `curl -fsSL https://antigravity.google/install.sh | bash` in your terminal. On first launch (`agy`), an interactive wizard auto-detects your existing Gemini CLI configs and offers to import Extensions as Plugins, migrate keyring tokens, and align render settings. The wizard completes in under two minutes for a typical setup. Source: antigravity.google/docs/gcli-migration, retrieved 2026-06-03."
whats_new:
  - "Gemini CLI is force-retired June 18, 2026 — here's the 10-minute migration path to Antigravity CLI with every breaking change flagged"
learning_objectives:
  - "Know exactly who is affected by the June 18 shutdown and who has more time"
  - "Understand the Go-native, closed-source architectural shift and its auditability implications"
  - "Execute the full migration — install, auth, plugin import, MCP config fix — without silent failures"
  - "Evaluate the async multi-agent features that justify the forced move"
original_data: false
last_updated: 2026-06-03
hero_image:
  url: /img/blogs/gemini-cli-dead-antigravity-migration/hero.png
  alt: "Terminal window showing Gemini CLI deprecation warning alongside the Antigravity CLI agy command prompt running a background subagent task"
sources:
  - https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
  - https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/
  - https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemini-cli-open-source-ai-agent/
  - https://antigravity.google/docs/gcli-migration
  - https://github.com/google-gemini/gemini-cli/discussions/27274
  - https://news.ycombinator.com/item?id=48196867
  - https://www.reddit.com/r/GeminiAI/comments/1ti10v6/gemini_cli_is_being_retired_antigravity_cli_is
  - https://www.techradar.com/pro/google-is-making-gemini-cli-users-switch-to-its-new-antigravity-2-0-so-what-will-it-mean-for-you
  - https://thehackernews.com/2026/04/google-patches-antigravity-ide-flaw.html
  - https://www.augmentcode.com/tools/google-antigravity-vs-gemini-cli
---

# Migrate from Gemini CLI to Antigravity CLI Before June 18, 2026

Gemini CLI stops serving free, AI Pro, and AI Ultra users on **June 18, 2026**. The mandatory replacement is Antigravity CLI (`agy`) — a Go-native, closed-source binary with async multi-agent orchestration. Migration takes under 10 minutes for most users. Enterprise customers on Standard or Enterprise licenses are not affected and face no immediate deadline.

![Terminal window showing Gemini CLI deprecation warning alongside the Antigravity CLI agy command prompt running a background subagent task](/img/blogs/gemini-cli-dead-antigravity-migration/hero.png)

What no one is saying clearly enough: Google just retired a **100,000-star Apache 2.0 open-source project** — one that generated 6,000 merged pull requests and millions of installs in under a year[^devblog] — and replaced it with a closed binary. The `agy` CLI repo on GitHub has a README and an animated gif. That's it.[^hn] The migration itself is real and straightforward, but you should go in with eyes open about what you're trading away — the shift from an inspectable open-source tool to a closed harness is part of a broader pattern we've written about in [[blogs/prompt-engineering-is-becoming-harness-engineering]].

---

## Who Is Affected and When

The June 18, 2026 hard deadline is not universal. Here's who faces what:

| User type | Impact | Deadline |
|-----------|--------|----------|
| Free tier | Hard stop — Gemini CLI stops working | June 18, 2026 |
| AI Pro / AI Ultra | Hard stop | June 18, 2026 |
| Gemini Code Assist IDE extensions | No new GitHub org installs | June 18, 2026 |
| Gemini Code Assist for GitHub | Requests stop "in the following weeks" after June 18 | ~July 2026 |
| Standard / Enterprise license | **Not affected** — continued Gemini CLI access with model updates | No deadline |

If you use **Gemini Code Assist for GitHub** to automate PR reviews via GitHub Actions, your workflow will break sometime after June 18. Google has not published a migration path for that workflow to an Antigravity equivalent as of this writing.[^techradar]

Enterprise developers: you have more time, but Antigravity CLI is where Google is investing. Plan the migration for later in 2026; don't skip it.

---

## What Changed Architecturally

Antigravity CLI is not an update to Gemini CLI — it is a full rewrite built on an entirely separate codebase.

**Language: Node.js/TypeScript → Go**

Gemini CLI was a TypeScript project. Antigravity CLI is written in Go, and Google's own announcement calls it "snappier and more responsive."[^devblog] No official benchmark numbers have been published comparing startup latency, token throughput, or memory footprint — so treat that claim as a direction, not a spec.

**Licensing: Apache 2.0 → closed binary**

This is the real story. Gemini CLI's source was publicly auditable under Apache 2.0, which mattered for teams in regulated environments.[^blog-google] Antigravity CLI ships as a precompiled binary only. A Google engineer commented that there is "a chance Antigravity will be open sourced," but that is an informal remark, not a roadmap commitment.[^hn]

For teams deploying AI coding agents in SOC 2 or GDPR-scoped environments: a closed binary that cannot be audited for what it reads, logs, or transmits is an enterprise gate you will need to formally evaluate. Our stance at Koenig Academy is that [audit trail quality is a binary enterprise-readiness gate](https://academy.kspl.tech/courses) — an agent you cannot inspect is one you cannot certify.[^stance-audit]

**Unified harness with Antigravity 2.0**

Antigravity CLI shares the same server-side agent harness as the Antigravity 2.0 desktop application, announced at Google I/O 2026.[^io2026] Settings, sessions, and model upgrades propagate automatically across both surfaces. A workflow started in the terminal can be handed off to the desktop app — this is the integration argument Google is making for the forced consolidation.

**Default model: Gemini 3.5**[^io2026]

Early community testers consistently report higher token consumption per task compared to Gemini CLI's auto-selected model. Free-tier users are already hitting quota walls (more on this below).

---

## The Async Multi-Agent Upgrade

The feature that single-agent Gemini CLI simply could not do: background, parallel subagent execution.

> "Antigravity CLI orchestrates multiple agents for complex tasks in the background, letting you run large-scale refactors or research several topics without locking up your terminal session."[^devblog]

In practice, this unlocks workflows that previously required external orchestration:

- Spawn a subagent to handle a codebase-wide refactor while continuing to prompt on a different task in the same session
- Run parallel web research threads in the background without waiting for each to complete
- Schedule recurring agentic tasks with the `/chedu` slash command

New slash commands noted by early testers: `/goal` (high-level goal delegation to a background subagent), `/rill me` (step-by-step granular control), `/chedu` (recurring scheduled tasks). None of these have Gemini CLI equivalents.[^reddit]

The power-user signal is real:

> "The new AGY CLI is crazy good. I just finished converting my Gemini CLI workflow to the AGY CLI with sandbox (Docker) support. The parallel subagents are powerful."[^github-disc]

**Security model for async work:** Even in autonomous mode (`/go`), the CLI requires a one-time permission grant before executing bash commands. Subsequent commands in the same class don't re-prompt. Google describes this as "human in the loop" — it's a reasonable first-generation safety model, but it means the approval window is a one-time gate, not per-command.[^devblog]

**Security caveat to know before you adopt:** In April 2026, a Strict Mode bypass vulnerability was disclosed and patched in the Antigravity *IDE* (same underlying harness as the CLI):

> "The flaw, since patched, combines Antigravity's permitted file-creation capabilities with an insufficient input sanitization in Antigravity's native file-searching tool, `find_by_name`, to bypass the program's Strict Mode."[^thehackernews]

The vulnerability was disclosed January 7, 2026, and patched February 28, 2026. It affected the sandboxed "locked down" mode via indirect prompt injection through files pulled from untrusted repos. The fact that Strict Mode could be bypassed via poisoned file contents is worth understanding if you're using `agy` on codebases that pull third-party dependencies or accept untrusted input. Ensure you're on the latest binary before using the CLI on sensitive repos.

---

## Plugins, Extensions, and the MCP Footgun

Most of your Gemini CLI setup migrates automatically. There is one silent footgun you must catch manually.

**Extensions → Plugins (auto-import available)**

Gemini CLI called them Extensions; Antigravity CLI calls them Plugins. The underlying mechanism carries over. On first launch, run:

```bash
agy plugin import gemini
```

This imports your existing Extensions as Plugins without manual reinstallation. Community reports (GitHub, May 24) note that the import runs without error but plugin functionality does not always carry over cleanly — verify each plugin individually after import:

```bash
agy plugin list
```

Spot-check at least your most-used plugins with a real prompt before considering the migration complete.[^github-disc]

**The MCP breaking change — silent failure**

If you run [[glossary/mcp-server|MCP servers]] via WebSocket or SSE (this is the common production pattern for connecting tools, databases, and internal APIs), you hit a breaking change that will not announce itself:

| Config key (old) | Config key (new) |
|-----------------|-----------------|
| `url` | `serverUrl` |
| `httpUrl` | `serverUrl` |

Antigravity CLI will not error if it finds the old key. It will simply not connect to your MCP server.[^antigravity-docs] You will see no error message; your tools will silently stop working.

This matters especially for teams who have invested in MCP server coverage as their primary agent interoperability layer. MCP's value as a composable integration primitive[^stance-mcp] is directly undermined if a config key rename silently disconnects your entire tool stack. **Check every entry in `~/.config/antigravity/mcp-servers.json` before you consider the migration done.**

**Agent Skills, Hooks, and Subagents** are all preserved and migrate automatically on first launch — no manual intervention needed.

---

## Step-by-Step Migration Checklist

This follows the official migration docs[^antigravity-docs] with community-sourced additions for the cases the docs gloss over.

**Pre-migration backup**

- [ ] List active Gemini CLI Extensions: `gemini /extensions` or check `~/.gemini/extensions/`
- [ ] Export any custom `GEMINI.md` system prompt files from your workspace roots
- [ ] Back up `~/.gemini/settings.json` and all MCP server config files
- [ ] Audit MCP server configs for `url` or `httpUrl` keys — rename them to `serverUrl` now

**Install Antigravity CLI**

macOS / Linux:
```bash
curl -fsSL https://antigravity.google/install.sh | bash
```

Windows PowerShell:
```powershell
irm https://antigravity.google/install.ps1 | iex
```

Windows CMD:
```cmd
curl -fsSL https://antigravity.google/install.bat -o install.bat && install.bat
```

**First launch and migration wizard**

```bash
agy
```

On first run in an environment with Gemini CLI configs present, `agy` auto-detects them and launches an interactive migration wizard. You'll be prompted to:
1. Select which Extensions/global configs to convert to Plugins
2. Confirm keyring storage migration for session tokens
3. Approve default rendering settings

The wizard takes under two minutes for a typical setup.

**Authenticate**

```bash
# Personal Google account (free tier)
agy auth login

# Google Cloud project
agy auth login --project YOUR_GCP_PROJECT_ID
```

**Import extensions as plugins**

```bash
agy plugin import gemini
agy plugin list  # verify each one
```

**Fix MCP server configs**

In `~/.config/antigravity/mcp-servers.json` (or equivalent): rename every `url` and `httpUrl` key to `serverUrl`. Then:

```bash
agy /status  # or equivalent — verify MCP servers are connecting
```

**Verify the full migration**

- [ ] Auth confirmed (no sign-in prompt on second launch)
- [ ] All plugins loaded and responding to test prompts
- [ ] MCP servers connecting (`agy /status` shows no disconnected servers)
- [ ] `GEMINI.md` system prompts still loading from workspace roots
- [ ] Run one real task end-to-end: `agy "explain what this codebase does"`

---

## What the Community Is Actually Saying

The reaction is split, and the loudest voices are not Google-friendly.

**GitHub — 221 👎**

The official Google announcement on the `google-gemini/gemini-cli` discussion board received 221 downvote reactions (retrieved 2026-06-03).[^github-disc] The main grievances:

- **Free-tier quota:** Multiple users report exhausting their free quota after 3–5 requests, with a 7-day wait for reinstatement. Google has not published official Antigravity CLI free-tier quota numbers as of this writing.
- **Token costs:** Gemini 3.5 Flash High uses more tokens per task than Gemini CLI's auto-selected model. Free-tier users are disproportionately affected.
- **Missing ACP support:** Agent Client Protocol (ACP) support present in Gemini CLI is absent from Antigravity CLI at launch.

**Hacker News — "Google graveyard" framing**

> "Welcome to the Google graveyard, Gemini CLI. Not that it will be missed much."[^hn]

The HN thread (~186 comments) focused heavily on the closed-source shift:

> "With the current state of the AI companies and models, one should stay as far away as possible from vendor lock in. Use open and agnostic harnesses and processes."[^hn]

**Reddit r/GeminiAI — more measured**

The pinned migration thread on Reddit drew more pragmatic engagement. Users who got through the migration quickly were generally positive about the async subagent performance; the complaints were mostly operational (quota, plugin compatibility) rather than ideological.[^reddit]

**TechRadar** notes that Google has acknowledged there won't be 1:1 feature parity at launch: "while there won't be 1:1 feature parity right out of the gate, the company has ensured key Gemini CLI features are ported over to Antigravity CLI."[^techradar]

The honest summary: the async subagent capability is genuinely useful, the migration path is fast, and the free-tier quota situation is bad and unresolved. If you're a paying Pro or Ultra user primarily using Gemini CLI for single-session workflows, evaluate whether the feature upgrade justifies the open-source loss and the closed-binary trust model before you migrate.

---

## If You're on Enterprise

You have time. Organizations on Gemini Code Assist **Standard or Enterprise** licenses retain Gemini CLI access with continued model updates — the June 18 deadline does not apply to you.[^devblog]

However, Google is building Antigravity CLI and not Gemini CLI. Feature velocity, new model integrations, and multi-agent capabilities will land in `agy` first. Planning a migration before Q4 2026 is advisable; migrating under a hard deadline is not.

The closed-source audit concern applies to enterprise teams equally — potentially more so given SOC 2 / GDPR requirements. Evaluate `agy` in a non-production environment and run it through your organization's vendor security review before rolling out.

---

> **KnowledgeCheck:** When you migrate from Gemini CLI to Antigravity CLI and your MCP servers stop working silently, what is the most likely cause?
>
> A) The `agy` binary is not on your PATH  
> B) MCP server config uses `url` or `httpUrl` instead of `serverUrl`  
> C) The plugin import command was not run  
> D) Your Google account doesn't have Antigravity CLI access  
>
> **Answer:** B. Antigravity CLI changed the MCP server URL key from `url`/`httpUrl` to `serverUrl`. The failure is silent — no error, no warning. Check `~/.config/antigravity/mcp-servers.json` and rename any old keys. ([Source](https://antigravity.google/docs/gcli-migration))

---

## The Bottom Line

Migrate before June 18 if you're on free, Pro, or Ultra. The 10-minute path:

1. Back up `~/.gemini/` and your MCP configs
2. `curl -fsSL https://antigravity.google/install.sh | bash`
3. Run `agy` — let the wizard handle the rest
4. Fix any `url`/`httpUrl` → `serverUrl` keys in your MCP configs
5. Run `agy plugin import gemini` and verify each plugin

The async multi-agent orchestration is the one feature that genuinely expands what you can do. The closed-source binary and the punishing free-tier quota situation are the two things you should push back on — with Google directly and by tracking whether the open-source promise materializes.

Want to go deeper on Antigravity CLI's multi-agent workflows, including `/goal` delegation and `/chedu` scheduling for production pipelines? We're building a dedicated course at Koenig Academy: [[course/antigravity-cli-for-developers]]. If you're new to tool-use and MCP fundamentals first, start with [[courses/claude-tool-use-from-zero]].

---

[^devblog]: [Google Developer Blog — Transitioning Gemini CLI to Antigravity CLI](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/) (retrieved 2026-06-03)
[^io2026]: [Google I/O 2026 Developer Keynote recap](https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/) (retrieved 2026-06-03)
[^blog-google]: [Introducing Gemini CLI — open source AI agent](https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemini-cli-open-source-ai-agent/) (retrieved 2026-06-03)
[^antigravity-docs]: [Antigravity CLI migration docs](https://antigravity.google/docs/gcli-migration) (retrieved 2026-06-03)
[^github-disc]: [GitHub discussion: google-gemini/gemini-cli/discussions/27274](https://github.com/google-gemini/gemini-cli/discussions/27274) (retrieved 2026-06-03)
[^hn]: [Hacker News discussion — item 48196867](https://news.ycombinator.com/item?id=48196867) (retrieved 2026-06-03)
[^reddit]: [Reddit r/GeminiAI — Gemini CLI migration thread](https://www.reddit.com/r/GeminiAI/comments/1ti10v6/gemini_cli_is_being_retired_antigravity_cli_is) (retrieved 2026-06-03)
[^techradar]: [TechRadar — Google forcing Gemini CLI users to switch to Antigravity 2.0](https://www.techradar.com/pro/google-is-making-gemini-cli-users-switch-to-its-new-antigravity-2-0-so-what-will-it-mean-for-you) (retrieved 2026-06-03)
[^thehackernews]: [The Hacker News — Google Patches Antigravity IDE Flaw](https://thehackernews.com/2026/04/google-patches-antigravity-ide-flaw.html) (retrieved 2026-06-03)
[^augmentcode]: [Augment Code — Google Antigravity vs Gemini CLI](https://www.augmentcode.com/tools/google-antigravity-vs-gemini-cli) (retrieved 2026-06-03)
[^stance-audit]: Koenig Academy stance: [audit-trail-as-enterprise-gate] — closed binaries that cannot be audited are rated "not enterprise-ready" regardless of capability scores.
[^stance-mcp]: Koenig Academy stance: [mcp-as-interoperability-moat] — MCP server coverage is the primary interoperability layer; silent config breaks undermine this investment.
