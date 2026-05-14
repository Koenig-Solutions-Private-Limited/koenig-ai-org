---
ticket: KOEA-2355
parent_ticket: KOEA-2355
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
preflight: status_passed=true, active_siblings=0, acceptance_criteria_passed=true, basebranch_verified=true
---

# Plan: classify opencode failure spike and fix empty Watchdog signatures

## Goal
Decide whether the `opencode_local` spike needs operational mitigation, adapter normalization, or Watchdog signature remediation. Success means the current incident is classified without restarting working agents, and any follow-up implementation produces non-empty failure signatures for future Watchdog spike tickets.

## Context
- Files to read first: `packages/adapters/opencode-local/src/server/parse.ts:1-90`, `packages/adapters/opencode-local/src/server/execute.ts:450-510`, `server/src/services/heartbeat-stop-metadata.ts:76-95`, `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md:55-88`
- Relevant prior work: KOEA-2343 Watchdog Bot run `c82589f2-8c84-406f-9b16-a6dcb6fbe11e` created KOEA-2355 from its Check 5 failure-spike SQL; KOEA-2355 Chief Engineering comment at `2026-05-14T09:11:00Z` confirms the opencode operational spike had recovered.
- Constraints: this planning ticket must make no code changes; future production-core code changes would require normal Chief Engineering routing and PR review, but this plan prefers a Watchdog operational-script/instruction fix that does not modify Paperclip core.

## Evidence
| Run ID | Agent | Time UTC | Status | Signature available in run data | Classification |
|---|---|---:|---|---|---|
| `c9b25b96-a65b-4d5f-bae0-074c24b01677` | Course Author | 06:01:03 | failed | `Error: Error code: 401 - {'error': {'message': 'User not found.', 'code': 401}}` | transient auth/provider incident |
| `d8eafebb-7418-497c-991a-f7ea57861fb1` | Course Author | 06:01:11 | failed | same 401 `User not found` | transient auth/provider incident |
| `47337422-10af-4a7e-a514-291c3c069407` | Course Author | 06:01:16 | failed | same 401 `User not found` | transient auth/provider incident |
| `77394b24-07cb-42d2-ab96-617172a31cf4` | Course Author | 06:06:35 | failed | same 401 `User not found` | transient auth/provider incident |
| `571b409d-16c0-4c25-9fad-584472642b60` | Course Author | 06:07:05 | succeeded | n/a | operational recovery |
| `51e0e8ba-bfd3-4118-8b54-b1c71fdd353d` | Course Author | 06:44:27 | failed | `Process lost -- child pid 77770 is no longer running; retrying once` | process loss, recovered later |
| `940187f8-e1bc-491d-872b-ff544afa37ad` | Course Author | 06:52:56 | failed | `{"code":400,"message":"Provider returned error","metadata":{"error_type":"invalid_request"}}` | provider 400, recovered later |
| `9f7f0828-d133-402d-9cc8-43e4ca93a753` | Course Author | 06:58:42 | succeeded | n/a | operational recovery |
| `fa195beb-f035-4bff-8cf5-181e27927c14` | Course Author | 08:11:08 | failed | `[Google AI Studio] Corrupted thought signature.` | separate provider incident |
| `d4af83d8-883f-4588-a937-f1fde6e934e7` | Course Author | 08:18:38 | succeeded | n/a | post-provider recovery |
| `8b7dae05-be19-439b-b203-1b56a4bdf110` | Course Author | 08:21:27 | succeeded | n/a | post-provider recovery |
| `3444ffa3-0e87-48a5-bbac-4763d1d9fe9d` | Course Author | 08:40:12 | succeeded | n/a | post-provider recovery |
| `e6e94830-c73c-4c52-ac75-11c666874825` | Course Author | 09:06:32 | succeeded | n/a | current recovery |
| `66ba62b3-b3bb-4ae9-b7a6-f5827ecdba59` | Course Author | 09:09:37 | succeeded | n/a | current recovery |
| `e59d5ed2-12f7-4621-a709-c5f16d223b3c` | Course Author | 09:10:52 | running | n/a | active surface healthy |

The Watchdog Bot run log shows the live Check 5 SQL used `left(coalesce(hr.error, hr.stderr_excerpt, hr.error_code, 'unknown'), 60)` while also selecting rows with `hr.exit_code IS NOT NULL`. That allows empty-string `hr.error` or `hr.stderr_excerpt` values to become the grouping signature before `error_code` is considered, which explains KOEA-2355's `hitting ""` title even though individual run errors contain usable text. The current Watchdog Bot instructions already document the safer query using `NULLIF(..., '')`; the failure is that the live heartbeat generated or reused a stale SQL block instead of executing the instruction literally.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Harden Watchdog Check 5 as an operational Watchdog fix. Move or wrap the failure-spike query so Watchdog Bot executes the exact `NULLIF`-based signature extraction, filters to `hr.status='failed'`, and records a fallback `unknown_failure` only when all fields are genuinely blank. This addresses the observed empty-signature alert without touching working opencode agents or Paperclip core.

**Rejected**: Adapter normalization in `packages/adapters/opencode-local` because the failed run rows already contain meaningful `error` values and opencode recovered without adapter changes; Paperclip core heartbeat schema changes because this is not a storage problem; no-op transient incident because the operational spike cleared, but the telemetry bug will keep producing low-quality incident tickets.

## Steps (Executor follows in order)
1. Confirm the current Watchdog Bot instructions still contain the exact Step 4 signature-normalization contract under Check 5: `LEFT(COALESCE(NULLIF(BTRIM(hr.error), ''), NULLIF(BTRIM(hr.stderr_excerpt), ''), NULLIF(BTRIM(hr.error_code), ''), NULLIF(BTRIM(hr.result_json->>'error'), ''), 'unknown_failure'), 60)`.
2. Inspect the latest Watchdog Bot run log for Check 5 and verify whether it still emits the stale `COALESCE(hr.error, hr.stderr_excerpt, hr.error_code, 'unknown')` query.
3. Replace the live Check 5 execution path with a deterministic helper script or exact pasted SQL block that cannot be rewritten from memory; keep it in the Watchdog Bot operational surface, not in `opencode_local`.
4. Use this signature expression: `LEFT(COALESCE(NULLIF(BTRIM(hr.error), ''), NULLIF(BTRIM(hr.stderr_excerpt), ''), NULLIF(BTRIM(hr.error_code), ''), NULLIF(BTRIM(hr.result_json->>'error'), ''), 'unknown_failure'), 60)`.
5. Preserve the 4-hour duplicate cooldown and Chief Engineering owner routing, but include the top 3 matching run IDs in each alert description so future triage can verify the grouped signature quickly.
6. Run the Check 5 query against the current database and confirm it no longer returns empty signatures for `opencode_local` or `codex_local`; do not wake or restart Course Author unless Chief Engineering separately asks.
7. If the implementation would move this into Paperclip core server code instead of Watchdog Bot operational code, stop and file a board/Chief Engineering approval before editing core.

## Verification (QA Verifier checks these)
- [ ] Re-running the Check 5 SQL for the last hour returns no row where `signature = ''`.
- [ ] A forced/local dry run over the KOEA-2355 evidence window groups Course Author failures under `Error: Error code: 401`, `Process lost -- child pid`, `{"code":400,"message":"Provider returned error"`, or `[Google AI Studio] Corrupted thought signature.`, never an empty string.
- [ ] No `packages/adapters/opencode-local` source changes are present unless new evidence shows missing adapter errors in `heartbeat_runs`.
- [ ] The parent KOEA-2355 can be unblocked with operational status "recovered" plus telemetry follow-up owner "Executor on Watchdog Bot operational surface".

## Risk
- Watchdog Bot may continue generating ad hoc SQL despite corrected instructions. Mitigation: Executor should make Check 5 deterministic by using a helper script or exact copied SQL, and QA should verify the next Watchdog Health heartbeat summary after implementation.

## Out of scope
- Restarting Course Author or Voice Producer, changing model/provider credentials, modifying Paperclip core heartbeat storage, or changing opencode adapter parsing without new evidence that adapter errors are missing from persisted run rows.
