---
ticket: KOEA-9575
source_planning_ticket: KOEA-9584
republish_ticket: KOEA-9590
planner: planner
date: 2026-06-29
estimated_complexity: medium
estimated_token_cost: $0.46
status: ready-to-execute
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_authorization: f3926fd6-d472-42c9-b33c-15b479d6b813
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 spec_source=issue_required_plan_output chain_depth=3_authorized_by_chief republished_from_KOEA-9590 basebranch_verified=true"
---

# Plan: Career API status counters without R2 status JSON

## Goal
Expose a small, authenticated live status surface for Career Courses WBR counters from `learnova-tc`. Success means WBR can read enrollment, progress, and certificate counters from `https://academy.koenig-solutions.com/api/admin/status` without enabling Convex HTTP actions publicly, committing secrets, or depending on a stale R2 `admin/status.json` object.

## Context
- Files to read first: `learnova-tc/convex/schema.ts:265-304`, `learnova-tc/convex/enrollments.ts:124-149`, `learnova-tc/convex/enrollments.ts:187-315`, `learnova-tc/convex/lessonProgress.ts:16-36`, `learnova-tc/convex/lessonProgress.ts:64-173`, `learnova-tc/src/app/api/students/[id]/courses/route.ts:6-23`, `learnova-tc/src/app/api/students/[id]/courses/route.ts:51-70`
- Relevant prior work: Chief Engineering probe on 2026-06-29 found Convex deployment URLs and academy `/api/status` paths returning 404/no GET, plus no committed `admin/status.json`; chain-depth alert `ee74600c-e3a5-44b3-b6b8-c804c08398c6` was unblocked by Chief Engineering comment `f3926fd6-d472-42c9-b33c-15b479d6b813`.
- Constraints: implementation must use `learnovaBeast` / `learnova-tc` only; base branch `academy/redesign-v1` is verified; do not deploy Convex from any other portal; do not touch student/sales/admin app code; keep endpoint secrets out of vault, code, and comments.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add an authenticated Next.js GET route backed by a narrow Convex aggregate query. Create one read-only Convex query for status counters and one `learnova-tc/src/app/api/admin/status/route.ts` that validates a bearer token from an env var, calls Convex with `ConvexHttpClient`/`makeFunctionReference`, and returns non-PII JSON. This uses the existing server-side Convex route pattern, avoids enabling Convex HTTP actions for public access, and gives WBR a stable URL on the academy domain.

**Rejected**: Use existing Convex query path only - rejected because current queries require app/session context, expose enriched per-user/per-course records, and are not directly reachable by WBR; add Convex `httpAction`/router - rejected because the deployment currently reports HTTP actions disabled and this would widen Convex deployment surface for one read-only report; publish R2 `admin/status.json` - rejected because no generator exists and static JSON would become stale unless a separate job is added.

## Steps (Executor follows in order)
1. Create a fresh implementation branch/worktree from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` at `origin/academy/redesign-v1`, scoped to `learnova-tc` only.
2. Add `learnova-tc/convex/status.ts` with a `getCareerApiStatus` query that returns only aggregate counts: total enrollments, enrollment status breakdown, lesson progress status breakdown, completed lesson progress count, certificates issued count, and timestamp-window counts where existing fields support them.
3. Keep counter semantics explicit: enrollments are feasible from `enrollments.enrolledAt/status`; progress is feasible from `lessonProgress.status/completedAt/lastAccessedAt`; certificates are feasible from `enrollments.certificateId/certificateIssuedAt`; any "approval" wording must map to progress completion records unless Chief Engineering supplies a separate approval table.
4. Add `learnova-tc/src/app/api/admin/status/route.ts` as `GET` only, requiring `Authorization: Bearer $CAREER_STATUS_TOKEN` or equivalent server-only env var, returning 401 on missing/mismatch and returning JSON shaped for WBR: `{ ok, generatedAt, source, counters }`.
5. Do not add or deploy `admin/status.json` to R2; update any WBR source-table notes in the handoff to use `/api/admin/status` and mark R2 status JSON formally de-scoped for KOEA-9575.
6. Verify locally with `npm run type-check`, `npm run lint`, a missing-token GET returning 401, and an authorized GET in an environment with `NEXT_PUBLIC_CONVEX_URL` plus the new server token returning aggregate JSON with no user emails, names, or IDs.
7. After code review approval, deploy Convex only from `learnova-tc`, then verify `https://academy.koenig-solutions.com/api/admin/status` with the configured bearer token; do not touch student/sales/admin/tc-adjacent portals outside this plan.

## Verification (QA Verifier checks these)
- [ ] `GET /api/admin/status` without the configured bearer token returns 401 and does not leak counters.
- [ ] Authorized `GET /api/admin/status` returns 200 JSON with `ok: true`, `generatedAt`, `source: "learnova-tc/convex"`, and aggregate enrollment/progress/certificate counters only.
- [ ] `npm run type-check` and `npm run lint` pass from `learnova-tc`.
- [ ] G_code confirms the PR touches only `learnova-tc/convex/status.ts`, the new API route, and any required generated/type artifacts; no secrets or PII are committed.
- [ ] G2 verifies the academy production URL with the configured token after Convex deployment from `learnova-tc`.

## Risk
- Full-table aggregate scans may become expensive if Career data grows quickly because current timestamp fields are not indexed for WBR windows. Mitigation: keep KOEA-9575 to coarse aggregate counters now and open a follow-up ticket for indexed daily rollups if the query approaches Convex limits.

## Out of scope
- R2 object generation, static `admin/status.json`, public unauthenticated status endpoints, WBR dashboard UI, new approval-domain modeling, and any code changes outside `learnova-tc`.
