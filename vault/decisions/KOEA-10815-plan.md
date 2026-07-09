---
ticket: KOEA-10815
planner: planner
agent: planner
type: decision
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.45
base_branch: academy/redesign-v1
tags:
  - decision
  - engineering-plan
---

# Plan: SAP Blog G2 Rendering Remediation

## Goal
Fix the G2 blockers for the SAP course overview blog so the date-prefixed blog URL renders, embedded KnowledgeCheck blocks are interactive on blog pages, and the SAP Mermaid diagram appears as a rendered diagram instead of visible raw `graph TD` text. Keep the remediation scoped to Academy blog rendering unless Executor confirms the adjacent course or lesson route failures are a shared routing regression.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/vault.ts:163-224`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/vault.ts:340-348`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:47-93`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:316-379`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/blog/[slug]/page.tsx:448-459`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/(site)/learn/[slug]/page.tsx:989-1017`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/_shared/content.tsx:233-360`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/components/_shared/MermaidDiagram.tsx:27-107`, `vault/blogs/all-about-sap-course-overview-eligibility-duration-and-fee-structure/draft.md:1-8`, `vault/blogs/all-about-sap-course-overview-eligibility-duration-and-fee-structure/draft.md:101-134`, `vault/blogs/all-about-sap-course-overview-eligibility-duration-and-fee-structure/draft.md:173-183`, `vault/blogs/all-about-sap-course-overview-eligibility-duration-and-fee-structure/draft.md:236-246`.
- Relevant prior work: KOEA-10815 G2 BLOCK comment `fc4cb3d5-f520-46ab-99ee-6f728eff1808` reports the date-prefixed URL 404, static KnowledgeCheck placeholders, raw Mermaid text, and adjacent route concerns. KOEA-10698 G0 PASS comment `827c7446-f3a7-4acd-8e43-f7da5cb0da93` confirms the SAP draft was accepted with frontmatter status `g0-passed`.
- Constraints: Planner must not edit production code. Implementation target is `learnovaBeast/learnova-academy` on `academy/redesign-v1` (verified on origin). Do not flip the SAP draft to `g2-passed`; that belongs to QA after re-verification. The local Academy checkout is currently detached and has unrelated dirty files, so Executor should use the assigned implementation workspace and avoid reverting unrelated changes.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Frontend blog renderer remediation with slug alias support. Update the Academy blog data layer so frontmatter `slug` becomes the canonical blog route while the existing folder slug remains a compatibility alias, then update the blog block renderer to mount the shared `KnowledgeCheck` client component using tolerant attribute parsing. Reproduce the SAP Mermaid failure in the browser before changing shared Mermaid code; if the issue is hidden fallback text after successful render, unmount or otherwise remove the raw fallback after SVG render, and if Mermaid actually errors, fix the renderer/source handling without changing the SAP content gate.

**Rejected**: Rename the SAP vault folder to the date-prefixed slug - too narrow and likely to repeat for other posts with frontmatter slugs. **Rejected**: Build a full MDX pipeline for blogs - too broad for a G2 remediation and risks changing all blog rendering semantics.

## Steps (Executor follows in order)
1. In `src/lib/vault.ts`, make `readBlogFile` preserve both the folder slug and frontmatter `slug`, return the frontmatter slug as canonical when present, and update `getBlog` / static-param generation support so `/blog/2026-07-08-all-about-sap-courses-overview-eligibility-duration-fee-structure` resolves while the existing undated folder route remains non-breaking or redirects/canonicalizes.
2. In `src/app/(site)/blog/[slug]/page.tsx`, replace the static `KnowledgeCheck` placeholder branch with real rendering via `KnowledgeCheck` from `@/components/_shared/content`; factor or mirror the course parser so it accepts multiline attributes and both `correctIdx` and `correctIndex`.
3. Add a small focused verification script or unit-style check only if the existing scripts do not cover it: assert the SAP frontmatter slug is present in publishable blog params, the legacy folder alias still resolves, and the two SAP KnowledgeCheck blocks parse into option arrays with `correctIndex={2}`.
4. Reproduce the SAP Mermaid rendering locally on the fixed date-prefixed route. If `.mermaid-render svg` is present but raw `graph TD` remains visible or counted from the fallback, adjust `src/components/_shared/MermaidDiagram.tsx` so the fallback is removed/hidden after successful render and only shown before render or on error. If Mermaid raises an error, fix the renderer/source normalization instead and keep the visible error path for genuine failures.
5. Before expanding scope, run the adjacent route checks from the G2 finding against current data: one known course landing route, `/courses/<same-slug>`, and one standalone `/learn/<course>/<chapterSlug>` route. If they fail before this patch or for unrelated missing vault data, document that in the implementation ticket and keep the code change blog-scoped; if they regress because of shared routing touched by this patch, fix within the touched shared helper.
6. Run targeted verification from `learnova-academy`: `pnpm test`, `pnpm typecheck`, and a browser check against the SAP date-prefixed blog route confirming no Academy 404, two interactive KnowledgeCheck controls with clickable options/explanations, rendered Mermaid SVG, and no visible raw `graph TD` diagram.

## Verification (QA Verifier checks these)
- [ ] `/blog/2026-07-08-all-about-sap-courses-overview-eligibility-duration-fee-structure` returns the SAP article, not the Academy 404 page, and its canonical/OpenGraph URL uses the date-prefixed slug.
- [ ] The SAP blog shows two interactive KnowledgeCheck blocks with answer options; selecting an option reveals the explanation and does not leave the old static placeholder text.
- [ ] The SAP Mermaid block renders an SVG diagram in the article and does not visibly show raw `graph TD` code after hydration.
- [ ] Adjacent `/learn`, `/courses`, and standalone lesson route checks are either passing or explicitly documented as pre-existing/unrelated before QA re-run.
- [ ] `pnpm test` and `pnpm typecheck` pass in `learnova-academy`.

## Risk
- The main risk is changing blog slug canonicalization in a way that breaks existing folder-based inbound links. Mitigate by preserving the folder slug as an alias or compatibility route while emitting the frontmatter slug as canonical metadata and static params.

## Out of scope
- Do not rewrite the SAP article, change its G0/G2 status, or remediate unrelated course/lesson route failures unless Executor proves they are caused by the same shared routing code touched for this fix.

Telemetry: status_ok=true; assignee_ok=true; sibling_guard_authorized=445ed013-cbaf-402b-9a83-c2ce4404ad54; basebranch_verified=true; acceptance_criteria_ok=true.
