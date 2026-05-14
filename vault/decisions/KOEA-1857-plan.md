---
ticket: KOEA-1857
planner: planner
date: 2026-05-13
estimated_complexity: medium
estimated_token_cost: $0.34
base_branch: master
basebranch_verified: true
---

# Plan: restore publish-action scheduler and authenticated Paperclip API access

## Goal
Restore the publish-action loop so it emits regular health markers, uses authenticated Paperclip API calls in authenticated mode, targets the correct Koenig company, and can create watchdog issues when the Phase 0 guard blocks unsafe publish flips. Success is observable from safe local checks plus scheduler/log inspection, without manually running a live publish path that can push `koenig-ai-org` or dispatch production publishes.

## Context
- Files to read first: `scripts/publish-action.sh:15-24`, `scripts/publish-action.sh:70-112`, `scripts/publish-action.sh:155-243`, `scripts/publish-action.sh:314-327`, `scripts/publish-action.sh:396-468`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `infra/launchd/com.koenig.cron-driver.plist:12-43`, `scripts/koenig-cron-driver.py:1-26`, `scripts/koenig-cron-driver.py:232-247`, `scripts/tests/publish-action-guard-logging.sh:1-81`
- Relevant prior work: `vault/decisions/KOEA-1137-plan.md` identified the original missing publish-action auth/company-id gap; `vault/decisions/KOEA-1615-plan.md` hardened Phase 0 guard logging but left the current `.env.koenig` token class and scheduler ownership unresolved.
- Constraints: Plan mode only for KOEA-1865. Do not read or print secret values from `.env.koenig`. Do not run `scripts/publish-action.sh` in live mode, do not run `git push`, do not run `launchctl kickstart` on `com.koenig.publish-action`, and do not trigger repository_dispatch manually from this ticket. `origin/master` is the verified base branch for this repo; `origin/main` is absent.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep the existing bash publish-action and launchd/cron-driver architecture, but add one explicit Paperclip API configuration/auth layer and one safe dry-run verification path before touching scheduler state. This is the smallest fix that addresses the observed failures: wrong default `COMPANY_ID`, unauthenticated Phase 1/2 reads and writes, watchdog issue creation using an agent-scoped token where board access is required, and launchd cron-driver failing with macOS `Operation not permitted`.

**Rejected**: Rewrite publish-action as a Paperclip routine because that changes ownership and scheduling semantics while production is already broken; patch only `.env.koenig` because the repo script would still default to the wrong company and unauthenticated calls; ignore launchd and rely on Docker because the sampled logs still show a loaded launchd cron-driver failing repeatedly and the workspace cannot assume host state without inspection.

## Steps (Executor follows in order)
1. Inspect live scheduler ownership read-only: run `launchctl print gui/$(id -u)/com.koenig.publish-action`, `launchctl print gui/$(id -u)/com.koenig.cron-driver`, `launchctl list | rg 'koenig.(publish-action|cron-driver)'`, and any existing Docker compose status command already used in this repo; capture whether launchd, Docker, or both own cadence before changing files.
2. In `scripts/publish-action.sh`, replace the top-level Paperclip config with a required normalization block after `.env.koenig` is sourced: prefer `PAPERCLIP_API_URL` then `PAPERCLIP_URL`, prefer `PAPERCLIP_COMPANY_ID` then `COMPANY_ID`, require the canonical company id `2a77f89b-33f0-4133-a20c-77ddaac5e744`, and select `PAPERCLIP_BOARD_TOKEN` for all Paperclip list/create/PATCH/invoke calls. If no board token exists, log a loud skip marker and exit before Phase 0 can commit or push.
3. Still in `scripts/publish-action.sh`, route every Paperclip `curl` through a small helper that always adds `Authorization: Bearer <board-token>`, captures HTTP status and a sanitized response summary on failure, and redacts token-like fields. Apply it to Phase 0 issue listing, guard watchdog issue creation, Phase 1 g4-approved listing, Phase 1 dispatching PATCH, Phase 2 dispatching listing, publish-verifier agent lookup, publish-state PATCHes, and publish-verifier heartbeat invoke.
4. Add a `PUBLISH_ACTION_DRY_RUN=1` mode in `scripts/publish-action.sh` for verification: it may read Paperclip and GitHub metadata, but it must skip `git commit`, `git push`, GitHub repository_dispatch, Paperclip PATCH/POST issue mutations, and publish-verifier invokes while logging what it would have done. Keep normal production behavior unchanged when the flag is unset.
5. Extend `scripts/tests/publish-action-guard-logging.sh` or add one adjacent shell fixture to stub Paperclip responses and prove: missing board token exits before commit/push, `PAPERCLIP_COMPANY_ID` is used, Phase 0 watchdog creation and Phase 1/2 mutations include auth, failure logs include endpoint/status/sanitized reason, and no token value appears in logs.
6. Restore one scheduler owner based on Step 1: if launchd remains canonical, fix `infra/launchd/com.koenig.cron-driver.plist` so it runs from a macOS-accessible runtime path or interpreter path that avoids the current `Operation not permitted`; if Docker is canonical, remove or disable the stale launchd cron-driver from the loader path and document Docker as the owner in the plan handoff comment. Do not change publish-action cadence below the existing 60s until the auth fix is verified.
7. After code review only, reload the selected scheduler owner and verify cadence passively by tailing logs for new non-secret health lines. For publish-action itself, use `PUBLISH_ACTION_DRY_RUN=1 bash scripts/publish-action.sh` or wait for a scheduled dry-run/authorized tick; do not manually execute a live push-capable publish action.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh` and `python3 -m py_compile scripts/koenig-cron-driver.py` pass.
- [ ] The publish-action shell fixture passes and proves auth/company-id/dry-run behavior without network calls, git push, GitHub dispatch, or Paperclip mutations.
- [ ] `PUBLISH_ACTION_DRY_RUN=1 bash scripts/publish-action.sh` logs Phase 0/1/2 decisions and `publish-action complete` without changing git history, pushing, dispatching, or PATCHing Paperclip.
- [ ] Read-only scheduler inspection shows exactly one intended cadence owner for `publish-action` and cron-driver after the fix; no stale launchd cron-driver continues emitting `Operation not permitted`.
- [ ] `/paperclip/logs/publish-action.log` receives a fresh health marker at the expected cadence after authorized scheduler reload, or the PR explicitly states reload was deferred pending board authorization.
- [ ] Plan Reviewer handoff: approve only if the PR diff shows all Paperclip API calls using the board-token helper, the canonical company id is not hardcoded to the old UUID, and verification evidence does not include a live push-capable run.

## Risk
- The main risk is accidentally running the production publish path while fixing scheduler cadence. Mitigation: implement and test dry-run first, perform scheduler inspection read-only before reloads, keep `launchctl kickstart` and live `bash scripts/publish-action.sh` out of verification unless Chief Engineering explicitly authorizes them, and require log evidence instead of manual dispatch.

## Out of scope
- Rewriting publish-action outside bash, changing G4/G5 publish-state semantics, changing learnovaBeast workflows, rotating or printing secrets, creating a new Paperclip scheduler subsystem, or cleaning unrelated dirty vault/blog/UI/watchdog files already present in the worktree.

## Pre-flight
- status_verified=true
- active_sibling_count=1
- acceptance_spec=issue_body_numbered_tasks_and_reopen_comment
- basebranch_verified=true origin/master
