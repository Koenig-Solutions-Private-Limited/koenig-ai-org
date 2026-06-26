---
ticket: KOEA-5008
source_planning_ticket: KOEA-5093
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: master
preflight: status_passed=true, active_siblings=0, chain_depth=2, acceptance_criteria_passed=true, basebranch_verified=true
---

# Plan: stop false Watchdog unknown_failure spike alerts

## Goal
Eliminate the false `unknown` / `unknown_failure` Watchdog spike caused by counting non-failed heartbeat runs as failures. Success means Watchdog Check 5 only alerts on true `heartbeat_runs.status = 'failed'` rows, preserves adapter/source identity in API fallback mode, and future alerts include enough evidence for Chief Engineering to triage without re-querying from scratch.

## Context
- Files to read first: `server/src/routes/agents.ts:2560`, `server/src/services/heartbeat.ts:7358`, `packages/shared/src/types/heartbeat.ts:11`, `server/src/__tests__/heartbeat-list.test.ts:1`, `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md:70`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:61`.
- Relevant prior work: `vault/decisions/KOEA-2355-plan.md` already identified Watchdog signature hardening as the right surface for empty/low-quality spike alerts; [KOEA-5008](/KOEA/issues/KOEA-5008) was created by Watchdog Bot run `17289227-8e37-4f05-90e4-679040d27257`.
- Constraints: Planner must not implement; target verified `origin/master` because `origin/main` does not exist in this repo; keep the alert company-scoped and do not change adapter execution behavior.
- Evidence: `GET /api/companies/<company>/heartbeat-runs?status=failed&limit=500` currently returns mixed statuses (`succeeded`, `queued`, `running`, `cancelled`) because `server/src/routes/agents.ts` ignores `status`; the response also has `agentId` but no `agent.adapterType` or flat `adapterType`, so Watchdog fallback classifies rows as `unknown`.
- Root-cause hypotheses: primary is API status-filter drift; secondary is missing adapter metadata in list response; tertiary is Watchdog Bot generating an API fallback despite its instructions containing the correct SQL. Direct DB cross-check found no current 1h failed spike and only 1 true failed row in the 11:22-12:23 UTC window around the alert, so this was a false positive.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the heartbeat-run list contract and pin Watchdog fallback to that contract. Add `status` filtering and flat `adapterType` / `agentName` fields to the company heartbeat-run listing, update the shared type/API helper as needed, and make Watchdog instructions explicitly treat the API fallback as valid only when it returns failed rows with adapter metadata.

**Rejected**: DB-only Watchdog script fix because the current false positive happened when Watchdog could not or did not use the SQL path, so the fallback would remain unsafe; adapter-specific fixes because there is no evidence of a codex/opencode/provider failure spike in persisted run rows; closing [KOEA-5008](/KOEA/issues/KOEA-5008) as noise because the telemetry bug would keep recreating low-quality incidents.

## Steps (Executor follows in order)
1. Update `server/src/routes/agents.ts` to parse an optional `status` query parameter for `/api/companies/:companyId/heartbeat-runs`, validating it against `HEARTBEAT_RUN_STATUSES` and returning `400` for unsupported values.
2. Update `server/src/services/heartbeat.ts` so `heartbeat.list(companyId, agentId, limit, status?)` applies the status filter and joins/selects agent metadata needed by API fallback consumers: at least flat `adapterType` and `agentName`.
3. Update `packages/shared/src/types/heartbeat.ts` and `ui/src/api/heartbeats.ts` only as needed so the list API can request `status` and type the optional metadata without breaking existing agent-detail UI consumers.
4. Add focused tests in `server/src/__tests__/heartbeat-list.test.ts` for status filtering, ignored nonmatching statuses, and returned `adapterType` / `agentName`.
5. Update the Watchdog Bot source instructions in `companies/learnova-academy/agents/watchdog-bot/SOUL.md` so Check 5 says API fallback must call `status=failed`, verify every returned row has `status === "failed"`, and prefer `adapterType` before falling back to `unknown`.
6. Run the smallest verification: targeted heartbeat-list tests, then a local `curl` against `/api/companies/$PAPERCLIP_COMPANY_ID/heartbeat-runs?status=failed&limit=500` to confirm all returned rows are failed and include adapter metadata.
7. Handoff follow-ups: Code Reviewer reviews the API contract/test diff; QA Verifier replays the Watchdog fallback over the [KOEA-5008](/KOEA/issues/KOEA-5008) evidence window and confirms it produces zero `unknown/unknown_failure` spike alerts.

## Verification (QA Verifier checks these)
- [ ] `pnpm --filter @paperclipai/server test -- heartbeat-list` passes, including status-filter and adapter-metadata cases.
- [ ] `curl "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/heartbeat-runs?status=failed&limit=500"` returns only rows with `status: "failed"`.
- [ ] The same curl response includes `adapterType` or nested equivalent for each row; Watchdog fallback no longer reports adapter `unknown` when the run's agent exists.
- [ ] Replaying the Watchdog Check 5 fallback over the [KOEA-5008](/KOEA/issues/KOEA-5008) alert window does not produce `unknown` hitting `unknown_failure` with 156 failures.
- [ ] A direct SQL cross-check of `heartbeat_runs` for the same window matches the API fallback counts.

## Risk
- The heartbeat list endpoint may have UI consumers that assume the current unfiltered shape. Mitigation: keep new fields additive, make `status` optional, and preserve the default unfiltered list behavior when no status query is provided.

## Out of scope
- Changing adapter execution, restarting agents, modifying provider credentials, closing unrelated Watchdog Health tickets, or replacing the entire Watchdog routine system.
