---
ticket: KOEA-2351
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
chain_alert_override: 3db30ec1-209e-47e2-b582-64c6fb3a6577
preflight: status_active=true; sibling_guard=approved_override; acceptance_criteria_ok=true; basebranch_verified=true
---

# Plan: Attribute Claude subscription print-mode runs to Agent SDK credits

## Goal
Paperclip should stop presenting `claude_local` subscription-auth `claude --print` heartbeats as ordinary subscription-included usage once Anthropic's 2026-06-15 Agent SDK credit policy takes effect. Success means these runs are visibly attributed to Anthropic Agent SDK credits / possible extra usage, while API-key and Bedrock Claude paths remain metered API-style paths.

## Context
- Files to read first: `packages/adapters/claude-local/src/server/execute.ts:96-107`, `packages/adapters/claude-local/src/server/execute.ts:493-517`, `packages/adapters/claude-local/src/server/execute.ts:726-744`, `server/src/services/heartbeat.ts:1017-1044`, `server/src/services/heartbeat.ts:4591-4629`, `packages/shared/src/constants.ts:334-341`, `ui/src/lib/utils.ts:79-131`, `ui/src/components/ProviderQuotaCard.tsx:220-327`, `ui/src/components/ClaudeSubscriptionPanel.tsx:54-139`, `packages/adapters/claude-local/src/index.ts:13-38`, `packages/adapters/claude-local/src/server/test.ts:123-138`.
- Relevant prior work: `vault/decisions/KOEA-2245-claude-agent-sdk-billing-audit.md`; Chief Engineering resolved `planner_chain_alert` `3db30ec1-209e-47e2-b582-64c6fb3a6577` and authorized this follow-up plan.
- Constraints: keep the change small and contract-compatible; `cost_events.billing_type` is text and shared `BILLING_TYPES` already includes `credits`, so no DB migration is needed; `origin/main` does not exist in this checkout, so use verified `origin/master` as the base branch.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Reuse the existing `credits` billing type and add Claude-specific attribution in the `claude_local` adapter. Add a small date-gated helper so subscription-auth print-mode runs on or after 2026-06-15 return `billingType: "credits"` and a distinct biller such as `anthropic_agent_sdk`, while Bedrock keeps `metered_api` / `aws_bedrock` and `ANTHROPIC_API_KEY` keeps API billing. This preserves current ledger contracts because heartbeat already normalizes `credits` without hard-zeroing it, and the UI can label `anthropic_agent_sdk` as "Anthropic Agent SDK".

**Rejected**: Add a new `agent_sdk_credit` billing type across shared constants, validators, UI, and tests — more explicit but broader than needed. Add a new cost/credit ledger dimension — more accurate long term, but too large for this ticket. Only update docs/UI copy — cheap, but it leaves runtime cost events misclassified as `subscription_included`.

## Steps (Executor follows in order)
1. Update `packages/adapters/claude-local/src/server/execute.ts` to replace `resolveClaudeBillingType` with a helper that resolves both `billingType` and `biller`, date-gated at `2026-06-15T00:00:00Z`; use it in the returned `AdapterExecutionResult`.
2. Add focused tests in `server/src/__tests__/claude-local-execute.test.ts` or a nearby Claude adapter test covering subscription before the date, subscription on/after the date, `ANTHROPIC_API_KEY`, and Bedrock attribution.
3. Update `ui/src/lib/utils.ts` so `anthropic_agent_sdk` renders as "Anthropic Agent SDK" and `credits` remains a non-zero-visible billing type.
4. Update `ui/src/components/ClaudeSubscriptionPanel.tsx` and, if needed, `ProviderQuotaCard.tsx` copy so the Claude quota panel explains Agent SDK monthly credits, per-user non-pooled limits, extra-usage behavior, and the API-key recommendation for shared production automation.
5. Update `packages/adapters/claude-local/src/index.ts` and `packages/adapters/claude-local/src/server/test.ts` guidance so adapter docs/onboarding distinguish subscription Agent SDK credits from Developer Platform API keys and Bedrock.
6. Run the smallest targeted checks: Claude adapter tests, quota/UI utility tests if touched, then `pnpm --filter @paperclipai/adapter-claude-local test` or the closest existing package/test command available.

## Verification (QA Verifier checks these)
- [ ] A simulated post-2026-06-15 `claude_local` run without `ANTHROPIC_API_KEY` or Bedrock records `billingType: "credits"` and a visible Agent SDK biller, not `subscription_included`.
- [ ] Simulated `ANTHROPIC_API_KEY` and Bedrock runs remain classified as metered/API billing and are not described as receiving subscription Agent SDK credits.
- [ ] The Costs/Provider quota UI or Claude adapter docs explain Agent SDK credit limits, per-user non-pooling, extra-usage behavior, and recommend Developer Platform API keys for shared production automation.

## Risk
- Anthropic may change the OAuth usage response shape for Agent SDK credits; mitigate by not depending on undocumented response fields for the core attribution, and keep any quota-panel wording static unless the field is present.

## Out of scope
- No historical cost-event migration, no new DB columns, no live Anthropic billing dashboard integration, and no attempt to infer whether a specific run consumed included Agent SDK credit versus paid extra usage unless the Claude CLI/API exposes that distinction.
