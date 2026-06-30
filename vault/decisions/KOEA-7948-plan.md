---
ticket: KOEA-7948
planner: planner
date: 2026-06-27
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
preflight_note: KOEA-7954 sibling-count preflight matched same-second auto-created child issues under KOEA-7948; no planner_chain_alert filed because the active sibling set is the planned execution chain.
---

# Plan: Guarantee at least 3 course FAQ entries

## Goal
Ensure every Academy course page emits at least three FAQ entries from `buildCourseFaqs()`, including `claude-agent-sdk-zero-to-production` and `claude-mcp-mastery`. Success means the fallback only adds a FAQ when existing course metadata would otherwise produce fewer than three entries, and both visible FAQ/on-page JSON-LD consumers continue to use the same shared builder output.

## Context
- Files to read first: `learnova-academy/src/lib/seo.ts:205`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:168`, `learnova-academy/src/app/(site)/courses/[slug]/page.tsx:1`, `learnova-academy/src/lib/courses.ts:120`, `learnova-academy/scripts/verify-g2-seo.mjs:1`.
- Relevant prior work: KOEA-7346 found course JSON-LD gaps; KOEA-7948 identifies two courses currently producing only two FAQ entries when they lack prerequisites, learning outcomes, and multi-chapter content.
- Constraints: work from `learnovaBeast` base branch `academy/redesign-v1` (verified present on origin). The issue names `~/Documents/Paperclip/learnovaBeast-fe-agent/` as the downstream worktree, but this Planner runtime only found `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`; Executor should use the assigned FE worktree if present, otherwise block with the lock/path owner and action.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a count-gated audience fallback inside `buildCourseFaqs()`. After the existing conditional/unconditional FAQ pushes, if `faqs.length < 3`, push `Who should take <title>?` using `targetAudience` when available and otherwise a generic audience derived from the course level, then return the list. This is the smallest contract-preserving fix because `/courses/[slug]` re-exports `/learn/[slug]`, and `/learn/[slug]` already passes `targetAudience` into the shared builder consumed by `faqPageLd()`.

**Rejected**: Add the audience FAQ unconditionally, because it changes FAQ ordering/count for every course even when they already have rich prereq/outcome/chapter FAQs. **Rejected**: Patch route-level JSON-LD in `/learn` or `/courses`, because that would duplicate builder logic and risk visible FAQ/schema drift. **Rejected**: Add course-specific metadata for the two slugs, because the bug is a general minimum guarantee in shared SEO generation.

## Steps (Executor follows in order)
1. In the FE worktree for `learnovaBeast`, create a branch from `origin/academy/redesign-v1`; if `~/Documents/Paperclip/learnovaBeast-fe-agent/` is missing or locked, either use the approved canonical checkout or mark KOEA-7956 blocked with the owner/action needed to restore that worktree.
2. Update `learnova-academy/src/lib/seo.ts` so `CourseFaqInput` includes the existing course level when needed for the fallback, and add a final `if (faqs.length < 3)` block before `return faqs`.
3. In the fallback block, compute `audienceDesc` as `c.targetAudience ?? \`${c.educationalLevel ?? "intermediate"} developers\`` and push a `Who should take ${c.title}?` FAQ whose answer mentions the audience, production scenarios, and free/no-payment access.
4. Update the `/learn/[slug]` call site in `learnova-academy/src/app/(site)/learn/[slug]/page.tsx` to pass `educationalLevel: course.level`; no change should be needed in `/courses/[slug]` because it re-exports the learn renderer.
5. Add or extend a focused verification script/test near existing Academy verification scripts to assert `buildCourseFaqs()` returns at least three entries for fixture inputs matching the two known failing shape: empty prerequisites, empty learning outcomes, one or zero chapters, with `targetAudience` present and absent.
6. Build or inspect rendered artifacts for `claude-agent-sdk-zero-to-production` and `claude-mcp-mastery`, then verify each page's FAQPage JSON-LD contains at least three `mainEntity` questions and includes a `Who should take ...?` question only when the pre-existing count would have been below three.

## Verification (QA Verifier checks these)
- [ ] `buildCourseFaqs()` returns at least three entries for a course with no prerequisites, no learning outcomes, and at most one chapter.
- [ ] `buildCourseFaqs()` preserves existing richer courses without adding duplicate/unneeded fallback FAQs when the count is already at least three.
- [ ] After build, `learnova-academy/.next/server/app/courses/claude-agent-sdk-zero-to-production.html` and `learnova-academy/.next/server/app/courses/claude-mcp-mastery.html` each contain FAQPage JSON-LD with at least three `mainEntity` questions.
- [ ] Targeted checks pass from `learnova-academy`: the new focused FAQ verification plus `pnpm typecheck`; run `pnpm build` if artifact verification depends on refreshed HTML.

## Risk
- The fallback might add generic copy to courses where richer metadata should have supplied a better FAQ. Mitigation: gate strictly on `faqs.length < 3`, prefer `targetAudience`, and use `educationalLevel` only as the final generic descriptor.

## Out of scope
- Rewriting course frontmatter/content, changing FAQPage schema structure, changing sitemap/canonical routing, or redesigning the course page FAQ UI.
