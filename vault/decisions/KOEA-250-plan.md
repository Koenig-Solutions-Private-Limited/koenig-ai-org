---
ticket: KOEA-250
title: QA Chromium runtime dependencies
planner: planner
date: 2026-05-11
estimated_complexity: small
estimated_token_cost: $0.25
status: ready-for-plan-review
related: KOEA-251, KOEA-1013, KOEA-1014, KOEA-1015
---

# Plan: KOEA-250 — Install Playwright headless_shell runtime libs in QA Verifier sandbox

## Goal

Add the Linux shared libraries Playwright's bundled `headless_shell` binary needs so the QA Verifier can launch browsers for visual walkthroughs and Lighthouse audits. Smallest viable change: one additive `apt-get install` line edit in `Dockerfile` plus an image rebuild — no Convex deploy, no other-portal changes, no app-code touch.

Success criterion: after rebuild, the verification commands in §Verification all exit 0 inside the running `paperclip-server` container.

## Context

### Why this is still open after KOEA-251

KOEA-251 (merged commit `e3b30eae` on 2026-05-01) added apt `chromium fonts-liberation libnss3 libasound2t64` and globals `lighthouse playwright`, and set `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` + `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium` (Dockerfile:57-130). That fixes the **system-Chromium** path (`qa-playwright-walkthrough` skill).

But the QA Verifier *also* carries a second skill — `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md` — whose Path 1 explicitly runs `npx playwright install chromium` and launches the **Playwright-bundled `headless_shell`** from `/paperclip/.cache/ms-playwright/`. `npx playwright install` ignores `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD`, so the bundled binary is pulled in, and that binary needs more shared libs than apt-`chromium` brings in transitively. The list in KOEA-250 (from `ldd headless_shell` in the sandbox) confirms 14 libs the image is still missing.

### Files to read first

- `Dockerfile:52-64` — current production-stage apt-get block (target of the edit)
- `Dockerfile:116-131` — ENV block (`PLAYWRIGHT_*` already correct, no change)
- `infra/docker-compose.koenig.yml:42-49` — builds `koenig/paperclip-server:dev` from root Dockerfile (one image; no QA-specific image to fork)
- `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md:139-158` — escalation block already names the exact apt list
- `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md` — system-chromium variant (already works; no change)

### Constraints

- Single Docker image — no separate QA sandbox. The image rebuild affects every agent. We must not change runtime behavior for non-QA agents (chiefs, content, code reviewer). Pure apt additions satisfy that.
- No Convex deploy required. No portal-facing change.
- Branch protection: do not touch upstream Paperclip directories (`packages/`, `server/`, `ui/`, `cli/`). Only the root `Dockerfile`.

## Approach (1 chosen, alternatives rejected)

**Chosen — A: apt-install the 14 missing libs in the existing Dockerfile production-stage block.** Pure superset of the current apt line. Idempotent (apt skips already-installed packages). Satisfies both the system-chromium path *and* Playwright's bundled `headless_shell` so we don't have to pick between the two skill flavors. Mirrors the exact list in the KOEA-250 description (which came from a real `ldd` in-sandbox).

**Rejected — B: `RUN npx playwright install-deps chromium`.** Canonical per Playwright docs, but: (1) needs Playwright globally installed *first* in the same RUN layer (Dockerfile already orders `npm install -g playwright` before apt, so this is workable), (2) the list it installs drifts release-to-release, breaking image reproducibility, (3) it can pull in `ttf-mscorefonts-installer` and other recommends we don't want. Rejected for non-determinism.

**Rejected — C: delete `browser-qa.md` so only the system-chromium path remains; no Dockerfile change.** Smaller diff, but leaves the underlying shared-lib gap latent — any agent (or future ticket) running `npx playwright install` regresses. Rejected because KOEA-250 is explicitly framed as an infra fix, not a skill-cleanup.

## Steps (Executor follows in order)

1. **Create a worktree off `master`** to avoid contaminating the current `koea-862/bwrap-docker-fix` branch:
   ```
   git fetch origin
   git worktree add -b koea-250/qa-chromium-libs ../wt-koea-250 origin/master
   cd ../wt-koea-250
   ```
2. **Edit `Dockerfile` line 60** (the production-stage apt-get install). Append, in alphabetical order after `libasound2t64`, exactly these 14 packages:
   ```
   libatk1.0-0t64 libatspi2.0-0t64 libdbus-1-3 libgbm1 libglib2.0-0t64 \
   libnspr4 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 \
   libxfixes3 libxkbcommon0 libxrandr2
   ```
   Keep the line layout (one logical line with `\` continuations). Do not reorder existing packages. Do not touch the `npm install --global` portion of that same RUN.
3. **Update the inline comment on line 57** from `(KOEA-251)` to `(KOEA-251, KOEA-250)` to make the second pass discoverable in `git blame`.
4. **No other file edits.** Do not modify `browser-qa.md`, `qa-playwright-walkthrough/SKILL.md`, AGENTS.md, or any compose file — they are correct as-is.
5. **Rebuild + run** locally (does not deploy):
   ```
   docker compose -f infra/docker-compose.koenig.yml build paperclip
   docker compose -f infra/docker-compose.koenig.yml up -d paperclip
   ```
6. **Execute the Verification block below inside the container.** If all five commands pass, open the PR. If any fail, BLOCK back to Planner with the failing command + stderr; do not paper over with retries.

## Verification (QA Verifier / Reviewer checks these)

Run inside `paperclip-server` (`docker exec -it paperclip-server bash`):

- [ ] **V1 — system chromium**: `chromium --version` prints a version string (already worked pre-change; smoke confirms no regression).
- [ ] **V2 — Playwright module resolves**: `node -e "require('playwright'); console.log('ok')"` prints `ok`.
- [ ] **V3 — bundled headless_shell launches** (the actual KOEA-250 fix):
  ```
  PLAYWRIGHT_BROWSERS_PATH=/tmp/ms-pw npx --yes playwright install chromium
  node -e "const {chromium}=require('playwright'); chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage']}).then(b=>{console.log('headless_shell ok');return b.close()}).catch(e=>{console.error('FAIL:',e.message.split(String.fromCharCode(10))[0]);process.exit(1)})"
  ```
  Must print `headless_shell ok`. Prior to this change it failed with `error while loading shared libraries: libatk-1.0.so.0`.
- [ ] **V4 — system chromium via Playwright** (regression guard for KOEA-251 path):
  ```
  node -e "const {chromium}=require('playwright'); chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']}).then(b=>{console.log('sys ok');return b.close()})"
  ```
- [ ] **V5 — Lighthouse end-to-end**: with any HTTP server serving on 3010 (or substitute `https://example.com`):
  ```
  lighthouse https://example.com --chrome-path /usr/bin/chromium --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" --quiet --output=json --output-path=/tmp/lh.json && jq '.categories.performance.score' /tmp/lh.json
  ```
  Must print a numeric score.

## Risk

**Image rebuild affects every agent in the container.** The change is purely additive apt installs of small shared libraries (~15 MB total), so behavioral risk is near-zero — but the rebuild itself temporarily takes the running stack down. Mitigation: rebuild during a low-traffic window, keep the prior image tagged (`docker image tag koenig/paperclip-server:dev koenig/paperclip-server:pre-koea-250`) so we can `docker compose up` the previous image with one command if anything regresses.

Secondary risk: the t64 (time64) ABI variants are Debian 13 (trixie) specific. If the base image bumps to a non-t64 release, the names change. Mitigation: the base is pinned at `node:lts-trixie-slim` (Dockerfile:2), so this won't drift unless someone changes the base.

## Rollback

Single revert of the Dockerfile commit + image rebuild. The change is one line; no state, no migration, no data path. Total rollback time: one image rebuild (~3 min on M-series Mac).

## Worktree & lock guidance

- Create a fresh worktree off `origin/master`, **not** off `koea-862/bwrap-docker-fix` — that branch hasn't merged and we don't want to entangle the two reviews. Branch name: `koea-250/qa-chromium-libs`.
- Do not run `pnpm install` in the worktree (no `package.json` change). Avoids pnpm lock contention with other agents.
- Do not hold the Docker build lock for other agents: build with `--pull=false` to skip base-image re-fetch unless explicitly bumping.
- After PR merge, clean up: `git worktree remove ../wt-koea-250`.

## Out of scope (file as follow-ups, do not include in this PR)

- The skill duplication between `agents/qa-verifier/skills/browser-qa.md` (bundled headless_shell) and `skills/qa-playwright-walkthrough/SKILL.md` (system chromium). Both work after this fix; consolidating them to one canonical path is a separate cleanup ticket.
- Removing the now-unnecessary `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1` env (it doesn't hurt, and a follow-up may want stricter pinning).
- Lighthouse threshold tuning in the QA Verifier SOUL (still references `INP < 200ms` etc., unrelated to this infra fix).
