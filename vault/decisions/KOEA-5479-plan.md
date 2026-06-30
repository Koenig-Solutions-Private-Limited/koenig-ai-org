---
ticket: KOEA-5479
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
chain_authorization_approval: 0ded7e64-6843-4ec9-bb38-cf36ce9754a3
---

# Plan: Claude billing attribution after Agent SDK credits

## Goal
Distinguish post-2026-06-15 `claude_local` subscription print-mode runs from ordinary `subscription_included` ledger treatment. Success means Claude CLI `--print` subscription runs can show Agent SDK credit consumption or paid subscription overage in existing cost events and UI, while API-key and Bedrock paths keep their current metered behavior.

## Context
- Files to read first: `packages/adapters/claude-local/src/server/execute.ts:104`, `packages/adapters/claude-local/src/server/execute.ts:497`, `packages/adapters/claude-local/src/server/execute.ts:742`, `server/src/services/heartbeat.ts:1017`, `server/src/services/heartbeat.ts:1041`, `server/src/services/heartbeat.ts:4591`, `packages/adapter-utils/src/types.ts:36`, `packages/shared/src/constants.ts:334`, `ui/src/lib/utils.ts:79`, `ui/src/pages/Costs.tsx:752`, `ui/src/components/ProviderQuotaCard.tsx:220`.
- Relevant prior work: `vault/decisions/KOEA-2245-claude-agent-sdk-billing-audit.md`, `vault/decisions/KOEA-2245-audit.md`, and KOEA-2256 PASS review.
- Constraints: no production implementation in this planning ticket; keep the implementation under 5 touched files; do not add a migration unless the existing text `cost_events.billing_type` field and existing shared billing enum cannot support the behavior; base branch verified with `git ls-remote --heads origin master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Adapter-side reclassification using existing billing types. Add a Claude-local helper that maps subscription-auth `claude --print` results after 2026-06-15 to `credits` when the run consumed token usage with no positive CLI cost, and to `subscription_overage` when the CLI reports a positive `total_cost_usd`; leave pre-2026-06-15 subscription runs as `subscription`. This uses the already-supported adapter/server/shared values (`credits`, `subscription_overage`, `subscription_included`) and lets existing heartbeat cost event creation, cost rollups, and cost UI show the distinction without a database migration.

**Rejected**: Add new billing types such as `agent_sdk_credit` and `agent_sdk_overage` - clearer labels, but it forces shared API, validator, UI, and likely test churn beyond the ticket size. **Rejected**: Add new `cost_events` columns for credit bucket metadata - more expressive, but migration-heavy and better reserved for the separate quota/docs visibility ticket. **Rejected**: Server-only remapping of all Claude subscription runs - too broad because the server cannot reliably know that a subscription result came from Claude CLI print mode rather than another adapter's subscription path.

## Steps (Executor follows in order)
1. Update `packages/adapters/claude-local/src/server/execute.ts` to add a small exported helper, for example `resolveClaudeLedgerBillingType({ authBillingType, costUsd, now })`, with a UTC constant for `2026-06-15T00:00:00.000Z`.
2. In `packages/adapters/claude-local/src/server/execute.ts`, keep `api` and `metered_api` unchanged, keep subscription runs before the cutoff as `subscription`, and after the cutoff return `subscription_overage` when parsed CLI cost is positive, otherwise `credits`.
3. Add focused unit coverage for that helper in a new or existing Claude-local server test file, covering API key, Bedrock, pre-cutoff subscription, post-cutoff zero-cost credit, and post-cutoff positive-cost overage cases.
4. Confirm `server/src/services/heartbeat.ts` needs no production change because it already maps `credits` and `subscription_overage` without forcing cost to zero; add or update a narrow test only if existing coverage does not prove positive `subscription_overage`/`credits` costs persist into `cost_events`.
5. Confirm `packages/shared/src/constants.ts`, `packages/shared/src/validators/cost.ts`, `packages/db/src/schema/cost_events.ts`, and UI display paths need no schema/API changes because the required billing types already exist; only adjust `ui/src/lib/utils.ts` labels if reviewers insist that generic "Credits" is too vague.
6. Run the smallest verification first: targeted Claude adapter tests and any touched heartbeat/cost tests; then run `pnpm -r typecheck` if shared type boundaries were touched.

## Verification (QA Verifier checks these)
- [ ] A post-2026-06-15 `claude_local` subscription-auth `--print` result with token usage and `total_cost_usd` absent or zero produces a cost event with `billingType: "credits"`, not `subscription_included`.
- [ ] A post-2026-06-15 `claude_local` subscription-auth `--print` result with positive `total_cost_usd` produces `billingType: "subscription_overage"` and non-zero `costCents`.
- [ ] `ANTHROPIC_API_KEY` and Bedrock-authenticated Claude runs still normalize to metered API billing and are not treated as Agent SDK credits.
- [ ] Costs UI by-agent/model/provider views display the new classification through existing billing-type labels without hiding paid overage cost.

## Risk
- Anthropic may not expose enough CLI signal to prove whether a zero-cost post-cutoff run consumed Agent SDK credit versus another subscription bucket. Mitigation: use the documented date/auth/print-mode conditions and keep quota-bucket details out of scope for this ticket.

## Out of scope
- No Anthropic OAuth quota-window UI for Agent SDK monthly credit buckets.
- No production automation guidance or operator warning copy.
- No direct Claude Agent SDK package integration.
- No billing dashboard scrape or live spend probe.

## Pre-flight
- ticket_status_checked=true
- assignee_verified=true
- chain_depth_authorized=true
- acceptance_spec_checked=true
- basebranch_verified=true
