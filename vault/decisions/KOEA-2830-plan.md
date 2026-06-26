---
ticket: KOEA-2830
planner_ticket: KOEA-3671
planner: planner
date: 2026-05-17
estimated_complexity: medium
estimated_token_cost: $0.45
approval_override: 535e84b3-07a1-4c6d-89ed-f5af1f6c7bb4
base_branch: master
basebranch_verified: true
---

# Plan: scoped Publish Verifier result-write path

## Goal
Publish Verifier can record a structured G5 PASS/BLOCK with L0-L4 check results on the source issue after live-site verification. Success means the source issue keeps normal ownership and status semantics, generic cross-issue `PATCH /api/issues/:id` remains denied for peer agents, and the verifier has one auditable least-privilege write path.

## Context
- Files to read first: `server/src/routes/issues.ts:563-641`, `server/src/routes/issues.ts:1923-2298`, `server/src/routes/issues.ts:3348-3492`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:358-472`, `packages/db/src/schema/issues.ts:21-63`, `packages/shared/src/validators/issue.ts:133-186`, `packages/shared/src/types/issue.ts:240-300`, `packages/shared/src/constants.ts:504-514`, `companies/learnova-academy/skills/verify-publish/SKILL.md:159-206`, `companies/learnova-academy/agents/publish-verifier/AGENTS.md:76-103`.
- Relevant prior work: `vault/decisions/KOEA-1653-plan.md` proposed a narrow G5 exception inside generic PATCH; Chief Engineering reopened KOEA-3671 via approval `535e84b3-07a1-4c6d-89ed-f5af1f6c7bb4` because this is legitimate scoped planning for KOEA-2830.
- Constraints: preserve company scoping, single-assignee ownership, active checkout lock enforcement, activity logging, and the rule that non-assignee agents cannot use generic issue mutation as a cross-issue write channel. Base branch verified: `git ls-remote --heads origin master` returned one row.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a dedicated `POST /api/issues/:id/publish-verifications` endpoint plus persisted issue metadata. The endpoint should run outside the generic update route but reuse the same company access, actor, comment, activity, and run-activity patterns. It accepts only a G5-shaped payload from a same-company agent with a new permission such as `tasks:write_publish_verifications`, writes one structured comment, merges only a whitelisted `metadata.publish_verification` object, records activity, and leaves the source issue status unchanged.

**Rejected**: Grant Publish Verifier `tasks:manage_active_checkouts` because it allows broad intervention in active peer work, not just verification result writes. Reopen verified source issues or make Publish Verifier check them out because G5 is post-publish evidence, not new ownership of the production task. Put the bypass inside generic `PATCH /api/issues/:id` because that makes the normal mutation boundary harder to reason about and repeats the cross-issue write path that correctly failed.

## Steps (Executor follows in order)
1. Add `metadata: jsonb("metadata").$type<Record<string, unknown>>()` to `packages/db/src/schema/issues.ts`, expose `metadata` on `Issue` in `packages/shared/src/types/issue.ts`, and generate the migration with `pnpm db:generate`.
2. Add shared validation for `publishVerification` in `packages/shared/src/validators/issue.ts`: required `verdict: "pass" | "block"`, required ISO `verifiedAt`, required `levels` object for `l0` through `l4` with values `"pass" | "fail" | "skip"`, optional `url`, `evidencePath`, `reason`, and required `idempotencyKey`; reject all other metadata keys.
3. Add permission key `tasks:write_publish_verifications` to `packages/shared/src/constants.ts` and implement `POST /api/issues/:id/publish-verifications` in `server/src/routes/issues.ts`; require same-company agent auth, the new permission grant, source issue status `done`, no closed execution workspace block, and no status/assignee/title/description/blocker/workspace fields in the payload.
4. In the new route, write the result in one transaction or service helper: row-lock/read the issue, no-op if `metadata.publish_verification.idempotency_key` already matches, otherwise merge only `metadata.publish_verification`, add the structured G5 comment with `svc.addComment`-equivalent attribution, sync comment references, call `heartbeat.reportRunActivity`, and log `issue.publish_verification_recorded` with previous verification metadata in `_previous`.
5. Preserve status semantics explicitly: successful writes to `done` issues must not reopen, move to `todo`, release checkout locks, reassign, or trigger assignee wakeups beyond the normal comment/reference side effects already used for closed issues; non-`done` and `cancelled` source issues should return `409` with a clear error.
6. Update `companies/learnova-academy/skills/verify-publish/SKILL.md` and `companies/learnova-academy/agents/publish-verifier/AGENTS.md` to tell Publish Verifier to use the scoped endpoint for its final PASS/BLOCK result instead of generic PATCH/comment mutation on another agent's issue.
7. Extend tests in `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` for the authorized endpoint, rejected peer generic PATCH/comment writes, missing permission, wrong company, non-`done` issue status, invalid level keys, idempotent repeat, and activity/comment attribution.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run --project @paperclipai/server server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts --pool=forks --poolOptions.forks.isolate=true` passes with the new publish-verification route cases.
- [ ] `pnpm -r typecheck` passes after the schema, constants, validators, route, and docs updates.
- [ ] Manual API smoke: a Publish Verifier-like same-company agent with `tasks:write_publish_verifications` can record one G5 PASS/BLOCK on a `done` source issue, the issue remains `done`, `metadata.publish_verification.levels.l0-l4` are present, and a repeat with the same `idempotencyKey` does not create a second comment.
- [ ] Negative smoke: the same agent still gets `403` or `409` for generic `PATCH /api/issues/:id` and `POST /api/issues/:id/comments` on another agent's source issue, and cannot change title/status/assignee through the scoped endpoint.

## Risk
- The main risk is creating a second mutation path that bypasses too much existing issue logic. Mitigation: make the route purpose-built, require a new permission, whitelist exactly one metadata object, keep status untouched, and add negative tests proving generic cross-issue mutation remains denied.

## Out of scope
- This plan does not change the live-site G5 checks, publish-action dispatch, `metadata.publish_state` state machine, Learnova academy templates, or broad issue metadata editing. It also does not grant Publish Verifier active-checkout management.
