---
ticket: KOEA-1851
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.42
triggered_by_approval: 57f671e2-95da-4b46-b7f9-4826927532f2
base_branch: academy/redesign-v1
basebranch_verified: true
pr: https://github.com/Koenig-Solutions-Private-Limited/learnovaBeast/pull/34
pr_head_ref: origin/koea-1773/serve-vault-blog-slides
---

# Plan: Resolve PR 34 lint and blog LCP revision blockers

## Goal
Close the KOEA-1757 G2 revision blockers on PR #34 without regressing the slide download fix. Success is observable when the glossary lint failure is gone, the changed blog page either meets the <2.5s LCP target or is documented under the approved LCP baseline, and the slide link/asset behavior remains green.

## Context
- Files to read first: `learnova-academy/src/components/GlossaryPopover.tsx:24-56`, `learnova-academy/src/app/blog/[slug]/page.tsx:107-183`, `learnova-academy/src/app/blog/[slug]/page.tsx:245-255`, `learnova-academy/src/app/academy.css:375-382`, `learnova-academy/src/lib/vault.ts:56-130`, `learnova-academy/scripts/sync-vault.mjs:175-219`.
- Relevant prior work: KOEA-1757 original plan is `vault/decisions/KOEA-1757-plan.md`; PR head `719756a` contains the slide restore, `20bcb5e` removed the glossary effect state cascade, and `4d58c27` tightened the blog LCP path. Chain guard approval `57f671e2-95da-4b46-b7f9-4826927532f2` allowed this revision to proceed despite active sibling lanes.
- Constraints: use learnovaBeast branch `koea-1773/serve-vault-blog-slides`; production base is `academy/redesign-v1` and was verified to exist; keep changes inside `learnova-academy`; preserve visible `Download slides .pptx`, `/slides/<slug>.pptx` 200 behavior, and no dead slide link for blogs without `slides.pptx`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Surgical PR-head revision. Keep the existing PR #34 slide mirror/link implementation, keep the event-driven `GlossaryPopover` fetch path that avoids `setState` inside an effect, and focus any remaining LCP work on the changed blog page's above-the-fold render path only. This is lowest risk because the slide behavior already exists on PR head and the lint blocker has a direct local fix.

**Rejected**: Rebuild the slide pipeline from base because PR #34 already has the required systematic mirror/link path and rework increases regression risk. Rebuild the blog article layout for LCP because the blocker is a narrow changed-page metric, not a design refresh.

## Steps (Executor follows in order)
1. Check out `koea-1773/serve-vault-blog-slides` and confirm it is at or after PR head `719756a`; do not restart from `academy/redesign-v1`.
2. In `learnova-academy/src/components/GlossaryPopover.tsx`, ensure there is no `useEffect` path that synchronously calls `setData(cached)`; preserve the `openPopover()`/`inFlightRef` pattern or equivalent event-driven fetch.
3. Preserve the current slide path in `scripts/sync-vault.mjs`, `src/lib/vault.ts`, and `src/app/blog/[slug]/page.tsx`: mirror `vault/blogs/<slug>/slides.pptx` to `public/slides/<slug>.pptx`, expose `post.slides_url` only when the vault file exists, and render the visible download chip only for that URL.
4. Re-run a mobile Lighthouse check for `/blog/2026-04-30-gpt-5-5-in-codex`. If LCP is still over target and the LCP element is text, keep/tighten the `blog-prose` first-paragraph CSS only; if it is the hero image, adjust only the hero `Image` sizing/fetch path in `src/app/blog/[slug]/page.tsx`. Do not change unrelated article rendering.
5. Run `pnpm --dir learnova-academy lint`, `pnpm --dir learnova-academy typecheck`, and `pnpm --dir learnova-academy build`.
6. Verify local preview or static output: `/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns 200, `/blog/2026-04-30-gpt-5-5-in-codex` contains visible `Download slides .pptx`, and a blog without `slides.pptx` renders no slide link.
7. Update PR #34 with the verification summary and hand off to KOEA-1852 for G_code review before any QA rerun.

## Verification (QA Verifier checks these)
- [ ] `pnpm --dir learnova-academy lint` passes with no `react-hooks/set-state-in-effect` error for `GlossaryPopover.tsx`.
- [ ] `pnpm --dir learnova-academy typecheck` and `pnpm --dir learnova-academy build` pass.
- [ ] `/slides/2026-04-30-gpt-5-5-in-codex.pptx` returns HTTP 200.
- [ ] `/blog/2026-04-30-gpt-5-5-in-codex` visibly links to `Download slides .pptx`, and a no-slide blog has no dead slide link.
- [ ] Mobile Lighthouse for `/blog/2026-04-30-gpt-5-5-in-codex` records LCP <2.5s, or the PR explicitly cites the already approved LCP baseline decision `f6b54e48-72be-4c91-8d13-f05f1d48407f`.

## Risk
- The LCP value may remain environment-sensitive around 2.5s. Mitigation: record the Lighthouse LCP element and run conditions, apply only targeted above-the-fold changes, and cite the approved baseline if the measured residual is the known 2.7s variance rather than a code regression.

## Out of scope
- This plan does not redesign blog pages, alter verifier rules, change other Learnova portals, replace the existing slide URL contract, or bypass G_code/QA handoff.
