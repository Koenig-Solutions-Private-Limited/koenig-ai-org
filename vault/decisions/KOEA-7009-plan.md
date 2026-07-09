---
ticket: KOEA-7009
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
basebranch_verified: true
authorized_by_approval: 7c108b23-3592-4578-ba19-dd2578a6ee99
---

# Plan: Add /map course prerequisite SVG graph

## Goal
Ship a `/map` page in `learnovaBeast/learnova-academy` that visualizes course build-upon relationships from course outline frontmatter. Success means learners can open a responsive SVG prerequisite graph, click course nodes to reach `/learn/<slug>`, see completed courses distinguished from incomplete courses using existing localStorage progress, and get a graceful empty state while Content is still populating `builds_on`.

## Context
- Files to read first: `src/lib/courses.ts:118-139`, `src/lib/courses.ts:535-599`, `src/lib/courses.ts:615-650`, `src/lib/course-progress.ts:1-17`, `src/lib/course-progress.ts:49-91`, `src/app/(site)/catalog/page.tsx:60-85`, `src/app/(site)/learn/[slug]/page.tsx:57-68`, `src/components/_shared/chrome.tsx:174-191`, `src/app/sitemap.ts:13-21`.
- Exact loader path: `src/lib/courses.ts` reads `KOENIG_VAULT_ROOT ?? /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault`, then `vault/courses/<slug>/outline.md` via `gray-matter`; `listDiscoverableCourses()` is the broad course source used by catalog and static params.
- Progress keys: `src/lib/course-progress.ts` uses legacy `academy-course-progress` percent map and per-course `course-progress-<slug>` with `completedChapterNums`; updates dispatch `course-progress-updated`.
- Routing conventions: `/catalog` is the catalog route; `/learn/[slug]` exists but metadata canonicalizes to `/courses/<slug>` and `next.config.ts` currently redirects generic `/learn/:slug` to `/courses/:slug`. The ticket still requires node hrefs in `/learn/<slug>` form.
- Build/test commands from `package.json`: `pnpm typecheck`, `pnpm test`, `pnpm lint`, `pnpm build`, and `pnpm dev` on port 3010.
- Relevant prior work: KOEA-10847 ruled Engineering owns implementation; KOEA-10859 owns Content semantics for `builds_on`; the existing lazy Knowledge Constellation uses `src/components/fx/GlobalMapOverlay.tsx`, `src/components/fx/ConstellationMap.tsx`, and `/api/graph`, but that is a separate overlay and should not be repurposed for this route.
- Constraints: preserve current dirty academy workspace state. In this runtime `learnova-academy` is detached HEAD with an existing `next.config.ts` modification and untracked generated/assets; do not revert or overwrite them. The available workspace is `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`; configured FE/QA worktrees were not present.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a route-local course map model plus lazy client renderer. Extend `Course` with `builds_on: string[]` parsed from outline frontmatter, add `src/lib/course-map.ts` to turn `listDiscoverableCourses()` into nodes, valid edges, and warnings for missing/self/cycle edges, then add `src/app/(site)/map/page.tsx` and a dynamically imported `course-map-client.tsx` that imports `@dagrejs/dagre` only in the `/map` route chunk and renders the responsive SVG. This keeps vault parsing centralized, avoids loading graph layout code on normal catalog/learn pages, and gives Executor a single route boundary for visual QA.

**Rejected**: Reuse `/api/graph` and `ConstellationMap` - it mixes blogs/glossary/reading history and uses an undirected force-style constellation, so it cannot express prerequisite direction cleanly. **Rejected**: hand-roll a topological layer layout - leaner dependency-wise, but it adds more custom geometry and edge-routing risk than `@dagrejs/dagre` for a DAG. **Rejected**: render the graph fully server-side - cannot read localStorage completion state and would make responsive/interactive node behavior awkward.

## Steps (Executor follows in order)
1. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`, verify the current workspace and claim the lock before edits: inspect `git status --short --branch`, confirm `origin/academy/redesign-v1` exists, preserve unrelated dirty files, and replace or update `.claude/agent-lock` with KOEA-7009, owner executor, phase implementation, worktree path, `branch_base: origin/academy/redesign-v1`, and the implementation branch name.
2. Update `learnova-academy/src/lib/courses.ts` to add `builds_on: string[]` to `Course` and parse `data.builds_on` with the existing `frontmatterStringList`; missing field must default to `[]` so Content can populate later without breaking builds.
3. Add `learnova-academy/src/lib/course-map.ts` with a serializable graph builder over `listDiscoverableCourses()`: nodes include slug/title/vendor/level/chapter_count/total_duration_min, edges are `builds_on` source -> course target, invalid or missing source slugs are skipped into warnings, self edges are skipped, and cycle-forming edges are skipped or reported so the rendered graph remains a DAG.
4. Add `learnova-academy/src/app/(site)/map/page.tsx`, optional `loading.tsx`, and `course-map-client.tsx`: page reads the graph server-side, renders `TopBar active="map"`, dynamically imports the client renderer with SSR disabled or route-local lazy loading, and shows an empty state when there are zero valid relationship edges.
5. Implement the client SVG renderer with `@dagrejs/dagre`: add the dependency, compute layout in `useMemo`, use a responsive `viewBox`, render arrowheaded directed edges and keyboard-focusable course nodes, link nodes to `/learn/<slug>`, color completed courses by reading `readCourseProgress(slug)` plus `readCourseProgressPercent(slug) >= 100`, and listen for `course-progress-updated`.
6. Wire route discoverability without broad nav churn: add `map` to `TopBar` `NavId` and desktop nav links; add `/map` to `src/app/sitemap.ts`. Leave mobile `BottomNav` unchanged unless the layout still fits cleanly after visual QA.
7. Add focused regression coverage: if practical, add a small unit/script check for `buildCourseMap()` invalid references and empty relationships; otherwise rely on `pnpm typecheck`, `pnpm test`, `pnpm lint`, and browser walkthrough.

## Verification (QA Verifier checks these)
- [ ] `pnpm typecheck` passes in `learnova-academy`.
- [ ] `pnpm test` passes in `learnova-academy`.
- [ ] `pnpm lint` passes in `learnova-academy`, or any pre-existing lint failures are isolated and documented.
- [ ] `pnpm build` passes; if Next/Vite build hangs on this filesystem, use the repo's Node-based command workaround only if applicable and document the exact command.
- [ ] Browser walkthrough on `pnpm dev` port 3010: `/map` loads, no text overlaps on desktop/mobile widths, empty/no-relationship state is graceful when `builds_on` is absent, and injected sample relationships render as a directed SVG DAG.
- [ ] Browser walkthrough confirms a node click navigates via `/learn/<slug>` and a fully completed course, simulated in localStorage with `course-progress-<slug>` or legacy `academy-course-progress`, receives distinct styling.
- [ ] Browser walkthrough confirms invalid/missing `builds_on` slugs do not crash the page and are surfaced as a small warning/count rather than a build failure.

## Risk
- Main risk: Content may introduce malformed `builds_on` values or cycles. Mitigation: normalize frontmatter through `frontmatterStringList`, skip invalid/self/cycle-forming edges, render warnings, and keep the empty state useful until KOEA-10859 finalizes semantics.

## Out of scope
- Do not mass-populate course outline `builds_on` values in this implementation ticket; KOEA-10859 or the operator owns content semantics/population.
- Do not replace or modify the existing Knowledge Constellation overlay or `/api/graph`.
- Do not resolve the pre-existing detached HEAD, dirty `next.config.ts`, generated `.next`, untracked slide asset, or `.pnpm-store` state except as required to avoid clobbering it.
