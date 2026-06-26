---
ticket: KOEA-4997
planning_ticket: KOEA-5000
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: master
basebranch_verified: true
preflight_authorization: "planner_chain_alert 234a5008-70e3-4f40-94ba-572e126bca2f approved 2026-05-26 by Chief Engineering"
type: decision
tags:
  - decision
  - g4
  - notifications
---

# Plan: Repair CEO G4 notification delivery

## Goal
CEO G4 routing for [KOEA-2169](/KOEA/issues/KOEA-2169) must report truthful per-channel delivery status and stop relying on ad hoc provider calls. Success means the CEO can validate the Resend route without exposing the key, send or fail closed on the email leg, send or explicitly mark unavailable on the Slack chat leg, and post the final channel status back to [KOEA-2169](/KOEA/issues/KOEA-2169) before any publish action continues.

## Context
- Files to read first: `companies/learnova-academy/skills/g4-routing/SKILL.md:35-80`, `companies/learnova-academy/.paperclip.yaml:38-51`, `scripts/sync_secrets.py:19-41`, `.env.koenig.example:17-47`, `companies/learnova-academy/ARCHITECTURE.md:344-470`, `README.koenig.md:63-74`.
- Relevant prior work: `vault/decisions/KOEA-2625-plan.md` already chose Slack via `SLACK_WEBHOOK_URL` as the canonical G4 chat route and left Teams as future/unused. `vault/decisions/KOEA-3697-plan.md` reused that Slack decision for EOD delivery. [KOEA-2169](/KOEA/issues/KOEA-2169) comment at 2026-05-26T12:13:53Z is the incident record: Paperclip UI approval exists, Resend returned `401 API key is invalid`, and Slack/Teams were not delivered because no webhook/helper was available.
- Constraints: Planner does not implement, rotate secrets, deploy Convex, or ask Vardaan to approve the content. Keep implementation in `koenig-ai-org`; no Paperclip core package edits, no production-destructive DB writes, no Learnova portal changes. Do not print, store, or comment real API keys, webhook URLs, recipient addresses, or magic-link bodies. Verified base branch for `koenig-ai-org`: `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add one local G4 notification helper plus CEO skill updates. The helper should own both delivery checks: Resend validation/email send through `RESEND_API_KEY`, and Slack chat send through `SLACK_WEBHOOK_URL`. It must support dry-run and validation-only modes, emit sanitized JSON channel statuses, and never mutate Paperclip approval or publish state. The G4 skill then calls the helper after creating/linking the Paperclip UI approval, posts the sanitized result back to the source issue, and blocks if email is unauthorized or chat is neither configured nor explicitly signed off as unavailable.

**Rejected**: Rotate `RESEND_API_KEY` only, because that fixes the 401 but leaves Slack/Teams silently undeliverable. **Rejected**: Implement Teams now, because this repo has no Teams payload convention and prior plans standardized on Slack. **Rejected**: Add Paperclip core outbound notification infrastructure, because this incident is repairable in the Koenig company runtime and core edits are outside this ticket's approval.

## Steps (Executor follows in order)
1. Add `scripts/g4-notify.sh` as a notification-only Bash helper. Inputs should include `--issue`, `--approval-id`, `--title`, `--preview-url`, `--vault-path`, `--gates`, `--dry-run`, `--validate-resend`, and `--allow-chat-unavailable`. It reads `RESEND_API_KEY` and optional `SLACK_WEBHOOK_URL`, sends email through Resend only outside dry-run, posts Slack only when configured, and prints sanitized JSON with `email.status` and `slack.status`.
2. Add `scripts/tests/g4-notify-smoke.sh` to exercise dry-run and missing-secret paths. Assert valid JSON, no secret-looking `Bearer`, `https://hooks.slack`, or `re_` token output, no Paperclip PATCH calls, and deterministic statuses for email/slack when env vars are absent.
3. Update `companies/learnova-academy/skills/g4-routing/SKILL.md` so the channel list is Paperclip UI plus Resend email plus Slack. Replace Slack/Discord and Slack/Teams ambiguity with the exact helper command, the rule that Teams is future/unused, and the rule that missing `SLACK_WEBHOOK_URL` requires `--allow-chat-unavailable` only after Chief Engineering/operator sign-off.
4. Update `.env.koenig.example` and, only if needed, `companies/learnova-academy/.paperclip.yaml`/`scripts/sync_secrets.py` to keep `RESEND_API_KEY` required for CEO and `SLACK_WEBHOOK_URL` optional for CEO. Do not add secret values. If the current bindings remain sufficient, leave those files unchanged and mention that in the Executor handoff comment.
5. Validate/repair the Resend route without exposing the key: run the helper in `--validate-resend` mode from a CEO-equivalent environment. If Resend returns `401`, stop implementation and mark [KOEA-4997](/KOEA/issues/KOEA-4997) blocked on Chief Engineering/operator rotating `RESEND_API_KEY` in `.env.koenig` and running `./scripts/sync-secrets.sh`; after rotation, rerun validation and one explicit test-only email.
6. Validate the chat route: if `SLACK_WEBHOOK_URL` is configured, run a single test-only Slack send labelled `TEST ONLY - no publish`; if it is absent, either block on Chief Engineering/operator adding it and running `./scripts/sync-secrets.sh`, or record owner sign-off by running the helper with `--allow-chat-unavailable` so the final status says chat was intentionally unavailable, not silently skipped.
7. Post the final sanitized channel report back to [KOEA-2169](/KOEA/issues/KOEA-2169): include Paperclip UI approval `88461ffc-4cf7-48ec-836d-f21734d579a6`, `email.status`, `slack.status`, any rotation/sync action performed, and the explicit statement `No publish action was taken by the notification repair`.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/g4-notify.sh scripts/tests/g4-notify-smoke.sh` passes.
- [ ] `bash scripts/tests/g4-notify-smoke.sh` passes and its stdout/stderr contains no API key, bearer token, webhook URL, recipient address, or magic-link body.
- [ ] `RESEND_API_KEY=dummy bash scripts/g4-notify.sh --validate-resend --dry-run ...` reports a sanitized non-live result; a real CEO-environment validation reports non-401 before any live email retry is considered fixed.
- [ ] `rg -n "Slack/Discord|Slack/Teams|TEAMS_WEBHOOK_URL|SLACK_WEBHOOK_URL|RESEND_API_KEY|g4-notify" companies/learnova-academy/skills/g4-routing/SKILL.md .env.koenig.example companies/learnova-academy/.paperclip.yaml scripts/sync_secrets.py scripts` shows Slack as canonical, Teams as future/unused only if mentioned, and CEO still has the required Resend binding.
- [ ] [KOEA-2169](/KOEA/issues/KOEA-2169) receives a final comment with sanitized per-channel status and `No publish action was taken by the notification repair`.

## Risk
- The helper could accidentally become a second approval or publish path. Mitigation: keep it notification-only, forbid Paperclip state mutation inside the helper, keep approval creation in the existing Paperclip UI flow, and keep publishing solely behind the existing G4 approval/publish-action path.

## Out of scope
- Rotating secrets by Planner, storing secret values, sending real approval content to Vardaan during planning, implementing Teams buttons, changing Paperclip core, changing `publish-action.sh` semantics, deploying Convex/Learnova, or approving/publishing [KOEA-2169](/KOEA/issues/KOEA-2169).
