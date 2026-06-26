---
ticket: KOEA-2625
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
preflight_authorization: "planner_chain_alert 1eef225c-6b39-43c2-8713-a516dc68bf56 resolved by Chief Engineering; KOEA-2625 sibling phases authorized"
---

# Plan: Wire CEO G4 Slack notification channel

## Goal
CEO G4 routing gets one concrete chat notification path for high-stakes course approvals without changing publish semantics. Success is observable when the repo documents `SLACK_WEBHOOK_URL`, the CEO runtime can receive that secret, a non-publishing dry-run renders the Slack payload, and live send remains blocked unless the operator provides a real webhook.

## Context
- Files to read first: `companies/learnova-academy/skills/g4-routing/SKILL.md:25-89`, `companies/learnova-academy/skills/g3-alignment/SKILL.md:30-47`, `companies/learnova-academy/.paperclip.yaml:21-48`, `scripts/sync_secrets.py:19-39`, `.env.koenig.example:17-46`, `companies/learnova-academy/ARCHITECTURE.md:344-365`, `README.koenig.md:63-74`, `scripts/publish-action.sh:343-498`.
- Relevant prior work: `scripts/publish-action.sh` already handles `publish_state=g4-approved -> dispatching -> published`; G4 chat must not change that path. Existing `scripts/discord-daily-digest.sh` proves Discord webhook posting is possible, but it is unrelated to CEO G4 and no `DISCORD_WEBHOOK_URL` is present in `.env.koenig`.
- Constraints: plan mode only; no secret values in git, logs, comments, or PR text; no Convex deploy; keep changes in `koenig-ai-org` G4/runtime docs and helper scripts; base branch `origin/master` exists. Current `.env.koenig` has `SLACK_WEBHOOK_URL` and `TEAMS_WEBHOOK_URL` empty and no `DISCORD_WEBHOOK_URL`, so live implementation is blocked on operator-provided `SLACK_WEBHOOK_URL`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Slack incoming webhook via `SLACK_WEBHOOK_URL`. Slack is the lowest-risk supported channel because it is already named in `README.koenig.md` as a G4 channel and already exists as an empty runtime variable in `.env.koenig.example` / `.env.koenig`. Add a small Slack-only notification helper with a dry-run mode, bind the optional secret to CEO, and update the G4 skill to call that helper after Resend/Paperclip queue routing. The helper must fail closed if the webhook is missing, so high-stakes G4 cannot falsely claim chat notification coverage.

**Rejected**: Teams webhook because the variable exists but there is no existing Teams payload convention in this repo; Discord fallback because only an unrelated daily digest uses it and no runtime secret is present; Telegram notifier reuse because it is already configured but outside the requested Slack/Teams/Discord provider set.

## Steps (Executor follows in order)
1. In `scripts/g4-chat-notify.sh`, add a new Bash helper that accepts issue id/title/preview/vault path/gates summary, reads `SLACK_WEBHOOK_URL`, supports `--dry-run` or `G4_CHAT_NOTIFY_DRY_RUN=1`, prints sanitized JSON in dry-run, posts to Slack only when not dry-run, and never echoes the webhook URL.
2. In `scripts/tests/g4-chat-notify-smoke.sh`, add a targeted smoke check that runs the helper in dry-run with dummy values and asserts valid JSON plus no secret-looking URL output.
3. In `companies/learnova-academy/.paperclip.yaml` and `scripts/sync_secrets.py`, add `SLACK_WEBHOOK_URL` as an optional CEO secret binding. Keep normal CEO heartbeats runnable if the secret is absent; the G4 helper itself must block live chat sends.
4. In `.env.koenig.example`, replace the current vague V2/future Slack/Teams note with a G4 chat section documenting `SLACK_WEBHOOK_URL` as the chosen variable and leaving `TEAMS_WEBHOOK_URL` as unused/future.
5. In `companies/learnova-academy/skills/g4-routing/SKILL.md`, update the channel text from Slack/Discord or Slack/Teams ambiguity to Slack, add the exact non-publishing dry-run command, and specify that missing `SLACK_WEBHOOK_URL` blocks the G4 chat leg rather than falling back silently.
6. In `companies/learnova-academy/ARCHITECTURE.md` and `README.koenig.md`, document `SLACK_WEBHOOK_URL` in the secrets inventory/onboarding and state that publish still occurs only through existing `metadata.publish_state="g4-approved"` plus `publish-action.sh`.
7. Before live verification, check only presence, not value, with `awk -F= '/^SLACK_WEBHOOK_URL=/{print length($2)>0 ? "set" : "empty"}' .env.koenig`. If it is still empty, stop Executor work and mark KOEA-2653 blocked on Chief Engineering/operator adding `SLACK_WEBHOOK_URL` and running `./scripts/sync-secrets.sh`.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/g4-chat-notify.sh scripts/tests/g4-chat-notify-smoke.sh` passes.
- [ ] `bash scripts/tests/g4-chat-notify-smoke.sh` passes and shows a sanitized dry-run payload without publishing content, mutating Paperclip state, or calling Slack.
- [ ] `rg -n "SLACK_WEBHOOK_URL|TEAMS_WEBHOOK_URL|DISCORD_WEBHOOK_URL" .env.koenig.example companies/learnova-academy scripts README.koenig.md` shows Slack as the chosen G4 chat variable, Teams as future/unused if mentioned, and no new Discord requirement.
- [ ] If `SLACK_WEBHOOK_URL` is set by the operator, a single explicit test run posts a message labelled `TEST ONLY - no publish` to Slack and does not PATCH any issue metadata.
- [ ] If `SLACK_WEBHOOK_URL` is absent, KOEA-2653 remains or becomes blocked with the exact missing variable and operator action.

## Risk
- A helper script could accidentally become a second approval/publish path. Mitigation: keep it notification-only, do not call Paperclip PATCH routes from the helper, and keep all publish state changes in the existing CEO G4/Paperclip UI and `publish-action.sh` path.

## Out of scope
- Implementing Teams or Discord, changing Resend magic-link approval, modifying `publish-action.sh` dispatch semantics, deploying Convex or any Learnova portal, adding interactive Slack buttons, or writing/storing webhook secret values.
