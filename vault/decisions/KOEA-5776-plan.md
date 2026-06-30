---
ticket: KOEA-5776
planner: planner
date: 2026-05-27
agent: planner
type: decision
tags:
  - decision
  - qa
  - browser-use
estimated_complexity: small
estimated_token_cost: $0.35
triggered_by_approval: 6857a0e3-b2ee-4dac-99e7-9747e5ae8313
base_branch: master
basebranch_verified: true
---

# Plan: Stabilize browser-use launch for KOEA-1382 QA

## Goal
Make QA Verifier use a deterministic, repeatable `browser-use` launch contract before rerunning KOEA-1382 G2. Success means Executor can update the QA runbook/agent instructions, prove `browser-use` can launch and navigate with bounded timeouts, then hand KOEA-1382 back to QA without bypassing the browser walkthrough gate.

## Context
- Files to read first: `companies/learnova-academy/agents/qa-verifier/AGENTS.md:18`, `companies/learnova-academy/skills/qa-verify-task/SKILL.md:47`, `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md:1`, `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md:128`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json:6`.
- Relevant prior work: [[KOEA-666-plan]] defines the publish/prerender checks; [[KOEA-1419-plan]] and [[koea-251-plan]] document the earlier Playwright fallback decision, but current QA instructions still make `browser-use` primary.
- Observed diagnostics from this planning heartbeat: `learnova-academy/.venv-qa/bin/browser-use doctor` passed package/browser/network checks; `browser-use --json open https://example.com` and `browser-use --json state` succeeded; direct Python `BrowserSession(...).start()` plus page acquisition/navigation hung until `timeout 30s` after CDP reconnect warnings.
- Constraints: preserve KOEA-666/KOEA-1382 G2; do not modify Learnova product code for a QA runtime issue; do not patch Paperclip core unless the new smoke proves the agent runtime cannot provide the `browser-use` binary.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a CLI-first `browser-use` launch contract to the QA runbook. The stable path is the installed `browser-use` CLI daemon with named sessions, JSON output, explicit `timeout`, `doctor`, `open`, `state`, and `close`; QA should not hand-roll direct `BrowserSession` Python snippets for G2. This belongs in `koenig-ai-org` QA agent docs/skills because the failure is in the QA invocation contract, not the Learnova app and not the Paperclip scheduler.

**Rejected**: Patch `learnovaBeast/learnova-academy` product scripts because the live/curl checks already prove the app routes and redirects work, while the launch failure happens before reliable browser navigation. Rebuild Paperclip runtime/env first because the CLI smoke succeeds in the current runtime; that would be too broad until a bounded smoke fails. Replace the mandatory walkthrough with Playwright because QA instructions and the latest Chief Engineering resolution are explicitly about stabilizing `browser-use`, not bypassing G2.

## Steps (Executor follows in order)
1. Create an isolated `koenig-ai-org` worktree from verified base `origin/master`, for example `git worktree add -b koea-5776/browser-use-launch ../wt-koea-5776 origin/master`, and leave the dirty root worktree untouched.
2. Add `companies/learnova-academy/skills/qa-browser-use-launch/SKILL.md` with the canonical smoke and cleanup commands using `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/.venv-qa/bin/browser-use`, named sessions, `--json`, and `timeout 20s`.
3. Update `companies/learnova-academy/agents/qa-verifier/AGENTS.md` to add `qa-browser-use-launch` to the skills list and replace vague "browser-use script" wording with "run the browser-use launch smoke first, then run the task walkthrough through the same CLI session contract."
4. Update `companies/learnova-academy/skills/qa-verify-task/SKILL.md` so Step 3 requires the new smoke before any frontend G2 walkthrough, forbids direct Python `BrowserSession` snippets for normal G2, and records Playwright as fallback only when the ticket plan or Chief Engineering explicitly accepts fallback evidence.
5. Reframe `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md:128` so Path 4 no longer points at a future adapter; it should point to the new CLI-first `browser-use` contract and keep Playwright/Lighthouse as separate fallback/performance tooling.
6. Verify the documentation contract and runtime with:
   `rg -n 'qa-browser-use-launch|BrowserSession|browser-use script' companies/learnova-academy/agents/qa-verifier companies/learnova-academy/skills/qa-verify-task/SKILL.md companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md`,
   `timeout 20s /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/.venv-qa/bin/browser-use --json --session koea-5776-smoke open https://example.com`,
   `timeout 20s /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/.venv-qa/bin/browser-use --json --session koea-5776-smoke state`,
   then repeat `open` + `state` for `https://academy.kspl.tech/blog/2026-04-30-claude-design-visual-workflows`.
7. Hand KOEA-1382 back to QA with the smoke output. If either smoke command times out or returns `success:false`, block as a first-class Paperclip runtime/env issue owned by Chief Engineering; otherwise QA reruns the original KOEA-1382 G2 checks, including publish-verifier L0 and Lighthouse blockers.

## Verification (QA Verifier checks these)
- [ ] `browser-use --json --session koea-5776-smoke open https://example.com` exits 0 within 20s and the following `state` output contains `Example Domain`.
- [ ] The same named session can navigate to `https://academy.kspl.tech/blog/2026-04-30-claude-design-visual-workflows` and `state` returns page text/title instead of `BrowserStartEvent` / `BrowserLaunchEvent` timeout.
- [ ] KOEA-1382 G2 rerun uses this contract and still reports any remaining publish-verifier L0 or Lighthouse blockers separately; it does not call the browser gate passed via static curl evidence alone.

## Risk
- The CLI daemon may mask an underlying CDP lifecycle bug that still appears in longer walkthroughs. Mitigation: the runbook must use bounded timeouts, named-session cleanup, and explicit BLOCK language that routes repeated launch timeouts to Chief Engineering instead of silently falling back.

## Out of scope
- Fixing the KOEA-1382 LCP >2.5s performance miss, fixing the publish-verifier L0 frontmatter RED artifact, changing Learnova app redirects, or changing Paperclip core runtime orchestration.

Pre-flight: status_ok=true; assigned_to_planner=true; acceptance_criteria_count=3; chain_depth_authorized_by=6857a0e3-b2ee-4dac-99e7-9747e5ae8313; basebranch_verified=true.
