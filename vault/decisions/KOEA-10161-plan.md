---
ticket: KOEA-10161
planner: planner
date: 2026-07-06
estimated_complexity: small
estimated_token_cost: "$0.28"
source_planner_issue: KOEA-10182
base_branch: master
basebranch_verified: true
chain_alert_resolved_by: "Chief Engineering comment 2026-07-06T06:08:16Z"
---

# Plan: restore G4 chat notification surfacing

## Goal
Restore a working chat leg for G4 approval notifications without committing webhook secrets or changing the human approval gate itself. Success means `scripts/g4-notify.sh` can report at least one delivered chat route for a safe test approval, and KOEA-10161 records the configured channel plus sanitized verification output.

## Context
- Files to read first: `scripts/g4-notify.sh:83-126`, `scripts/tests/g4-notify-smoke.sh:40-72`, `scripts/sync_secrets.py:20-153`, `companies/learnova-academy/.paperclip.yaml:38-45`, `companies/learnova-academy/skills/g4-routing/SKILL.md:67-73`, `companies/learnova-academy/ARCHITECTURE.md:353-355`, `vault/_index/timeline-W28.md:71-73`
- Relevant prior work: KOEA-10161 parent description says `scripts/g4-notify.sh` found Resend configured but both chat env vars empty; W28 timeline records G4 as email-only until this lands.
- Constraints: do not publish content, do not approve or reject any G4 request, do not print webhook URLs/tokens/approval links, keep Paperclip UI as source of truth, and keep the implementation to the Koenig org config/helper path rather than Paperclip core.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Repair the existing helper and CEO secret binding path. Keep `scripts/g4-notify.sh` as the G4 notification entrypoint, make it deliver through `SLACK_WEBHOOK_URL` when present and optionally `TEAMS_WEBHOOK_URL` when Slack is absent, then update the sync/config path so the CEO heartbeat can actually receive the configured secret. This is the smallest route that satisfies "Slack or Teams" while preserving Paperclip approvals as the authoritative queue.

**Rejected**: Build a new Paperclip server-side notification service because KOEA-10161 is an operational chat-route repair, not a core product feature. **Rejected**: Only set an operator secret out of band because the CEO agent currently reports no env bindings, so the route would drift again after config/import. **Rejected**: Treat Teams as complete without code support because the current helper hardcodes `"teams": "future_unused"` and never reads `TEAMS_WEBHOOK_URL`.

## Steps (Executor follows in order)
1. Update `scripts/g4-notify.sh` so chat delivery tries Slack when `SLACK_WEBHOOK_URL` is non-empty, tries Teams when `TEAMS_WEBHOOK_URL` is non-empty and Slack is unavailable, returns distinct sanitized statuses for `slack` and `teams`, and still exits non-zero unless at least one chat route is delivered or `--allow-chat-unavailable` is set.
2. Update `scripts/tests/g4-notify-smoke.sh` to cover dry run, no-chat failure, allowed unavailable chat, Slack-delivered mock success, Teams-delivered mock success, and secret-redaction assertions for both webhook families.
3. Update `scripts/sync_secrets.py` so `TEAMS_WEBHOOK_URL` maps to `ceo`, and make `verify_ceo_bindings()` report redacted presence for both Slack and Teams while requiring Resend plus at least one chat route only when running KOEA-10161 verification.
4. Update `companies/learnova-academy/.paperclip.yaml` to declare `SLACK_WEBHOOK_URL` and `TEAMS_WEBHOOK_URL` as optional CEO secret inputs beside `RESEND_API_KEY`, keeping `GH_TOKEN` unchanged.
5. Update `companies/learnova-academy/skills/g4-routing/SKILL.md` only to match the helper behavior: Slack and Teams are optional chat mirrors, at least one should be configured for G4 chat surfacing, and the status comment must remain sanitized.
6. Run the smoke test plus a safe helper invocation against a non-publishing test approval or dry-run/mock endpoint; paste only sanitized JSON channel statuses onto KOEA-10161.
7. If no real webhook value is available to Executor, stop after code/config/tests and mark KOEA-10161 blocked for operator secret provisioning with exact unblock action: provide either `SLACK_WEBHOOK_URL` or `TEAMS_WEBHOOK_URL`, then run `./scripts/sync-secrets.sh --verify-ceo-bindings` or the equivalent sync command.

## Verification (QA Verifier checks these)
- [ ] `bash scripts/tests/g4-notify-smoke.sh` passes and its combined output contains no webhook URL, bearer token, API key, email address, or direct approval URL.
- [ ] With a local mock Slack webhook returning HTTP 2xx, `scripts/g4-notify.sh` emits `"slack": "delivered"` and does not require Teams.
- [ ] With Slack unset and a local mock Teams webhook returning HTTP 2xx, `scripts/g4-notify.sh` emits `"teams": "delivered"` and does not report Teams as `future_unused`.
- [ ] CEO env binding verification shows `RESEND_API_KEY` bound and at least one of `SLACK_WEBHOOK_URL` or `TEAMS_WEBHOOK_URL` bound, without printing values.
- [ ] KOEA-10161 has a final comment naming the configured channel and including sanitized helper output; no content was published and no G4 approval was decided.

## Risk
- The main risk is treating chat delivery as fixed when the webhook secret is still absent from the runtime. Mitigation: keep helper/test changes separate from operational verification, and block on operator secret provisioning if neither Slack nor Teams is bound.

## Out of scope
- Paperclip core notification services, UI approval rendering changes, publish-action behavior, G4 approval decisions, content publication, and any committed secret values.

Preflight: status_checked=true; sibling_chain_authorized=true; acceptance_scope_checked=true; basebranch_verified=true.
