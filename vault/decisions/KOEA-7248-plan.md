---
ticket: KOEA-7248
planner: planner
agent: planner
date: 2026-06-10
type: decision
tags:
  - decision
  - blog-visuals
estimated_complexity: large
estimated_token_cost: "$0.48"
base_branch: academy/redesign-v1
basebranch_verified: true
revision: 2
triggered_by_approval: f527bda0-2901-432a-b86e-a176a6c6bc9c
---

# Plan: Add product screenshots to 9 coding-agent blog posts

## Goal

Add one product screenshot to each of the 9 target Academy blog posts so the article body has concrete product visuals, not just hero imagery and Mermaid diagrams. Success means every target post has one new `inline_images` frontmatter entry that renders through the existing Next.js `Image` path, uses the next numbered diagram asset after existing Mermaid figures, and passes privacy, performance, and visual QA.

Because this implementation would touch more than five content files if done as one change, split execution into three batches of three posts each. This plan still specifies all 9 placements so Chief Engineering can route review and execution without another discovery pass.

## Context

- Files to read first:
  - `learnovaBeast/learnova-academy/src/lib/vault.ts:21-38` - `BlogPost.inline_images` contract.
  - `learnovaBeast/learnova-academy/src/lib/vault.ts:194-210` - frontmatter parsing exposes `inline_images`.
  - `learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:293-331` - images are grouped by `slugify(after_heading)` and inserted after matching H2s.
  - `learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:353-357` - Mermaid blocks render as figures before the planned screenshot numbering.
  - `learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:658-680` - `InlineImage` renders via Next.js `Image`.
  - `vault/blogs/2026-06-02-cursor-composer-2-5-deep-dive/draft.md:128-226`
  - `vault/blogs/2026-06-04-claude-code-opus-4-7-production-guide/draft.md:69-206`
  - `vault/blogs/ai-tool-deep-dive-claude-code/draft.md:73-225`
  - `vault/blogs/ai-tool-deep-dive-codex-cli/draft.md:70-277`
  - `vault/blogs/ai-tool-deep-dive-aider/draft.md:152-350`
  - `vault/blogs/ai-tool-deep-dive-continue-dev/draft.md:61-198`
  - `vault/blogs/codex-cli-vs-cursor-composer-2/draft.md:110-195`
  - `vault/blogs/2026-06-02-mcp-1-0-production-patterns-2026/draft.md:86-213`
  - `vault/blogs/ai-coding-agents-production-2026-buyers-guide/draft.md:86-429`
- Relevant prior work: existing renderer already supports `inline_images`; no app code change is needed unless QA finds the `sizes` constraint insufficient.
- Official source URLs to start from:
  - Cursor: `https://cursor.com/blog/composer-2-5`, `https://cursor.com/`
  - Anthropic Claude Code: `https://docs.anthropic.com/en/docs/claude-code/overview`, `https://docs.anthropic.com/en/docs/claude-code/common-workflows`, `https://docs.anthropic.com/en/docs/claude-code/sub-agents`
  - OpenAI Codex: `https://developers.openai.com/codex/cli`, `https://developers.openai.com/codex/cli/features`, `https://developers.openai.com/codex/app`
  - Aider: `https://aider.chat/`, `https://aider.chat/docs/usage/browser.html`, `https://aider.chat/docs/usage/images-urls.html`
  - Continue.dev: `https://docs.continue.dev/customize/model-roles`, `https://docs.continue.dev/reference`, `https://docs.continue.dev/customize/overview`
  - MCP: `https://modelcontextprotocol.io/docs/getting-started/intro`, `https://registry.modelcontextprotocol.io/docs`, `https://modelcontextprotocol.io/registry/about`
- Constraints:
  - Base branch verified: `learnovaBeast` origin has `academy/redesign-v1`.
  - Current `koenig-ai-org` workspace has pre-existing dirty blog draft changes; Executor must preserve them and edit only the planned frontmatter entries.
  - Use official/vendor product pages, docs, or press/blog assets first; use clean terminal or local browser captures only when no official screenshot is usable.
  - Keep each exported asset at width `<= 1200px`; for this ticket, export and reference the exact `.png` paths below so the committed assets, frontmatter URLs, and QA checklist stay aligned.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Add one `inline_images` frontmatter entry per target blog and save the corresponding product screenshot under `learnova-academy/public/img/blogs/<slug>/diagrams/<NN>.png`. This matches the existing blog data contract, avoids Markdown/MDX component edits, keeps captions structured, and lets the current `InlineImage` component handle lazy loading, alt text, responsive sizing, and figure captions.

**Rejected**: Inline Markdown images in each article body - renderer supports some Markdown image syntax, but those images bypass structured `inline_images` placement and captions are inconsistent. **Rejected**: modify `BlogBody` or add an MDX component - unnecessary app-surface change when the data contract already exists. **Rejected**: add multiple screenshots per post in one pass - higher visual QA cost and too much file churn for one execution ticket.

## Screenshot Placements

| Blog slug | Mermaid count -> asset | Insert after H2 | Source strategy | Alt text | Caption |
|---|---:|---|---|---|---|
| `2026-06-02-cursor-composer-2-5-deep-dive` | 2 -> `learnova-academy/public/img/blogs/2026-06-02-cursor-composer-2-5-deep-dive/diagrams/03.png` | `Workflow patterns that actually work` | Prefer Cursor official Composer 2.5 blog or live Cursor product demo capture from `cursor.com`; crop to the Composer/agent panel, model selector, and task progress. | `Cursor Composer 2.5 agent panel showing a multi-step coding task inside the Cursor IDE.` | `Composer 2.5 works best when the task, context, and acceptance criteria are visible inside the IDE.` |
| `2026-06-04-claude-code-opus-4-7-production-guide` | 2 -> `learnova-academy/public/img/blogs/2026-06-04-claude-code-opus-4-7-production-guide/diagrams/03.png` | `Memory, Plan Mode, and Long-Context Workflows` | Prefer Anthropic Claude Code docs screenshots if available; otherwise create a sanitized terminal capture demonstrating `/model`, plan mode, memory reference, and a non-sensitive sample repo. | `Claude Code terminal session showing plan mode and memory-aware task execution in a sanitized sample repository.` | `Plan mode and persistent memory are the controls that make long-context Claude Code work auditable.` |
| `ai-tool-deep-dive-claude-code` | 2 -> `learnova-academy/public/img/blogs/ai-tool-deep-dive-claude-code/diagrams/03.png` | `Set Up Claude Code for Production: 10 Steps` | Use Anthropic Claude Code overview/common-workflows docs as source of truth; capture a clean terminal setup screen with no local paths or real project names. | `Claude Code setup terminal showing a clean project onboarding flow with permissions and tool context visible.` | `A production Claude Code setup starts with explicit permissions, repo context, and reviewable command output.` |
| `ai-tool-deep-dive-codex-cli` | 2 -> `learnova-academy/public/img/blogs/ai-tool-deep-dive-codex-cli/diagrams/03.png` | `Setup Walkthrough: Codex CLI 5.4 in 10 Steps` | Prefer OpenAI Codex CLI developer docs; capture the CLI TUI with approval mode, model/reasoning selection, and a small harmless diff preview. | `Codex CLI terminal interface showing model selection, approval mode, and a reviewable code diff.` | `Codex CLI is strongest when terminal actions, approval policy, and generated diffs stay in one auditable loop.` |
| `ai-tool-deep-dive-aider` | 2 -> `learnova-academy/public/img/blogs/ai-tool-deep-dive-aider/diagrams/03.png` | `Set Up Aider in 10 Steps` | Prefer official Aider docs/site assets; if needed, capture a terminal session showing `/model`, files in chat, and an auto-commit in a toy repo. | `Aider terminal session showing files in chat, model selection, and an AI-generated git commit in a sample repository.` | `Aider's product surface is the git-native terminal loop: choose files, ask for a change, review the commit.` |
| `ai-tool-deep-dive-continue-dev` | 2 -> `learnova-academy/public/img/blogs/ai-tool-deep-dive-continue-dev/diagrams/03.png` | `Setup Walkthrough: Continue.dev in VS Code in 10 Steps` | Prefer Continue.dev docs on model roles/configuration; capture VS Code with Continue sidebar and `config.yaml` model roles for chat/autocomplete/edit. | `Continue.dev sidebar in VS Code with model-role configuration for chat, autocomplete, and edit workflows.` | `Continue.dev's advantage is explicit model routing across IDE chat, autocomplete, edit, and apply roles.` |
| `codex-cli-vs-cursor-composer-2` | 2 -> `learnova-academy/public/img/blogs/codex-cli-vs-cursor-composer-2/diagrams/03.png` | `Benchmark the harness with three small tasks` | Build a side-by-side sanitized capture: Codex CLI terminal audit trail on the left, Cursor Composer IDE task panel on the right. Source UI references from OpenAI Codex CLI docs and Cursor official product/demo pages; compose the final 2-panel PNG with Pillow using equal-width crops, a small neutral gutter, and no added logos/text. | `Side-by-side comparison of Codex CLI audit trail and Cursor Composer IDE agent task panel.` | `The practical split is audit-first terminal automation versus IDE-native human steering.` |
| `2026-06-02-mcp-1-0-production-patterns-2026` | 2 -> `learnova-academy/public/img/blogs/2026-06-02-mcp-1-0-production-patterns-2026/diagrams/03.png` | `Production Patterns: Auth, Orchestration, Observability` | Prefer the official MCP Registry UI or Model Context Protocol docs; capture registry/server metadata with auth or tool-surface signals visible, no private server entries. | `Official MCP Registry interface showing server metadata and production integration details.` | `Production MCP work starts with discoverable server metadata, explicit auth, and observable tool boundaries.` |
| `ai-coding-agents-production-2026-buyers-guide` | 3 -> `learnova-academy/public/img/blogs/ai-coding-agents-production-2026-buyers-guide/diagrams/04.png` | `The 12 Tools in Depth` | Create a 2x2 comparison image using official product surfaces only: Claude Code, Codex CLI, Cursor Composer, and Continue.dev. Use clean crops rather than logos-only tiles; compose the final grid PNG with Pillow on a `1200px`-wide canvas using consistent gutters and no overlay text beyond what appears in the captured product UI. | `Four AI coding agent product surfaces compared: Claude Code, Codex CLI, Cursor Composer, and Continue.dev.` | `The buyer's-guide tradeoff is visible in the interface: terminal audit trails, IDE steering, model routing, and automation depth.` |

## Steps (Executor follows in order)

1. Re-read the 9 current blog drafts and `src/app/(site)/blog/[slug]/page.tsx` before editing, because the vault worktree already has unrelated dirty changes.
2. Split implementation into three child execution batches of three posts each, or three commits in one branch if Chief Engineering explicitly keeps one executor ticket; do not mix all 9 edits into one unreviewable diff.
3. For each blog, create the planned `diagrams/<NN>.png` asset at `<= 1200px` wide, with no secrets, no personal names, no local paths, no private repo names, and a neutral editor/terminal theme that does not clash with the Academy page.
   For the two composite assets, use a short Pillow stitching script or one-off notebook to combine sanitized equalized crops into the planned side-by-side or 2x2 PNG; do not depend on manual design-tool state or renderer changes.
4. Add or extend `inline_images:` frontmatter in each target draft with exactly one entry using the table's `after_heading`, `url`, `alt`, and `caption`; keep YAML formatting consistent with existing frontmatter.
5. Use URL values in the form `/img/blogs/<slug>/diagrams/<NN>.png` so `InlineImage` resolves them from `learnova-academy/public`.
6. Run a targeted Academy validation: parse/render the affected posts locally or run the narrowest available blog/Next build check, then inspect each page at desktop and mobile widths for caption fit, image crop, and no LCP regression.
7. Record source URLs and any manual capture commands in the implementation issue comment so QA can verify licensing, freshness, and privacy.

## Verification (QA Verifier checks these)

- [ ] Each of the 9 target blog pages renders exactly one new inline product screenshot after the planned H2, with the correct caption and no broken image requests.
- [ ] Asset numbering follows Mermaid count: eight posts use `03.png`; `ai-coding-agents-production-2026-buyers-guide` uses `04.png`.
- [ ] All screenshots are `<= 1200px` wide, visually sharp at blog content width, and lazy-loaded through the existing `InlineImage` Next.js `Image` component.
- [ ] Privacy review passes: no tokens, keys, emails, personal names, local filesystem paths, private repo/org names, browser profile data, or sensitive terminal history.
- [ ] Source review passes: each screenshot is from an official/vendor source or a sanitized local capture based on official docs; implementation comment lists source URLs.
- [ ] Mobile and desktop visual checks show no text overlap, no awkward crop, and no figure/caption layout shift.

## Risk

- Official product pages may not expose reusable screenshot assets, forcing manual captures. Mitigation: use sanitized terminal or browser captures against toy/sample repos, document source URLs, and keep screenshots product-faithful rather than illustrative.
- Current blog drafts are already dirty in the workspace. Mitigation: Executor should preserve existing edits, only append frontmatter entries, and review `git diff -- vault/blogs/<slug>/draft.md` per post before handing off.

## Out of scope

- Rewriting article copy, changing hero images, changing Mermaid diagrams, or changing the blog renderer.
- Producing more than one new screenshot per target blog.
- Solving image CDN or R2 upload workflows beyond committing static assets under `learnova-academy/public/img/blogs/.../diagrams/`.
