---
ticket: KOEA-1973
parent_ticket: KOEA-1969
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.25
base_branch: master
basebranch_verified: true
---

# Plan: publish-action silent-exit and auth hardening

## Goal

Make `scripts/publish-action.sh` finish every run with an explicit terminal log line, including failures inside Phase 1 and Phase 2 command substitutions. Success means Paperclip API calls are authenticated when `PAPERCLIP_API_KEY` is present, curl/JSON failures are logged with bounded waits, and a failed metadata PATCH cannot cause repeated `repository_dispatch` calls for the same G4 issue.

## Context

- Files to read first: `scripts/publish-action.sh:26-113`, `scripts/publish-action.sh:392-548`, `scripts/tests/publish-action-guard-logging.sh:19-80`, `/paperclip/logs/publish-action.log`
- Relevant prior work: current branch `koea-1615/publish-action-guard-logging`; existing guard helper already authenticates one Paperclip read path and redacts token-like strings.
- Constraints: do not clean or overwrite unrelated dirty worktree files; keep deploy path limited to `Koenig-Solutions-Private-Limited/learnovaBeast` and `https://academy.kspl.tech`; no direct merge to `main`; verified repo base is `origin/master`, not `origin/main`.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Add small shell helpers and a dispatch ledger while preserving the current script architecture. Executor should keep the fix inside `scripts/publish-action.sh` and `scripts/tests/publish-action-guard-logging.sh`: add authenticated Paperclip/GitHub curl helpers with timeout/status/body capture, add an EXIT trap plus cleanup registry that logs normal and error terminal states, wrap Python JSON parsing so failures log a sanitized reason, and add a local `$LOG_DIR/.dispatch-ledger/` entry per issue to retry the Paperclip metadata PATCH instead of firing duplicate dispatches after the first accepted GitHub dispatch.

**Rejected**: Rewrite publish-action in Python because it broadens the ticket and risks changing the vault git-sync behavior. Rejected: only adding `Authorization` headers to existing curls because `set -euo pipefail` command substitutions can still exit silently before the run-status or complete logs. Rejected: moving deploy/publish responsibility to another portal because this ticket explicitly preserves the learnovaBeast GitHub Actions path.

## Steps (Executor follows in order)

1. Update `scripts/publish-action.sh` near the logging helpers to add `CURRENT_PHASE`, `TERMINAL_REASON`, an EXIT trap, and a cleanup-file registry so normal completion logs `publish-action complete.` once and failures log `publish-action terminal: failed ... cleanup=...` before removing temp files.
2. Add reusable `paperclip_curl_json`, `paperclip_patch_issue_metadata`, and `github_curl_json` shell helpers that always include `Authorization: Bearer $PAPERCLIP_API_KEY` when set, use bounded curl flags, capture HTTP status and stderr/body into temp files, and log sanitized non-2xx/curl failures.
3. Replace Phase 1 issue listing and metadata PATCH curls with the helpers; after a 204 `repository_dispatch`, write a per-issue dispatch ledger before PATCH, retry the metadata PATCH from the ledger on later runs, and skip a fresh dispatch while that ledger exists.
4. Replace Phase 2 issue listing, GitHub Actions run fetch, publish-verifier lookup, issue metadata PATCHes, and verifier heartbeat invoke with the helpers; each helper failure should log a reason and continue or mark `TERMINAL_REASON` without aborting silently.
5. Wrap Phase 1/Phase 2 Python JSON parsing in named helper calls that catch parse errors, log `phase=<n> json-parse-failed reason=...`, and return an empty result or `unknown_parse_error` status instead of letting `set -e` exit between log lines.
6. Extend `scripts/tests/publish-action-guard-logging.sh` or add a sibling focused shell fixture that simulates Paperclip 401/500, malformed GitHub JSON, and a post-dispatch metadata PATCH failure; assert the log contains sanitized failure reasons, no token leak, a terminal line, and no second `repository_dispatch` for the same issue while the ledger is pending.
7. Run `bash scripts/tests/publish-action-guard-logging.sh`, then a narrow shell syntax check with `bash -n scripts/publish-action.sh scripts/tests/publish-action-guard-logging.sh`.

## Verification (QA Verifier checks these)

- [ ] Paperclip API reads/writes in Phase 1 and Phase 2 include auth when `PAPERCLIP_API_KEY` is present; unauthenticated or non-2xx responses log sanitized HTTP status/body context.
- [ ] A malformed GitHub runs response in Phase 2 logs a JSON parse failure and still emits a terminal publish-action line.
- [ ] A successful `repository_dispatch` followed by failed Paperclip metadata PATCH does not dispatch the same issue again on the next run; it retries/records the metadata update path instead.
- [ ] Successful Phase 2 completion still marks issues `published`, triggers only the learnova `publish-verifier`, and logs `publish-action complete.`
- [ ] No deploy path is introduced outside learnovaBeast/GitHub Actions, and no instruction or script path directly merges to `main`.

## Risk

- Dispatch ledger state can become stale if Paperclip stays unavailable for a long period; mitigate by logging the ledger path and issue id on every skip/retry so an operator can inspect or clear one file intentionally.

## Out of scope

- Replacing the launchd schedule, changing GitHub Actions workflows in `learnovaBeast`, altering Paperclip schema/API contracts, or resolving the existing non-fast-forward branch push noted in the active log.

## Plan-Reviewer Checklist

- [ ] Authenticated Paperclip API reads/writes when `PAPERCLIP_API_KEY` is present.
- [ ] Bounded curl error/status handling around Paperclip and GitHub calls.
- [ ] Terminal logging and cleanup for every early exit, including Phase 2 JSON parsing failures.
- [ ] No repeated `repository_dispatch` for the same G4 issue when metadata PATCH fails.
- [ ] Focused script test covers guard/Phase 2 failure logging and terminal line behavior.
- [ ] No deploy from any portal other than learnovaBeast and no direct merge to `main`.

Pre-flight: status=active assignee=planner siblings=2 basebranch_verified=true
