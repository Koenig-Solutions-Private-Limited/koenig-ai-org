---
task-id: KOEA-251
title: Provision browser-use + Lighthouse runner for QA Verifier
date: 2026-05-01
status: approved
author: chief-engineering
---

# Plan: KOEA-251 — QA Verifier Browser/Lighthouse Infrastructure

## Context

QA Verifier runs in a Debian 13 (trixie) ARM64 Docker container (`linuxkit` on Apple Silicon Mac). Three QA tickets ([KOEA-92](/KOEA/issues/KOEA-92), [KOEA-93](/KOEA/issues/KOEA-93), [KOEA-247](/KOEA/issues/KOEA-247)) have been blocked by the same gap: no Chromium, no lighthouse, no browser-use/Playwright.

## Environment Facts (verified 2026-05-01)

- OS: Debian GNU/Linux 13 (trixie) aarch64 (linuxkit kernel)
- Node.js v24.15.0, npm 11.12.1, Python 3.13.5
- Dockerfile base: `node:lts-trixie-slim` — Debian 13 trixie apt repos available
- No chromium, no lighthouse, no playwright installed

## Decision: Path 2 — Linux headless Chromium + Playwright + Lighthouse in Docker

Path 1 (Mac-local routing) avoided because it requires a separate adapter/routing layer and the existing stack already runs all agents inside the Docker container. Path 2 is self-contained and reproducible on VPS (Hetzner target).

Swap `browser-use` → Playwright in QA Verifier skill. `browser-use` is a Mac-first wrapper; Playwright is the correct headless-first equivalent for Linux.

## Files to Change

### 1. `Dockerfile` — production stage (add Chromium + Lighthouse + Playwright)

In the existing `npm install --global` block (line 57), append:
- `lighthouse`
- `playwright`

In the existing `apt-get install` block (line 59), append:
- `chromium`
- `fonts-liberation`
- `libnss3`
- `libasound2t64`

Add ENV block after existing ENV:
```
PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium
```

### 2. `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md` (new)

Document how QA Verifier uses Playwright in the Linux container:
- Write an inline `qa-walk.mjs` script per QA task
- Chromium launch flags: `--headless --no-sandbox --disable-dev-shm-usage`
- Template for a verification walkthrough
- How to run lighthouse: `lighthouse <url> --chrome-path /usr/bin/chromium --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" --preset=desktop --output=json --output-path=/tmp/lh.json`

### 3. `companies/learnova-academy/skills/qa-verify-task/SKILL.md` (update)

- Replace `browser-use --headless --task "..."` example with Playwright `node qa-walk.mjs` pattern
- Update lighthouse command to include `--chrome-path /usr/bin/chromium --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage"`
- Add note in escalation section about Linux environment requirements

### 4. `companies/learnova-academy/agents/qa-verifier/AGENTS.md` (update)

- Update Tools section: replace `browser-use` CLI with Playwright
- Add `qa-playwright-walkthrough` to skills list

## Verification

After image rebuild:
1. `chromium --version` returns version string
2. `lighthouse --version` returns version string
3. `node -e "const { chromium } = require('playwright'); console.log('ok')"` → "ok"
4. Run KOEA-247 QA successfully end-to-end

## PR Scope

Branch: `academy/redesign-v1`

Files changed:
- `Dockerfile` (~5 lines in production stage)
- `companies/learnova-academy/agents/qa-verifier/AGENTS.md`
- `companies/learnova-academy/skills/qa-verify-task/SKILL.md`
- `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md` (new)

Estimated risk: low. No product code changed. Dockerfile additions are additive; removing them reverts the change completely.
