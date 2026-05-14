---
ticket: KOEA-2571
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.25
base_branch: academy/redesign-v1
---

# Plan: Add blog glossary hover-card triggers for known terms

## Goal
Make glossary hover-cards observable on Academy blog posts without expanding scope beyond `learnova-academy` blog rendering. Success means `/blog/2026-05-14-anthropic-mcp-legal-platform-playbook` renders at least the existing glossary terms `MCP` and `RAG` as hoverable `GlossaryPopover` triggers, while ordinary markdown links, course wikilinks, code spans, footnotes, and article layout continue to work.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:20-23`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:295-333`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:499-685`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx:1-75`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/glossary.ts:35-49`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/blogs/2026-05-14-anthropic-mcp-legal-platform-playbook/draft.md:88-189`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/glossary/mcp.md:1-18`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/glossary/rag.md:1-16`.
- Relevant prior work: KOEA-2320 / KOEA-2329 covers a `GlossaryPopover.tsx` lint failure and blog page weight, but not this functional absence. Older wikilink plans (for example KOEA-339 and KOEA-709) established explicit blog wikilink parsing; current code already renders `[[glossary/<term>]]` in blogs as `GlossaryPopover`.
- Constraints: implementation target is `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy` on `academy/redesign-v1`; `git ls-remote --heads origin academy/redesign-v1` was verified. Current local worktree is not on that branch and has unrelated dirty/untracked files (`learnova-academy/next-env.d.ts`, `.claude/`, `.pnpm-store/`, `learnova-academy/public/slides/`), so Executor must use the issue execution workspace or otherwise preserve unrelated work. No Convex deploys, no cross-portal edits, and no new glossary taxonomy unless Chief Engineering opens a separate content ticket.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a narrow blog-renderer auto-linking pass for known glossary entries. Keep the existing explicit `[[glossary/...]]` path as the source of truth, but when `BlogBody` renders plain prose segments, derive a bounded matcher from `listGlossary()` and render first occurrences of known terms as `GlossaryPopover`. This matches the existing product scope: the popover component is documented for chapter/blog bodies and the blog renderer already imports it, but source blog prose does not contain glossary wikilinks today.

**Rejected**: Edit this one vault blog to manually add `[[glossary/mcp|MCP]]` and `[[glossary/rag|RAG]]`, because it fixes only the repro article and leaves the blog pipeline behavior absent. **Rejected**: Move glossary processing into the vault sync/content generation pipeline, because the current ticket is scoped to `learnova-academy` blog rendering and a build-time vault rewrite risks changing source content. **Rejected**: Fold this into KOEA-2320, because that ticket's acceptance is lint/page-weight cleanup; this is a separate functional rendering defect and can be sequenced after KOEA-2320 if that work lands first.

## Steps (Executor follows in order)
1. Start from `origin/academy/redesign-v1` in the Learnova execution workspace and preserve unrelated local work; if KOEA-2320 lands first, rebase before editing because it may touch `GlossaryPopover.tsx` or blog client payload code.
2. In `src/app/blog/[slug]/page.tsx`, import `listGlossary` and create a small server-side matcher from current glossary entries inside `BlogBody`; derive aliases from `entry.term` including parenthetical acronyms such as `MCP` and `RAG`, plus the full term without the parenthetical.
3. Add a helper in the same file or a new pure `src/lib/glossary-autolink.ts` that scans plain text segments case-insensitively, prefers longer aliases, respects word boundaries, skips already-seen slugs, and caps auto-links per article to prevent overlinking/page-weight growth.
4. Thread a render context from `BlogBody` through `renderBlock()` into paragraph and list-item `inline()` calls; do not auto-link headings, code spans, existing markdown links, footnotes, or existing `[[...]]` wikilinks.
5. In `inline()`, keep the explicit `[[glossary/<slug>|label]]` branch before the auto-link logic, then replace only plain text pushes (`remaining` chunks at the end of parsing) with text-plus-`<GlossaryPopover term={slug} label={matchedText} />` nodes from the helper.
6. Verify the repro article renders `/glossary/mcp` and `/glossary/rag` triggers in the article body and that hovering/focusing one trigger fetches `/api/glossary/mcp` and displays tooltip text.

## Verification (QA Verifier checks these)
- [ ] `pnpm --dir learnova-academy lint` exits 0 or reports only unrelated pre-existing failures named in the handoff.
- [ ] `pnpm --dir learnova-academy typecheck` exits 0.
- [ ] On `/blog/2026-05-14-anthropic-mcp-legal-platform-playbook`, `MCP` and `RAG` in article prose are rendered as links to `/glossary/mcp` and `/glossary/rag` with the dotted glossary-link styling.
- [ ] Hover or keyboard focus on the `MCP` glossary trigger displays a `role="tooltip"` card populated from `/api/glossary/mcp`.
- [ ] Existing course wikilinks in the same article, especially `[[course/claude-tool-use-from-zero]]`, still link to `/learn/claude-tool-use-from-zero`.

## Risk
- Auto-linking could overmatch common words or inflate the blog page with too many client popover islands. Mitigation: run it only on plain prose chunks, derive conservative aliases, require word boundaries, link each slug once per article, and cap total auto-links.

## Out of scope
- Creating missing glossary entries for `e-discovery` or `vertical AI`, changing course rendering, changing Convex, replacing the markdown renderer, or fixing KOEA-2320's lint/page-weight gates.

## Executor handoff
Pre-flight telemetry: status_verified=true, assignee_verified=true, sibling_guard_passed=true, spec_verified=true, basebranch_verified=true. Product-scope confirmation: blog hover-cards are intended, because `GlossaryPopover.tsx` explicitly says it replaces `[[glossary/<term>]]` in "chapter/blog body" and `src/app/blog/[slug]/page.tsx` already renders explicit glossary wikilinks with that component. Root-cause hypothesis: the renderer path exists, but current blog content contains no `[[glossary/...]]` wikilinks and no auto-linking pass converts known glossary terms into triggers.
