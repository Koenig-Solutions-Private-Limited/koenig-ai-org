---
ticket: KOEA-3697
planning_ticket: KOEA-3707
planner: planner
date: 2026-05-18
estimated_complexity: small
estimated_token_cost: "$0.24"
base_branch: master
basebranch_verified: true
learnova_base_branch_checked: academy/redesign-v1
learnova_basebranch_verified: true
preflight_authorization: "planner_chain_alert 13d6625c-0388-4466-bd5d-2f1707d39dae approved 2026-05-18"
---

# Plan: Wire CEO EOD outbound delivery routes

## Goal
CEO EOD digest delivery has durable route configuration, one concrete chat channel, and a verification result that future CEO runs can report without exposing secrets. Success is observable when the CEO can read a non-secret email recipient route, attempt email and Slack delivery, and emit sanitized sent/failed status per channel after writing `vault/decisions/eod-<date>.md`.

## Context
- Files to read first: `companies/learnova-academy/skills/eod-digest/SKILL.md:86-100`, `companies/learnova-academy/.paperclip.yaml:38-45`, `scripts/sync_secrets.py:19-57`, `.env.koenig.example:39-46`, `docs/runbook.md:103-118`, `watchdog/watchdog.mjs:40-43`, `watchdog/watchdog.mjs:184-196`, `docs/companies/companies-spec.md:456-470`.
- Relevant prior work: `vault/decisions/KOEA-2625-plan.md` chose Slack via `SLACK_WEBHOOK_URL` for CEO G4 chat notification and left Teams as future/unused. Reuse that channel decision instead of introducing a second chat provider for EOD.
- Constraints: plan mode only; no production code changes by Planner; do not write real recipient addresses, webhook URLs, API keys, or email bodies into vault comments/logs; implement in `koenig-ai-org` from verified base branch `master`; do not use the locked shared `learnovaBeast-fe-agent` checkout; no Convex deploy is expected. If Executor unexpectedly needs Learnova code, use an isolated worktree from verified `academy/redesign-v1` and deploy only from `learnova-tc`.
- Pre-flight: KOEA-3707 status/assignee passed; parent KOEA-3697 has three concrete success criteria; sibling-chain guard was approved by Chief Engineering via approval `13d6625c-0388-4466-bd5d-2f1707d39dae`; `git ls-remote --heads origin master` in `koenig-ai-org` and `git ls-remote --heads origin academy/redesign-v1` in `learnovaBeast` both returned refs.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small EOD delivery helper plus CEO runtime route bindings in `koenig-ai-org`. The helper should read `CEO_EOD_EMAIL_TO` as a plain, non-secret runtime input, `RESEND_API_KEY` as a secret, and optional `SLACK_WEBHOOK_URL` as the canonical chat route; send email through Resend, post a Slack text summary when configured, and print a sanitized JSON delivery report. The CEO `eod-digest` skill then calls this helper after writing the vault digest and records the per-channel status in the Paperclip task comment.

**Rejected**: Keep the recipient hardcoded in `eod-digest`, because it is brittle and was the root of the missing durable recipient failure. **Rejected**: Put the recipient in the encrypted secrets store, because the ticket explicitly asks for a non-secret recipient source and Paperclip supports plain env inputs. **Rejected**: Build Teams first, because this repo already has a Slack route decision and no Teams payload convention.

## Steps (Executor follows in order)
1. Add `scripts/eod-outbound-deliver.sh` that accepts `--date`, `--digest-path`, `--subject`, and `--summary`, supports `--dry-run` or `EOD_OUTBOUND_DRY_RUN=1`, reads `CEO_EOD_EMAIL_TO`, optional `CEO_EOD_EMAIL_FROM`, `RESEND_API_KEY`, and optional `SLACK_WEBHOOK_URL`, and emits only sanitized JSON status for `email` and `slack`.
2. Add `scripts/tests/eod-outbound-deliver-smoke.sh` with a temporary dummy digest and dry-run assertions: valid JSON, no raw webhook/API key output, email route reported configured/missing correctly, and Slack reported skipped when no webhook is present.
3. Update `companies/learnova-academy/.paperclip.yaml`, `.env.koenig.example`, and `scripts/sync_secrets.py` so CEO receives `CEO_EOD_EMAIL_TO` as required plain env, `CEO_EOD_EMAIL_FROM` as optional plain env, and `SLACK_WEBHOOK_URL` as optional secret env. Keep `TEAMS_WEBHOOK_URL` documented as future/unused.
4. Update `companies/learnova-academy/skills/eod-digest/SKILL.md` so step 7 calls the helper after writing the vault file, treats Slack as the canonical chat channel, and replaces the invalid "delivered" status wording with a Paperclip comment/status-summary handoff.
5. Update operator docs (`README.koenig.md`, `companies/learnova-academy/ARCHITECTURE.md`, `docs/SECRETS_CHECKLIST.md`, and `docs/runbook.md`) with the EOD route variables, the sync command, the dry-run command, and the rule that verification checks presence/status only, never secret values.
6. Before live verification, run only presence checks such as `awk -F= '/^(CEO_EOD_EMAIL_TO|SLACK_WEBHOOK_URL)=/{print $1 \"=\" (length($2)>0 ? \"set\" : \"empty\")}' .env.koenig`; if required values are missing, block implementation on Chief Engineering/operator filling `.env.koenig` and running `./scripts/sync-secrets.sh`.

## Verification (QA Verifier checks these)
- [ ] `bash -n scripts/eod-outbound-deliver.sh scripts/tests/eod-outbound-deliver-smoke.sh` passes.
- [ ] `bash scripts/tests/eod-outbound-deliver-smoke.sh` passes and prints sanitized dry-run JSON without sending email, calling Slack, mutating Paperclip state, or exposing secret-looking URLs/tokens.
- [ ] `rg -n "CEO_EOD_EMAIL_TO|CEO_EOD_EMAIL_FROM|SLACK_WEBHOOK_URL|TEAMS_WEBHOOK_URL" .env.koenig.example companies/learnova-academy scripts docs README.koenig.md` shows EOD email route variables, Slack as canonical chat, and Teams as future/unused only.
- [ ] A CEO EOD dry run against a dummy digest reports `email` and `slack` channel statuses as `sent`, `skipped`, or `failed` with no secret values in stdout/stderr.
- [ ] If the operator provides real route values, one explicit live test sends a message labelled test-only and the resulting Paperclip issue comment reports per-channel status without logging recipient values or webhook URLs.

## Risk
- The helper could falsely report success when only the vault write succeeded. Mitigation: make each channel status independent, fail closed for missing required email config, and require the CEO task comment to include the helper's sanitized channel report.

## Out of scope
- Implementing Teams delivery, adding interactive Slack buttons, changing G4 approval semantics, modifying Learnova app/Convex code, deploying Convex, writing real recipient addresses or webhook URLs into git/vault/comments, or closing the sibling-chain governance work Chief Engineering retained.
