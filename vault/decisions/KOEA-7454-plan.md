---
ticket: KOEA-7454
planner: planner
planner_issue: KOEA-7459
date: 2026-06-10
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: academy/redesign-v1 for learnovaBeast; master for koenig-ai-org vault/script changes
basebranch_verified: true
---

# Plan: Add build-time vault status lint and canonical Academy status guard

## Goal
Prevent non-canonical vault `status:` frontmatter from silently entering the publish/build path. Success means KOEA vault content is linted against the canonical 8-value vocabulary before local/package and Vercel builds, and the Academy `vault.ts` reader no longer accepts invented `gN-*` gate strings through a regex escape hatch.

## Context
- Files to read first: `koenig-ai-org/scripts/migrate-status.mjs`, `koenig-ai-org/package.json`, `koenig-ai-org/vault/STATUS.md`, `learnovaBeast/.github/workflows/publish.yml`, `learnovaBeast/learnova-academy/package.json`, `learnovaBeast/learnova-academy/src/lib/vault.ts`.
- Current-state findings:
  - `scripts/migrate-status.mjs` already defines the canonical set and legacy migration map, scans `vault/blogs` plus `vault/courses`, and exits nonzero for unknown values; it is a mutating migration tool, not a build lint.
  - Root `koenig-ai-org/package.json` has no `verify-status` script today.
  - Vercel config is workflow-driven for publish dispatch: `learnovaBeast/.github/workflows/publish.yml` checks out `academy/redesign-v1`, checks out `koenig-ai-org` into `vault-root`, then runs `vercel build --prod` with `KOENIG_VAULT_ROOT`.
  - `learnova-academy/src/lib/vault.ts` is the app file found by `git grep -P 'g\d+-(passed|approved|revision)'`; it currently has `GATE_STATE_PATTERN = /^g\d+-(passed|approved|revision)$/`, so invented values like `g5-approved` can render instead of failing loudly.
  - `.vercel/project.json` files are project metadata only; no checked-in `vercel.json` build command was found.
- Relevant prior work: `vault/STATUS.md` is the source of truth for `draft`, `awaiting-g0`, `g0-blocked`, `g0-passed`, `g3-passed`, `g4-approved`, `published`, `deprecated`.
- Constraints: do not edit vault content in this ticket; do not broaden runtime course status handling unless a separate ticket asks for it; Planner made no production code changes.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a non-mutating verifier beside the existing migration script, wire it into the root KOEA package and the publish workflow before Vercel build, and replace the Academy regex with explicit canonical status sets. This reuses the migration script's scan scope and canonical vocabulary while making the failure mode deterministic in CI/builds; `vault.ts` remains a narrow app-side guard and does not become the source of truth.

**Rejected**: Extend `GATE_STATE_PATTERN` or add more regex cases, because it preserves the bug class where agents can mint new statuses. **Rejected**: Only fix `vault.ts` without a build-time lint, because bad vault files would still land and fail later or disappear from routes. **Rejected**: Make the migration script run automatically in builds, because builds should fail on bad source rather than rewrite content.

## Steps (Executor follows in order)
1. In `koenig-ai-org/scripts/verify-status.mjs`, create a read-only verifier from the scan portions of `scripts/migrate-status.mjs`: scan `vault/blogs` and `vault/courses` for `draft.md`, `index.md`, and `outline.md`; extract the first frontmatter `status:` value; accept only the canonical 8-value `Set`; print every offending relative path/value; exit `1` if any invalid value exists.
2. In `koenig-ai-org/package.json`, add `"verify-status": "node scripts/verify-status.mjs"` without changing existing scripts.
3. In `learnovaBeast/.github/workflows/publish.yml`, prefix the Build step with `node vault-root/scripts/verify-status.mjs` before `vercel build --prod`, using the already-checked-out `vault-root` and existing `KOENIG_VAULT_ROOT`.
4. In `learnovaBeast/learnova-academy/src/lib/vault.ts`, replace `GATE_STATE_PATTERN` with a `CANONICAL_STATUSES` `Set` containing exactly `draft`, `awaiting-g0`, `g0-blocked`, `g0-passed`, `g3-passed`, `g4-approved`, `published`, `deprecated`; keep a separate publishable/hidden decision so `g0-blocked`, `deprecated`, and raw `draft` stay hidden, `g4-approved` is accepted, and unknown strings warn via `console.warn` then return `false`.
5. Update the `BlogPost.status` type in `vault.ts` to the canonical union and remove legacy statuses from that type; do not change course status handling in `courses.ts` unless tests prove the blog guard import must be shared.
6. Run the smallest checks below, then report any pre-existing dirty worktree files separately so the PR scope only includes the verifier, package script, workflow prefix, and `vault.ts` guard.

## Verification (QA Verifier checks these)
- [ ] From `koenig-ai-org`: `pnpm verify-status` exits `0` with the current vault; a temporary fixture with `status: g5-approved` makes it exit `1` and prints the offending path.
- [ ] From `learnovaBeast/learnova-academy`: `pnpm typecheck` passes after the `BlogPost.status` union and guard changes.
- [ ] From `learnovaBeast`: the publish workflow Build step shows `node vault-root/scripts/verify-status.mjs` before `vercel build --prod`.
- [ ] `git grep -n -P 'g\\d+-(passed|approved|revision)' learnova-academy/src/lib/vault.ts` returns no matches.

## Risk
- Risk: canonical lint may expose existing dirty vault content that still uses legacy statuses. Mitigation: run `node scripts/migrate-status.mjs --dry-run` first; if it lists migrations, either migrate in a separate content cleanup or block with the exact offending files rather than weakening the verifier.

## Rollback
- Remove `scripts/verify-status.mjs`, the `verify-status` package script, and the workflow pre-build line to restore previous build behavior.
- Revert `vault.ts` to the prior `PUBLISHABLE_STATES` plus regex guard only if an emergency deploy is blocked; keep the rollback scoped to `vault.ts`.

## Out of scope
- Bulk-editing vault content statuses.
- Changing `learnova-academy/src/lib/courses.ts` course visibility semantics.
- Adding a checked-in `vercel.json` where none exists today.
- Any production code change by Planner; this document is the only file Planner created.
