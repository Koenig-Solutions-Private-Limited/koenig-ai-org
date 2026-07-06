---
ticket: KOEA-7470
planner: planner
date: 2026-07-01
estimated_complexity: large
estimated_token_cost: $0.46
type: decision
agent: planner
tags:
  - decision
base_branch: master
basebranch_verified: true
target_branch: upgrade/v2026.609.0
upstream_target: v2026.609.0
chain_alert_approval: 6089ecd8-ef91-42a3-896a-f9a01d070185
---

# Plan: Upgrade Koenig Paperclip to v2026.609.0

## Goal
Upgrade the Koenig Paperclip fork from the current `0.3.1` baseline to upstream `v2026.609.0` on branch `upgrade/v2026.609.0`. Success means the upstream fixes and features land while preserving Koenig-only migration state, Hermes behavior, recovery dampening, and production compose settings.

## Context
- Files to read first: `packages/db/src/migrations/meta/_journal.json:499`, `packages/db/src/migrations/0075_low_nick_fury.sql:1`, `packages/db/src/schema/issues.ts:35`, `server/package.json:45`, `server/src/services/issues.ts:88`, `server/src/services/issues.ts:2916`, `server/src/services/issues.ts:3128`, `server/src/services/recovery/service.ts:1318`, `server/src/services/recovery/service.ts:1779`, `infra/docker-compose.koenig.yml:42`
- Relevant prior work: Koenig commit `d7783f9bf` / KOEA-5183 added `issues.metadata` plus blocked-status activation guards; parent ticket KOEA-7470 records the pre-upgrade DB backup at `/tmp/paperclip-pre-upgrade-20260610-141510.sql.gz`.
- Constraints: `master` exists and is the verified base branch; `upgrade/v2026.609.0` does not exist yet and should be created from `master`. No Convex or `learnovaBeast` deploy is involved; if the merge appears to require any learnova portal or Convex change, stop and escalate.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Create a locked upgrade branch from `master`, merge upstream tag `v2026.609.0`, then resolve only the known fork conflict surfaces. Treat upstream migrations `0075` through `0098` as authoritative, renumber Koenig's `0075_low_nick_fury.sql` to the next free slot `0099_koenig_blocked_status_drift.sql`, and manually preserve the underlying `issues.metadata` schema plus blocked activation guard code where upstream rewrote nearby issue service logic.

**Rejected**: Cherry-pick selected upstream fixes only - this misses the release's migration chain and adapter/session fixes; rebase Koenig commits onto upstream - higher risk with hundreds of vault/content commits and no benefit over a merge branch; externalize Hermes during the upgrade - out of scope and risky because the current production fork still has Hermes-specific server/UI/runtime assumptions.

## Steps (Executor follows in order)
1. Guard the workspace before editing: verify no active `.claude/agent-lock`; create `.claude/agent-lock` containing issue `KOEA-7470`, executor agent id, run id, branch, and timestamp; confirm `git status --short` and do not touch unrelated dirty files.
2. Create branch `upgrade/v2026.609.0` from verified `master`, fetch `upstream` tags, and merge `v2026.609.0` without deploying or starting production containers.
3. Resolve migrations as one surface: keep upstream `packages/db/src/migrations/0075_cultured_sebastian_shaw.sql` through `0098_project_icon.sql` and upstream snapshots/journal entries, rename Koenig `0075_low_nick_fury.sql` to `0099_koenig_blocked_status_drift.sql`, append a journal entry with `idx: 99`, and ensure `packages/db/src/schema/issues.ts` still includes both upstream fields (`workMode`, monitor fields, `sourceTrust`) and Koenig `metadata`.
4. Resolve Hermes/package surfaces: in `server/package.json` and adapter registry/UI-related imports, keep upstream new adapters (`acpx_local`, `cursor_cloud`, `grok_local`) and preserve working `hermes_local` support, including Koenig auth-token injection, `PAPERCLIP_RUN_ID` env injection, `detectModel`, model list behavior, and `PAPERCLIP_HERMES_MODELS` compose env.
5. Resolve `server/src/services/issues.ts` by starting from upstream `v2026.609.0` service shape and reinserting Koenig's blocked activation guard helpers plus both enforcement points: update path blocks `blocked -> in_progress` unless unblock metadata changes, and checkout path rejects metadata-guarded blocked issues.
6. Resolve `server/src/services/recovery/service.ts` by starting from upstream `v2026.609.0` recovery service and preserving Koenig recovery dampening semantics: recent recovery cooldown, no recursive stranded recovery pile-ups, Hermes/status-only recovery compatibility, and visible blocked escalation comments.
7. Preserve deployment and rollback assets: keep `infra/docker-compose.koenig.yml` rather than deleting it during merge, update only the Paperclip image tag when ready for the swap, keep the backup `/tmp/paperclip-pre-upgrade-20260610-141510.sql.gz`, and leave rollback commands in the PR body.

## Verification (QA Verifier checks these)
- [ ] `git diff --check` passes and `git status --short` shows only intentional upgrade files plus `.claude/agent-lock` removed or deliberately ignored before handoff.
- [ ] Migration order has no duplicate slot: upstream `0075` remains, upstream `0098` remains, Koenig metadata migration is `0099_koenig_blocked_status_drift.sql`, and `_journal.json` has unique `idx` values.
- [ ] `pnpm -r typecheck` passes.
- [ ] `pnpm test -- --run server/src/__tests__/adapter-registry.test.ts server/src/__tests__/issues*.test.ts server/src/__tests__/recovery*.test.ts` or the closest existing targeted Vitest files pass; if filenames changed, record the exact replacement.
- [ ] `pnpm build` passes before PR-ready handoff.
- [ ] Off-hours deployment checklist is recorded but not executed by Executor: verify no running heartbeats, tag fallback image `koenig/paperclip-server:dev-pre-upgrade-20260610`, build `koenig/paperclip-server:v2026.609.0`, update compose image tag, run `docker compose up -d paperclip`, then check `curl localhost:3100/api/health`, agent list, sample issue render, one heartbeat, and new DB tables/columns.
- [ ] Rollback checklist remains executable: `docker compose stop paperclip`, restore compose image tag to `:dev-pre-upgrade-20260610`, restore DB from `/tmp/paperclip-pre-upgrade-20260610-141510.sql.gz` if migrations corrupt state, then `docker compose up -d paperclip`.

## Risk
- The highest risk is migration drift: the parent ticket expected `0091+`, but fetched upstream `v2026.609.0` already owns `0091` through `0098`. Mitigation: use `0099` for Koenig's migration, preserve `issues.metadata` in schema, and verify journal uniqueness before any container swap.

## Out of scope
- No Convex deploy, no learnova portal change, no Hermes externalization project, no production container swap during the implementation PR, and no cleanup of unrelated dirty vault/content files.

## Pre-flight Footer
- `vault_pull=true`
- `basebranch_verified=true`
- `chain_alert_approval_status=rejected_and_issue_resumed`
- `upstream_tag_verified=true`
