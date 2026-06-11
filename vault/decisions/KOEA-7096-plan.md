---
ticket: KOEA-7096
planner: planner
date: 2026-06-02
estimated_complexity: medium
estimated_token_cost: "$0.34"
base_branch: academy/redesign-v1
basebranch_verified: true
plan_issue: KOEA-7104
---

# Plan: Add accessible inline diagrams to 10 Academy blog posts

## Goal
Add useful, source-backed diagrams to ten high-value Academy blog posts so readers and AI crawlers get multimodal explanations instead of prose-only pages. Success means each selected post has 2-3 diagrams placed near the first relevant H2 sections, each diagram has a descriptive accessible name or markdown image alt text, and the rendered mobile layout still has no horizontal page overflow.

## Context
- Files to read first: `learnova-academy/src/components/_shared/MermaidDiagram.tsx:16-24`, `learnova-academy/src/components/_shared/MermaidDiagram.tsx:79-91`, `learnova-academy/src/lib/markdown-fence.ts:1-7`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:26-27`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:329-332`, `learnova-academy/src/app/academy.css:548-564`, `learnova-academy/src/lib/vault.ts:10-12`, `learnova-academy/src/lib/vault.ts:121-238`, `learnova-academy/src/lib/vault.ts:282-286`.
- Relevant prior work: KOEA-7005 is done; local commits `9387d21d`, `e4461360`, and `49d5b054` added lazy strict Mermaid rendering for blog and course fences. Existing precedent: `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/images/README.md` documents Mermaid `.mmd` sources plus SVG exports and alt text.
- Constraints: work in the learnovaBeast FE worktree targeting `academy/redesign-v1`; do not use `main` as the code base branch. The current Planner workspace had unrelated dirty files, so Executor should start from a clean worktree or preserve unrelated local changes. Content claims and diagrams must be fact-checked against each post's existing sources; do not invent new benchmark numbers.
- Candidate list reconciliation:
  - KOEA-6973 listed traffic/sitemap candidates. Most exist as blog files; `claude-agent-sdk-zero-to-production` is a course slug, not a `vault/blogs/*/draft.md` blog post.
  - KOEA-7096 listed topic candidates. Two entries (`claude-tool-use-from-zero`, `mcp-from-first-principles`) are course-like slugs, not current blog posts. `2026-05-28-cloudflare-agentic-cloud-control-plane` exists but is `status: draft`, so it does not satisfy the live-site acceptance until separately promoted.
  - Final selected files:
    1. `vault/blogs/2026-05-14-openai-realtime-api-production-patterns-2026/draft.md`
    2. `vault/blogs/2026-04-30-gpt-5-5-in-codex/draft.md`
    3. `vault/blogs/cursor-3-2-vs-claude-code-workflow/draft.md`
    4. `vault/blogs/mcp-2026-roadmap-explained/draft.md`
    5. `vault/blogs/2026-05-30-gemini-managed-agents-production-checklist-2026/draft.md`
    6. `vault/blogs/2026-05-14-claude-max-chatgpt-pro-dev-org-economics/draft.md`
    7. `vault/blogs/2026-04-30-vercel-ai-sdk-6-vs-claude-agent-sdk/draft.md`
    8. `vault/blogs/2026-05-12-ai-agent-observability-langfuse/draft.md`
    9. `vault/blogs/codex-cli-vs-cursor-composer-2/draft.md`
    10. `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/draft.md`
  - Rationale: this keeps eight resolvable KOEA-6973 targets, replaces the missing course slug with KOEA-7096's `codex-cli-vs-cursor-composer-2`, and counts the supply-chain atlas because it already has three diagram assets and is the local pattern for Mermaid-derived SVG + alt text. Cloudflare control-plane work is out of scope until that draft is publishable; a published Cloudflare substitute can be added by Chief Engineering if Cloudflare coverage is mandatory.

## Approach (1 chosen, alternatives rejected)
**Chosen**: mixed engineering + content authoring. First add a tiny Mermaid accessibility path so inline diagrams can carry a per-diagram label/caption from markdown metadata. Then have Content Author add 2-3 source-backed Mermaid fences or SVG embeds to the selected blog files. This uses KOEA-7005's renderer, avoids commissioning opaque images, and closes the current generic `aria-label="Mermaid diagram"` gap that would otherwise miss the alt-text acceptance criterion.

**Rejected**: content-only Mermaid fences - fastest, but every rendered diagram currently has the same generic accessible label; static SVG-only exports for all posts - satisfies alt text but loses markdown-native, AI-readable Mermaid source unless every SVG is paired with `.mmd`; broad renderer redesign - unnecessary because KOEA-7005 already solved rendering and responsiveness.

## Steps (Executor follows in order)
1. In the learnovaBeast FE worktree on a task branch targeting `academy/redesign-v1`, patch only the Mermaid metadata surface: extend `src/lib/markdown-fence.ts` to parse optional info-string metadata such as ` ```mermaid title="..."`, pass that label through the blog and course renderers, and update `src/components/_shared/MermaidDiagram.tsx` so `role="img"` uses the provided label with an optional visible caption.
2. Keep the existing lazy `import("mermaid")`, `securityLevel: "strict"`, dark-mode rerender, fallback code block, and responsive CSS behavior intact; only add caption/label styling in `src/app/academy.css` if needed.
3. For each selected `vault/blogs/.../draft.md`, add 2-3 diagrams at or immediately after the first relevant H2/H3 where the diagram clarifies architecture, sequence, decision criteria, lifecycle state, comparison, or measurement methodology. `2026-05-30-gemini-managed-agents-production-checklist-2026` already has one Mermaid fence; improve its label and add only the missing additional diagrams.
4. For `ai-coding-agent-supply-chain-threat-atlas-2026`, verify the three existing SVG diagrams and `images/README.md` alt text already satisfy the requirement; only edit if G_code finds stale alt text, broken relative links, or missing source files.
5. For each new diagram, add a one-sentence caption or label that describes what the diagram shows, keep all claims traceable to the post's existing references, and avoid new unsourced quantitative claims. Use Mermaid flowcharts, sequence diagrams, state diagrams, or simple XY/chart forms; use SVG/Excalidraw exports only when Mermaid cannot render the needed chart clearly.
6. Run focused local verification from `learnova-academy`: `pnpm test` if available, `pnpm lint` or the repo's nearest lint/typecheck command if configured, and `node node_modules/vite/bin/vite.js build` only if the Next/Vite build path applies in this worktree. Do not use `npx vite build` on NTFS.
7. Browser-check `/blog/<slug>` for at least the ten selected slugs at desktop and mobile widths. Confirm diagrams render, labels/captions are specific, no horizontal page overflow appears, dark mode remains readable, fallback code is not visible after hydration, and the supply-chain SVG embeds still show descriptive markdown alt text.

## Verification (QA Verifier checks these)
- [ ] Each selected blog file either has at least 2-3 diagrams or, for `ai-coding-agent-supply-chain-threat-atlas-2026`, retains its three existing documented diagram assets with descriptive alt text.
- [ ] Rendered Mermaid diagrams expose specific accessible names/captions instead of the generic `Mermaid diagram` label.
- [ ] Mobile browser checks on the ten `/blog/<slug>` pages show rendered diagrams without horizontal page overflow.
- [ ] G_code review confirms the renderer change is narrow, keeps Mermaid lazy/strict, and does not regress course-page Mermaid fences.
- [ ] G2/content review confirms diagram claims are source-backed and captions accurately describe the visual.

## Risk
- The highest risk is content drift: diagrams can imply architectural facts or benchmark comparisons the post sources do not actually support. Mitigation: use the post's existing references for every diagram label/node, avoid fresh numbers unless the cited source already has them, and send the finished content through G2 before publishing.

## Out of scope
- Promoting draft posts such as `2026-05-28-cloudflare-agentic-cloud-control-plane` to publishable status.
- Adding diagrams to course pages like `claude-agent-sdk-zero-to-production`, `claude-tool-use-from-zero`, or `mcp-from-first-principles`.
- Reworking the full markdown renderer or replacing KOEA-7005's Mermaid implementation.
- Creating new original benchmark datasets for the diagram content.

## Next Phase Owner
After plan review, route implementation as two coordinated pieces: Engineering Executor owns the narrow Mermaid accessibility metadata patch, and Content Author owns KOEA-6973 diagram authoring for the selected blog files. If the board insists on one owner, assign Content Author after the engineering patch lands; a general Executor should not invent final source-backed blog content without content-lane review.

## Pre-flight Footer
- status_checked: KOEA-7104 was `in_progress` and assigned to Planner.
- chain_checked: parent KOEA-7096 is root; active sibling count was 1; recursive depth was 2.
- acceptance_checked: KOEA-7104 has four acceptance bullets and a concrete target path.
- basebranch_verified: `academy/redesign-v1` exists on learnovaBeast origin.
- vault_synced: `git pull origin master --rebase=false` returned already up to date before this file was written.
