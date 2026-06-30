---
ticket: KOEA-5480
planner: planner
agent: planner
date: 2026-06-26
type: decision
tags:
  - decision
  - vendor/anthropic
  - billing
estimated_complexity: medium
estimated_token_cost: "$0.35"
status: ready-to-execute
base_branch: master
basebranch_verified: true
preflight_approvals:
  - 0ded7e64-6843-4ec9-bb38-cf36ce9754a3
  - 7c91433f-0882-4e9f-afd0-00d576e3bfc5
---

# Plan: Claude Agent SDK credit quota and docs visibility

## Goal
Make Paperclip's Claude subscription guidance honest after the Agent SDK credit change: operators should see that `claude_local` print-mode runs consume per-user, non-pooled Agent SDK credits when subscription auth is used, that extra usage may take over after the credit is exhausted, and that API-key/Bedrock paths are separate. Success is observable in adapter docs, onboarding guidance, and the Anthropic quota panel without changing billing attribution or provider configuration in this ticket.

## Context
- Files to read first: `vault/decisions/KOEA-2245-claude-agent-sdk-billing-audit.md`, `vault/decisions/KOEA-2245-audit.md`, `packages/adapters/claude-local/src/index.ts:13-38`, `packages/adapters/claude-local/src/server/quota.ts:149-275`, `packages/adapters/claude-local/src/server/quota.ts:481-541`, `server/src/__tests__/quota-windows.test.ts:501-632`, `ui/src/components/ClaudeSubscriptionPanel.tsx:10-139`, `ui/src/components/OnboardingWizard.tsx:239-247`, `ui/src/components/OnboardingWizard.tsx:1000-1021`.
- Relevant prior work: KOEA-2245 audit concluded Paperclip uses Claude Code CLI `--print`, not direct Agent SDK imports, and recommended docs/quota follow-up; KOEA-2256 passed review of that audit. Approval `0ded7e64-6843-4ec9-bb38-cf36ce9754a3` authorized this parallel follow-up chain; approval `7c91433f-0882-4e9f-afd0-00d576e3bfc5` confirmed acceptance criteria and `base_branch=master`.
- Constraints: implementation only; do not change cost ledger semantics, billing type normalization, adapter auth behavior, provider config defaults, or live Anthropic credentials. Keep the touch set to five files or fewer. Base branch is `master` because `origin/master` exists and `origin/main` is absent.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add explicit guidance at the three operator-facing surfaces that already own this concept: the `claude_local` adapter configuration doc, the onboarding environment-check copy, and the Claude quota panel. Extend the existing Anthropic OAuth quota parser only far enough to surface an Agent SDK credit-style window if Anthropic exposes one in the usage payload; otherwise the Claude quota panel must show clear fallback copy that Paperclip only sees normal subscription and extra-usage windows.
**Rejected**: Billing-ledger change - out of scope and belongs to the separate attribution follow-up. **Rejected**: Live Anthropic probing - would spend or expose operator quota and is unnecessary for this docs/UI visibility change. **Rejected**: Broad README/product-doc rewrite - too wide for this ticket; leave public marketing docs unchanged unless Chief Engineering files a separate docs pass.

## Steps (Executor follows in order)
1. Update `packages/adapters/claude-local/src/index.ts` in `agentConfigurationDoc`: add a short "Billing and quota" note explaining that subscription-auth `claude_local` runs use Claude Code `--print`, draw from per-user non-pooled Agent SDK monthly credits where applicable, may move to extra usage or stop when exhausted, and that `ANTHROPIC_API_KEY`/Bedrock use metered API-style paths instead.
2. Update `ui/src/components/OnboardingWizard.tsx` around the Claude adapter environment-check guidance: preserve the existing `ANTHROPIC_API_KEY` override warning, but add concise Claude-only helper copy that recommends API-key auth for shared production automation and subscription auth only when the operator accepts per-user Agent SDK credit limits.
3. Update `packages/adapters/claude-local/src/server/quota.ts`: keep existing five-hour, weekly, and extra-usage windows unchanged; add a narrow parser helper for an Agent SDK credit window only if the OAuth usage response includes a recognizable credit object. Do not invent a required shared type; represent it as the existing `QuotaWindow` with label `Agent SDK credit`, percentage/value label when available, reset detail when available, and no raw payload logging.
4. Update `server/src/__tests__/quota-windows.test.ts`: add parser coverage for the Agent SDK credit-style OAuth payload and a no-bucket case proving existing windows still parse without adding a fake credit row.
5. Update `ui/src/components/ClaudeSubscriptionPanel.tsx`: order `Agent SDK credit` before `Extra usage` when present; when absent, render fallback explanatory copy saying Anthropic has not exposed a separate Agent SDK credit bucket to Paperclip, so this panel shows the available subscription and extra-usage windows only.
6. Run targeted verification: `pnpm --filter @paperclipai/adapter-claude-local test -- quota`, `pnpm --filter @paperclipai/server test -- quota-windows`, and `pnpm --filter @paperclipai/ui typecheck` if available; otherwise run the closest package scripts and report any missing script.

## Verification (QA Verifier checks these)
- [ ] `claude_local` adapter docs mention per-user non-pooled Agent SDK credits, extra-usage behavior, and API-key/Bedrock exclusion.
- [ ] Onboarding guidance distinguishes subscription-auth convenience from API-key production automation and preserves the existing API-key override warning.
- [ ] The Anthropic quota parser surfaces an Agent SDK credit row when the mocked OAuth payload includes one and does not fabricate a row when absent.
- [ ] The Claude quota panel shows the Agent SDK credit row when present and fallback copy when Anthropic exposes only normal subscription/extra-usage windows.

## Risk
- The main risk is guessing Anthropic's private OAuth usage shape. Mitigation: keep parsing defensive and optional, test only explicit fixture shapes, and make the fallback copy truthful when the bucket is not exposed.

## Out of scope
- No billing ledger changes, cost hard-zero changes, live Anthropic quota probes, provider configuration mutations, README rewrite, or production automation policy enforcement.
