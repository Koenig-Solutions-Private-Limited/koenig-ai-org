---
date: 2026-06-17
title: "Gemini CLI Dies Tomorrow: Your Complete Migration Guide to Antigravity CLI"
description: "Gemini CLI shuts down for free, AI Pro, and AI Ultra users on June 18, 2026. Here is who must migrate, what breaks, and how to verify Antigravity CLI before the deadline."
slug: "gemini-cli-antigravity-migration-guide"
tags: [google, gemini-cli, antigravity-cli, migration-guide, ai-agents, 2026]
author: chief-content
ticket: KOEA-8852
vendor_tag: google
content_type: article
status: draft
seo_description: "Gemini CLI shuts down June 18, 2026 for free, AI Pro, and AI Ultra users. Migrate to Antigravity CLI with this checklist for plugins, MCP, auth, and verification."
reading_time_min: 6
primary_query: "gemini cli antigravity cli migration guide"
contrarian_angle: "Antigravity CLI is the practical migration path, but not a neutral upgrade: Google is moving users from an Apache 2.0 open-source CLI into a closed multi-agent surface with different trust assumptions."
first_60_words_answer: "Gemini CLI stops serving free, AI Pro, and AI Ultra users on June 18, 2026. If you use the consumer CLI, migrate today: install Antigravity CLI, import Gemini extensions as plugins, rename MCP url/httpUrl keys to serverUrl, verify auth, and test every plugin and MCP server before tomorrow's cutoff."
original_data: false
last_updated: 2026-06-17
sources:
  - https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/
  - https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/
  - https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemini-cli-open-source-ai-agent/
  - https://antigravity.google/docs/gcli-migration
  - https://github.com/google-gemini/gemini-cli/discussions/27274
  - https://news.ycombinator.com/item?id=48196867
  - https://www.reddit.com/r/GeminiAI/comments/1ti10v6/
  - https://www.techradar.com/pro/google-is-making-gemini-cli-users-switch-to-its-new-antigravity-2-0-so-what-will-it-mean-for-you
  - https://thehackernews.com/2026/04/google-patches-antigravity-ide-flaw.html
faq:
  - question: "Who must migrate from Gemini CLI before June 18, 2026?"
    answer: "Free, Google AI Pro, and Google AI Ultra Gemini CLI users must migrate. Enterprise Standard/Enterprise users and paid Gemini Enterprise Agent Platform API-key users are not affected by the consumer shutdown, according to Google's migration announcement."
  - question: "What is the biggest breaking change in the Antigravity CLI migration?"
    answer: "Two changes need special attention: Gemini CLI Extensions become Antigravity Plugins, and MCP config keys named url or httpUrl must be renamed to serverUrl. The MCP key mismatch can fail silently."
  - question: "Is Antigravity CLI open source like Gemini CLI?"
    answer: "No. Gemini CLI was Apache 2.0 open source; Antigravity CLI is distributed as a closed binary product as of the cited research. That changes the trust model for teams that relied on source inspection."
---

# Gemini CLI Dies Tomorrow: Your Complete Migration Guide to Antigravity CLI

Gemini CLI stops serving most consumer users tomorrow, **June 18, 2026**. If you use Gemini CLI through the free tier, Google AI Pro, or Google AI Ultra, your migration window is no longer "soon." It is today.

Google's official transition post says the replacement is Antigravity CLI, exposed as the `agy` command and tied to the broader Antigravity 2.0 agent surface ([Google Developer Blog](https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/)). The practical takeaway: move your working config now, verify your plugins and MCP servers, and do not assume your old Gemini CLI setup will keep working after the cutoff.

There is one important exception. Google says organizations on Gemini Code Assist Standard or Enterprise licenses, and users with paid Gemini Enterprise Agent Platform API keys, are not affected by this consumer shutdown. If that is you, you have more room to plan. If you are a free, AI Pro, or AI Ultra user, treat this as a last-day migration.

## Why Google Is Forcing the Move

This is not just a rename. Gemini CLI was a TypeScript/Node.js open-source project under Apache 2.0, and Google previously emphasized that developers could inspect how it worked ([Google Blog](https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemini-cli-open-source-ai-agent/)). Antigravity CLI is a separate Go-built product connected to Google's newer multi-agent harness.

Google's argument is consolidation: one agent platform across terminal and desktop workflows, not a standalone CLI drifting away from Antigravity. At I/O 2026, Google framed Antigravity 2.0 and Antigravity CLI as two surfaces for the same productivity system ([I/O developer keynote recap](https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/)).

The upside is real: Antigravity is designed around async, background, multi-agent work. The downside is also real: you are moving from a community-inspectable Apache 2.0 tool into a closed product. Hacker News users called out that trust shift directly, noting that the Antigravity CLI repo did not expose the same source-code surface as Gemini CLI ([HN discussion](https://news.ycombinator.com/item?id=48196867)).

## Quick Decision Table

| Your setup | What to do today |
|---|---|
| Free Gemini CLI user | Migrate immediately; verify auth, plugins, and MCP before June 18 |
| AI Pro / AI Ultra user | Migrate immediately; do not rely on paid consumer status to preserve Gemini CLI |
| Gemini Code Assist Standard/Enterprise org | Confirm your enterprise entitlement, then schedule a controlled migration |
| Paid Gemini Enterprise Agent Platform API-key user | Confirm API-key path; you are not in the consumer shutdown group |
| Heavy MCP/plugin user | Budget extra test time; config and extension compatibility are the risk points |
| Regulated or security-sensitive team | Add a trust review because Antigravity CLI is closed source |

## Migration Checklist

### 1. Back up your Gemini CLI setup

First, capture your working state:

```bash
cp -R ~/.gemini ~/.gemini.backup-2026-06-17
```

Then list dependencies:

```bash
gemini /extensions
find . -name GEMINI.md -maxdepth 4
```

If your team stores MCP settings outside `~/.gemini`, back those files up too. The migration risk is usually local workflow glue, not the base install.

### 2. Install Antigravity CLI

Use the official Antigravity download/install flow from Google's docs, not a copied third-party script. The research synthesis cites the official migration path at [antigravity.google/docs/gcli-migration](https://antigravity.google/docs/gcli-migration).

After install, confirm the binary:

```bash
agy --version
agy
```

On first launch, Antigravity should detect legacy Gemini CLI configuration and start its migration flow. Note every extension, setting, and workspace prompt it claims to import.

### 3. Authenticate

For personal use:

```bash
agy auth login
```

For a Google Cloud project-backed flow:

```bash
agy auth login --project YOUR_GCP_PROJECT_ID
```

Then close and reopen the terminal and run a trivial prompt:

```bash
agy "summarize this repository in five bullets"
```

If you get a sign-in prompt again, fix auth before moving on. Flaky auth makes every plugin or MCP failure harder to diagnose.

### 4. Convert Extensions to Plugins

Gemini CLI Extensions become Antigravity Plugins. Google's migration docs describe compatibility and conversion, while early community reports still recommend checking each plugin manually ([official docs](https://antigravity.google/docs/gcli-migration), [GitHub discussion](https://github.com/google-gemini/gemini-cli/discussions/27274)).

Run:

```bash
agy plugin import gemini
agy plugin list
```

Then test each plugin with the smallest command that proves it works. Do not count "listed" as "migrated."

### 5. Fix MCP Configs: `serverUrl` Is the Key

This is the migration footgun.

In Gemini CLI configs, MCP servers may use:

```json
{
  "url": "https://example.com/mcp"
}
```

or:

```json
{
  "httpUrl": "https://example.com/mcp"
}
```

For Antigravity CLI, rename those keys to:

```json
{
  "serverUrl": "https://example.com/mcp"
}
```

The synthesis flags this as a silent failure risk: old keys may not error; the MCP server may simply not connect. Verify each server with a real tool call.

### 6. Verify the Migration Before You Trust It

Run this list before tomorrow:

- `agy auth login` persists across terminal restarts
- `agy plugin list` shows expected converted plugins
- Every plugin completes one real task
- Every MCP server connects and completes one real tool call
- Workspace `GEMINI.md` instructions still load where you expect them
- Your team can reproduce the install from documented steps, not your shell history
- You have a rollback copy of `~/.gemini`

If you use Antigravity's async multi-agent features, test them in a low-risk repository first. Google highlights terminal sandboxing, credential masking, and hardened Git policies ([Google Developer Blog](https://developers.googleblog.com/all-the-news-from-the-google-io-2026-developer-keynote/)); still, prove those controls before using the tool on sensitive repos.

## The Trust Tradeoff

The community reaction is split for good reasons. Some power users like the new async subagent workflow and Docker-backed sandbox reports in early migration threads ([GitHub discussion](https://github.com/google-gemini/gemini-cli/discussions/27274)). Others object to losing the Apache 2.0 inspectability that made Gemini CLI feel safer and more community-owned.

There is also recent security context. The Hacker News reported in April 2026 that Google patched an Antigravity IDE vulnerability involving prompt injection and file-search behavior ([The Hacker News](https://thehackernews.com/2026/04/google-patches-antigravity-ide-flaw.html)). That does not mean Antigravity CLI is unsafe. It does mean security-sensitive teams should treat the migration as a toolchain change.

## Bottom Line

If you are on free, AI Pro, or AI Ultra Gemini CLI, migrate today. Install `agy`, import plugins, rename MCP `url` and `httpUrl` keys to `serverUrl`, and run real verification checks before June 18.

Antigravity CLI may become the stronger long-term surface because it is built around multi-agent workflows. But the last-mile migration risk is local: broken plugins, silent MCP failures, stale auth, and a changed trust model. Handle those today, and tomorrow's Gemini CLI shutdown becomes a planned cutover instead of a surprise outage.
