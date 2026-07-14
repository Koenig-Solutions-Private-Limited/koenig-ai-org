---
ticket: KOEA-7076
planner: planner
date: 2026-07-14
estimated_complexity: medium
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
source_planner_ticket: KOEA-7078
revision: 2
triggered_by: G_code REQUEST CHANGES — runs 034ce298 and e5ee7c18 (missing failure/empty-state behavior; implicit /tutor navigation contract)
---

# Plan: Add Sonnet 4.6 Try in Nova CTAs to course chapters

## Goal
Course chapter pages must show a visible "Try this with Sonnet 4.6" affordance after rendered chapter H2 sections on `/learn/claude-tool-use-from-zero#ch-01-introduction-to-claudes-tool-use`. Clicking the CTA should open the existing Nova tutor with an editable draft prompt prefilled for that section, and the stale `Claude Sonnet 4.5` label must become `Claude Sonnet 4.6`.

## Context
- Files to read first: `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:477-495`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:968-1022`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:1102-1135`, `learnova-academy/src/components/_shared/tutor-open.ts:1-10`, `learnova-academy/src/components/_shared/tutor.tsx:95-104`, `learnova-academy/src/components/_shared/content.tsx:36-39`.
- Relevant prior work: KOEA-7076 DOM audit reported no `Sonnet 4.6`, no `Try this` / `Ask Nova` CTA, and a stale `Claude Sonnet 4.5` label. Current local learnovaBeast workspace has untracked chapter-route residue including `learnova-academy/src/components/CourseChapterContent.tsx`; `origin/academy/redesign-v1` does not contain that extraction.
- Constraints: Target only `learnova-academy`; do not deploy Convex. Executor must start from a clean dedicated branch/worktree on `academy/redesign-v1`, must not stage unrelated untracked files, and should treat the untracked `CourseChapterContent.tsx` / `[chapterSlug]` files as out of scope unless they are already committed on the fresh branch.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small client CTA component and render it from the committed course page `ChapterBody` H2 path. `page.tsx` is a server component, but it can import a focused `"use client"` button that calls the existing `openTutorWithMessage()` event helper; this keeps the behavior on the actual target branch, reuses the current TutorRail draft-prefill mechanism, and avoids adopting local untracked route work.
**Rejected**: Modify `CourseChapterContent.tsx` because it is untracked in the current workspace and absent from `origin/academy/redesign-v1`; plan against it would not execute cleanly. Add markdown `<RunPromptCell>` blocks to course content because it would require content edits across chapters and would not guarantee every H2 gets the CTA. Expand TutorRail API or auto-submit prompts because the existing event already opens Nova and pre-fills a draft with less behavioral risk.

## Steps (Executor follows in order)
1. In `learnovaBeast`, create a clean branch from `origin/academy/redesign-v1` for KOEA-7076; run `git status --short --branch` and proceed only if no unrelated tracked changes will be staged.
2. Add `learnova-academy/src/components/TryInNovaCta.tsx` as a client component that renders a compact button with visible copy `Try this with Sonnet 4.6`, imports `openTutorWithMessage` from `_shared/tutor-open`, and on click pre-fills Nova with exactly: `Try this section with Sonnet 4.6: <heading>\n\nGive me one practical prompt to run, explain what a strong answer should include, and ask one follow-up question to check my understanding.` Empty-state: if the `heading` prop is empty or whitespace, return `null` — render no CTA. Failure-state: wrap the `openTutorWithMessage` call in try/catch; on throw, log the error to console and return early — user stays on the learn page with no crash, no navigation, no visible error UI needed.
3. Update `learnova-academy/src/app/(site)/learn/[slug]/page.tsx` to import `TryInNovaCta` and change the `trimmed.startsWith("## ")` render branch so it returns the existing H2 followed immediately by `<TryInNovaCta heading={stripFormatting(text)} />`; keep the current infographic injection behavior after the first H2 intact.
4. Update `learnova-academy/src/components/_shared/content.tsx` so the Claude option label changes from `Claude Sonnet 4.5` to `Claude Sonnet 4.6`.
5. Run focused verification from `learnova-academy`: `pnpm lint`, `pnpm typecheck`, and `pnpm build`.
6. Browser-check `http://localhost:3010/learn/claude-tool-use-from-zero#ch-01-introduction-to-claudes-tool-use`: confirm each rendered H2 is followed by `Try this with Sonnet 4.6`, no `Claude Sonnet 4.5` text remains, clicking the CTA opens the tutor at the `/tutor` route surface (confirm URL path includes `/tutor`), Nova's input contains the exact draft prompt with the clicked H2 heading and the message is not auto-sent, and that a section with no heading text shows no CTA button.
7. Open the PR against `academy/redesign-v1` with notes for G_code/G2 that the change is limited to the Academy frontend, no Convex deploy is needed, and the key QA path is the reported chapter-anchor URL.

## Verification (QA Verifier checks these)
- [ ] Reported route `/learn/claude-tool-use-from-zero#ch-01-introduction-to-claudes-tool-use` visibly contains `Try this with Sonnet 4.6` after chapter H2 sections.
- [ ] Clicking a CTA opens the Nova tutor at the `/tutor` route surface (URL contains `/tutor`) and pre-fills, without auto-sending, the exact Sonnet 4.6 draft prompt for that section heading.
- [ ] A section whose heading resolves to empty/whitespace renders no CTA. If `openTutorWithMessage` dispatch throws at click time, the page does not crash and the user remains on the learn page.
- [ ] Search/build output shows no remaining user-visible `Claude Sonnet 4.5` label in `learnova-academy`.

## Risk
- The CTA is rendered after every markdown H2, which may be visually repetitive on dense chapters. Mitigation: keep the component compact and scoped to H2s only; if QA finds clutter, reduce to substantive H2s in a follow-up ticket instead of changing scope during execution.

## Out of scope
- Do not adopt or complete the untracked `[chapterSlug]` route / `CourseChapterContent.tsx` extraction.
- Do not edit course markdown content to add per-section `RunPromptCell` blocks.
- Do not change Nova streaming behavior, model backend selection, or Convex data.

Pre-flight: status=active; sibling_count=1; chain_depth=2; acceptance_criteria=3; basebranch_verified=true.
