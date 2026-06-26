---
title: KOEA-1326 plan — fix KOEA-1321 G2 blockers for the KOEA-1316 publish OOM chain
date: 2026-05-12
author: planner
ticket: KOEA-1326
parent: KOEA-1316
planner_ticket: KOEA-1330
supersedes: vault/decisions/KOEA-1316-plan.md
tags: [plan, publish-action, learnova-academy, lint, typecheck, github-actions, ceo-gated, koea-1326]
estimated_complexity: small
estimated_loc: ~6 (3 files across 2 branches)
status: ready-for-plan-review
---

# Plan: clear the G2 blockers from KOEA-1321 without expanding scope

## Goal

Get KOEA-1316's publish-OOM fix all the way through G2 by closing the
five items raised in KOEA-1321's G2 BLOCK comment, while staying inside
the lane rules (no direct merge to `main` without CEO approval, no
Convex deploy, no unrelated portal changes).

Observable success:
1. `pnpm --filter learnova-academy typecheck` exits 0 (gate command now
   exists).
2. `pnpm --filter learnova-academy lint` no longer reports
   `react-hooks/set-state-in-effect` on
   `src/components/GlossaryPopover.tsx`.
3. `.github/workflows/publish.yml` on the **default branch** (`main`)
   carries `NODE_OPTIONS: --max-old-space-size=6144` on the Deploy step
   — only after a CEO-approved promotion PR is merged.
4. A fresh `repository_dispatch` (event=`publish-ready`) for any
   currently-published academy slug runs the workflow from `main` to
   `conclusion=success`, and publish-action.sh Phase 2 flips the issue
   to `publish_state=published`.

What this plan **does not** try to do: ship the `secure-coding` lesson
content, install `browser-use` in the QA runtime, or touch anything
inside `learnova-academy/src/` beyond the one lint fix.

## Context

### Blocker inventory from KOEA-1321 (verbatim mapping)

| # | Blocker (from G2 comment)                                                                                                          | Classification                          | Owner here   |
| - | ---------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | ------------ |
| 1 | `pnpm typecheck` failed — script not defined in `learnova-academy/package.json` (`ERR_PNPM_RECURSIVE_EXEC_FIRST_FAIL`)             | True impl fix (verification contract)   | Executor     |
| 2 | `pnpm lint` failed — `src/components/GlossaryPopover.tsx:34` violates `react-hooks/set-state-in-effect` (`setData(cached)`)        | True impl fix                           | Executor     |
| 3 | `browser-use` CLI unavailable in QA runtime (Playwright fallback used)                                                             | QA-environment limitation               | Out of scope |
| 4 | Playwright walkthrough: `/learn/secure-coding` returned 404 — no `secure-coding` card in catalog on `academy/redesign-v1`           | QA expectation mismatch (content gap)   | Out of scope |
| 5 | KOEA-256 still has no successful publish run — `publish.yml` fix is on `academy/redesign-v1` but `repository_dispatch` uses `main` | True impl fix, **needs CEO approval**   | Executor + CEO/Vardaan |

### Why #4 is out of scope, not a bug

The `secure-coding` course is KOEA-256's slug, but the course MDX,
catalog card, and route assets are not yet on `academy/redesign-v1`
(`git ls-tree -r origin/academy/redesign-v1 | grep secure-coding`
returns nothing). The 404 is therefore a content-not-published symptom,
not a regression introduced by PR #26 (a workflow-only change can't
create routes). The right G2 fix for the next round is to ask QA to
walk an already-published slug — e.g. `claude-opus-47-from-zero` or
`claude-tool-use-from-zero` — when verifying the deploy path. Content
authoring for `secure-coding` belongs to the Content Author chain
(KOEA-256), not to this fix chain.

### Why #3 is out of scope

`browser-use` missing from the QA runtime is a tooling gap, not
something this code change can repair. Per CLAUDE.md cardinal rule 3,
`browser-use` is the default browser-automation, but the QA agent's
runtime did not have it installed. That is an environment / Chief
Engineering issue — file separately or document the install path in
the QA agent's SOUL.md. This plan does not modify the QA agent or its
runtime.

### Repository constraints recap

- Implementation branches off `academy/redesign-v1` for academy code
  (Chief Engineering rule).
- **No direct merge to `main`.** Workflow changes that need to take
  effect on `repository_dispatch` are the **one** exception, and even
  that exception requires explicit CEO/Vardaan approval per CLAUDE.md
  ("No direct merge to `main` on learnovaBeast").
- Convex deploys are limited to `learnova-tc`; this plan touches no
  Convex code or schema.
- Plan-only phase right now — Executor opens the implementation PR
  after Plan-Review approval (KOEA-1331).

## Approach (1 chosen, 2 rejected)

### Chosen — **Two-PR split: code fix on `academy/redesign-v1`, workflow promotion to `main` as a CEO-gated draft PR.**

Branch A (no approval needed beyond Plan-Review):
- `koea-1326/g2-blocker-fixes` off `academy/redesign-v1` → PR to
  `academy/redesign-v1`.
- Touches **only** `learnova-academy/package.json` (add `typecheck`
  script) and `learnova-academy/src/components/GlossaryPopover.tsx`
  (refactor cache read out of `useEffect`).
- Closes blockers #1 and #2.

Branch B (CEO/Vardaan approval required before merge):
- `koea-1326/publish-yml-main-promotion` off `main` → PR to `main`,
  **opened as draft** with body explicitly tagged `BLOCKED ON
  CEO/Vardaan approval`.
- Touches **only** `.github/workflows/publish.yml` — mirrors the one
  `NODE_OPTIONS` line from KOEA-1316's `academy/redesign-v1` fix.
- Closes blocker #5.

The split keeps the academy-source PR fully self-mergeable through
the normal Reviewer → G2 chain, while the workflow promotion stays
ring-fenced behind the explicit governance gate so neither Executor
nor Reviewer can accidentally fast-forward `main`.

### Rejected — single PR straight to `main` containing all fixes.

Mixes academy app source with a workflow file, blurs review surface,
breaks the "no direct merge to `main`" rule, and rolls the lint/
typecheck verification (Branch A's purpose) into a CEO-gated wait. Not
acceptable.

### Rejected — change the repository default branch from `main` to `academy/redesign-v1`.

Cleanest "fix" for blocker #5 in theory (one PR, no main promotion),
but it's a far larger lane-boundary change with knock-on effects on
every other workflow's `on: push: branches: [main]`, branch protection
rules, Vercel "Production Branch" setting, and analytics. Out of phase;
escalate as its own Chief Engineering proposal if we ever revisit.

## Allowed file scope (hard list — Executor must not touch anything else)

**Branch A — `koea-1326/g2-blocker-fixes` (PR → `academy/redesign-v1`):**

| File                                                              | Allowed edit                                                                                                                                                            |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `learnova-academy/package.json`                                   | Add **one** line to `scripts`: `"typecheck": "tsc --noEmit"`. No version bumps, no dep changes.                                                                          |
| `learnova-academy/src/components/GlossaryPopover.tsx`             | Refactor the `useEffect` so cache hits do **not** call `setData` inside the effect. Move synchronous cache read to a `useState` lazy initializer or to render-time.     |

Nothing else under `learnova-academy/`, no `convex/`, no `vault/`, no
GitHub workflow files, no `pnpm-lock.yaml`.

**Branch B — `koea-1326/publish-yml-main-promotion` (PR → `main`, draft):**

| File                                                              | Allowed edit                                                                                                                                                            |
| ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.github/workflows/publish.yml`                                   | Add **one** line to the `Deploy` step `env:` block: `NODE_OPTIONS: --max-old-space-size=6144`. Mirror the exact diff already shipped on `academy/redesign-v1`. No other step, key, runner, or trigger may change. |

Nothing else, period. No README touch-ups, no `actions/checkout`
version bumps, no `concurrency:` changes.

## Steps (Executor follows in order)

### Branch A — code fixes (no approval gate beyond Plan-Review)

1. From the learnovaBeast worktree, `git fetch origin && git checkout
   -B koea-1326/g2-blocker-fixes origin/academy/redesign-v1`.
2. Edit `learnova-academy/package.json`: in the `scripts` block, add
   `"typecheck": "tsc --noEmit"` (place between `lint` and `test` so
   the diff is one line). Do not touch any other key.
3. Edit `learnova-academy/src/components/GlossaryPopover.tsx`: replace
   the in-effect `setData(cached)` with a lazy `useState` initializer
   that reads `cache.get(slug)` at component-mount time. Concretely:

   ```ts
   const [data, setData] = useState<GlossaryData | null>(
     () => cache.get(slug) ?? null,
   );
   ```

   Then strip the synchronous cache-hit branch out of the `useEffect`
   so the effect only handles the **fetch** path. Keep the cleanup
   (`cancelled`) and the cache-miss `cache.set(slug, null)` behaviour
   intact. Re-run lint locally before committing.
4. Commit: `fix(academy): satisfy react-hooks/set-state-in-effect on
   GlossaryPopover + add typecheck script (KOEA-1326)`.
5. Open PR `koea-1326/g2-blocker-fixes → academy/redesign-v1`. PR body
   must link this plan, KOEA-1321 G2 comment, and explicitly call out
   blockers #1 and #2 as closed; #3, #4 as deferred (see "Out of
   scope" below); #5 as covered by Branch B.

### Branch B — workflow promotion (CEO/Vardaan approval required)

6. From the learnovaBeast worktree, `git fetch origin && git checkout
   -B koea-1326/publish-yml-main-promotion origin/main`.
7. Edit `.github/workflows/publish.yml`: in the `Deploy` step `env:`
   block, add `NODE_OPTIONS: --max-old-space-size=6144` as the last
   key. The resulting block must match exactly what is already on
   `academy/redesign-v1` (verify with `diff <(git show
   koea-1326/publish-yml-main-promotion:.github/workflows/publish.yml)
   <(git show origin/academy/redesign-v1:.github/workflows/publish.yml)`
   — expect zero diff for the Deploy step).
8. Commit: `fix(ci): promote vercel-deploy heap bump to main so
   repository_dispatch picks it up (KOEA-1326)`.
9. Open PR `koea-1326/publish-yml-main-promotion → main` **as a
   draft**. PR title must start with `[CEO-GATED]`. PR body must
   contain the literal line:

   > **Approval required:** This PR merges directly into `main` to
   > make `repository_dispatch` pick up the publish OOM fix. Per
   > CLAUDE.md, direct merge to `main` on learnovaBeast requires
   > explicit CEO/Vardaan approval. **Do not un-draft or merge until
   > Vardaan comments `LGTM-MAIN-MERGE` on this PR.**

10. **Stop.** Do not un-draft, do not merge, do not request review
    from Reviewer until the explicit `LGTM-MAIN-MERGE` approval lands.
    File a child issue under KOEA-1326 titled `[APPROVAL] CEO sign-off
    for publish.yml main-promotion (KOEA-1326)` assigned to Vardaan,
    with the PR link in the body and `unblock owner: Vardaan`.

### After both PRs land

11. After Branch A merges into `academy/redesign-v1`: notify QA
    Verifier on KOEA-1321 that blockers #1 and #2 are cleared and ask
    them to **re-run only the test gate** (`pnpm typecheck` + `pnpm
    lint`) for evidence. No browser re-walk yet.
12. After Branch B merges into `main` (post-Vardaan approval): run the
    re-dispatch / publish-resume flow exactly as named in the
    KOEA-1316 plan's "Publish-resume handling for KOEA-256" section,
    but **substitute a currently-published slug** (e.g. PATCH a
    benign `publish_state` for `claude-opus-47-from-zero` if a fresh
    test is desired). Do **not** treat the `secure-coding` 404 as
    proof of failure.

## Verification plan (smallest sequence; what Executor must post as evidence)

After Branch A is opened, Executor posts on KOEA-1326 with the
following — and **only** the following — evidence:

- [ ] **V1** — `pnpm --filter learnova-academy typecheck` output
      showing `tsc --noEmit` exit 0. Paste last 10 lines.
- [ ] **V2** — `pnpm --filter learnova-academy lint` output showing no
      error on `GlossaryPopover.tsx`. Existing warnings (the comment
      mentions 3) are acceptable and should be left untouched unless
      they're on lines we already edited.
- [ ] **V3** — `pnpm --filter learnova-academy build` exit 0 (sanity:
      the lazy-initializer refactor must not break SSR/build).
- [ ] **V4** — `git diff origin/academy/redesign-v1...HEAD -- '*.ts'
      '*.tsx' 'package.json'` must list exactly two files
      (`learnova-academy/package.json` and
      `learnova-academy/src/components/GlossaryPopover.tsx`). Paste
      the file list.

After Branch B is opened (still in draft, pre-approval), Executor
posts on KOEA-1326 with:

- [ ] **V5** — `git diff origin/main...koea-1326/publish-yml-main-promotion`
      shows exactly one added line, in the `Deploy` step `env:` block,
      reading `NODE_OPTIONS: --max-old-space-size=6144`. Paste the
      diff.
- [ ] **V6** — child issue `[APPROVAL] CEO sign-off…` created,
      assigned to Vardaan, with the PR URL. Paste the child issue ID.

After Branch B is merged (post-approval, by Reviewer or CEO):

- [ ] **V7** — `gh workflow view publish.yml -R
      Koenig-Solutions-Private-Limited/learnovaBeast --ref main
      --yaml` shows `NODE_OPTIONS: --max-old-space-size=6144` under
      the Deploy step. Paste the matching line.
- [ ] **V8** — a fresh `repository_dispatch` run for any
      currently-published slug (NOT `secure-coding`) reaches
      `conclusion=success` with no `FATAL ERROR: Reached heap limit`
      and no `Error: Upload aborted` storm. Paste the run URL +
      conclusion field.

QA Verifier (KOEA-1321) re-opens its check from V1/V2/V7/V8 only; #3
and #4 remain out of scope until separately ticketed.

## Risk + mitigation

- **R1 — `useState` lazy initializer breaks SSR.** Reading from a
  module-level `Map` during render is safe in React 19 / Next 16
  because the cache starts empty on the server and the component is
  `"use client"`. Mitigation: V3 build check; if SSR ever flips this
  to a hydration mismatch, fall back to keeping `setData` but
  switching the effect to read cache **before** the `if (!open …)`
  early-return so the call happens unconditionally inside an effect
  body that the lint rule whitelists for cache-only sync.
- **R2 — Default-branch promotion races a concurrent publish run.**
  The workflow's `concurrency: publish-${issue_id}` with
  `cancel-in-progress: false` keeps in-flight runs safe. Mitigation:
  none needed; just don't fire a fresh `repository_dispatch` until V7
  passes.
- **R3 — CEO approval never arrives / takes too long.** Blocker #5
  stays open; KOEA-256 and any other `dispatch_failed` issues remain
  stuck. Mitigation: child `[APPROVAL]` issue (step 10) keeps the
  owner/action visible. Do **not** route blocker #5 around the gate
  by editing the workflow on `academy/redesign-v1` instead — that
  reverts to the same dead-letter state.
- **R4 — Executor edits `learnova-academy/src/app/learn/secure-coding/…`
  trying to "fix" the 404.** Out of scope; would expand the PR into a
  content change without a Content-Author handoff. Reviewer must
  reject any such diff.
- **R5 — Lint refactor regresses popover behaviour.** Cache hits
  rendered the popover from cached `data`; the lazy initializer
  preserves that, but if the wider mouse-enter/blur flow changes,
  catch it in V3 build + a manual smoke (Playwright is fine here for
  smoke). Note: explicitly **not** a full browser-use walkthrough.

## Approval-gate summary (so this is unambiguous)

| Action                                                                                  | Approval needed                              |
| --------------------------------------------------------------------------------------- | -------------------------------------------- |
| Merge Branch A (`koea-1326/g2-blocker-fixes` → `academy/redesign-v1`)                   | Standard Reviewer + G2 chain (no CEO).       |
| Open Branch B as draft PR to `main`                                                     | Plan-Review (KOEA-1331) is sufficient.       |
| Un-draft Branch B / request Reviewer / merge to `main`                                  | **CEO/Vardaan explicit `LGTM-MAIN-MERGE`.** |
| Re-dispatch a publish run after Branch B merges                                         | Standard publish-action flow.                |
| Touch anything not in the file lists above                                              | New planner round (replan).                  |

## Out of scope (explicit non-goals)

- Installing `browser-use` in the QA runtime (blocker #3) — file
  separately if needed; cite CLAUDE.md cardinal rule 3.
- Drafting / publishing the `secure-coding` course content (blocker
  #4) — belongs to the Content Author chain (KOEA-256). Open a child
  ticket on the Author lane only if the priority bumps.
- Any change inside `learnova-academy/src/app/learn/`,
  `learnova-academy/convex/`, or any Convex schema — explicitly
  forbidden by lane boundaries.
- Direct merge of `academy/redesign-v1` → `main` (the whole branch,
  not just the workflow file). Out of phase.
- Bumping Vercel CLI version, `actions/checkout`, `pnpm/action-setup`,
  or any other action SHA — still out of scope per KOEA-1316 plan's
  "Out of scope" list.
- Adjusting the verification contract on the QA agent (removing the
  `pnpm typecheck` requirement) — adding the script is the lighter
  fix and standardizes the gate across the workspace; the verifier
  contract stays as-is.

## Handoff

- **Status flips on this planner ticket (KOEA-1330):** plan written →
  `ready-for-plan-review`. Create `request_confirmation` interaction
  on KOEA-1330 targeting this plan revision.
- **On Plan-Review approval (KOEA-1331):** KOEA-1326 →
  `ready-to-execute`. Executor follows steps 1–10 above.
- **Branch contracts:**
  - Branch A: `koea-1326/g2-blocker-fixes` → `academy/redesign-v1`.
  - Branch B: `koea-1326/publish-yml-main-promotion` → `main`
    (**draft, CEO-gated**).
- **Re-route after Executor:** KOEA-1332 (G_code) reviews both PRs;
  KOEA-1321 re-runs G2 verification (V1/V2/V7/V8 evidence only).
- **Unblock owner for blocker #5 promotion:** Vardaan (CEO). Action:
  comment `LGTM-MAIN-MERGE` on Branch B's PR. Tracked on the child
  `[APPROVAL]` issue.
