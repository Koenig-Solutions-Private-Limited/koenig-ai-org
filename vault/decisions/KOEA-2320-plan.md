---
ticket: KOEA-2320
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.28
base_branch: academy/redesign-v1
plan_revision: 2
---

# Plan: Re-fix GlossaryPopover lint path and verify Claude Security blog weight

## Goal
Get KOEA-2320 back through the engineering harness without bypassing plan-review. Success is observable when `GlossaryPopover.tsx` no longer has the stale cached-data path that triggered PR #53 review feedback, and `/blog/claude-security-beta-devsecops` serves at or below 81,920 bytes from the current website route.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx:24-54`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:101-112`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:235-250`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/client-shell.tsx:17-52`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx:46-112`.
- Relevant prior work: PR #53 remains open and its latest Code Reviewer finding says `GlossaryPopover` initializes `data` from the first slug only, then `if (!open || data || cache.get(slug) !== undefined)` can suppress fetches after `term` changes. The old May plan is stale because the blog route moved to `src/app/(site)/blog/[slug]` and the client no longer receives `body` or `markdownForToc`.
- Constraints: base branch `academy/redesign-v1` exists as of 2026-07-09; keep changes inside `learnova-academy` website code; do not touch Convex; preserve unrelated dirty worktree files already present in both repos; do not assign fresh Executor work until Code Reviewer passes this plan-review gate.

## Approach (1 chosen, alternatives rejected)
**Chosen**: make the remaining fix small and evidence-driven. First repair `GlossaryPopover` so cached glossary state is keyed to the current `slug` instead of using one-time state initialization that can go stale. Then freshly measure the current blog route's served HTML and remove only proven oversized initial-payload contributors, starting with accidental client/RSC payload duplication and nonessential below-article payload before any article-content reduction.

**Rejected**: replay the May prop-removal plan unchanged, because the current `BlogPageClient` already takes `headings` only and `TutorRail` already derives article text from the rendered DOM. **Rejected**: immediately trim the approved blog article, because the current overweight source has to be measured first and page shell/RSC payload may be enough. **Rejected**: route directly to Executor, because Chief Engineering explicitly required Plan-Review first and Executor is over the configured monthly cap.

## Steps (Executor follows in order)
1. In `src/components/GlossaryPopover.tsx`, replace the one-time `useState(() => cache.get(slug) ?? null)` plus `data` truthiness guard with slug-keyed state, for example `{ slug, data }`, so a new `term` cannot display or suppress fetches with previous-term data.
2. Keep the glossary fetch effect asynchronous-only: on open, read `cache.get(slug)` for the current slug, set current-slug state from cache when present, fetch only when the cache has no entry, and ignore late responses for old slugs via the existing cancellation guard or an equivalent current-slug check.
3. Verify `BlogPageClient` still receives only `slug`, `title`, `readingTimeMin`, and `headings`; if measurement shows overweight, inspect served HTML and `self.__next_f.push` chunks before editing page code.
4. If page weight is still above 81,920 bytes, remove or defer the smallest measured nonessential initial-payload contributors in `src/app/(site)/blog/[slug]/page.tsx` or `client-shell.tsx` first, such as duplicate body-like props, oversized related-card data, or below-article modules that are not needed for first render.
5. If the route remains above 81,920 bytes after code-level payload removal, make only minimal non-substantive markdown/frontmatter reductions for `claude-security-beta-devsecops`, preserving section substance, citations, glossary links, Nova tutor behavior, TOC, and References.
6. Do not modify Convex, shared portal code, unrelated blog routes, or the current untracked/modified files unless they are the exact files required by steps 1-5.

## Verification (QA Verifier checks these)
- [ ] `pnpm lint` passes, or any remaining warnings/errors are unrelated and named in the handoff.
- [ ] `pnpm typecheck` passes.
- [ ] `pnpm test` passes.
- [ ] Served HTML for `/blog/claude-security-beta-devsecops` is `<= 81920` bytes by `curl -sS http://localhost:3010/blog/claude-security-beta-devsecops | wc -c`.
- [ ] Browser smoke confirms article body, TOC, Nova tutor, glossary popovers, References, related sections, and audio player presence/absence still behave coherently on the changed page.
- [ ] A manual or automated glossary smoke confirms the same mounted `GlossaryPopover` instance cannot show prior-term data after its `term` prop changes.

## Risk
- Page-weight optimization can accidentally remove useful below-article discovery or tutor context. Mitigation: make measurement identify the largest payload source first, keep article substance intact unless all code-level payload cuts fail, and verify the visible blog affordances after the byte-size check.

## Out of scope
- Convex changes, platform authentication, unrelated SEO rewrites, publishing/merging PR #53, dispatching Executor before Plan-Review, or optimizing all blog pages beyond the specific Claude Security route.

## Plan-review handoff
Route this revision to Code Reviewer for G_plan. Executor must wait for Code Reviewer approval before changing website files. Pre-flight telemetry: status_verified=true, assignee_verified=true, spec_verified=true, basebranch_verified=true, sibling_check=root-auto-pass, plan_review_required=true.
