---
ticket: KOEA-1653
planner: planner
date: 2026-05-13
estimated_complexity: medium
estimated_token_cost: $0.55
approval_override: d734d524-1a96-4f00-be95-81103bf66a99
---

# Plan: Restore G5 done-artifact write path

## Goal
Publish Verifier can record a G5 PASS/BLOCK on an already-done published source issue without reopening it, taking ownership, or gaining broad active-checkout powers. Success is observable as a structured G5 comment plus `metadata.g5_verified_at` and `metadata.g5_verdict` on the source issue, while unrelated peer-agent mutations continue to return `403` or `409`.

## Context
- Files to read first: `server/src/routes/issues.ts:595-641`, `server/src/routes/issues.ts:1928-1995`, `server/src/routes/issues.ts:3348-3388`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:360-470`, `packages/db/src/schema/issues.ts:21-62`, `packages/shared/src/validators/issue.ts:133-154`, `packages/shared/src/types/issue.ts:240-285`, `scripts/paperclip-issue-update.sh:1-95`.
- Relevant prior work: KOEA-1623 timed out while Publish Verifier tried to code around this; KOEA-1644/KOEA-1653 escalated it as a Paperclip runtime bug. Planner chain override approved in `d734d524-1a96-4f00-be95-81103bf66a99`.
- Constraints: preserve company scoping, single-assignee checkout semantics, activity logging, and the existing rule that active peer-agent mutations are rejected. Deadline is 2026-05-13 18:00 UTC.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add issue metadata support plus a narrow G5 verifier PATCH path. Add `issues.metadata` as nullable JSONB across db/shared/server contracts, then teach `PATCH /api/issues/:id` to allow a same-company agent with a dedicated least-privilege grant to submit only a G5-shaped comment and `metadataPatch` for `g5_verified_at` / `g5_verdict` on `done` issues. This bypass should run before the normal peer-assignee guard, but only for this exact terminal-artifact write; all status, assignment, title, description, blocker, workspace, and active checkout mutations still use the existing guard.

**Rejected**: Grant Publish Verifier `tasks:manage_active_checkouts` because it is broader than G5 artifact writes and would allow intervention in unrelated active work. Reopen done issues to `todo` or force checkout because it changes the source issue lifecycle and can wake the wrong chain. Add a separate G5 endpoint because the existing PATCH route already supports comment-plus-issue updates and keeps audit behavior centralized.

## Steps (Executor follows in order)
1. Add `metadata: jsonb("metadata").$type<Record<string, unknown>>()` to `packages/db/src/schema/issues.ts`, expose it in `packages/shared/src/types/issue.ts`, add `metadata`/`metadataPatch` validation in `packages/shared/src/validators/issue.ts`, and generate the migration with `pnpm db:generate`.
2. In `server/src/routes/issues.ts`, add a small helper that recognizes an authorized G5 done-artifact write: actor is an agent with a new least-privilege permission such as `tasks:write_publish_verifications`, issue status is `done`, comment starts with `✅ G5` or `❌ G5`, and the only metadata keys are `g5_verified_at` plus `g5_verdict` (`pass` or `block`).
3. In the PATCH route, compute the G5 exception before `assertAgentIssueMutationAllowed`; if it matches, skip only that ownership guard and merge `metadataPatch` into existing metadata. Do not allow `reopen`, `resume`, `interrupt`, status changes, assignee changes, title/description edits, blockers, labels, workspace fields, documents, attachments, or work products through this exception.
4. Extend `scripts/paperclip-issue-update.sh` with a `--metadata-patch-json` option that validates JSON with `jq`, includes it in the PATCH payload, and preserves the current multiline comment behavior.
5. Extend `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` with route tests proving the authorized G5 PATCH on a `done` issue writes the comment and metadata, while peer PATCH/comment/document/work-product/attachment mutations still reject on active checkouts and non-G5 done mutations still reject.
6. After the fix lands, update KOEA-1623 by either resuming it to Publish Verifier for one heartbeat with a G5-only comment/metadata write, or closing it with a comment if the original published artifact no longer needs verification.

## Verification (QA Verifier checks these)
- [ ] `pnpm exec vitest run --project @paperclipai/server server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts --pool=forks --poolOptions.forks.isolate=true` passes, including authorized G5 done-artifact write and rejected peer-agent mutation cases.
- [ ] `scripts/paperclip-issue-update.sh --dry-run --metadata-patch-json '{"g5_verified_at":"2026-05-13T00:00:00.000Z","g5_verdict":"pass"}'` emits valid JSON while preserving multiline comments.
- [ ] `pnpm -r typecheck` passes after the issue metadata schema/type/validator changes.
- [ ] A manual API smoke with a Publish Verifier-like agent can PATCH a done source issue with a `✅ G5` comment and metadata, and cannot change the issue status or title through the same path.

## Risk
- Adding issue metadata broadens the issue contract; mitigate by using `metadataPatch` merge semantics for this workflow, validating the two G5 fields strictly, and keeping normal ownership checks on all non-G5 fields.

## Out of scope
- This plan does not change Publish Verifier's live-site checks, run timeout, model, or routing rules. It also does not grant broad checkout-management powers to Publish Verifier.
