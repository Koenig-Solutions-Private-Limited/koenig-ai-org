---
ticket: KOEA-1803
planner: planner
date: 2026-05-13
estimated_complexity: medium
estimated_token_cost: "$0.32"
base_branch: master
basebranch_verified: true
agent: planner
type: decision
tags:
  - decision
  - paperclip
  - hermes
---

# Plan: diagnose hermes_local failure spike and mitigation path

## Goal
Restore reliable content-agent execution after the `hermes_local` failure spike and make future Hermes provider failures actionable instead of generic `adapter_failed` noise. Success means affected work can continue on the emergency adapter path, while a permanent Paperclip/Hermes fix gives operators a concrete provider/auth/quota diagnosis and preserves existing session-recovery behavior.

## Context
- Files to read first: `packages/adapters/hermes-local/src/server/execute.ts:283-292`, `packages/adapters/hermes-local/src/server/execute.ts:378-390`, `packages/adapters/hermes-local/src/server/execute.ts:500-510`, `packages/adapters/hermes-local/src/server/execute.ts:533-549`, `packages/adapters/hermes-local/src/server/test-environment.ts:92-120`, `server/src/adapters/registry.ts:235-295`.
- Relevant prior work: [KOEA-1803](/KOEA/issues/KOEA-1803), [KOEA-1809](/KOEA/issues/KOEA-1809), [KOEA-1810](/KOEA/issues/KOEA-1810), Chief Engineering authorization comment `840311d3-2fc3-4bac-be03-6044f7c576cb`.
- Evidence: recent failed Blog Author and Content Author runs invoked `hermes chat -q <prompt> -Q --source paperclip -r <session> -m <model> --provider openrouter`; logs show fallback workspace, Hermes resumed-session text, and `session_id`, then exit code 1. KOEA-1809 records direct diagnosis that the OpenRouter key was exhausted with 401. Both affected agents now show `adapterType: claude_local`; Content Author has a subsequent succeeded Claude run.
- Constraints: do not modify Learnova portals; keep company-scoped API boundaries; do not log secrets or raw provider keys; Paperclip core code changes require normal engineering PR review; `origin/main` does not exist in this repo, so this plan targets verified `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Keep the emergency mitigation on `claude_local`, then harden `hermes_local` provider diagnostics. Executor should treat the adapter swap as the immediate mitigation and implement the smallest Paperclip/Hermes code change that turns OpenRouter/auth/quota failures into explicit diagnostics, while leaving normal Hermes session resume and unknown-session fresh-retry behavior intact.

**Rejected**: permanently remove Hermes from content agents — avoids today’s failure but does not fix the adapter or future operators; blindly clear Hermes sessions/retry fresh sessions — the observed failures affect fresh and resumed sessions and KOEA-1809 points to provider exhaustion, so session reset is not the primary fix; make Learnova/content-ticket edits — the root cause is Paperclip adapter/runtime infrastructure, not portal content.

## Steps (Executor follows in order)
1. Confirm mitigation state with API reads only: affected agents `de11bfa2-e63c-462a-8b4b-56c0e5b345a3` and `1f8e653d-1e0b-430e-84f2-a159e8410b86` should remain on `claude_local` until Hermes provider health passes; if not, stop and ask CEO/operator to complete [KOEA-1810](/KOEA/issues/KOEA-1810).
2. Add a small provider diagnostic helper under `packages/adapters/hermes-local/src/server/` that validates configured provider health for `openrouter` without printing secrets; return structured codes such as `hermes_openrouter_auth_failed`, `hermes_openrouter_quota_exhausted`, or `hermes_provider_health_unknown`.
3. Wire that helper into `packages/adapters/hermes-local/src/server/test-environment.ts` after the existing key-presence check so environment tests distinguish “key exists” from “key rejected/exhausted”.
4. In `packages/adapters/hermes-local/src/server/execute.ts`, when Hermes exits non-zero and `firstMeaningfulStderrLine()` is empty, enrich `errorMessage`, `errorCode`, and `resultJson` with provider/model/diagnostic metadata instead of only `Hermes exited with code 1`.
5. Preserve the existing unknown-session retry path in `execute.ts:533-549`; provider-auth/quota failures must not be treated as unknown-session errors and must not clear task sessions.
6. Add focused tests in the Hermes adapter package covering OpenRouter 401/exhausted diagnostics, generic no-stderr exit fallback, and unchanged unknown-session fresh retry behavior.
7. Leave the current `claude_local` mitigation in place until G2 proves Hermes diagnostics and provider health; do not switch content agents back to Hermes inside this implementation PR.

## Verification (QA Verifier checks these)
- [ ] `pnpm -C packages/adapters/hermes-local test` passes, including new provider-diagnostic and exit-code tests.
- [ ] `pnpm -C packages/adapters/hermes-local typecheck` passes.
- [ ] `hermes --version` still succeeds locally and the Hermes adapter environment test reports an explicit OpenRouter auth/quota diagnostic when run with the failing OpenRouter configuration.
- [ ] API run-history check shows no new `adapter_failed` / `Hermes exited with code 1` on Blog Author or Content Author after the Claude mitigation.
- [ ] G_code confirms the diff is limited to Paperclip/Hermes adapter/runtime tests, contains no Learnova portal edits, and redacts all provider secrets.
- [ ] G2 triggers or observes one formerly affected content-agent heartbeat on `claude_local` and confirms the content ticket either progresses or has a non-adapter blocker.

## Risk
- Provider-specific probing can accidentally leak or overfit secret/provider behavior. Mitigation: centralize the diagnostic helper, redact keys in all logs/result JSON, keep provider-specific checks opt-in by configured provider, and fall back to `hermes_provider_health_unknown` when the probe cannot safely classify.

## Out of scope
- Rewriting Hermes session management, changing Learnova portal content, adding automatic adapter failover, or switching agents back from `claude_local` to `hermes_local` before reviewed verification passes.
