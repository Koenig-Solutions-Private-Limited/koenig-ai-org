---
ticket: KOEA-7889
planner: planner
date: 2026-06-12
estimated_complexity: small
estimated_token_cost: $0.28
base_branch: academy/redesign-v1
basebranch_verified: true
authorized_by_approval: 288cf48d-4925-4912-8f2d-a0df7d012b7f
---

# Plan: Unblock learnova-academy dev server by restoring Linux lightningcss install

## Goal
Restore local Next.js dev-server health for `learnovaBeast/learnova-academy` so KOEA-7791 browser QA can load the 9 target blog routes. Success is observable when `next dev -p 3010` starts without `Cannot find module '../lightningcss.linux-arm64-gnu.node'` and all 9 blog URLs return non-404 responses locally.

## Context
- Files to read first: `learnova-academy/package.json:5-17`, `learnova-academy/package.json:19-48`, `learnova-academy/pnpm-lock.yaml:1-80`, `learnova-academy/next.config.ts:7-24`, `learnova-academy/next.config.ts:77-80`, `learnova-academy/src/lib/vault.ts:136-163`, `learnova-academy/src/lib/vault.ts:287-318`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:39-85`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:490-508`.
- Relevant prior work: KOEA-7791 depends on KOEA-7248 screenshot batches already merged via PR #123, PR #124, and PR #125; KOEA-7891 authorized this plan after chain alert approval `288cf48d-4925-4912-8f2d-a0df7d012b7f`.
- Constraints: implement on a feature branch targeting `academy/redesign-v1`; do not deploy Convex from any portal except `learnova-tc`; preserve stale primary checkout state (`.claude/agent-lock`, detached HEAD, modified `learnova-academy/next-env.d.ts`, untracked `.pnpm-store/`, untracked `.qa-koea-5152/`).
- Current diagnosis: `pnpm-lock.yaml` already contains `lightningcss-linux-arm64-gnu@1.32.0`, but `learnova-academy/node_modules` currently exposes Darwin lightningcss packages only on a Linux arm64 runtime. Treat this as a corrupted/cross-platform install unless verification proves otherwise.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Use a clean feature worktree from `origin/academy/redesign-v1`, reinstall `learnova-academy` dependencies with pnpm on the current Linux arm64 host, and verify the dev server plus the 9 blocked blog routes. This directly fixes the missing native optional package without changing application behavior, and it avoids trampling the dirty detached primary checkout.

**Rejected**: Add `lightningcss-linux-arm64-gnu` as a direct dependency — the lockfile already models it as an optional native package, and direct platform dependencies are brittle. **Rejected**: Disable `experimental.optimizeCss` in `next.config.ts` — it would hide the broken install and change CSS optimization behavior. **Rejected**: Run npm over the pnpm app — `learnova-academy` is pnpm-managed and mixing package managers risks lockfile churn.

## Steps (Executor follows in order)
1. Create a clean feature worktree or branch from `origin/academy/redesign-v1`, for example `koea-7889/lightningcss-dev-server-unblock`; do not reuse the dirty detached primary checkout except as read-only context.
2. In the clean checkout, inspect `learnova-academy/package.json`, `learnova-academy/pnpm-lock.yaml`, and `learnova-academy/node_modules` for package-manager consistency; confirm the host is Linux arm64 with `node -p "process.platform + ' ' + process.arch"`.
3. From `learnova-academy/`, run `pnpm install --frozen-lockfile` to rebuild platform-specific optional dependencies; if it fails only because `node_modules` is stale/cross-platform, remove `learnova-academy/node_modules` in the clean worktree and rerun the same frozen install.
4. Confirm the native package resolves with `node -e "require('lightningcss'); console.log('lightningcss ok')"` and confirm `find node_modules -maxdepth 3 -name 'lightningcss-linux-arm64-gnu*' -print` returns the Linux package.
5. Start the app with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm dev`; capture startup output and verify it reaches the listening state on port 3010 without the lightningcss module error.
6. Smoke the 9 KOEA-7791 routes with `curl -L -o /dev/null -w "%{http_code} %{url_effective}\n"` against `/blog/<slug>` for the target slugs; require non-404 responses and no dev-server error overlay/log crash.
7. Commit only intentional repo changes, if any. Do not commit `.pnpm-store/`, `.qa-koea-5152/`, generated `.next/`, or unrelated `next-env.d.ts` churn; if the fix is environment-only with no diff, report the exact verification commands on KOEA-7889 instead of manufacturing a code change.

## Verification (QA Verifier checks these)
- [ ] `pnpm install --frozen-lockfile` completes in `learnova-academy/` on Linux arm64 and `require('lightningcss')` succeeds.
- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm dev` starts on port 3010 without `Cannot find module '../lightningcss.linux-arm64-gnu.node'`.
- [ ] The 9 routes return non-404 locally: `2026-06-02-cursor-composer-2-5-deep-dive`, `2026-06-04-claude-code-opus-4-7-production-guide`, `ai-tool-deep-dive-claude-code`, `ai-tool-deep-dive-codex-cli`, `ai-tool-deep-dive-aider`, `ai-tool-deep-dive-continue-dev`, `2026-06-02-mcp-1-0-production-patterns-2026`, `codex-cli-vs-cursor-composer-2`, `ai-coding-agents-production-2026-buyers-guide`.

## Risk
- Risk: reinstalling dependencies in the dirty primary checkout could overwrite another agent's stale artifacts or produce misleading diffs. Mitigation: do all mutable work in a clean branch/worktree based on `origin/academy/redesign-v1`, and treat the current detached checkout as read-only unless Chief Engineering explicitly clears it.

## Out of scope
- This plan does not change blog screenshot content, inline image placement, Convex configuration, production deployment, or unrelated Next.js source behavior.
