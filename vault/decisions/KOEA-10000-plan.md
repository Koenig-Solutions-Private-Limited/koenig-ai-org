---
ticket: KOEA-10000
planner: planner
date: 2026-07-02
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: beb8ac59-7a07-489f-810e-756b5524f0be
---

# Plan: Insert SAP ABAP/ECC request-lifecycle diagram

## Goal
Insert a mobile-scannable SAP ECC + ABAP request-lifecycle sequence diagram into the live `/blog/sap-abap-ecc` article at the SAP ABAP/ECC relationship section. Success means the draft PR renders a real diagram with an accessible name/caption, does not edit generated output or unrelated portals, and is held for Content Reviewer G0 before any publish.

## Context
- Files to read first: `learnova-academy/src/lib/vault.ts:1-12`, `learnova-academy/src/lib/vault.ts:145-160`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:1-31`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:356-360`, `learnova-academy/src/components/_shared/MermaidDiagram.tsx:27-105`, `learnova-academy/src/app/academy.css:687-704`
- Evidence-only generated artifact: `learnova-academy/.vercel/output/functions/blog/sap-abap-ecc.rsc.prerender-fallback.rsc:43-48` shows the live article heading `## What Is the SAP ABAP/ECC Relationship?` and a malformed Mermaid fence rendered as prose. Do not edit `.vercel` or `.next`.
- Relevant prior work: KOEA-10000 parent handoff; KOEA-10002 chain alert `beb8ac59-7a07-489f-810e-756b5524f0be` resolved by Chief Engineering as intentional Harness chain.
- Constraints: work in `learnovaBeast/learnova-academy` on `academy/redesign-v1`; run the FE worktree/agent-lock check before edits; do not touch `koenig-ai-org/vault/blogs`, student/sales/admin/tc portals, Convex, or generated build output; open draft PR only; Content Reviewer G0 is required before publishing.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Source-first Markdown Mermaid repair with a repo-state gate. The blog renderer already parses fenced `mermaid` blocks and renders them through `MermaidDiagram`, which supplies `role="img"`, caption-based accessible naming, fallback code, and horizontal overflow behavior. Executor should first locate or restore the canonical editable markdown source for `sap-abap-ecc`; if it is still absent from the base-branch worktree, stop with a repo-state blocker instead of editing compiled artifacts. Once the source is present, insert a valid `mermaid title="SAP ECC ABAP Request Lifecycle"` sequence diagram immediately after `## What Is the SAP ABAP/ECC Relationship?`, replacing any malformed literal-fence text.
**Rejected**: edit `.vercel`/`.next` generated route artifacts -- not source-controlled content and would be overwritten; inline SVG/MDX component -- unnecessary because the blog route already has Mermaid support and matching CSS; add a new company-vault blog file -- explicitly outside this ticket and conflicts with the parent's no-vault/blogs constraint.

## Steps (Executor follows in order)
1. In the FE worktree for KOEA-10000, verify the worktree/agent lock and confirm `origin/academy/redesign-v1` is the base before editing; do not continue if another active engineering issue owns the same blog/source files.
2. Locate the canonical editable source for `/blog/sap-abap-ecc` using `git grep -n -i 'sap-abap-ecc\\|SAP ABAP\\|ABAP/ECC\\|SAP ECC' origin/academy/redesign-v1 -- . ':(exclude)learnova-academy/.next' ':(exclude)learnova-academy/.vercel' ':(exclude)learnova-academy/node_modules'` plus a local worktree search. If the only matches are generated artifacts, file a repo-state blocker naming the missing source; do not edit generated output.
3. In the located markdown source, insert the diagram directly after `## What Is the SAP ABAP/ECC Relationship?`, replacing any literal broken fence with one valid fenced block:
   ```mermaid title="SAP ECC ABAP Request Lifecycle"
   sequenceDiagram
     actor User
     participant UI as SAP GUI / Fiori
     participant Dispatcher as Application Server Dispatcher
     participant WorkProcess as ABAP Work Process
     participant Runtime as ABAP Runtime
     participant DB as ECC Database

     User->>UI: Start transaction (for example VA01)
     UI->>Dispatcher: Send DIAG/RFC request
     Dispatcher->>WorkProcess: Assign free dialog work process
     WorkProcess->>Runtime: Load program and execute ABAP logic
     Runtime->>DB: Read business data
     DB-->>Runtime: Return result set
     Runtime->>DB: Update records inside LUW
     DB-->>Runtime: Commit acknowledged
     Runtime-->>WorkProcess: Build response
     WorkProcess-->>Dispatcher: Return screen data/status
     Dispatcher-->>UI: Send response
     UI-->>User: Show confirmation or output
   ```
4. Use this exact accessible text/caption expectation: `SAP ECC and ABAP request lifecycle from user transaction through dispatcher, ABAP work process, database update, commit, and response.` If using the existing Mermaid title path, add a one-sentence paragraph immediately after the diagram with that caption text; if the renderer is extended later, use the same string as the diagram accessible name.
5. Keep the diagram narrow enough for mobile: no more than six participants, short message labels, no inline HTML, and rely on `.mermaid-render { overflow-x: auto; }` rather than fixed widths. Do not add custom global CSS unless mobile verification shows clipping.
6. Verify from `learnova-academy/` with `pnpm test`, then run the local academy app and inspect `/blog/sap-abap-ecc` at desktop and a mobile viewport around 390px width. Confirm the diagram renders as SVG, the fallback prose is hidden after render, no horizontal page overflow or clipping occurs outside the diagram scroller, and the caption/accessibility text is visible or exposed.
7. Open a draft PR only. In the PR and issue comment, report the source path found, the exact verification commands/results, mobile viewport checked, Content Reviewer G0 dependency (`KOEA-10006`), and that no publish/merge/deploy occurred.

## Verification (QA Verifier checks these)
- [ ] Draft PR changes only the canonical source for `/blog/sap-abap-ecc` and does not edit `.vercel`, `.next`, `koenig-ai-org/vault/blogs`, student/sales/admin/tc portals, or Convex files.
- [ ] `/blog/sap-abap-ecc` renders a Mermaid sequence diagram immediately after `## What Is the SAP ABAP/ECC Relationship?`, not a visible literal code fence.
- [ ] The diagram has the specified caption/accessibility text and remains scannable at a 390px-wide mobile viewport without overlap, clipping, or page-level horizontal overflow.
- [ ] `pnpm test` passes from `learnova-academy/`, and the PR remains draft pending Content Reviewer G0.

## Risk
- The editable markdown source for `sap-abap-ecc` is missing from the current base branch even though generated artifacts prove the page exists. Mitigation: Executor must stop with a repo-state blocker if the canonical source cannot be found, rather than editing generated output or recreating the article in the wrong vault.

## Out of scope
- Publishing, merging, deploying, adding new blog infrastructure, modifying the Mermaid renderer/CSS unless required by verification, editing generated artifacts, and changing any non-academy portal.
