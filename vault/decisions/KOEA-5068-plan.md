---
ticket: KOEA-5068
planner: planner
date: 2026-05-26
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
agent: planner
type: decision
tags:
  - decision
  - engineering
  - research-ops
  - watchdog
---

# Plan: Auto-cancel stale superseded Research daily-synthesis tickets

## Goal
Add a narrow, auditable guard that cancels only blocked Research daily-synthesis work that is stale, clearly superseded by a newer same-cycle successful synthesis output, and backed by an explicit vault evidence path. Success is observable as cancelled stale duplicates with a cancellation comment naming the superseding issue, evidence path, and timestamp, while ambiguous or active work remains open with a triage-request comment.

## Context
- Files to read first: `scripts/koenig-cron-driver.py:1-235`, `server/src/routes/issues.ts:189-205`, `server/src/routes/issues.ts:906-990`, `server/src/routes/issues.ts:1936-2052`, `server/src/services/issues.ts:2110-2225`, `server/src/services/issues.ts:2788-2910`, `packages/db/src/schema/issues.ts:17-120`, `packages/db/src/schema/issue_comments.ts:1-28`
- Research-lane instructions: `agents/08faf10d-cb39-4951-be93-e040c1950828/instructions/AGENTS.md:78-122`, `agents/6e7baea2-1d5e-427d-a085-f0f2bb515a0d/instructions/AGENTS.md:1-22`, `agents/6e7baea2-1d5e-427d-a085-f0f2bb515a0d/instructions/AGENTS.md:112-122`
- Relevant prior work: [KOEA-5068](/KOEA/issues/KOEA-5068) parent acceptance criteria; parent comment `9cbc64e8-3b6b-48cf-9912-57470bacda47` dispatching this Planner phase.
- Constraints: keep this in company-specific automation unless Chief Engineering explicitly approves core changes; do not cancel live tickets during implementation verification; preserve company scoping through `/api/companies/{companyId}/issues` and existing authenticated issue update routes.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extend the Koenig cron/watchdog driver. Add a small daily-synthesis stale guard to `scripts/koenig-cron-driver.py` that runs once per tick before the Chief Engineering wake. It should use the existing company-scoped issues API to find blocked candidates, inspect their comments and labels, require `updatedAt` older than 6 hours, require a same-cycle newer `done` or `in_review` synthesis issue with explicit `vault/research/_daily/<date>.md` or `vault/research/_synthesis/*.md` evidence, and then PATCH the stale issue to `cancelled` with a deterministic audit comment. Ambiguous candidates get a deduped triage comment while remaining `blocked`.

**Rejected**: Paperclip core recovery service - this rule is Research-vault specific and would bake Koenig lane semantics into generic control-plane recovery. **Rejected**: Chief Research prompt-only change - the instructions already mention "if superseded: cancel with reason", but the stale duplicates came from operational gaps and need deterministic automation. **Rejected**: direct database script - bypasses route-level company access, status side effects, activity logs, and active-run cancellation handling.

## Steps (Executor follows in order)
1. In `scripts/koenig-cron-driver.py`, add reusable HTTP helpers for GET/PATCH issue routes and a `run_daily_synthesis_stale_guard(board_token, now)` call from `tick()` after `fire_daily_schedules()`. No-op when `PAPERCLIP_BOARD_TOKEN` is absent.
2. In `scripts/koenig-cron-driver.py`, implement candidate discovery with `/api/companies/{COMPANY_ID}/issues?status=blocked&limit=100&q=daily-synthesis` plus label-based passes for labels whose names include `RESEARCH` or `SYNTHESIS`; dedupe by issue id.
3. In `scripts/koenig-cron-driver.py`, implement pure helper functions for `is_synthesis_candidate`, cycle-date extraction, evidence-path extraction, superseder selection, and triage-comment dedupe. Use only title/description/comments/labels and require `updatedAt < now - 6h`.
4. In `scripts/koenig-cron-driver.py`, for true positives PATCH `/api/issues/{id}` with `{"status":"cancelled","comment":"[daily-synthesis-stale-guard] cancelled: superseded by <identifier>; evidence: <path>; evaluated_at: <UTC timestamp>"}`. For ambiguous candidates PATCH with `{"status":"blocked","comment":"[daily-synthesis-stale-guard] triage requested: <reason>; evaluated_at: <UTC timestamp>"}` so board-authored comments do not implicitly move blocked issues to `todo`.
5. Add `scripts/test_koenig_cron_driver.py` using `unittest` and monkeypatched HTTP helpers to cover true-positive cancellation, active/non-stale false positive, no-evidence false positive, ambiguous multi-match triage, label-based candidate detection, and dedupe behavior.
6. Add a short Chief Research audit runbook note at `vault/decisions/KOEA-5068-runbook.md` with the last-24h audit query: search cancelled issues with `q=daily-synthesis-stale-guard`, inspect cancellation comments for `superseded by`, evidence path, and timestamp, and escalate any ambiguous triage comments still older than 24h.
7. Do not change `server/`, `packages/db/`, or route permissions unless step 4 cannot work through existing issue APIs; if that happens, stop and file a CEO/Chief Engineering approval because it would change core mutation semantics.

## Verification (QA Verifier checks these)
- [ ] `python3 -m unittest scripts/test_koenig_cron_driver.py` passes and includes a fixture where blocked >6h daily-synthesis issue A is cancelled because newer same-cycle issue B is `done` or `in_review` and contains `vault/research/_daily/<date>.md` evidence.
- [ ] False-positive fixtures prove no cancellation for active/non-stale issues, blocked issues without explicit vault evidence, and candidates without a same-cycle terminal-success superseder.
- [ ] The generated cancellation body contains `[daily-synthesis-stale-guard]`, `superseded by <identifier>`, an accepted evidence path, and an ISO UTC evaluation timestamp.
- [ ] The triage path keeps the issue status `blocked` and emits at most one guard triage comment per candidate per 24 hours.

## Risk
- Risk: The issues list API returns description previews, so evidence in a long description may be truncated. Mitigation: fetch candidate and possible superseder details plus comments by id before making any cancellation decision; do not rely solely on list rows for evidence.

## Out of scope
- No production cancellation during planning or unit tests.
- No broad stale-ticket cleanup outside Research daily synthesis.
- No Paperclip core recovery, database schema, route-permission, or generic watchdog changes unless separately approved.

## Pre-flight
- status_checked=true
- sibling_chain_checked=true
- acceptance_criteria_checked=true
- basebranch_verified=true
