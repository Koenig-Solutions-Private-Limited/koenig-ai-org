---
ticket: KOEA-9112
planner: planner
date: 2026-07-16
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
planner_chain_approval: d0f0448f-7571-4295-9250-d75dc2cd14cd
---

# Plan: PR-time blog frontmatter status lint

## Goal
Ensure every `vault/blogs/*/draft.md` file that can land through a PR or publish-action vault sync uses a status accepted by Academy `PUBLISHABLE_STATES`. Success means an invalid blog status such as `g2-passed` fails before merge and before publish-action commits the vault, preventing silent Academy filtering and soft-404 regressions.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:43-53`, `scripts/verify-status.mjs:17-32`, `.github/workflows/pr.yml:54-84`, `scripts/publish-action.sh:667-699`, `vault/blogs/build-your-first-mcp-server-python-2026-complete-guide/draft.md:1-12`.
- Relevant prior work: `vault/decisions/KOEA-1401-plan.md:166-185` and `scripts/publish-action.sh:538-608` already establish the Phase 0 pattern for checking staged vault frontmatter before auto-commit.
- Constraints: keep implementation in `koenig-ai-org`; use `learnovaBeast` only as the source-of-truth reference for the current Academy blog status set; do not rewrite course status handling or the broader publish pipeline.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a focused blog-only status lint in `koenig-ai-org` that encodes the current Academy `PUBLISHABLE_STATES` values from `learnova-academy/src/lib/vault.ts` (`draft-for-review`, `awaiting-g0`, `g0-passed`, `g3-passed`, `published`). Wire it into PR CI and publish-action Phase 0, and normalize the one current blog baseline offender (`g2-passed`) so the guard is immediately green on `master`.

**Rejected**: Wire existing `scripts/verify-status.mjs` directly into PR CI — it currently fails unrelated course statuses and uses the vault canonical set, not Academy `PUBLISHABLE_STATES`; Academy prebuild-only validation — too late because bad vault content can still merge and publish-action can still auto-commit it; cross-repo import/fetch from `learnovaBeast` during koenig PR CI — brittle and unnecessary for this narrow guard.

## Steps (Executor follows in order)
1. Create `scripts/verify-blog-status.mjs` in `koenig-ai-org` that scans only `vault/blogs/*/draft.md`, parses the first YAML frontmatter block, and exits 1 with `file: status="value"` lines when `status` is missing or outside the Academy blog publishable set.
2. Add `verify-blog-status` to `package.json` scripts as `node scripts/verify-blog-status.mjs`.
3. Add a PR workflow step in `.github/workflows/pr.yml` before `Typecheck` that runs `pnpm verify-blog-status`, so changed PRs fail before merge.
4. In `scripts/publish-action.sh`, after `git add -A vault/` and the `.obsidian` reset/checkout but before `verify_no_pending_g4_publish`, run `node scripts/verify-blog-status.mjs`; if it fails, log the output, send the existing Telegram alert helper, and exit before committing or pushing the vault sync.
5. If still present, change `vault/blogs/build-your-first-mcp-server-python-2026-complete-guide/draft.md` from `status: g2-passed` to the nearest Academy-accepted reviewed state (`g3-passed`); do not touch course outline statuses in this ticket.
6. Keep `scripts/verify-status.mjs` behavior unchanged except where Executor finds it is needed to avoid naming confusion; this ticket's guard is blog-only and Academy-set-specific.

## Verification (QA Verifier checks these)
- [ ] `pnpm verify-blog-status` exits 0 on the current repository after the `g2-passed` blog baseline is fixed.
- [ ] A temporary fixture or local edit setting any `vault/blogs/*/draft.md` to `status: g2-passed` makes `pnpm verify-blog-status` exit 1 and print the offending path.
- [ ] `.github/workflows/pr.yml` contains a PR-time `pnpm verify-blog-status` step before typecheck/build/test.
- [ ] `scripts/publish-action.sh` runs the same lint during Phase 0 before any vault sync commit can be created.

## Risk
- The allowed set can drift if Academy changes `PUBLISHABLE_STATES` later. Mitigation: keep the script comment pointing to `learnova-academy/src/lib/vault.ts:43-53` and require any future Academy status-set change to update this koenig lint in the same PR/chain.

## Out of scope
- Course status vocabulary cleanup, `vault/STATUS.md` policy reconciliation, and exporting a shared cross-repo status package are out of scope for KOEA-9112.

Pre-flight telemetry: vault_pull=true; ticket_status=in_progress; assignee_verified=true; sibling_count=0; chain_depth=4; chain_override_approval=d0f0448f-7571-4295-9250-d75dc2cd14cd; basebranch_verified=true.
