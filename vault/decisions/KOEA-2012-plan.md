---
ticket: KOEA-2012
planner: planner
planner_issue: KOEA-2016
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.55
base_branch: master
basebranch_verified: true
triggered_by_approval: 32e4a067-dec9-4b50-a3cc-f5bfdb1c5f89
---

# Plan: Fix Hermes adapter crash blocking blog draft workers

## Goal
Restore a live execution path for Hermes-backed content workers so blog draft tasks can run without repeated `adapter_failed` recovery loops. Success means the Hermes failure is either resolved by a working provider/model configuration or reported with the real upstream credential/model error instead of the generic `Hermes exited with code 1`.

## Context
- Files to read first: `packages/adapters/hermes-local/src/server/execute.ts:125-553`, `packages/adapters/hermes-local/src/server/parse.ts:14-112`, `packages/adapters/hermes-local/src/server/test-environment.ts:165-201`, `server/src/adapters/registry.ts:235-295`, `server/src/services/heartbeat.ts:5564-5813`, `server/src/__tests__/adapter-registry.test.ts:216-389`
- Relevant prior work: failing runs `f07649eb-7864-460e-bdc1-64c5e9cdf42c`, `a50a72d6-751c-4184-a806-4f9eacc36181`, and `1e56b5c1-b939-4db5-a399-ee54dbcd3b5f` on KOEA-1770; Hermes `errors.log` for session `20260513_121610_40e237` shows OpenRouter `401 User not found` and exhausted credential-pool warnings at the same timestamps.
- Constraints: plan approved after `planner_chain_alert` approval `32e4a067-dec9-4b50-a3cc-f5bfdb1c5f89`; do not deploy Convex or touch unrelated portals; keep changes scoped to Paperclip Hermes adapter/config; branch from `origin/master` because `origin/main` does not exist in this repo.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Repair Hermes provider configuration first, then add narrow adapter diagnostics. The observed root cause is not a Paperclip task-state bug: Hermes receives the run, creates/resumes session `20260513_121610_40e237`, then fails its model call because the configured OpenRouter credential is invalid or exhausted. Executor should move affected Hermes content agents to a known-working provider/model or refresh the OpenRouter credential, then patch the adapter so stderr-only Hermes failures surface the matching Hermes log error and do not look like a silent crash.

**Rejected**: Retry every non-zero Hermes exit with a fresh session; this hides credential failures and can double-spend tokens. **Rejected**: Rewrite Hermes as an external-only plugin in this ticket; that belongs to the fork externalization track and is outside this bug. **Rejected**: Change heartbeat recovery semantics; the recovery loop is reacting correctly to an adapter failure.

## Steps (Executor follows in order)
1. Create a worktree/branch from verified `origin/master`: `koea-2012/hermes-crash-diagnostics` in `koenig-ai-org`; leave existing dirty/untracked files alone.
2. Inspect affected agent/run configuration via the API, especially Hermes runs for KOEA-1770 and active `hermes_local` agents, to confirm whether they still use OpenRouter models such as `openai/gpt-5.4` or `claude-sonnet-4-6` with provider `openrouter`.
3. Fix the runtime configuration: refresh the OpenRouter credential if available, or temporarily set affected Hermes content/research agents to a known-working Hermes provider/model from current successful runs, e.g. `provider: "nous"` and `model: "stepfun/step-3.5-flash"`. Do not commit secrets.
4. Patch `packages/adapters/hermes-local/src/server/execute.ts` so non-zero Hermes results with only `session_id` on stderr consult a sanitized, bounded tail of `${HERMES_HOME}/logs/errors.log` for the current Hermes session id and use that line as `errorMessage`/diagnostic context.
5. Add focused tests in `packages/adapters/hermes-local/src/server/parse.test.ts` or a new small helper test file covering session-id-only stderr plus a matching Hermes log line such as `401 User not found`; keep the helper pure and avoid reading real local logs in tests.
6. Verify with `pnpm -C packages/adapters/hermes-local test` and a targeted Hermes environment/run smoke: `hermes --version`, then one Paperclip-triggered Hermes run against a low-risk test issue or KOEA-1770 only after config is fixed.
7. Comment on KOEA-2012 and KOEA-1770 with the real cause, the config/model used for the successful smoke, and the PR or commit link; then let the blocked child chain continue.

## Verification (QA Verifier checks these)
- [ ] A Hermes-backed run no longer fails with only `Hermes exited with code 1`; credential/model failures show the real upstream message such as `401 User not found` or provider exhaustion.
- [ ] `pnpm -C packages/adapters/hermes-local test` passes, including the new diagnostic test.
- [ ] A blog-worker retry or equivalent Hermes smoke run reaches `succeeded` with non-zero output tokens, or explicitly fails with a real credential/model error that names the remaining operator action.
- [ ] KOEA-1770 is unblocked only after the Hermes execution path is actually healthy.

## Risk
- Reading Hermes logs could leak too much local detail if done broadly. Mitigation: only read a small tail of `errors.log`, only match lines containing the current Hermes session id, redact through existing heartbeat error redaction, and never include `.env`, request dumps, prompts, or auth material.

## Out of scope
- Externalizing Hermes into `@henkey/hermes-paperclip-adapter`, changing Convex/deployment flows, rewriting heartbeat recovery, or migrating all blog workers to a different adapter permanently.
