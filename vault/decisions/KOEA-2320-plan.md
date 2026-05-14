---
ticket: KOEA-2320
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
triggered_by_approval: 6c008f79-6fb0-4a72-b39f-4a9ba05e3240
---

# Plan: Fix GlossaryPopover lint and reduce Claude Security blog page weight

## Goal
Bring KOEA-2320's two blocking checks green in `learnova-academy`: `pnpm lint` must stop failing on `GlossaryPopover.tsx`, and `/blog/claude-security-beta-devsecops` must render at or below 81,920 bytes. Success should preserve the approved blog content and keep Nova tutor behavior available without shipping duplicate article markdown in the initial HTML.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx:31-54`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:67-78`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:261-266`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/client-shell.tsx:10-36`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx:26-63`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx:105-112`.
- Root-cause hypotheses: lint fails because the glossary effect synchronously calls `setData(cached)` inside the effect body; page weight is inflated because `BlogPageClient` serializes the full blog markdown twice as client props (`body` and `markdownForToc`) even though the server already renders the article body.
- Relevant prior work: KOEA-1235 is blocked on this prerequisite; KOEA-2329 chain alert approval `6c008f79-6fb0-4a72-b39f-4a9ba05e3240` authorizes continuing despite active sibling lanes.
- Constraints: use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on `academy/redesign-v1`; do not touch Convex; do not delete approved article content unless the DOM-prop fix cannot hit the 80 KB gate; respect any FE worktree lock if it reappears before execution.

## Approach (1 chosen, alternatives rejected)
**Chosen**: remove duplicated client-prop article payloads and defer tutor grounding extraction until user interaction. Pass server-computed `headings` into `BlogPageClient` instead of `markdownForToc={body}`, stop passing `body={body}` from the blog page, and extend `TutorRail` with an optional DOM text source such as `bodySourceSelector="#main article"` so `/api/tutor` still receives page context when the reader asks a question. Separately, fix `GlossaryPopover` by deriving initial cached data during state initialization and letting the effect only fetch/cache asynchronous misses.

**Rejected**: trim the approved `vault/blogs/claude-security-beta-devsecops/draft.md` article, because the measured payload issue is serialization duplication rather than excessive editorial length; change `/api/tutor` to load blog bodies server-side, because the route is `runtime = "edge"` and the current vault reader uses Node `fs`; remove Nova tutor from blog pages, because a smaller DOM-prop change should preserve the feature.

## Steps (Executor follows in order)
1. In `src/components/GlossaryPopover.tsx`, initialize `data` from `cache.get(term.toLowerCase()) ?? null`, keep the cache miss fetch inside `useEffect`, and remove the synchronous `setData(cached)` branch that triggers `react-hooks/set-state-in-effect`.
2. In `src/app/blog/[slug]/client-shell.tsx`, change props from `body` and `markdownForToc` to `headings: TocItem[]`, remove `extractHeadings`/`useMemo`, render `<Toc items={headings} />`, and call `<TutorRail ... bodySourceSelector="#main article" />`.
3. In `src/app/blog/[slug]/page.tsx`, pass the existing server-derived `headings` into `BlogPageClient` and stop passing `body={body}` or `markdownForToc={body}`; keep `BlogScrollLayer headings={headings}` unchanged.
4. In `src/components/_shared/tutor.tsx`, add optional `bodySourceSelector?: string`; compute the grounded body inside `send()` from `body ?? document.querySelector(bodySourceSelector)?.textContent ?? ""`; base `canStream` on a non-empty body prop or configured selector; send that computed body to `/api/tutor`.
5. Rebuild or restart the app and measure `/blog/claude-security-beta-devsecops` byte size from served HTML with `curl -sS http://localhost:3010/blog/claude-security-beta-devsecops | wc -c`; if still above 81,920 bytes, inspect remaining large `self.__next_f.push` chunks before considering content edits.
6. If a content edit is still needed after step 5, make only minimal non-substantive markdown reductions in `vault/blogs/claude-security-beta-devsecops/draft.md`, such as removing duplicate inline citation links already represented in the References footer; do not remove approved sections or the course CTA without Chief Engineering approval.

## Verification (QA Verifier checks these)
- [ ] `pnpm lint src/components/GlossaryPopover.tsx` exits 0.
- [ ] `pnpm lint` exits 0 or reports only unrelated pre-existing failures with file names captured in the handoff.
- [ ] Served page weight for `/blog/claude-security-beta-devsecops` is `<= 81920` bytes by `curl -sS http://localhost:3010/blog/claude-security-beta-devsecops | wc -c`.
- [ ] Blog page still renders TOC, Nova FAB, article body, glossary links, and References footer.
- [ ] Asking Nova a question on the blog still POSTs non-empty article text to `/api/tutor`.

## Risk
- DOM text extraction may include navigation/reference text or omit markdown formatting, slightly changing tutor grounding. Mitigation: extract from `#main article` only and verify the request body is non-empty and article-specific; the tutor API already accepts a string body and does not require raw markdown parsing.

## Out of scope
- Convex changes, portal changes, changing approved article substance, replacing the markdown renderer, or optimizing unrelated blog/course pages.

## Executor handoff
Use base branch `academy/redesign-v1` in `learnova-academy`; it was verified on 2026-05-14 with `git ls-remote --heads origin academy/redesign-v1`. Pre-flight telemetry: status_verified=true, assignee_verified=true, spec_verified=true, basebranch_verified=true, chain_alert_approval=6c008f79-6fb0-4a72-b39f-4a9ba05e3240.
