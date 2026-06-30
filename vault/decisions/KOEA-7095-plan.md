---
ticket: KOEA-7095
planner: planner
agent: planner
date: 2026-06-02
type: decision
tags:
  - decision
  - planning
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: a380c560-8131-48f5-aee1-0d0e776c4ed6
---

# Plan: Quick Takeaways blocks at H2 boundaries

## Goal
Render a distinct "Quick Takeaways" callout for each H2 section in blog and learn/chapter prose without introducing a new markdown engine. Success means authors can add a simple block after every `##` heading, the Academy frontend renders it consistently on mobile and desktop, and the content pipeline has explicit handoffs for new-draft enforcement plus top-10 blog backfill.

## Context
- Files to read first: `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:268-337`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:736-980`, `learnova-academy/src/components/CourseChapterContent.tsx:323-620`, `learnova-academy/src/app/academy.css:533-541`, `learnova-academy/src/lib/vault.ts:1-205`, `learnova-academy/src/lib/courses.ts:1-120`
- Relevant prior work: KOEA-6972 backlog request promoted into KOEA-7095; chain authorization approval `a380c560-8131-48f5-aee1-0d0e776c4ed6` confirms the Plan -> Plan Review -> Implement -> G_code -> G2 split is intentional.
- Constraints: Executor must use `~/Documents/Paperclip/learnovaBeast-fe-agent/` on branch `academy/redesign-v1`; Planner read the fetched `origin/academy/redesign-v1` because that exact worktree path was not present in this session. Keep the frontend change at five files or fewer. Do not author the top-10 takeaway prose inside the frontend PR.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Explicit fenced takeaways blocks. Add a server-safe shared component at `src/components/_shared/Takeaways.tsx` that exports both `<Takeaways items={...} />` and `parseTakeawaysBlock(raw)`. Authors write a paragraph-separated block immediately after each H2:

~~~markdown
```takeaways
- First section takeaway.
- Second section takeaway.
- Optional third section takeaway.
```
~~~

The existing renderers already split markdown into paragraph blocks, so each renderer can check `parseTakeawaysBlock(trimmed)` before list/paragraph rendering and return the shared component. This avoids MDX migration risk, keeps malformed blocks visible as ordinary prose only when they do not match the fenced syntax, and gives Content Reviewer a concrete pattern to enforce.

**Rejected**: Auto-generate takeaways from section prose - too much editorial risk and no deterministic G0 evidence. **Rejected**: Introduce remark/MDX parsing for blogs and chapters - higher blast radius than the custom renderer needs. **Rejected**: `{takeaways}` brace blocks - ambiguous with existing plain paragraph handling and harder to validate than fenced code.

## Steps (Executor follows in order)
1. In `learnova-academy/src/components/_shared/Takeaways.tsx`, create a server component that renders an `<aside>` with an eyebrow label `Quick Takeaways`, a concise heading or hidden label, and a 2-3 item `<ul>`. Export `parseTakeawaysBlock(raw: string): string[] | null` that accepts only fenced `takeaways` blocks and strips leading `-`, `*`, or numbered markers.
2. In `learnova-academy/src/app/(site)/blog/[slug]/page.tsx`, import the component/parser and add a `takeaways` branch near the top of `renderBlock`, before the generic list branch. Keep glossary auto-linking out of takeaways unless the Executor can do it without expanding scope.
3. In `learnova-academy/src/app/(site)/learn/[slug]/page.tsx`, import the same parser/component and add the branch to the local `renderBlock`, before `##`/list/paragraph fallbacks so chapter-level fenced blocks render consistently.
4. In `learnova-academy/src/components/CourseChapterContent.tsx`, mirror the same branch so any alternate course chapter renderer does not diverge from `learn/[slug]/page.tsx`.
5. In `learnova-academy/src/app/academy.css`, add responsive styles for `.quick-takeaways`, `.quick-takeaways__eyebrow`, and list items using existing tokens (`--surface-2`, `--rule`, `--teal-700`, `--ink`, `--ink-soft`). Keep desktop/mobile spacing close to `.blog-callout` and existing chapter callouts.
6. Add a Paperclip handoff comment or child request for Chief Content: Blog Author must add one fenced `takeaways` block immediately after every H2 in new blogs; Content Reviewer G0 must block new blog drafts missing a block for any H2; top-10 existing blogs must be backfilled by Blog Author/Content Author and rechecked by Content Reviewer before publication status changes.
7. Keep the PR scoped to the frontend renderer/component plus the content-handoff note. Do not bulk-edit vault blog drafts in the implementation PR.

## Verification (QA Verifier checks these)
- [ ] On a local branch from `academy/redesign-v1`, run `pnpm --dir learnova-academy typecheck` and `pnpm --dir learnova-academy lint`.
- [ ] Build with `pnpm --dir learnova-academy build`; note that `pnpm --dir learnova-academy test` is currently a no-op per `package.json`.
- [ ] Add or temporarily use one blog fixture/draft with two H2 sections and fenced takeaways; verify `/blog/<slug>` renders two callouts, preserves heading anchors/TOC, and leaves inline images after headings intact.
- [ ] Add or temporarily use one course chapter with fenced takeaways; verify `/learn/<slug>` renders the callout in the chapter body and `CourseChapterContent` renders the same branch if that path is used.
- [ ] Run a Lighthouse/perf sanity check on one blog page and one learn page before/after the PR. The callouts should not add client JS, layout shift, or meaningful LCP/CLS regression.

## Risk
- The custom paragraph splitter requires blank lines around fenced blocks; authors may omit them and get plain text. Mitigation: make the Blog Author and Content Reviewer handoff specify exact fenced syntax with blank lines before and after every block, and have G0 reject malformed/missing blocks.

## Out of scope
- Auto-generating takeaway copy, choosing the actual top-10 traffic list from analytics, bulk editing 10 existing vault blog drafts inside the frontend PR, and replacing the custom markdown renderers with MDX/remark.
