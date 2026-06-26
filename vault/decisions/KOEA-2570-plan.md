---
ticket: KOEA-2570
planning_issue: KOEA-2627
planner: planner
date: 2026-05-14
type: decision
tags:
  - decision
  - course/academy
estimated_complexity: medium
estimated_token_cost: $0.42
base_repo: learnovaBeast
base_branch: academy/redesign-v1
basebranch_verified: true
worktree: /paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570
branch: koea-2570/mdx-rendering
---

# Plan: Repair Academy course chapter MDX rendering

## Goal
Fix the Academy course chapter body renderer so authored course content no longer leaks MDX-like component source or fenced-code delimiters as raw prose. Success means `Callout`, `KnowledgeCheck`, and `RunPromptCell` render as learner-facing widgets, Python fences render as code blocks, `[[course/.../...]]` references become internal links, and Nova markdown behavior is either fixed in the same Academy renderer scope or explicitly documented as deferred.

## Context
- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/app/learn/[slug]/page.tsx:1`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/app/learn/[slug]/page.tsx:986`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/components/_shared/content.tsx:39`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/components/_shared/content.tsx:229`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/lib/courses.ts:152`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/scripts/sync-vault.mjs:1`, `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy/src/components/_shared/tutor.tsx:467`.
- Evidence content: `vault/courses/claude-tool-use-from-zero/07-creative-connectors.md:120`, `vault/courses/claude-tool-use-from-zero/07-creative-connectors.md:146`, `vault/courses/claude-tool-use-from-zero/07-creative-connectors.md:327`, `vault/courses/claude-tool-use-from-zero/08-legal-connectors.md:99`, `vault/courses/gemini-enterprise-agents/05-enterprise-security.md:153`.
- Root cause hypothesis: ingestion is not losing content; `src/lib/courses.ts` reads raw markdown/MDX-like chapter bodies correctly. The break is the course page's hand-rolled renderer: `ChapterBody` splits only on blank lines, `renderBlock` has no fenced-code support, handles only a narrow all-in-one-block `Callout`, handles `RunPromptCell` as a static placeholder instead of the existing client component, has no `KnowledgeCheck` branch, and `inline()` only supports `[[course/<slug>]]` or `[[<course>/<chapter>]]`, not `[[course/<slug>/<chapter>]]`.
- Constraints: scope remains `learnova-academy` only; no Convex or cross-portal changes; work on branch `koea-2570/mdx-rendering` from `origin/academy/redesign-v1`; do not mutate vault course source as the fix path.

## Approach (1 chosen, alternatives rejected)
**Chosen**: MDX-lite renderer repair in `learnova-academy`. Keep the current build-time vault ingestion and static course page model, but replace the brittle paragraph splitter with a small stateful tokenizer that preserves fenced code blocks and complete MDX-like component blocks before rendering. Reuse the existing client widgets from `_shared/content.tsx` where practical, and add narrow, deterministic parsers for the two authored `KnowledgeCheck` shapes (`questions={[...]}` and single-prop form) rather than evaluating arbitrary JSX.

**Rejected**: Full runtime MDX compilation with `@mdx-js/mdx` — larger blast radius, arbitrary-content evaluation risk, and RSC/client-component wiring complexity for a hotfix; Content rewrite in `vault/courses` — treats symptoms, would recur across existing course files and violates the requested renderer repair; Blog renderer unification first — useful later, but the ticket is about course chapters and unifying both renderers would exceed the scope.

## Steps (Executor follows in order)
1. In `learnova-academy/src/app/learn/[slug]/page.tsx`, import `RunPromptCell` and `KnowledgeCheck` from `@/components/_shared/content`, then replace `ChapterBody`'s `markdown.split(/\n\n+/)` with a `tokenizeChapterMarkdown(markdown)` helper that emits paragraph, code fence, and component-block tokens while preserving blank lines inside fences and JSX-like component props.
2. In the same file, update `renderBlock` to render code-fence tokens as `<pre><code>` with a visible language label when present, normalize only renderer artifacts around fence markers, and never pass fenced code through `inline()`.
3. In `renderBlock`, support complete `<Callout ...>...</Callout>` blocks across internal blank lines and accept the authored aliases currently present in vault content: `warning`, `warn`, `info`, `success`, `tip`, and `hot`.
4. In `renderBlock`, parse `<RunPromptCell ... />` attributes for `prompt`, `expectedOutput`, and `model`; map model strings to the existing `initialModel` union (`claude`, `gpt`, `gemini`) and render the real `RunPromptCell` with `initialPrompt` and `initialOutput` instead of the current static placeholder.
5. In `learnova-academy/src/components/_shared/content.tsx`, extend `KnowledgeCheck` minimally so it can render either the current single-question props or a `questions` array, then in `page.tsx` parse both authored shapes without `eval` and pass them to the component with correct answer indexes hidden until learner interaction.
6. In `page.tsx` `inline()`, add support for `[[course/<courseSlug>/<chapterSlug>]]` by linking to `/learn/<courseSlug>#ch-<chapterSlug>`, while preserving existing glossary, course-only, markdown-link, bold, italic, code, and footnote behavior.
7. For the minor Nova issue, update `learnova-academy/src/components/_shared/tutor.tsx` `renderWithCites()` to handle the same safe inline subset already used by the course renderer (`**bold**`, `*em*`, backtick code, markdown links, and `[§Heading]` citations), but do not add block-level markdown or component rendering to chat bubbles.

## Verification (QA Verifier checks these)
- [ ] From `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-2570/learnova-academy`, run `pnpm typecheck` and `pnpm lint`; `pnpm test` is optional/no-op because this package currently has no configured tests.
- [ ] Run the Academy dev server on port 3010 with `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm dev`, then inspect `/learn/claude-tool-use-from-zero`: chapter 7 renders callouts, real prompt cells, and knowledge checks; answer keys such as `correct: 2` are not visible before interaction.
- [ ] Inspect `/learn/claude-tool-use-from-zero` chapter 8 to confirm the single-prop `KnowledgeCheck` form still renders and `Callout type="warn"` is styled.
- [ ] Inspect `/learn/gemini-enterprise-agents` chapter 5 to confirm the `from google.adk.auth import AuthManager` Python fence renders as a formatted code block, not an inline run-on paragraph with visible fence markers.
- [ ] In chapter 7, confirm `[[course/mcp-from-first-principles-to-production/01-why-mcp-exists]]` and `[[course/picking-a-frontier-model-2026-q2/01-dimensions-that-matter]]` render as clickable `/learn/...#ch-...` links.
- [ ] Ask Nova or seed a local Nova bubble containing `**Blender**`, `*italic*`, and `` `code` ``; confirm inline markdown renders in the bubble while `[§Heading]` citations still link.

## Risk
- The largest risk is fragile parsing of JSX-like attributes containing nested backticks, braces, and newlines. Mitigate by making the tokenizer line-oriented, parsing only known component names/props, adding fallback rendering that hides raw answer keys rather than dumping source, and manually verifying both `questions={[...]}` and single-prop examples from the current vault.

## Out of scope
- Do not deploy Convex, touch `learnova-tc`, modify course source files in `vault/courses`, build a general-purpose MDX runtime, or refactor the blog renderer beyond learning from its existing safe-link behavior.
