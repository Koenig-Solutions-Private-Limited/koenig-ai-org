---
ticket: KOEA-2029
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
revision: 2
triggered_by_approval: be056ad9-620c-42cf-a177-a95a24df5f0d
supersedes: vault/decisions/KOEA-1857-plan.md
---

# Plan: restore current publish-action auth and scheduler health

## Goal
Restore the current `publish-action` loop so it uses the Koenig company id, authenticated Paperclip board-token calls, and safe dry-run verification before any push-capable publish path can run. Success is observable from shell syntax checks, a stubbed local fixture, dry-run output, and scheduler/log health evidence or an explicit note that host scheduler inspection was unavailable in the agent runtime.

## Context
- Files to read first: `scripts/publish-action.sh:15-193`, `scripts/koenig-cron-driver.py:232-250`, `infra/launchd/com.koenig.publish-action.plist:7-27`, `infra/docker-compose.koenig.yml:167-184`, `scripts/load-launchd-agents.sh:22-28`
- Relevant prior work: `vault/decisions/KOEA-1857-plan.md` was approved, but Executor blocked because it referenced absent Phase 0 sections and missing `scripts/tests/publish-action-guard-logging.sh`.
- Constraints: Do not print secrets. Do not run live `scripts/publish-action.sh` without the dry-run guard. Do not deploy Convex. Do not push this repo directly from the agent runtime. `origin/master` is the verified base branch; `origin/main` is absent.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Patch the existing Phase 1/2 bash script in place with a small Paperclip API helper, canonical company-id validation, and `PUBLISH_ACTION_DRY_RUN=1` behavior, then add a new stubbed shell fixture under `scripts/tests/` that proves auth, redaction, company targeting, and no live mutations. This preserves the current publish architecture while removing the stale Phase 0 assumptions that blocked execution.

**Rejected**: Recreate the old Phase 0 guard workflow because the current script no longer contains that surface and this ticket is about restoring current health; convert publish-action to a Paperclip routine because that changes scheduler ownership during a critical outage; only edit `.env.koenig` because the script would still default to the wrong company id and unauthenticated API calls.

## Steps (Executor follows in order)
1. Update `scripts/publish-action.sh` config loading near lines 15-35: source only the needed values from `.env.koenig`, normalize `PAPERCLIP_API_URL`/`PAPERCLIP_URL`, require company id `2a77f89b-33f0-4133-a20c-77ddaac5e744`, require `PAPERCLIP_BOARD_TOKEN` for Paperclip API access, and log only presence/absence, never token values.
2. Add helper functions in `scripts/publish-action.sh` for `paperclip_get`, `paperclip_patch`, and optional `paperclip_post` that always include `Authorization: Bearer <board-token>`, capture HTTP status, and log sanitized endpoint/status/failure summaries.
3. Route the existing Phase 1 and Phase 2 Paperclip calls through those helpers: company issue listing, dispatching-state PATCH, agent lookup, published/dispatch_failed PATCH, and publish-verifier heartbeat invoke. Keep GitHub repository_dispatch behavior unchanged except for dry-run gating.
4. Add `PUBLISH_ACTION_DRY_RUN=1` to `scripts/publish-action.sh`: permit authenticated reads and GitHub metadata reads, but skip GitHub repository_dispatch, Paperclip PATCH/POST mutations, publish-verifier invokes, git commit, and git push while logging `DRY-RUN would ...` markers.
5. Create `scripts/tests/publish-action-auth-dry-run.sh` with temporary fixture env and stubbed `curl`/network responses that verifies: old default company id is gone, missing board token exits before mutations, auth headers are present on Paperclip calls, dry-run skips dispatch/PATCH/heartbeat invoke, failure logs are sanitized, and no secret token appears in captured logs.
6. Verify scheduler ownership without changing host state: if `launchctl`/`docker` are available, run read-only inspections for `com.koenig.publish-action`, `com.koenig.cron-driver`, and `koenig-cron-driver`; if unavailable, report that limitation and rely on file-level evidence that publish-action is launchd-owned while cron-driver is docker-owned. Do not reload or kickstart schedulers in this ticket.
7. Leave an implementation report on KOEA-2029 with changed files, branch/PR or local branch work product, safe command output, whether scheduler inspection was available, and `git status --short --branch` showing unrelated dirty files separately from Executor's changes.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh` passes.
- [ ] `python3 -m py_compile scripts/koenig-cron-driver.py` passes.
- [ ] `bash scripts/tests/publish-action-auth-dry-run.sh` passes without real network calls, git push, GitHub dispatch, or Paperclip mutations.
- [ ] `PUBLISH_ACTION_DRY_RUN=1 bash scripts/publish-action.sh` logs Phase 1/2 decisions and `publish-action complete` without printing secrets or taking live mutation/dispatch actions.
- [ ] Read-only scheduler evidence is included, or the report explicitly says `launchctl`/`docker` were unavailable in the agent runtime and no scheduler reload was attempted.

## Risk
- The main risk is accidentally invoking a live publish path while restoring auth. Mitigation: implement dry-run and stubbed fixture first, gate every mutating call behind dry-run checks, and keep scheduler reload/kickstart out of scope for this implementation ticket.

## Out of scope
- Reintroducing absent Phase 0 guard code, creating `scripts/tests/publish-action-guard-logging.sh`, changing G4/G5 publish-state semantics, deploying Convex, rotating or exposing secrets, modifying learnovaBeast workflows, or cleaning unrelated dirty vault/watchdog/adapter files already present in the worktree.

## Pre-flight
- status_verified=true
- active_sibling_count=1
- chain_depth=2
- acceptance_spec=5_bullets_in_issue_description
- basebranch_verified=true origin/master
