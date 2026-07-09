---
ticket: KOEA-7433
planner: planner
date: 2026-07-08
estimated_complexity: small
estimated_token_cost: $0.42
base_branch: academy/redesign-v1
type: decision
tags:
  - decision
  - planning
---

# Plan: PR #119 Bugbot follow-up fixes

## Goal
Confirm and, if needed, apply the four distinct Cursor Bugbot fixes from PR #119 on the merged production branch. Success means `academy/redesign-v1` no longer has the StatTicker hydration flash, RefPopover premature dismissal, leading-slash hero resolution bug, or raw hero URL JSON-LD bug.

## Context
- Files to read first: `learnova-academy/src/lib/hero-image.ts:14-25`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:65-85`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:110-156`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:515-516`, `learnova-academy/src/components/fx/StatTicker.tsx:23-54`, `learnova-academy/src/components/fx/RefPopover.tsx:23-29`, `learnova-academy/src/components/fx/RefPopover.tsx:40-42`, `learnova-academy/src/components/fx/RefPopover.tsx:81-82`
- Relevant prior work: PR #119, "Academy redesign v2 - The Living Academy", is now merged: https://github.com/Koenig-Solutions-Private-Limited/learnovaBeast/pull/119
- Constraints: the original head branch `academy/redesign-v2-frontend` is no longer fetchable, so Executor should branch from verified base `academy/redesign-v1`. Current `origin/academy/redesign-v1` already appears to contain the intended fixes; treat this as verify-first work, not a blind patch.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Verify existing merged fixes, then patch only missing safeguards. The merged base already shows `resolveHeroUrl` stripping leading slashes before checking `public/`, blog JSON-LD using resolved `heroUrl`, `StatTicker` keeping the SSR final value for visible counters, and `RefPopover` clearing the hide timer on show and popover enter. Executor should preserve those patterns and only edit if their working branch does not match.

**Rejected**: Patch the PR head branch directly - the remote head branch is gone after merge; split one ticket per Bugbot finding - the four fixes are small and all live in the same Academy frontend surface.

## Steps (Executor follows in order)
1. Create a work branch from `origin/academy/redesign-v1` in `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy`; do not base work on the current unrelated dirty local branch.
2. Inspect `src/lib/hero-image.ts` and ensure `resolveHeroUrl()` handles local paths by removing leading slashes from the existence-check path while returning the original URL when the file exists.
3. Inspect `src/app/(site)/blog/[slug]/page.tsx` and ensure both `blogPostingLd({ imageUrl })` and `howToLd({ imageUrl })` receive the resolved `heroUrl`, not `post.hero_image?.url`; keep markdown image rendering on `resolveHeroUrl(m[2], "")`.
4. Inspect `src/components/fx/StatTicker.tsx` and ensure the state initializes to `value`, visible-at-hydration counters return before `setDisplay(0)`, and below-fold counters still animate on intersection.
5. Inspect `src/components/fx/RefPopover.tsx` and ensure `cancelHide()` is called before showing a reference and on popover mouse enter, with cleanup clearing any outstanding timer.
6. If any safeguard is missing, apply the minimal local patch in the matching file only; if all safeguards are present on the working branch, make no code edits and report the Bugbot findings as already fixed by the merged PR.
7. Run targeted verification from `learnova-academy`: `pnpm lint`, `pnpm typecheck`, and `pnpm build`. If build is too expensive for the heartbeat, run lint and typecheck first and report build as not run.

## Verification (QA Verifier checks these)
- [ ] `git ls-remote --heads origin academy/redesign-v1` returns a branch, and the implementation branch is based on it.
- [ ] Source inspection confirms `blogPostingLd` and `howToLd` use resolved `heroUrl` for structured-data images.
- [ ] Source inspection confirms `StatTicker` does not reset an already visible SSR-rendered final count to zero at hydration.
- [ ] Source inspection confirms `RefPopover` cancels the hide timer on link show and popover pointer enter.
- [ ] `pnpm lint` and `pnpm typecheck` pass in `learnova-academy`; `pnpm build` passes or is explicitly reported as not run.

## Risk
- The merged branch may already contain fixes, so Executor could create unnecessary churn. Mitigation: verify first and make no-op handoff if all safeguards are present.

## Out of scope
- Reopening PR #119, redesigning the Academy landing page, or adding new visual behavior beyond the Bugbot fixes.

Preflight: `vault_sync=true`; `basebranch_verified=true`; `pr_119_state=MERGED`; `head_branch_fetchable=false`; prior `planner_chain_alert` was cancelled before this plan was written.
