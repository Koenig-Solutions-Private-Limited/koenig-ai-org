---
ticket: KOEA-8129
planner: planner
date: 2026-06-17
estimated_complexity: small
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
---

# Plan: Restore agent runtime access to Koenig distribution env vars

## Goal
Agent subprocesses should see the current Koenig distribution, Career R2, and PostHog environment variables that are already present in `.env.koenig` after the Paperclip runtime is restarted. Success is observable when PostHog and dev.to checks work from an agent heartbeat without ad hoc env injection, and the stale duplicate `TELEGRAM_BOT_TOKEN` no longer shadows the operator-injected GTM block.

## Context
- Files to read first: `packages/adapter-utils/src/server-utils.ts:873-884`, `packages/adapter-utils/src/server-utils.ts:1464-1495`, `packages/adapter-utils/src/execution-target.ts:186-213`, `packages/adapters/codex-local/src/server/execute.ts:378-472`, `server/src/services/heartbeat.ts:271-292`, `server/src/services/heartbeat.ts:5520-5595`, `infra/docker-compose.koenig.yml:98-99`, `.env.koenig:174-228`, `CLAUDE.md:66-75`.
- Relevant prior work: KOEA-8129 discovered the runtime gap; KOEA-8786 is the planning child; Chief Engineering comment `81a2b6d3-4183-49b1-9bbf-e5714738c964` authorized proceeding despite intentional downstream gate siblings.
- Constraints: do not deploy Convex; do not modify unrelated portals; do not print secret values; preserve the operator-injected GTM and `CAREER_R2_*` blocks; remove only the stale duplicate `TELEGRAM_BOT_TOKEN`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Treat this as a stale live runtime env snapshot plus duplicate-env precedence issue, not a broad Paperclip core allowlist rewrite. Current code shows local child processes merge `sanitizeInheritedPaperclipEnv(process.env)` with adapter env and that sanitizer only removes inherited `PAPERCLIP_*` keys except runtime listen/API keys. The live agent process has older env keys such as `CLOUDFLARE_R2_*` but lacks the newer GTM, `CAREER_R2_*`, and PostHog keys, so Executor should remove the stale earlier `TELEGRAM_BOT_TOKEN`, restart Paperclip so `infra/docker-compose.koenig.yml` reloads `.env.koenig`, and add a small regression test proving non-`PAPERCLIP_` inherited env keys are preserved for adapter subprocesses.

**Rejected**: Hardcode Koenig credential names in `packages/adapter-utils` — this pollutes generic Paperclip adapter code and is unnecessary for local subprocesses. **Rejected**: Parse `.env.koenig` inside the server at heartbeat time — this bypasses compose/launchd env ownership and risks secret leakage or precedence surprises.

## Steps (Executor follows in order)
1. Edit `.env.koenig` only at the duplicate token site: remove the stale `TELEGRAM_BOT_TOKEN` line in the older Koenigacademybot block around line 175, and preserve the operator-injected GTM block around lines 221-228, including its newer `TELEGRAM_BOT_TOKEN`.
2. Confirm by key name only that `.env.koenig` still contains `TELEGRAM_BOT_USERNAME`, `LINKEDIN_ORG_ID`, `GTM_ANCHOR_EMAIL`, `DEVTO_API_KEY`, `DEVTO_USERNAME`, `INDEXNOW_KEY`, `COMPANY_ID`, `CAREER_R2_ACCOUNT_ID`, `CAREER_R2_ACCESS_KEY_ID`, `CAREER_R2_SECRET_ACCESS_KEY`, `CAREER_R2_BUCKET`, `POSTHOG_PERSONAL_API_KEY`, and `POSTHOG_PROJECT_ID`, with exactly one `TELEGRAM_BOT_TOKEN`.
3. Add a targeted regression in `packages/adapter-utils/src/server-utils.test.ts` or the smallest adjacent adapter execution test to prove `runChildProcess()` preserves representative non-`PAPERCLIP_` inherited env keys such as `DEVTO_API_KEY`, `CAREER_R2_BUCKET`, and `POSTHOG_PROJECT_ID`, while still stripping inherited run-scoped `PAPERCLIP_*` keys.
4. Restart the Paperclip runtime after the env edit so the process environment is rebuilt from `.env.koenig`; use the repo’s current operator path rather than deploying Convex.
5. From a fresh agent heartbeat or equivalent controlled subprocess check, verify key presence without values: `POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PROJECT_ID`, `DEVTO_API_KEY`, `TELEGRAM_BOT_USERNAME`, `INDEXNOW_KEY`, `COMPANY_ID`, and all four `CAREER_R2_*` names are present.
6. Run the smallest relevant automated check for the test touched in step 3, for example the adapter-utils/server-utils Vitest target or package-level test command that covers it.
7. Run operational verification: `node scripts/career-posthog-query.mjs 7` returns data without manual injection, and a Distribution Writer heartbeat no longer reports `DEVTO_API_KEY not available`.

## Verification (QA Verifier checks these)
- [ ] `.env.koenig` contains exactly one `TELEGRAM_BOT_TOKEN`, and the surviving one is in the operator-injected GTM block.
- [ ] A fresh agent subprocess sees `POSTHOG_PERSONAL_API_KEY`, `POSTHOG_PROJECT_ID`, `DEVTO_API_KEY`, `TELEGRAM_BOT_USERNAME`, `INDEXNOW_KEY`, `COMPANY_ID`, and `CAREER_R2_ACCOUNT_ID` / `CAREER_R2_ACCESS_KEY_ID` / `CAREER_R2_SECRET_ACCESS_KEY` / `CAREER_R2_BUCKET` by key presence only.
- [ ] `node scripts/career-posthog-query.mjs 7` returns PostHog data without inline env injection.
- [ ] Distribution Writer no longer emits the `DEVTO_API_KEY not available` blocker.
- [ ] The targeted env inheritance regression test passes.

## Risk
- Restarting Paperclip can interrupt active local agent runs. Mitigation: check for running/queued local runs first, restart during a quiet window, and record any skipped verification if active runs make restart unsafe.

## Out of scope
- No Convex deployment, no unrelated portal changes, no migration of these credentials into Paperclip secrets, and no broad audit of every operator-injected env block beyond the variables listed in KOEA-8129.
