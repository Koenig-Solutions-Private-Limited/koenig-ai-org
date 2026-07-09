---
ticket: KOEA-10900
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.22
base_repo: Koenig-Solutions-Private-Limited/koenig-career-academy
base_branch: main
basebranch_verified: true
---

# Plan: Career course publish guardrails

## Goal
Prevent Career Compass courses from being deployed or announced when the vault course is only a shell. Success means every `course_track: career` course is validated before publish dispatch, the ready-email cron only ships requests with renderable chapters, and nested-only `NN-slug/chapter.md` layouts fail before release.

## Context
- Files to read first: `scripts/validate-course-chapters.mjs:1-86`, `src/lib/courses.ts:439-575`, `src/lib/quiz.ts:129-144`, `src/app/api/career/check-requests/route.ts:1-111`, `koenig-ai-org/scripts/publish-action.sh:725-793`.
- Relevant prior work: `src/lib/courses.ts:138-145` defines this repo as `TRACK_MODE = "career"`; `src/lib/courses.ts:552-570` currently tolerates nested `NN-slug/chapter.md` fallback, which this ticket should block at publish validation time rather than by changing runtime rendering.
- Constraints: scope is `koenig-career-academy` plus the existing `koenig-ai-org/scripts/publish-action.sh` dispatch hook; do not modify student, sales, admin, or TC portals; base branch `main` exists on `koenig-career-academy`; the local checkout is dirty on an unrelated branch, so Executor should start from fresh `origin/main`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a publish-time validation contract and reuse the runtime course reader for readiness. Extend `scripts/validate-course-chapters.mjs` so it discovers every vault course whose `outline.md` has `course_track: career`, validates only root `NN-slug.md` chapter files, detects nested-only `NN-slug/chapter.md`, checks `chapters.length >= outline.chapter_count`, and requires each chapter frontmatter `quiz` block to expose at least 3 questions. Then call this script from `koenig-ai-org/scripts/publish-action.sh` immediately before Career repository dispatch, and update `src/app/api/career/check-requests/route.ts` to require `findCourseBySlug(slug)?.chapters.length > 0` before emailing subscribers.

**Rejected**: Remove nested fallback from `src/lib/courses.ts` outright - this is broader runtime behavior and may break current courses that have root chapters plus nested asset sidecars. **Rejected**: Keep the hardcoded course allow-list and append new slugs - this repeats the current failure mode whenever a new Career course is added. **Rejected**: Trust HTTP `HEAD /learn/<slug>` only - a rendered shell can return 200 while still having no usable chapters.

## Steps (Executor follows in order)
1. Start in `koenig-career-academy` from a clean branch off `origin/main`; leave unrelated local untracked assets alone.
2. Update `scripts/validate-course-chapters.mjs` to discover career courses by parsing `KOENIG_VAULT_ROOT/courses/*/outline.md` and selecting `course_track: career`.
3. In the same validator, parse each selected outline's `chapter_count`, validate root `NN-slug.md` chapter files, fail nested-only `NN-slug/chapter.md` directories that lack a matching root file, and keep the existing duplicate/raw-title/positive-duration checks.
4. Add quiz validation in `scripts/validate-course-chapters.mjs`: every root chapter must have a frontmatter `quiz` block with at least 3 questions, accepting either array form or object-with-`questions` form.
5. Update `src/app/api/career/check-requests/route.ts` so the cron treats a request as shippable only when `findCourseBySlug(rec.suggested_slug)` returns a course with at least one renderable chapter; keep email retry semantics unchanged.
6. Update `koenig-ai-org/scripts/publish-action.sh` Phase 1 so Career-track items run the Career repo validator before `repository_dispatch`; on validator failure, skip dispatch for that issue and leave `publish_state` at `g4-approved` with a clear log line.
7. Add narrow tests or script fixtures near the touched files for career-course discovery, nested-only rejection, quiz-count failure, and `check-requests` empty-shell suppression.

## Verification (QA Verifier checks these)
- [ ] `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node scripts/validate-course-chapters.mjs` passes for current valid Career courses and lists all `course_track: career` courses, not just two hardcoded slugs.
- [ ] A temporary fixture with `outline.chapter_count = 3` and only two root chapters fails with a clear `chapter_count` error.
- [ ] A temporary fixture with `01-example/chapter.md` and no `01-example.md` fails with a clear nested-only layout error.
- [ ] A temporary fixture chapter with missing quiz or fewer than 3 quiz questions fails.
- [ ] `pnpm test` in `koenig-career-academy` passes, plus any new targeted validator/check-requests fixture command.
- [ ] G2 browser/API check: hit `/api/career/check-requests` with cron auth against a request whose URL returns 200 but whose slug has zero renderable chapters; verify no ready email is sent and request status is not `shipped`.
- [ ] G2 publish check: simulate a Career `g4-approved` issue through `publish-action.sh` with a bad course fixture and verify no GitHub `repository_dispatch` is attempted.

## Risk
- Validator strictness can block existing career courses if current vault data has hidden chapter or quiz drift. Mitigation: run the validator against the real vault before wiring publish dispatch, and if existing content fails, fix the course data in a separate content ticket rather than weakening the guardrail.

## Rollback
Revert the validator discovery/assertion changes, remove the `publish-action.sh` Career validation call, and restore `check-requests` to the HTTP live check. This returns the old behavior while leaving already-shipped course/request records untouched.

## Out of scope
- Rewriting `src/lib/courses.ts` runtime nested chapter support.
- Touching student, sales, admin, or TC portals.
- Repairing any existing course content that the new validator exposes as invalid.

