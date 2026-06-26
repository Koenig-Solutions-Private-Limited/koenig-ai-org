---
ticket: KOEA-4800
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
preflight: status_checked=true; chain_alert_resolved=825381fd-10ee-405d-9648-8b757e1e6854; basebranch_verified=true
---

# Plan: Fix stale local-agent JWT on resumed Paperclip sessions

## Goal
Resumed or recovered local-adapter heartbeats must start with a fresh run-scoped `PAPERCLIP_API_KEY` JWT for the current `heartbeat_runs.id`. Success is observable when a continuation/recovery run that resumes an existing local session receives a token whose `run_id` matches the new run and whose `exp` is valid against the API server clock before the adapter process starts.

## Context
- Files to read first: `server/src/services/heartbeat.ts:5520-5602`, `server/src/services/heartbeat.ts:6320-6395`, `server/src/agent-auth-jwt.ts:68-124`, `packages/adapters/codex-local/src/server/execute.ts:376-458`, `packages/adapters/claude-local/src/server/execute.ts:145-231`, `server/src/__tests__/heartbeat-workspace-session.test.ts:415-460`, `server/src/__tests__/agent-auth-jwt.test.ts:1-100`
- Relevant prior work: KOEA-4838 planner handoff noted the plan path but the artifact was missing; KOEA-4839 requested changes until this artifact is republished.
- Constraints: do not change core human auth or long-lived `agent_api_keys`; keep the fix company-scoped through existing agent/company claims; preserve explicit non-JWT `PAPERCLIP_API_KEY` overrides for operators who intentionally configured a static key.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Refresh Paperclip local JWT-shaped explicit API keys before local JWT-capable adapter execution. Add a small JWT inspection helper in `server/src/agent-auth-jwt.ts` that can identify a Paperclip local-agent JWT and report expiry/run/agent/company claims against an injected `now`. In `server/src/services/heartbeat.ts`, after creating the current run token and before `adapter.execute`, validate the new token against the API clock and sanitize the adapter config for `supportsLocalAgentJwt` adapters: replace any explicit `PAPERCLIP_API_KEY` that is a stale, expired, mismatched, or previous-run Paperclip local JWT with the fresh current-run token, while leaving opaque/static non-JWT keys untouched.

**Rejected**: Patch every local adapter's `hasExplicitApiKey` branch individually - duplicates auth policy across Codex, Claude, Cursor, Gemini, Opencode, Pi, and Hermes. **Rejected**: Remove support for explicit `PAPERCLIP_API_KEY` entirely - breaks intentional operator-provided static agent keys and external adapter expectations.

## Steps (Executor follows in order)
1. Extend `server/src/agent-auth-jwt.ts` with an exported inspector such as `inspectLocalAgentJwt(token, { now })` that parses Paperclip JWT claims, verifies signature when possible, and reports `expired`, `runId`, `agentId`, `companyId`, and `adapterType` without accepting expired tokens for authentication.
2. Add focused tests in `server/src/__tests__/agent-auth-jwt.test.ts` proving the inspector flags expired tokens against a fake API clock and still keeps `verifyLocalAgentJwt()` rejecting expired tokens.
3. Add a helper in `server/src/services/heartbeat.ts` near local adapter invocation that validates the freshly created JWT with the API clock and builds an adapter-safe agent config by replacing only Paperclip local-agent JWT-shaped `adapterConfig.env.PAPERCLIP_API_KEY` values when they are expired or do not match the current run/agent/company/adapter.
4. Keep opaque explicit API keys untouched in that helper so existing long-lived `agent_api_keys` and non-Paperclip secrets are not rewritten.
5. Add a regression test in a heartbeat service test, preferably `server/src/__tests__/heartbeat-workspace-session.test.ts` or a new focused heartbeat JWT test, using a mocked `supportsLocalAgentJwt` adapter: seed an agent with an expired previous-run Paperclip JWT in `adapterConfig.env.PAPERCLIP_API_KEY`, invoke a continuation/resume context with a fresh run id, and assert the adapter receives the fresh token whose claims match the current run.
6. Add a companion regression assertion that an opaque explicit key remains unchanged, proving the fix is scoped to stale Paperclip JWTs rather than all explicit credentials.

## Verification (QA Verifier checks these)
- [ ] `pnpm test -- server/src/__tests__/agent-auth-jwt.test.ts`
- [ ] `pnpm test -- server/src/__tests__/heartbeat-workspace-session.test.ts` or the new focused heartbeat JWT test file
- [ ] Manual code review confirms no change to `server/src/middleware/auth.ts` acceptance rules beyond existing JWT verification and no mutation of `agent_api_keys`.

## Risk
- The main risk is incorrectly classifying an operator-provided JWT-like static secret as a Paperclip run JWT. Mitigation: only replace keys whose decoded claims carry the Paperclip local-agent shape (`company_id`, `run_id`, `adapter_type`, expected issuer/audience when present) and only inside `supportsLocalAgentJwt` adapter execution.

## Out of scope
- This plan does not redesign local-agent authentication, rotate secrets, change human session auth, or alter external adapters that do not opt into `supportsLocalAgentJwt`.
