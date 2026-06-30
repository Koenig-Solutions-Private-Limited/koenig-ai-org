---
ticket: KOEA-5481
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: origin/master
preflight:
  status_ok: true
  sibling_count: 2
  acceptance_criteria_ok: true
  basebranch_verified: true
---

# Plan: Claude production automation config guidance

## Goal
Document and surface the operator guidance from the Claude billing audit so shared production automation uses `ANTHROPIC_API_KEY` / Developer Platform billing by default. Success means operators can still choose subscription-auth `claude_local` deliberately for personal or low-volume use, but Paperclip no longer nudges production/shared automation toward a per-user subscription credit path without warning.

## Context
- Files to read first: `vault/decisions/KOEA-2245-claude-agent-sdk-billing-audit.md:1-96`, `vault/decisions/KOEA-2245-audit.md:1-75`, `packages/adapters/claude-local/src/index.ts:13-38`, `packages/adapters/claude-local/src/server/test.ts:123-138`, `ui/src/components/OnboardingWizard.tsx:239-247`, `ui/src/components/OnboardingWizard.tsx:1000-1020`, `doc/DOCKER.md:124-148`
- Relevant prior work: [KOEA-2256](/KOEA/issues/KOEA-2256) PASS review confirmed the audit is code-path accurate and actionable; [approval e87786ef-6475-4b14-9230-2c371654e960](/KOEA/approvals/e87786ef-6475-4b14-9230-2c371654e960) approved `origin/master` as the base branch.
- Constraints: do not implement billing-ledger attribution or quota-panel credit visibility here; keep the change under five files and below the ticket-split threshold; do not add new vendor claims beyond the audited Anthropic source summary.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Update the existing operator-facing guidance surfaces that already explain Claude auth mode: the adapter configuration doc, adapter environment diagnostics, onboarding retry copy, and Docker/operator docs. This is the smallest path that changes what operators see before configuring shared automation, while reusing current warning/result plumbing instead of adding new product surfaces.

**Rejected**: Change ledger billing types in `server/src/services/heartbeat.ts` because that is the sibling billing-attribution follow-up, not guidance. Rejected: add Agent SDK credit buckets to `ClaudeSubscriptionPanel` or quota parsing because that is the sibling quota/docs visibility follow-up and depends on provider payload availability.

## Steps (Executor follows in order)
1. Branch from `origin/master`, then re-read the context files above plus `server/src/__tests__/claude-local-adapter-environment.test.ts:29-157` before editing.
2. Update `packages/adapters/claude-local/src/index.ts` so `agentConfigurationDoc` has an "Auth and billing guidance" note: `ANTHROPIC_API_KEY` / Developer Platform billing is recommended for shared production automation; subscription-auth `claude_local` is per-user and should be treated as personal or low-volume automation after 2026-06-15.
3. Update `packages/adapters/claude-local/src/server/test.ts` diagnostics without changing check codes: when `ANTHROPIC_API_KEY` is present, say this is API-key mode and is recommended for shared production automation; when absent, say subscription auth may use per-user Claude Agent SDK credit / extra usage and should be intentional.
4. Update `ui/src/components/OnboardingWizard.tsx` copy around the `claude_anthropic_api_key_overrides_subscription` result so it no longer presents unsetting `ANTHROPIC_API_KEY` as the normal fix for production/shared use; make the copy say to clear it only when intentionally using personal subscription auth.
5. Update `doc/DOCKER.md` near the Claude/Codex local adapter API-key section to state that containers or shared deployments should pass `ANTHROPIC_API_KEY` for predictable Developer Platform billing, while logged-in subscription auth is local/personal.
6. Update `server/src/__tests__/claude-local-adapter-environment.test.ts` to assert the new diagnostic wording or hints for API-key and subscription-auth modes; add a narrow UI text test only if an existing onboarding test already renders this warning path cleanly.
7. Run the smallest relevant checks: `pnpm test:run -- claude-local-adapter-environment`, then `pnpm --filter @paperclipai/ui typecheck` if `OnboardingWizard.tsx` changed.

## Verification (QA Verifier checks these)
- [ ] Environment diagnostics explain both modes correctly: API-key mode is recommended for shared production automation; subscription mode is deliberate personal/per-user usage.
- [ ] Onboarding no longer nudges production/shared operators to unset `ANTHROPIC_API_KEY` without context.
- [ ] Docker/operator docs mention `ANTHROPIC_API_KEY` as the shared/container production path and leave subscription auth scoped to local/personal use.
- [ ] Targeted server test and UI typecheck from step 7 pass, or any inability to run them is reported with the exact reason.

## Risk
- Operators who intentionally use subscription auth may read the warning as a prohibition. Mitigation: keep the copy explicit that subscription-auth `claude_local` remains allowed for personal or low-volume automation, but should be intentional.

## Out of scope
- Billing ledger semantics for post-credit overage, `subscription_included` cost suppression, provider quota UI buckets for Agent SDK credits, live Claude billing-dashboard probing, and any change to default adapter selection.
