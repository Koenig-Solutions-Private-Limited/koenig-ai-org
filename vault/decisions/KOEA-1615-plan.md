---
ticket: KOEA-1615
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.22
---

# Plan: harden publish-action Phase 0 guard logging

## Goal
Make the Phase 0 guard diagnosable when Paperclip API reads or watchdog issue creation fail. Success means the runtime and repo copies have one source of truth, guard failures log endpoint/status/sanitized response details without secrets, and a guarded-out vault tick still emits a clear completion marker instead of looking silent.

## Context
- Files to read first: `scripts/publish-action.sh:1-193`, `/paperclip/scripts/publish-action.sh:49-79`, `/paperclip/scripts/publish-action.sh:121-197`, `/paperclip/scripts/publish-action.sh:282-341`, `vault/decisions/KOEA-1401-plan.md:288-483`
- Relevant prior work: KOEA-1610 confirmed publish-action liveness recovered but left opaque `guard:api-error` and `guard:watchdog-issue-create-failed` logs; KOEA-1401 introduced the Phase 0 pending-G4 guard in the live runtime script.
- Constraints: Do not run a path that pushes `koenig-ai-org` from this ticket. Treat `/paperclip/scripts/publish-action.sh` as the observed runtime copy, but make `scripts/publish-action.sh` the audited source of truth before syncing runtime. Never log bearer tokens, Telegram tokens, or full request headers.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Reconcile the live Phase 0 guard into the repo script, then harden the two failing curl paths in place. This keeps the current bash pipeline and KOEA-1401 guard behavior intact, closes the repo/runtime drift called out in KOEA-1615, and scopes the actual behavior change to diagnostics plus an explicit all-excluded completion log.

**Rejected**: Patch only `/paperclip/scripts/publish-action.sh` because it would preserve the unaudited drift and be overwritten later; rewrite publish-action in TypeScript because KOEA-1615 is a logging hardening follow-up, not a pipeline rewrite; add a separate watchdog process because the failure context already exists inside the Phase 0 guard.

## Steps (Executor follows in order)
1. Diff `scripts/publish-action.sh` against `/paperclip/scripts/publish-action.sh`; port the live Phase 0 helper/block into `scripts/publish-action.sh` so the repo copy contains `fetch_issues_by_slug`, `slug_to_issue_info`, `create_guard_watchdog_issue`, `verify_no_pending_g4_publish`, and the Phase 0 vault-sync block now present in runtime.
2. In `scripts/publish-action.sh`, replace the opaque issue-list fetch in `fetch_issues_by_slug` with a temp-body + `curl -sS -w "%{http_code}"` pattern that logs `guard:api-error endpoint=<path> http_status=<code|curl-failed> reason=<sanitized first line/bytes>` and still defaults closed.
3. In `create_guard_watchdog_issue`, capture the POST response/status the same way and log `guard:watchdog-issue-create-failed endpoint=<path> http_status=<code|curl-failed> reason=<sanitized summary>`; keep the existing hash sentinel and cleanup behavior.
4. Add a small local sanitizer helper in `scripts/publish-action.sh` that strips control characters, redacts obvious token/key/password substrings, truncates response text, and never prints request headers or env values.
5. Adjust the Phase 0 commit branch so when guard exclusions leave `STAGED_COUNT=0`, it logs an explicit all-excluded/continuing marker and skips `git commit` instead of relying on a failed commit message; keep the final `publish-action complete.` marker reachable.
6. Add a narrow shell test or fixture script under `scripts/tests/` only if it can run without pushing: cover API 500/empty response logging, watchdog POST failure logging, and all-excluded completion behavior. Otherwise document the manual fixture commands in the PR body and do not add a brittle test.
7. After review approval only, sync the audited repo script to `/paperclip/scripts/publish-action.sh`, set executable mode, and compare checksums. Do not trigger a live run that can push unless Chief Engineering explicitly authorizes it.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/publish-action.sh` passes.
- [ ] If a test script is added, `bash scripts/tests/publish-action-guard-logging.sh` passes and performs all work in a temp git repo or copied script with network calls stubbed.
- [ ] `rg -n "guard:api-error|guard:watchdog-issue-create-failed|all.*excluded|publish-action complete" scripts/publish-action.sh` shows the new structured log paths and the completion marker.
- [ ] `diff -u scripts/publish-action.sh /paperclip/scripts/publish-action.sh` is empty after the authorized runtime sync, or the PR notes why runtime sync was deferred.
- [ ] No verification command invokes `git push`, `launchctl load`, or a live publish-action run without explicit Chief Engineering authorization.

## Risk
- The main risk is accidentally changing Phase 0 guard behavior while improving logs. Mitigation: port the live guard first, keep allow/block semantics unchanged, use temp fixtures for failure paths, and make the PR diff easy to review around only the curl/logging and zero-staged branch changes.

## Rollback
- If the hardened script causes false blocks or noisy logs, restore `/paperclip/scripts/publish-action.sh` from the pre-change runtime copy and revert the repo commit. Because this plan does not authorize a live publish tick or manual push, rollback should be limited to the script file unless Executor receives separate deployment authorization.

## Out of scope
- Rewriting publish-action outside bash, changing publish-state semantics, changing G4/G5 workflows, pushing `koenig-ai-org`, or expanding the watchdog bot beyond the Phase 0 guard issue path.
