---
ticket: KOEA-2455
planning_issue: KOEA-2491
planner: planner
agent: planner
date: 2026-05-14
type: decision
tags:
  - decision
estimated_complexity: medium
estimated_token_cost: "$0.28"
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Fix homepage course links that point at missing Academy lessons

## Goal
Stop the Academy homepage from rendering `/learn/*` links for course slugs that do not have vault-backed course outlines. Success means the hero/course-of-day, this-week-in-AI, skill-path, and popular-course homepage surfaces either link to real course pages or route users to `/catalog`, and a small build-time check fails if homepage data can generate another dead `/learn/*` link.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/app/page.tsx:27-62`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/app/page.tsx:163-201`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/lib/fixtures.ts:104-316`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/lib/courses.ts:186-260`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/app/catalog/page.tsx:29-49`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/app/sitemap.ts:23-28`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/components/_shared/content.tsx:381-387`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy/src/components/_shared/content.tsx:570-572`.
- Relevant prior work: KOEA-2455 parent comment created isolated worktree `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455` on `koea-2455/homepage-skill-path-links` from `origin/academy/redesign-v1`; no PR exists yet.
- Constraints: preserve lane boundaries to `learnova-academy` only; do not modify course vault content; keep the fix under five implementation files; production base branch `academy/redesign-v1` exists on origin.
- Current source of bad slugs: `src/lib/fixtures.ts` defines fixture courses for `gemini-2m-context-deep-dive`, `prompt-engineering-without-tears`, `agents-from-prompt-to-production`, and `your-first-prompt-in-five-minutes`, plus a news item for `gemini-enterprise-agent-platform-hands-on-tour`. `CourseCard` and `NewsCard` turn those values into `/learn/<slug>` links.
- Canonical course source: `src/lib/courses.ts` reads `vault/courses/<slug>/outline.md`; `/catalog` uses `listAllCourses()`, `/learn/[slug]` statically generates from `listAllCourses()`, and `/sitemap.xml` uses `listPublishableCourses()`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Move homepage course-card data to the same vault-backed course source as `/catalog`, by extracting the catalog `VaultCourse -> CourseCard` adapter into a shared `src/lib/course-cards.ts` helper. Use `listAllCourses()` as the resolvability set for homepage links because `/learn/[slug]` generates pages for every outline-backed course; prefer `listPublishableCourses()` only when choosing the featured/published-first ordering, and fall back to `listAllCourses()` rather than fixtures when few courses are publishable. Guard `NewsCard` course links against that same slug set so fixture news can still render text but unresolved courses route to `/catalog`.

**Rejected**: Add redirects for the five missing slugs — this hides stale homepage data and invents course mappings the vault does not own. **Rejected**: Publish placeholder vault course folders for those slugs — that changes content/lane ownership and would make low-quality course pages just to satisfy links.

## Steps (Executor follows in order)
1. Add `learnova-academy/src/lib/course-cards.ts` with the existing `toCatalogCard` mapping from `src/app/catalog/page.tsx`, plus a helper such as `toCourseCards(courses: VaultCourse[]): Course[]`; keep the fixture `Course` UI shape so `CourseCard` and `CatalogClient` do not need visual changes.
2. Update `learnova-academy/src/app/catalog/page.tsx` to import the shared mapper and delete its local duplicate `VENDOR_MAP`, `COVER_MAP`, and `toCatalogCard` definitions.
3. Update `learnova-academy/src/app/page.tsx` so `featured`, `featuredWithThumb`, and `popular` are built from vault courses only: compute `allCourses = listAllCourses()`, `publishableCourses = listPublishableCourses()`, `availableSlugs = new Set(allCourses.map(c => c.slug))`, use publishable courses first for ordering, and fall back to all outline-backed courses rather than `fixtures.courses`.
4. In `src/app/page.tsx`, sanitize `news` before rendering: if `item.course` is absent from `availableSlugs`, pass a copy with `course: undefined` and `live: false` so `NewsCard` links to `/catalog` instead of a missing lesson.
5. Add `learnova-academy/scripts/check-internal-links.mjs` that reads vault course outline folders, checks the homepage-relevant fixture course/news slugs against the homepage allowlist logic, and fails with a clear list of any `/learn/<slug>` homepage candidate not present in `vault/courses/<slug>/outline.md`.
6. Update `learnova-academy/package.json` with `check:internal-links` and run it from `prebuild` after `sync-vault.mjs`, so `pnpm build` catches regressions automatically.

## Verification (QA Verifier checks these)
- [ ] From `/paperclip/instances/default/workspaces/learnovaBeast-koea-2455/learnova-academy`, `pnpm check:internal-links` passes and prints the number of homepage `/learn/*` candidates checked.
- [ ] `pnpm typecheck` passes for the shared mapper and homepage changes.
- [ ] `pnpm build` passes, including the `prebuild` vault sync plus internal-link check.
- [ ] Manual source check: `src/app/page.tsx` no longer imports `courses` from `@/lib/fixtures`, and every homepage `CourseCard` receives a course derived from `listAllCourses()` or `listPublishableCourses()`.

## Risk
- The vault may be empty in some local/dev builds, which would make a strict link check noisy. Mitigation: make the checker skip with an explicit warning only when no vault course outlines exist, matching the existing `sync-vault.mjs` empty-vault tolerance, but fail when outlines exist and a homepage candidate is unresolved.

## Out of scope
- Do not create or publish new course content for the five missing slugs.
- Do not change non-Academy apps in `learnovaBeast`.
- Do not redesign cards, routing, or catalog filtering beyond preventing dead homepage `/learn/*` links.
