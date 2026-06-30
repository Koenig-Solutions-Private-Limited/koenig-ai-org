---
ticket: KOEA-2170
planning_ticket: KOEA-6023
planner: planner
agent: planner
date: 2026-05-28
type: decision
tags:
  - decision
  - engineering
  - performance
  - course/picking-a-frontier-model-2026-q2
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: academy/redesign-v1
basebranch_verified: true
revision: 2
revision_marker: koea-2170-lcp-replan-r2
supersedes_revision: 1
triggered_by_approval: 66c4cfec-bc9a-42c7-a751-635e863bbe47
prior_pr: https://github.com/Koenig-Solutions-Private-Limited/learnovaBeast/pull/68
---

# Plan: Finish the remaining LCP path for the frontier-model course page

## Goal
Bring `https://academy.kspl.tech/learn/picking-a-frontier-model-2026-q2` below the G2 mobile LCP threshold of 2500 ms after PR #68 failed that gate. Success is a narrow continuation of PR #68 that preserves the course page, Nova tutor, search palette, analytics, CLS, and TBT while proving the remaining LCP path with before/after Lighthouse evidence.

## Context
- Files to read first: `learnova-academy/src/app/layout.tsx:9-29`, `learnova-academy/src/app/layout.tsx:83-97`, `learnova-academy/src/components/_shared/SitePalette.tsx:1-12`, `learnova-academy/src/components/_shared/chrome.tsx:167-185`, `learnova-academy/src/app/academy.css:55-57`, `learnova-academy/src/app/learn/[slug]/page.tsx:196-218`, PR #68 head `learnova-academy/src/app/learn/[slug]/page.tsx:85-116`, PR #68 head `learnova-academy/src/app/learn/[slug]/page.tsx:420-425`, PR #68 head `learnova-academy/src/app/learn/[slug]/client-shell.tsx:10-35`, PR #68 head `learnova-academy/src/components/_shared/tutor.tsx:72-124`.
- Relevant prior work: PR #68 (`920301c9`, `59d7af77`) capped Nova tutor context at 18000 chars, lazy-loaded chapter widgets, moved tutor context into `#nova-tutor-context`, deferred TutorRail hydration, and removed the duplicate course-page command palette.
- Verification evidence from Executor: G2 baseline `2889 ms`, live pre-merge `3028 ms`, local post-fix `3653 ms`, Vercel preview `5325 ms`; CLS stayed `0` and TBT stayed acceptable, so the remaining failure is LCP-specific.
- Constraints: continue in `learnovaBeast/learnova-academy` only, based on `academy/redesign-v1` and preferably continuing PR #68 branch `koea-2170/lcp-frontier-model`; do not touch `learnova-tc`, Convex, other portals, vault course prose, slides, or audio. Keep the patch to at most these files unless measurement proves a different LCP owner: `src/app/layout.tsx`, `src/components/_shared/SitePalette.tsx`, `src/components/_shared/chrome.tsx`, `src/app/academy.css`, `src/app/learn/[slug]/page.tsx`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: continue PR #68 and remove sitewide non-critical work from the mobile course-page critical path. PR #68 already addressed the route-specific tutor payload, so Executor should first capture a fresh Lighthouse trace on the PR preview, then defer the root command-palette/tutor chunk and Clarity script from initial page load. If the trace shows the hero title or target-audience text is the LCP element and font work is still delaying paint, reduce the course hero's dependency on preloaded Google font assets with the smallest route-scoped typography change.

**Rejected**: repeat the tutor payload work from revision 1 — already implemented and did not meet the gate; accept the current baseline — violates KOEA-2170 success criteria; broad redesign/CDN/Convex changes — outside scope and unlikely to address a single static course route.

## Steps (Executor follows in order)
1. Continue from PR #68 branch `koea-2170/lcp-frontier-model` against `origin/academy/redesign-v1`; do not discard commits `920301c9` or `59d7af77`, and ignore unrelated dirty files in local worktrees.
2. Capture a fresh mobile Lighthouse JSON against the PR #68 Vercel preview and, if possible, local production start. Record LCP element selector/text, LCP subparts, main-thread tasks, JS transfer/evaluation, font requests, and Clarity request timing before editing.
3. In `learnova-academy/src/components/_shared/SitePalette.tsx`, keep the global `OPEN_PALETTE_EVENT` behavior but stop importing/rendering `CommandPalette` on initial load. Use a tiny client shell that listens for the event and dynamically imports the palette only after the user opens search; update `TopBar` only if the event wiring needs a stable exported helper.
4. In `learnova-academy/src/app/layout.tsx`, move Microsoft Clarity from the inline body script to a lazy non-critical load path, preferably `next/script` with `strategy="lazyOnload"` or an equivalent idle callback. Preserve Vercel Analytics and do not remove Clarity entirely unless the Lighthouse trace proves it is the dominant LCP contention and the PR notes call out that rollback.
5. Re-run local Lighthouse. If LCP is still above 2500 ms and the trace shows the course hero text is LCP with font-related delay, make the smallest typography-path fix in `src/app/layout.tsx`, `src/app/academy.css`, and/or `src/app/learn/[slug]/page.tsx`: reduce non-critical `next/font` preloads/weights, avoid loading JetBrains Mono on first paint, or let the course hero use the system serif fallback before Source Serif 4. Do not change course content.
6. Run verification and open/update PR #68 with before/after metrics. If the preview still cannot reach <2500 ms after steps 3-5, stop and block with the trace evidence rather than adding new scope.
7. Comment on KOEA-2170, KOEA-2156, and KOEA-2135 with the revised plan marker `koea-2170-lcp-replan-r2`, changed files, before/after LCP/CLS/TBT, PR URL, and whether the final fix was palette, Clarity, font, or a measured combination.

## Verification (QA Verifier checks these)
- [ ] `pnpm --dir learnova-academy typecheck` passes on the PR branch.
- [ ] `pnpm --dir learnova-academy build` passes after the normal vault sync.
- [ ] Mobile Lighthouse on local production or PR preview reports LCP `<2500 ms`, CLS `<=0.1`, and TBT not meaningfully worse than the prior acceptable runs; attach or summarize the JSON metrics.
- [ ] Course smoke: `/learn/picking-a-frontier-model-2026-q2` shows the title, chapter list, first chapter content, bottom navigation, and no console errors.
- [ ] Search/Nova smoke: clicking the topbar search opens the command palette after lazy loading; opening Nova and sending a short question still reads `#nova-tutor-context` and streams a grounded answer.
- [ ] Analytics smoke: Vercel Analytics remains mounted and Clarity still loads after idle/lazy load on a production-like page unless intentionally disabled with trace evidence.

## Risk
- The Vercel preview may be slower than G2/live because of deployment variance rather than code. Mitigation: require the trace and LCP element/subpart evidence before each change, compare local production and preview results, and stop with a measured blocker if the remaining gap is environment noise rather than code.

## Out of scope
- Rewriting course prose, citations, slide/audio assets, Nova API behavior, or sitemap/source URL fixes.
- Touching `learnova-tc`, Convex, `learnova-admin`, `learnova-sales`, or `learnova-student`.
- Replacing the sitewide design system, removing the command palette feature, or removing analytics permanently without explicit Chief Engineering approval.
