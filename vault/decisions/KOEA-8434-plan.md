---
ticket: KOEA-8434
planner: planner
date: 2026-06-15
estimated_complexity: small
estimated_token_cost: $0.30
type: decision
agent: planner
tags:
  - decision
  - engineering
base_branch: master
triggered_by_approval: e93cfa38-4d68-4dd9-9551-0300bb0f2873
---

# Plan: Repair claude_local 401 for Search Visibility Optimizer

## Goal
Restore confidence that Search Visibility Optimizer (`b17b6992-a180-4835-b22d-8dff1e86d615`) can authenticate through `claude_local` before the 2026-06-22 W26 SEO run. Success means a current `claude_local` environment probe and one fresh b17b6992 heartbeat complete without 401, with no secret values exposed in logs, comments, or the vault.

## Context
- Files to read first: `packages/adapters/claude-local/src/server/execute.ts:91-107`, `packages/adapters/claude-local/src/server/execute.ts:145-152`, `packages/adapters/claude-local/src/server/execute.ts:347-353`, `packages/adapters/claude-local/src/server/execute.ts:750-779`, `packages/adapters/claude-local/src/server/test.ts:77-139`, `packages/adapters/claude-local/src/server/test.ts:164-180`, `server/src/routes/agents.ts:969-997`, `server/src/routes/agents.ts:2528-2558`, `server/src/services/secrets.ts:83-132`, `server/src/services/secrets.ts:218-250`, `packages/shared/src/types/secrets.ts:9-23`, `packages/shared/src/validators/agent.ts:34-40`.
- Relevant prior work: KOEA-8417 and KOEA-8418 failed with Claude 401s around 2026-06-15 04:17-04:19 UTC; run `71340c84-38e4-46cd-bc98-6251679b2b0e` shows `api_error_status: 401` and CLI `apiKeySource: "none"`. Later run `73e97be4-1f7c-4f7d-9278-061ce03bb859` for the same agent/session succeeded at 2026-06-15 04:50-04:51 UTC.
- Constraints: do not print or write API keys/OAuth tokens; do not edit source code unless a probe proves adapter behavior is still wrong; use `master` as the verified koenig-ai-org base branch; board-only credential actions must stay with Chief Engineering/board context.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Probe-first operational repair. Treat this as a likely credential/runtime-state issue, not an adapter bug, because b17b6992 has empty `adapterConfig`, no default environment, the failed run surfaced Claude 401s before any task work, and the same agent later succeeded without code changes. Executor should first prove current auth health through the existing adapter test/login/heartbeat surfaces, then change only the minimal config or secret binding if 401 still reproduces.

**Rejected**: Blindly rotate `ANTHROPIC_API_KEY` — the failed run reports `apiKeySource: "none"` and later success means rotation may be unnecessary; patch `claude_local` retry/auth code — current code already distinguishes API-key/subscription/Bedrock paths and includes auth retry handling, so code changes need fresh reproducible evidence; reset all b17b6992 sessions/workspaces — too broad and can discard useful state when a fresh probe may be sufficient.

## Steps (Executor follows in order)
1. Fetch the current b17b6992 agent record with `GET /api/agents/b17b6992-a180-4835-b22d-8dff1e86d615`; confirm `adapterType=claude_local`, inspect only key names/shapes under `adapterConfig.env`, and do not log secret values.
2. Run the board/configuration environment probe for the effective config via `POST /api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment` using the agent's current adapter config; record check codes only, especially `claude_anthropic_api_key_overrides_subscription`, `claude_subscription_mode_possible`, `claude_hello_probe_passed`, or `claude_hello_probe_failed`.
3. If the probe passes, invoke one fresh b17b6992 heartbeat with `forceFreshSession: true` and a small no-op/manual verification payload, then inspect the resulting heartbeat run summary/log for absence of `api_error_status: 401`; do not rotate credentials.
4. If the probe fails with API-key override evidence, have Chief Engineering/board either remove the stale `ANTHROPIC_API_KEY` from `adapterConfig.env` to use subscription auth, or replace it with an `env.secret_ref` to a valid company secret; never persist plaintext or a redacted placeholder.
5. If the probe fails with subscription login required, use the board-only `POST /api/agents/b17b6992-a180-4835-b22d-8dff1e86d615/claude-login` flow and complete Claude login in the same runtime environment; re-run the environment probe after login.
6. If both probe and fresh heartbeat still fail after credential/login repair, then and only then inspect adapter code for a defect in env merging or auth classification and file a narrow follow-up code issue with the failed probe output and run id.
7. Comment on KOEA-8434 with the final diagnosis: current-auth-healthy/no-op, credential rotation/removal, subscription relogin, or adapter bug follow-up; include run ids and check codes, not secrets.

## Verification (QA Verifier checks these)
- [ ] b17b6992 has a post-plan `claude_local` environment probe whose final status is `pass` or whose warnings are explained as intentional.
- [ ] A fresh b17b6992 heartbeat after the probe reaches `succeeded` and its result/log contains no `api_error_status: 401` or `authentication_error`.
- [ ] No API key, OAuth token, credential JSON, or secret material appears in KOEA comments, the plan file, heartbeat logs, or vault artifacts.

## Risk
- The 401 may already be transiently resolved, causing unnecessary credential churn. Mitigation: require a current probe and fresh heartbeat before any credential mutation.

## Out of scope
- Re-running the full W25 SEO report, changing `claude_local` source code without fresh repro, modifying learnovaBeast content, or exposing/recording credential material.
