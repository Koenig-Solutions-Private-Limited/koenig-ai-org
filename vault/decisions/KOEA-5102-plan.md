---
ticket: KOEA-5102
planning_ticket: KOEA-5107
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: "$0.52"
base_branch: master
basebranch_verified: true
basebranch_note: "origin/main returned no ref; origin/master verified and used for koenig-ai-org"
preflight_authorization: "planner_chain_alert 3aa68d08-c66d-48a4-a6f0-ae80d80e07f6 approved 2026-05-26 by Chief Engineering"
type: decision
tags:
  - decision
  - g4
  - notifications
---

# Plan: Restore CEO G4 notification routing

## Goal
CEO G4 approval notices must stop being Paperclip-UI-only. Success means a CEO heartbeat has a tested, non-publishing path that creates the Paperclip approval, attempts Resend email, attempts or explicitly marks Slack unavailable, and comments sanitized per-channel status back to KOEA-5102 and the affected G4 issue.

## Context
- Files to read first: `companies/learnova-academy/skills/g4-routing/SKILL.md:35-80`, `companies/learnova-academy/.paperclip.yaml:38-51`, `scripts/sync-secrets.sh:17-29`, `scripts/sync_secrets.py:21-40`, `.env.koenig.example:17-47`, `.mcp.json:3-40`, `server/src/routes/approvals.ts:71-121`, `server/src/routes/approvals.ts:136-188`.
- Current-state finding: this runtime has Paperclip approval/API routing and repo MCP tools only (`filesystem`, `github`, `tavily`, `fetch`). No Gmail/Outlook, Slack, or Teams connector is available to CEO heartbeats. `.env.koenig` currently has `RESEND_API_KEY=set`, `SLACK_WEBHOOK_URL=empty`, and `TEAMS_WEBHOOK_URL=empty`; the live CEO agent API record is `codex_local` with `adapterConfig.env={}`, so even Resend is not proven bound into the CEO heartbeat environment until sync/config is repaired.
- Relevant prior work: `vault/decisions/KOEA-2625-plan.md` chose Slack via `SLACK_WEBHOOK_URL` as the canonical G4 chat route and left Teams as future/unused. `vault/decisions/KOEA-3697-plan.md` reused Slack for EOD. `vault/decisions/KOEA-4997-plan.md` planned a combined Resend plus Slack G4 helper but no helper exists yet.
- Corroborating incidents: KOEA-3784 created approval `d9123b9f-f722-4649-aca6-cce9d2232d9c`; KOEA-3783 created approval `e33050ef-299f-4553-917d-eebbc8f36e7c`. Both reached Paperclip approval queue, but external email/chat delivery was unavailable from the CEO runtime.
- Constraints: no Planner implementation; no secret values in git, logs, vault, comments, or PR text; no Convex deploy; do not publish KOEA-3783 or KOEA-3784; do not modify Learnova portal code; keep the implementation in `koenig-ai-org` scripts, company runtime config, and docs unless Executor proves a Paperclip core change is unavoidable.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Implement the existing Koenig-local Resend plus Slack route and make missing channels explicit. Paperclip UI remains the durable approval source of truth. Add one notification-only helper that sends or validates Resend email, posts Slack when `SLACK_WEBHOOK_URL` is configured, and emits sanitized JSON statuses. Repair the secret sync/config path so CEO heartbeats can actually receive `RESEND_API_KEY` and optional `SLACK_WEBHOOK_URL`; document Teams as unavailable/future until a real Teams payload convention and webhook are provided.

**Rejected**: Gmail/Outlook connector routing because no such connector is installed in this runtime. **Rejected**: Teams-first delivery because only an empty variable exists and prior plans standardized on Slack. **Rejected**: Paperclip core outbound notification infrastructure because the current failure can be fixed in the Koenig company runtime without changing approval semantics.

## Steps (Executor follows in order)
1. Add `scripts/g4-notify.sh` as a notification-only helper with `--issue`, `--approval-id`, `--title`, `--preview-url`, `--vault-path`, `--gates`, `--dry-run`, `--validate-resend`, and `--allow-chat-unavailable`; it must never PATCH Paperclip issue metadata or print secrets.
2. Add `scripts/tests/g4-notify-smoke.sh` to cover dry-run, missing-secret, JSON validity, and redaction assertions for API keys, bearer tokens, webhook URLs, recipient addresses, and approval links.
3. Update `scripts/sync-secrets.sh` and `scripts/sync_secrets.py` so Koenig sync targets the current company id by default or `KOENIG_COMPANY_ID`, supports an auth header from `PAPERCLIP_API_KEY` or `PAPERCLIP_BOARD_TOKEN`, and can verify that CEO has `RESEND_API_KEY` plus optional `SLACK_WEBHOOK_URL` bound without printing values.
4. Update `companies/learnova-academy/skills/g4-routing/SKILL.md` to define the supported channels as Paperclip UI, Resend email, and Slack; remove Slack/Discord and Slack/Teams ambiguity; include the exact helper command; require a sanitized channel-status comment after each G4 routing attempt.
5. Update `.env.koenig.example`, `README.koenig.md`, and `companies/learnova-academy/ARCHITECTURE.md` to document `RESEND_API_KEY` as required for email, `SLACK_WEBHOOK_URL` as the canonical optional chat route, `TEAMS_WEBHOOK_URL` as future/unused, and the operator command to run sync for company `2a77f89b-33f0-4133-a20c-77ddaac5e744`.
6. Verify live configuration with presence-only commands: `.env.koenig` key presence, CEO `adapterConfig.env` key names through the API, `bash -n`, and the smoke test. If `SLACK_WEBHOOK_URL` is still empty, either block on operator-provided Slack webhook or run the helper with explicit `--allow-chat-unavailable` so the status says chat was intentionally unavailable.
7. Post the tested command/API/tool path back to KOEA-5102, referencing KOEA-3783/`e33050ef-299f-4553-917d-eebbc8f36e7c` and KOEA-3784/`d9123b9f-f722-4649-aca6-cce9d2232d9c`; state clearly that no publish action was taken.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/g4-notify.sh scripts/tests/g4-notify-smoke.sh` passes.
- [ ] `bash scripts/tests/g4-notify-smoke.sh` passes and stdout/stderr contains no API key, bearer token, Slack webhook URL, recipient address, magic link, or raw approval body.
- [ ] `rg -n "Gmail|Outlook|Slack/Discord|Slack/Teams|TEAMS_WEBHOOK_URL|SLACK_WEBHOOK_URL|RESEND_API_KEY|g4-notify" companies/learnova-academy/skills/g4-routing/SKILL.md .env.koenig.example companies/learnova-academy/ARCHITECTURE.md README.koenig.md scripts` shows Gmail/Outlook absent as supported routes, Slack canonical, Teams future/unused, and the helper documented.
- [ ] Presence-only API/config check shows CEO has `RESEND_API_KEY` bound and either has `SLACK_WEBHOOK_URL` bound or the final status explicitly says chat unavailable by operator choice.
- [ ] KOEA-5102 receives a final comment with the tested commands, sanitized per-channel result, both corroborating approval ids, and `No publish action was taken`.

## Risk
- A notification helper could accidentally become a publish or approval state machine. Mitigation: keep it notification-only, forbid Paperclip PATCH calls in the helper and smoke test, and leave approval creation/resolution plus publish-state changes in the existing Paperclip approval and publish-action paths.

## Out of scope
- Rotating or revealing secrets, sending real G4 email/chat during planning, implementing Teams buttons, installing Gmail/Outlook/Slack connectors, changing Paperclip core approval semantics, changing `publish-action.sh`, deploying Convex/Learnova, approving or publishing KOEA-3783/KOEA-3784, or resolving the separate blog-versus-course G4 policy contradiction.
