---
ticket: KOEA-2571
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.30
base_branch: academy/redesign-v1
revision: 2
revision_ticket: KOEA-2732
review_trigger: KOEA-2681
---

# Plan: Add tested blog glossary auto-link triggers

## Goal
Make glossary hover-cards observable on Academy blog posts without expanding scope beyond `learnova-academy` blog rendering. Success means `/blog/2026-05-14-anthropic-mcp-legal-platform-playbook` renders known glossary terms such as `MCP` and `RAG` as `GlossaryPopover` triggers, while ordinary markdown links, course wikilinks, inline code, footnotes, headings, and article layout continue to work.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:22-23`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:240-277`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:287-547`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx:24-76`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/glossary.ts:12-42`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json:4-10`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/blogs/2026-05-14-anthropic-mcp-legal-platform-playbook/draft.md:88-189`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/glossary/mcp.md:1-18`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/glossary/rag.md:1-16`.
- Relevant prior work: KOEA-2681 requested plan changes because revision 1 did not require automated parser regression tests and allowed untestable inline helper placement. PR #42 (`koea-2649/glossary-popover-autolink` -> `academy/redesign-v1`) is already open and changed `learnova-academy/src/app/blog/[slug]/page.tsx` plus `learnova-academy/src/lib/glossary-autolink.ts`; treat it as paused until revised to match this plan.
- Constraints: implementation target is `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on `academy/redesign-v1`; `git ls-remote --heads origin academy/redesign-v1` was verified. Current local checkout is on `main`, so Executor must use the issue execution workspace or otherwise start from `origin/academy/redesign-v1` and preserve unrelated work. No Convex deploys, no cross-portal edits, and no glossary taxonomy/content additions unless Chief Engineering opens a separate content ticket.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extract the auto-link parser to `learnova-academy/src/lib/glossary-autolink.ts` as pure exported functions with targeted Vitest coverage, then wire the blog renderer to map parser link tokens to `GlossaryPopover`. The parser should build aliases from `listGlossary()` entries, prefer longer aliases, match case-insensitively with word boundaries, link each slug once per article, cap total links, and expose a safe inline-tokenization path that can prove code spans, markdown links, footnote markers, headings, and existing wikilinks are not auto-linked.

**Rejected**: Keep the parser inline in `page.tsx`, because KOEA-2681 correctly flagged that as hard to unit test and likely to drift inside a large renderer. **Rejected**: Manually add `[[glossary/...]]` links to the repro blog, because it fixes one article instead of the blog rendering behavior. **Rejected**: Move glossary processing into the vault sync/content pipeline, because the ticket is scoped to `learnova-academy` rendering and build-time source rewrites would broaden risk.

## Steps (Executor follows in order)
1. Start from `origin/academy/redesign-v1`, then update PR #42 rather than opening a competing branch; if the PR branch cannot be reused cleanly, preserve its work and explain the replacement branch in the handoff.
2. Update `learnova-academy/package.json` and lockfile only as needed so `pnpm --dir learnova-academy test -- src/lib/glossary-autolink.test.ts` runs real tests, not the current placeholder `echo`; prefer a minimal Vitest setup.
3. Implement `learnova-academy/src/lib/glossary-autolink.ts` with pure exported matcher/context/tokenization functions; derive aliases from `entry.term`, including parenthetical acronyms such as `MCP` and full terms such as `Model Context Protocol`.
4. Add `learnova-academy/src/lib/glossary-autolink.test.ts` covering acronym and full-term matching, case-insensitive word-boundary behavior, no matches inside larger words, no auto-links in code spans, no auto-links inside markdown links or existing wikilinks, no auto-links for footnote markers/headings when disabled, one-link-per-slug, and total-link cap.
5. Wire `learnova-academy/src/app/blog/[slug]/page.tsx` so `BlogBody` builds the matcher from `listGlossary()`, carries one article-level context through rendering, auto-links only safe paragraph/list prose chunks, keeps explicit `[[glossary/<slug>|label]]` handling before auto-linking, and leaves headings, code spans, markdown links, footnotes, and other wikilinks unmodified.
6. Update the PR #42 description or issue handoff to state that the PR was revised after KOEA-2681, list the parser test file, and confirm it must receive a fresh G_code review before implementation proceeds.

## Verification (QA Verifier checks these)
- [ ] `pnpm --dir learnova-academy test -- src/lib/glossary-autolink.test.ts` exits 0 and includes the required parser cases from Step 4.
- [ ] `pnpm --dir learnova-academy lint` exits 0 or reports only unrelated pre-existing failures named in the handoff.
- [ ] `pnpm --dir learnova-academy typecheck` exits 0.
- [ ] On `/blog/2026-05-14-anthropic-mcp-legal-platform-playbook`, `MCP` and `RAG` in article prose are rendered as links to `/glossary/mcp` and `/glossary/rag` with glossary trigger styling.
- [ ] Hover or keyboard focus on the `MCP` glossary trigger displays a `role="tooltip"` card populated from `/api/glossary/mcp`.
- [ ] Existing course wikilinks in the same article, especially `[[course/claude-tool-use-from-zero]]`, still link to `/learn/claude-tool-use-from-zero`.

## Risk
- Adding auto-linking can overmatch common words or increase client popover islands. Mitigation: keep the parser pure and tested, require word boundaries, skip protected markdown constructs, link each slug once, cap total auto-links, and limit UI wiring to blog paragraph/list prose.

## Out of scope
- Creating missing glossary entries for `e-discovery` or `vertical AI`, changing course rendering, changing Convex, replacing the blog markdown renderer, or approving/merging PR #42 without a fresh G_code pass.

## Executor handoff
Pre-flight telemetry: status_verified=true, assignee_verified=true, parent_chain_depth=2, active_sibling_count=1, spec_verified=true, basebranch_verified=true. Revision 2 addresses KOEA-2681 by locking implementation to `src/lib/glossary-autolink.ts`, requiring automated parser tests and an exact targeted test command, and requiring PR #42 to be revised before G_code. Product-scope confirmation: blog hover-cards are intended because `GlossaryPopover.tsx` says it replaces `[[glossary/<term>]]` in chapter/blog body and `page.tsx` already handles explicit glossary wikilinks; the missing behavior is automatic conversion of known glossary terms in plain blog prose.
