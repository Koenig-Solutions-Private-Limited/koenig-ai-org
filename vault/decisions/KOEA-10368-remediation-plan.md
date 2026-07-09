---
ticket: KOEA-10368
plan_issue: KOEA-10425
planner: planner
date: 2026-07-08
estimated_complexity: medium
estimated_token_cost: "$0.46"
base_branch: academy/redesign-v1
basebranch_verified: true
vault_base_branch: master
vault_basebranch_verified: true
chain_alert_authorization: 105cc1dc-ea80-417e-8a97-3e670f6f3642
plan_path: vault/decisions/KOEA-10368-remediation-plan.md
---

# Plan: Remediate Mermaid rendering, routing, overflow, and source liveness for KOEA-10368

## Goal
Make KOEA-10368 / KOEA-7142 pass G2 without expanding into unrelated portals or a broad academy rewrite. Success means the scoped blog Mermaid fences render as actual diagrams with names derived from existing `title="..."` metadata, the Realtime blog route resolves, mobile checks no longer show horizontal overflow on the scoped pages, and source-liveness failures are either repaired by Content or explicitly classified as acceptable paywall/rate-limit cases.

## Context
- Files to read first: `learnova-academy/src/app/blog/[slug]/page.tsx:32-71`, `learnova-academy/src/app/blog/[slug]/page.tsx:285-435`, `learnova-academy/src/app/learn/[slug]/page.tsx:893-945`, `learnova-academy/src/app/learn/[slug]/page.tsx:954-1155`, `learnova-academy/src/lib/vault.ts:78-179`, `learnova-academy/src/app/academy.css:347-399`, `learnova-academy/src/app/academy.css:448-489`, `vault/blogs/2026-05-14-openai-realtime-api-production-patterns-2026/draft.md:1-94`.
- Relevant prior work: `vault/decisions/KOEA-7096-plan.md` is useful historical context, but its referenced `MermaidDiagram.tsx` and `markdown-fence.ts` surfaces are no longer present in the current `learnovaBeast` checkout. Current G2 blocker evidence is parent comment `00a4e937-0195-4ad9-ab1c-bde7eb07e785` on KOEA-10368.
- Constraints: target only `learnova-academy` in `learnovaBeast` plus scoped vault blog/content source edits in `koenig-ai-org`; do not touch student, sales, admin, or tc portals. Branch check passed for `learnovaBeast` `academy/redesign-v1` and vault `master`. Treat root `koenig-ai-org` test/typecheck failures from the G2 comment as out of scope unless a vault content edit directly causes them.

## Approach (1 chosen, alternatives rejected)
**Chosen**: academy-only renderer plus content triage. Add a minimal Mermaid fence render path to the current custom blog renderer, optionally share a tiny parser/render helper with the lesson renderer if Executor confirms course Mermaid fences are still expected, and add CSS constraints that make diagrams/code-like blocks width-safe on mobile. Fix the Realtime route by aligning the vault folder and rendered slug behavior for the scoped blog, then route the 16 strict non-200 cited URLs through a Content-owned triage where official/paywalled/rate-limited sources can be documented rather than blindly replaced.

**Rejected**: switch to `react-markdown` or MDX rendering - too broad for a G2 remediation and risks regressions in citations, glossary links, and custom callouts; content-only source/title edits - titles already pass 11/11 and do not solve visible code fences or 0 Mermaid SVGs; global CSS overflow masking only - can hide evidence while leaving diagrams unrendered and inaccessible.

## Steps (Executor follows in order)
1. In `learnova-academy/src/app/blog/[slug]/page.tsx`, add a dedicated Mermaid block path before the paragraph fallback in `renderBlock`: detect fenced blocks whose info string starts with `mermaid`, parse `title="..."`, render a client-safe Mermaid component or lazy client island, and use the title as the accessible name plus visible caption/alt text. Keep existing citation, glossary, list, stat, and image behavior intact.
2. If the academy lesson renderer can receive Mermaid fences, mirror the same narrow handling in `learnova-academy/src/app/learn/[slug]/page.tsx`; otherwise document why lesson overflow is addressed only through shared CSS and browser verification. Do not modify non-academy portals.
3. Add scoped styles in `learnova-academy/src/app/academy.css` for Mermaid figures/SVG containers, long labels, fallback `<pre>` blocks, and mobile widths so diagrams and existing prose cannot force horizontal page overflow. Prefer `max-width: 100%`, `overflow-x: auto` inside the figure, and contained captions over global `overflow-x: hidden` masking.
4. Fix the Realtime slug mismatch by making `/blog/openai-realtime-api-production-patterns-2026` and the intended canonical `/blog/2026-05-14-openai-realtime-api-production-patterns-2026` agree through a minimal vault-folder/frontmatter/canonical adjustment. Verify `generateStaticParams`, metadata canonical URL, sitemap, RSS, and direct route behavior all point to the same surviving slug.
5. Triage the 16 strict non-200 source URLs from the KOEA-10368 G2 comment in vault content only. Engineering may replace clearly dead or wrong URLs, but official OpenAI/Microsoft URLs returning 403, VentureBeat 429s, Bloomberg/CNBC/Ars/Skadden paywall or bot-defense responses, and the Ars 202 response need Chief Content classification before removal if the cited claim is still source-backed.
6. Run focused verification from `learnova-academy`: `pnpm typecheck`, `pnpm lint`, `pnpm test`, and a local build/start or dev-server browser pass on the scoped pages. Browser checks must include desktop and mobile widths for the 10 KOEA-7096 blog slugs, `/`, `/catalog`, and `/learn/claude-agent-sdk-zero-to-production`; check Mermaid SVG count, accessible names/captions, dark mode readability, route status, no visible source fences after hydration, and `document.documentElement.scrollWidth <= window.innerWidth`.
7. Hand off through the child sequence: Plan-Review validates this plan first; Executor implements the approved narrow patch; G_code reviews the PR for renderer/CSS/content scope; QA Verifier reruns G2 on KOEA-10368/KOEA-7142 and records pass/fail evidence.

## Verification (QA Verifier checks these)
- [ ] `/blog/2026-05-14-openai-realtime-api-production-patterns-2026` or the approved canonical replacement returns the intended article, not the academy 404 page, and sitemap/RSS/canonical agree.
- [ ] On each scoped blog page with Mermaid fences, the browser DOM contains rendered Mermaid SVGs/figures instead of visible markdown fences, and each diagram exposes a specific accessible name/caption from `title="..."`.
- [ ] Mobile checks on Home, `/learn/claude-agent-sdk-zero-to-production`, Langfuse blog, Claude Max economics blog, GPT-5.6 blog, Anthropic/Alibaba blog, and the ten KOEA-7096 slugs report no horizontal page overflow.
- [ ] Dark mode keeps Mermaid text, edges, captions, and fallbacks readable.
- [ ] Source-liveness rerun documents all 16 prior strict non-200 URLs as either replaced with reachable sources, still-valid paywall/bot-defense/rate-limit citations approved by Chief Content, or out-of-scope for Engineering.
- [ ] `pnpm typecheck`, `pnpm lint`, and `pnpm test` in `learnova-academy` pass or have explicitly documented pre-existing warnings only.

## Risk
- A Mermaid client island can increase JavaScript and affect the already-failing GPT-5.5 LCP spot check. Mitigate by lazy-loading Mermaid only when fences exist, rendering a stable server-side figure shell, and re-running Lighthouse on `/blog/2026-04-30-gpt-5-5-in-codex` after the patch.
- Source URL replacement can become editorial scope creep. Mitigate by limiting Engineering to broken-link mechanics and sending disputed paywall/rate-limit replacements to Chief Content.

## Out of scope
- Replacing the academy custom markdown renderer wholesale.
- Changing student, sales, admin, or tc portals.
- Repairing root `koenig-ai-org` Vitest/typecheck/lint failures reported as pre-existing in the G2 comment.
- Rewriting article claims or adding new benchmark/source claims beyond the 16 URL triage.
- Publishing or G4 approval decisions for the affected blogs.

## Follow-on Child Sequence
1. `Plan-Review: KOEA-10368 remediation plan` assigned to G_code/plan reviewer; accept or request changes on this plan file.
2. `Implement: KOEA-10368 Mermaid renderer + route + overflow remediation` assigned to Executor after plan review passes; base `learnovaBeast` branch `academy/redesign-v1`.
3. `Content Triage: KOEA-10368 strict non-200 source URLs` assigned to Chief Content or Content Author for disputed replacements/classifications; may run in parallel with Executor but must complete before G2 pass.
4. `G_code: KOEA-10368 remediation PR` assigned to Code Reviewer after Executor opens the PR.
5. `G2 RE-QA: KOEA-10368 / KOEA-7142 remediation` assigned to QA Verifier after G_code approval and Content triage completion.

## Pre-flight Footer
- status_checked: KOEA-10425 was `in_progress` and assigned to Planner on 2026-07-08.
- chain_checked: depth 4 was previously blocked by `planner_chain_alert` 105cc1dc-ea80-417e-8a97-3e670f6f3642; Chief Engineering comment `2d554142-1b18-4d4a-ae09-2ce36e5d4e20` authorized continuing this legitimate remediation chain.
- acceptance_checked: KOEA-10425 has three concrete acceptance bullets plus five plan requirements.
- basebranch_verified: `academy/redesign-v1` exists on `learnovaBeast` origin; `master` exists on `koenig-ai-org` origin.
- vault_synced: `git pull origin master --rebase=false` returned already up to date before this file was written.
