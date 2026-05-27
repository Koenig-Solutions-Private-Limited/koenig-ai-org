---
ticket: KOEA-2170
planning_ticket: KOEA-5775
planner: planner
agent: planner
date: 2026-05-27
type: decision
tags:
  - decision
  - engineering
  - course/picking-a-frontier-model-2026-q2
estimated_complexity: medium
estimated_token_cost: "$0.42"
base_branch: academy/redesign-v1
basebranch_verified: true
authorized_by_approval: 8e6bb0cb-4da7-4075-9a21-ffee42523b26
---

# Plan: Fix LCP on the published frontier-model course page

## Goal
Bring `https://academy.kspl.tech/learn/picking-a-frontier-model-2026-q2` below the G2 LCP threshold of 2500 ms while preserving the existing course content, layout, Nova tutor affordance, chapter navigation, and learning resources. Success is a small Academy-only change with before/after Lighthouse evidence showing LCP under 2500 ms, CLS still acceptable, and TBT not regressed.

## Context
- Files to read first: `learnova-academy/src/app/learn/[slug]/page.tsx:83-164`, `learnova-academy/src/app/learn/[slug]/page.tsx:394-518`, `learnova-academy/src/app/learn/[slug]/page.tsx:801-973`, `learnova-academy/src/app/learn/[slug]/client-shell.tsx:1-37`, `learnova-academy/src/components/_shared/tutor.tsx:26-64`, `learnova-academy/src/components/_shared/tutor.tsx:76-118`, `learnova-academy/src/app/api/tutor/route.ts:19-39`, `learnova-academy/src/lib/courses.ts:91-172`, `learnova-academy/README.md:147-155`.
- Relevant prior work: KOEA-2135 recorded G2 Lighthouse LCP `2889ms` on the live course URL, with CLS `0` and TBT `47.5ms`; KOEA-2156 and KOEA-2170 ask for the smallest safe LCP fix; Chief Engineering authorized this plan after planner-chain alert `8e6bb0cb-4da7-4075-9a21-ffee42523b26`.
- Current code evidence: the route has already moved heavy slide/PDF embeds into closed `<details>` sections, but still builds `groundingBody` from the full outline plus every chapter and passes it through the client shell into `TutorRail`. The tutor API later slices that body to 18000 chars, so shipping more than that to the browser is avoidable initial payload.
- Constraints: target only `learnovaBeast/learnova-academy` on `origin/academy/redesign-v1`; do not edit vault course prose or media unless a verification run proves content metadata is the direct LCP cause; do not touch `learnova-tc` unless Convex is required, and this plan expects no Convex change; current local worktree was dirty/ahead/behind during planning, so Executor should start from a clean branch off freshly fetched `origin/academy/redesign-v1`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Measure first, then reduce the course page's initial client payload and non-critical hydration. Keep the visual page structure intact, but stop sending the full multi-chapter `groundingBody` to the client when `/api/tutor` only uses the first 18000 chars. If the first Lighthouse trace shows remaining LCP pressure from client JS, lazily split the study-guide, mind-map, and flashcard widgets behind their click affordances so the chapter text can paint before optional learning-resource UI hydrates.

**Rejected**: remove audio/slides/resources from the page - too much product regression for a performance bug; change course content or delete media assets - violates the KOEA-2170 scope unless metadata is proven causal; add CDN or Convex deploy steps - unnecessary for a static Next route and risks targeting the wrong portal.

## Steps (Executor follows in order)
1. Create a clean implementation branch from `origin/academy/redesign-v1` in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`; ignore the unrelated dirty local files seen during planning (`learnova-academy/next-env.d.ts`, `learnova-academy/public/slides/`, `learnova-academy/scripts/check-meta-descriptions.mjs`).
2. Capture baseline evidence before editing: run Lighthouse against the live URL and, if feasible, a local production build of the same branch. Record LCP element, LCP ms, CLS, TBT, transferred bytes, and JS execution/hydration cost in the PR notes.
3. In `learnova-academy/src/app/learn/[slug]/page.tsx`, replace the full `groundingBody` passed to `CoursePageClient` with a bounded tutor context helper, capped at the same 18000 chars used by `src/app/api/tutor/route.ts`. Preserve the title, outline, and chapter ordering, but do not serialize the entire course body to the browser.
4. In `learnova-academy/src/app/learn/[slug]/client-shell.tsx` and `learnova-academy/src/components/_shared/tutor.tsx`, rename or document the prop as bounded tutor context, keep the existing Nova UX, and ensure `/api/tutor` still receives `slug`, `type`, `title`, and the bounded body when the learner actually sends a message.
5. If the post-step-4 local Lighthouse run is still above 2500 ms or shows high JS evaluation/hydration, split optional chapter asset widgets out of the initial route: use `next/dynamic` or a small local lazy wrapper for `StudyGuideEmbed`, `MindMapTree`, and `FlashcardsDeck` in `learnova-academy/src/app/learn/[slug]/page.tsx`, keeping visible links/buttons stable and fetching/rendering rich widgets only after user interaction.
6. Run the verification commands below. If the exact G2 harness is unavailable, include the local Lighthouse command output and the live-production Lighthouse command output, then state that it is the closest reproducible verifier.
7. Hand back to the existing KOEA-2170 Executor chain: comment on KOEA-2170, KOEA-2156, and KOEA-2135 with changed files, before/after metrics, and PR URL; then clear KOEA-2170's blocker on KOEA-5775 or ask Chief Engineering to wake Executor if direct blocker mutation is not permitted.

## Verification (QA Verifier checks these)
- [ ] From `learnova-academy`, `pnpm typecheck` passes.
- [ ] From `learnova-academy`, `pnpm build` passes after `scripts/sync-vault.mjs` runs.
- [ ] Local production smoke: `pnpm start -p 3010` serves `/learn/picking-a-frontier-model-2026-q2` with the course title, chapter index, Nova button, and chapter content visible.
- [ ] Lighthouse local command exits successfully and reports LCP under 2500 ms, CLS <= 0.1, and TBT not meaningfully worse than the prior 47.5 ms baseline:
  `npx lighthouse http://localhost:3010/learn/picking-a-frontier-model-2026-q2 --chrome-flags="--headless=new" --only-categories=performance --output=json --output-path=/tmp/koea-2170-local-lh.json`
- [ ] Lighthouse live command after deploy reports LCP under 2500 ms on `https://academy.kspl.tech/learn/picking-a-frontier-model-2026-q2`; include the JSON or parsed metrics in the issue/PR.
- [ ] Manual click smoke: open Nova, send a short prompt, and confirm `/api/tutor` still streams an answer grounded in the course; open one chapter resource button if present and confirm no client-side error.

## Risk
- The actual live LCP element may be text/font/CSS rather than client payload. Mitigation: Step 2 requires capturing the LCP element before edits; if the trace points elsewhere, make the smallest targeted fix in that path and document why the chosen payload work was insufficient.

## Out of scope
- Rewriting course prose, citations, slide decks, audio, or source URLs.
- Convex deploys or changes to `learnova-tc`, `learnova-admin`, `learnova-sales`, or `learnova-student`.
- Broad Academy redesign or a new performance framework; this is a focused LCP fix for one published course route.
