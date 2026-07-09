---
ticket: KOEA-10837
planner: planner
agent: planner
date: 2026-07-09
type: decision
tags:
  - decision
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Add SSR indexable Nova content below /tutor chat

## Goal
Add the provided three static Nova content sections to the `/tutor` server-rendered HTML so crawlers can see meaningful tutor copy, sample questions, and course/blog links without JavaScript. Success is observable in the raw `/tutor` response: static `<h2>` text, sample-question prose, and at least five `/learn/` links appear below the chat shell without changing the above-the-fold chat experience.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/tutor/page.tsx:7`, `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/tutor/tutor-static-shell.tsx:3`, `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/tutor/tutor-hydrate.tsx:5`, `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/tutor/tutor-client.tsx:39`, `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy/src/app/academy.css:138`
- Relevant prior work: KOEA-6710 split `/tutor` into a server-rendered static shell plus `TutorHydrate` client island; current `TutorClient` hides `#tutor-static-shell` after hydration.
- Constraints: use repository `learnovaBeast/learnova-academy`, worktree `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent/learnova-academy`, base branch `academy/redesign-v1` verified on origin. The named FE worktree has a stale `.git` pointer in this container, so branch verification was performed from another valid learnovaBeast clone. Do not invent or rewrite copy beyond the three sections in KOEA-10837.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small server-only `TutorIndexabilityContent` component and render it from `TutorStaticShell` immediately after the existing chat grid `<main>`. Store the three provided HTML sections as a static controlled HTML string and render it inside a wrapper div with `dangerouslySetInnerHTML`; this preserves the supplied markup and copy verbatim while keeping the block SSR-only. Add scoped CSS in `academy.css` so the block starts below the `100vh` chat shell, uses existing dark theme tokens, and does not affect the hydrated chat UI.

**Rejected**: Paste the long block inline in `tutor-static-shell.tsx` - works but makes the LCP shell hard to scan; use JSX for every paragraph and link - safer React style, but it forces `className` conversion and increases copy-drift risk; render below `TutorHydrate` in `page.tsx` - could become visible under the hydrated client app and create duplicate user-facing page structure.

## Steps (Executor follows in order)
1. Create `src/app/tutor/tutor-indexability-content.tsx` exporting `TutorIndexabilityContent`, with a static `NOVA_INDEXABILITY_HTML` string copied from KOEA-10837's three "Copy to implement" sections without text, heading, link, or class changes.
2. Update `src/app/tutor/tutor-static-shell.tsx` to import `TutorIndexabilityContent` and render it after the existing `<main>` chat grid and before the closing `</div>` for `#tutor-static-shell`.
3. Add scoped styles in `src/app/academy.css` for `.nova-indexability-wrapper`, `.nova-capabilities`, `.nova-sample-questions`, and `.nova-related-courses`, using existing tokens, a top divider, constrained readable width, and spacing that leaves the chat shell above the fold.
4. Preserve `src/app/tutor/tutor-hydrate.tsx` and `src/app/tutor/tutor-client.tsx` behavior so the client island still hides `#tutor-static-shell` after hydration and the chat UX remains unchanged.
5. Run the verification commands locally against the built app; if the raw response remains below 80 KB after the verbatim copy is present, report that as a KOEA-10837 acceptance-risk instead of padding the page with unspecced content.

## Verification (QA Verifier checks these)
- [ ] `pnpm typecheck` passes in `learnova-academy`.
- [ ] After `pnpm build` and `pnpm start`, `curl -s http://localhost:3010/tutor | wc -c` is checked against the 80000-byte target and the result is reported.
- [ ] `curl -s -A Googlebot http://localhost:3010/tutor | grep -c '<h2>'` returns at least 3.
- [ ] `curl -s -A Googlebot http://localhost:3010/tutor | grep -c 'href="/learn/'` returns at least 7, and `grep -c 'href="/blog/'` returns at least 1.
- [ ] `curl -s -A Googlebot http://localhost:3010/tutor | grep -c 'How does Claude tool use work in production'` returns at least 1, proving sample-question prose is present without JavaScript.

## Risk
- The supplied three-section copy may not raise the raw response from the reported 38 KB to 80 KB by itself; mitigation is to verify and report the byte count explicitly, then ask Chief Engineering for additional approved copy if the byte-count acceptance remains unmet.

## Out of scope
- Wiring real tutor responses, changing `/api/tutor`, altering course/blog routes, adding new marketing copy, or modifying the hydrated chat UI beyond preserving its current behavior.
