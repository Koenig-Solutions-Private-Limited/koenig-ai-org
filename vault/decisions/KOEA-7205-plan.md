---
ticket: KOEA-7205
planner: planner
date: 2026-06-03
estimated_complexity: medium
estimated_token_cost: $0.55
base_branch: academy/redesign-v1
basebranch_verified: true
triggered_by_approval: 49905f96-0971-41c6-a1d9-5a80effd9b77
---

# Plan: Wire Quick Takeaways into course chapter pages

## Goal
Make Quick Takeaways render consistently for course markdown on both the existing long course page, `/learn/[slug]`, and the intended standalone chapter page, `/learn/[slug]/[chapterSlug]`. Success means fenced ```takeaways blocks render as the existing styled component, standalone chapter URLs exist and navigate prev/next correctly, and the first backfill wave has a bounded chapter list for content agents.

## Context
- Files to read first: `learnova-academy/src/components/_shared/Takeaways.tsx:3-34`, `learnova-academy/src/lib/markdown-fence.ts:16-22`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:365-373`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:801-815`, `learnova-academy/src/components/CourseChapterContent.tsx:16-22`, `learnova-academy/src/components/CourseChapterContent.tsx:395-402`, `learnova-academy/src/lib/courses.ts:280-399`, `learnova-academy/src/app/academy.css:620-649`.
- Relevant prior work: Quick Takeaways component and CSS already exist; blog and `/learn/[slug]` renderers already call `parseTakeawaysBlock`. `CourseChapterContent.chapterPath()` already points at `/learn/${courseSlug}/${ch.slug}`, but there is currently no checked-in `src/app/(site)/learn/[slug]/[chapterSlug]/page.tsx`.
- Constraints: implementation branch must be based on `academy/redesign-v1`; do not deploy Convex; keep to `learnova-academy` plus planned vault markdown backfill. Current local `learnovaBeast` checkout is dirty on another branch (`koea-7247/homepage-imagery-visual-hierarchy`) with changes in `learnova-academy/src/app/academy.css` and `learnova-academy/src/components/CourseChapterContent.tsx`, so Executor must use a clean worktree or coordinate before editing.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add the missing standalone chapter route and reuse the existing Takeaways parser/component. The route should use `getCourse`, `listDiscoverableCourses`, and `CourseChapterSection` from `CourseChapterContent.tsx` so `/learn/[slug]/[chapterSlug]` renders the same markdown block pipeline that already recognizes fenced `takeaways` blocks, while `/learn/[slug]` remains unchanged except for any tiny compatibility fixes required by the shared component.
**Rejected**: duplicate the full renderer inside the new route - this would fork markdown behavior and make Takeaways drift between long-form and standalone pages; add a new frontmatter field for takeaways - fenced blocks already exist as the parser contract and avoid schema changes.

## Steps (Executor follows in order)
1. Prepare a clean `learnovaBeast` worktree from `origin/academy/redesign-v1`; do not reuse the currently dirty feature checkout unless those unrelated changes are intentionally carried forward.
2. Add `learnova-academy/src/app/(site)/learn/[slug]/[chapterSlug]/page.tsx` with `generateStaticParams`, `generateMetadata`, `notFound()` handling, `TopBar`, and a constrained main content layout that renders exactly one matching chapter through `CourseChapterSection`.
3. In the new route, compute `prevChapter` and `nextChapter` from `course.chapters` and pass them into `CourseChapterSection` so `ChapterNavCard` follows the existing `/learn/${courseSlug}/${chapter.slug}` path contract.
4. Keep `learnova-academy/src/components/_shared/Takeaways.tsx` unchanged unless a narrow parser bug appears; valid content format is a standalone fenced block with one to three bullet or numbered lines.
5. Leave markdown backfill to KOEA-7225, scoped to renderable top-level chapter files in these first-pass courses: `mcp-from-first-principles-to-production` (5), `claude-mcp-mastery` (1), `claude-tool-use-from-zero` (10), `gemini-enterprise-agents` (8), `production-agents-claude-agent-sdk-mcp-connector` (5), and `picking-a-frontier-model-2026-q2` (4). Exclude courses with zero top-level `NN-slug.md` chapters until their content layout is normalized.
6. Verify route behavior locally from `learnova-academy`: run `pnpm typecheck`, then `pnpm dev` and browser/curl check `/learn/mcp-from-first-principles-to-production` plus `/learn/mcp-from-first-principles-to-production/why-mcp-exists`.
7. After KOEA-7225 backfills a sample chapter, repeat the browser check and confirm a visible `Quick Takeaways` box appears on both the long course page and the standalone chapter page without duplicate rendering.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm typecheck` passes on the implementation branch.
- [ ] `curl -I http://localhost:3010/learn/mcp-from-first-principles-to-production/why-mcp-exists` returns 200 after `pnpm dev`; an invalid chapter slug returns 404.
- [ ] A backfilled sample fenced block renders a visible `.quick-takeaways` card on both `/learn/[slug]` and `/learn/[slug]/[chapterSlug]`.
- [ ] Prev/next chapter cards on standalone pages navigate to `/learn/<course>/<chapter-slug>` and the first chapter's previous link returns to `/learn/<course>`.

## Risk
- The standalone route could accidentally diverge from the long course page's markdown renderer. Mitigation: reuse `CourseChapterSection`/`ChapterBody` through `CourseChapterContent.tsx` rather than cloning renderer logic.

## Out of scope
- Do not redesign the Quick Takeaways visual treatment, change course publication rules, normalize nested course folders, or backfill every vault course in the route implementation PR.

---

## G3 decision · CEO · 2026-06-10

**status: g3-passed**

- PR #116 (`koea-7223/quick-takeaways-chapter-wiring`, base `academy/redesign-v1`) verified: new route `learnova-academy/src/app/(site)/learn/[slug]/[chapterSlug]/page.tsx` reuses `CourseChapterSection` so fenced ```takeaways blocks flow through the same renderer that already exists on `/learn/[slug]` and on blog pages. Vercel preview SUCCESS.
- Plan review (KOEA-7222), G_code (KOEA-7224), and QA (KOEA-7226) all green; `pnpm typecheck` and `pnpm build` pass.
- Acceptance criteria named **claude-tool-use-from-zero (35 blocks / 10 chapters)**, **gemini-enterprise-agents (27 / 7)**, **mcp-from-first-principles-to-production (20 / 5)** — all three fully backfilled (82 / 22 confirmed via `grep -c '^\`\`\`takeaways'`).
- Plan §5 also scoped `claude-mcp-mastery` (1), `production-agents-claude-agent-sdk-mcp-connector` (5), `picking-a-frontier-model-2026-q2` (4) — these have **0** backfilled blocks today. Tracked as a follow-up child issue, not a G4 blocker, because the explicitly-named acceptance courses are complete and the route itself ships universally.

Next: request_board_approval filed for Vardaan G4 → merge PR #116 + propagate vault content via publish-action.
