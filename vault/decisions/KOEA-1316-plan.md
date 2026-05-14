---
title: KOEA-1316 plan — fix learnovaBeast publish-to-Vercel OOM on Deploy step
date: 2026-05-12
author: planner
ticket: KOEA-1316
parent: KOEA-1316
planner_ticket: KOEA-1317
tags: [plan, publish-action, vercel, oom, learnova-academy, github-actions, koea-1316]
estimated_complexity: small
estimated_loc: ~3
status: ready-for-review
---

# Plan: bump Node heap on Vercel CLI deploy step

## Goal

Stop GitHub Actions run `publish-${issue_id}` from crashing on the **Deploy**
step with `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap
out of memory` (exit 134). Restore end-to-end Academy publish so the
g4-approved → published → G5 chain (KOEA-256) completes.

Observable success: a fresh `repository_dispatch` (event=publish-ready,
client_payload.issue_id=`781ec769-d5e1-4239-b376-e465a49bdb14`) runs the
publish workflow to `conclusion=success`, and publish-action.sh Phase 2 flips
the issue to `publish_state=published` and triggers the publish-verifier.

## Context

### Failure evidence

GH Actions run **25747288480**, job **75613872185** at
`Koenig-Solutions-Private-Limited/learnovaBeast`:

- Workflow: `.github/workflows/publish.yml` (`name: Publish blog/course to Vercel`).
- Step **Build** (`vercel build --prod`) — ✅ success.
- Step **Deploy** (`vercel deploy --prod --prebuilt --yes`) — ❌ exit 134
  after ~2 minutes.
- Tail of the log shows dozens of `Error: Upload aborted` rejections from
  `uploadList.<computed>.retries` inside the Vercel CLI, immediately followed
  by:
  ```
  <--- Last few GCs --->
  [2482:...] 13297 ms: Mark-Compact (reduce) 2050.4 (2054.8) -> 2048.1
    (2054.4) MB ... allocation failure; scavenge might not succeed
  FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory
  ```
  V8 crashes at the default ~2 GB old-space ceiling inside
  `v8::internal::Runtime_StringSplit`, called from the upload-manifest path.
  Exit 134 = SIGABRT after V8 OOM.
- Run was triggered for KOEA-256 (issue id
  `781ec769-d5e1-4239-b376-e465a49bdb14`, slug `secure-coding`;
  `display_title: publish-781ec769-d5e1-4239-b376-e465a49bdb14`). After
  failure, publish-action.sh Phase 2 will mark
  `publish_state=dispatch_failed`, which blocks KOEA-256.

### Why this is happening now

The `vercel deploy --prebuilt` path enumerates everything under
`.vercel/output/` (Next.js prebuilt static + edge/serverless functions),
builds an in-memory upload manifest with per-file sha256 + retry state, and
holds all of it on Node's old-space heap. With many MDX-rendered pages
(blogs, courses, slides) and bundled assets in the prebuilt output, the
manifest plus retry buffers cross the default ~2 GB `--max-old-space-size`
of the CLI's Node process. The repeated "Upload aborted" entries are the
CLI retrying chunks under memory pressure right before V8 aborts.

This is a Vercel-CLI–side limit, not a Next.js build limit (Build step
succeeded). Vault is only ~23 MB on disk; the heap blow-up comes from
prebuilt artifacts + upload bookkeeping, not raw vault size.

### Repository constraints

- Implementation branch must be `academy/redesign-v1` (Chief Engineering rule).
- No direct merge to `main` on learnovaBeast.
- Convex deploys are limited to `learnova-tc`; this fix touches neither
  Convex nor the academy app source.
- No code changes during this planning phase (Plan-only).

## Approach (1 chosen, 2 rejected)

**Chosen — Raise Node heap for the Vercel CLI on the Deploy step.**
Add `NODE_OPTIONS: --max-old-space-size=6144` to the `env:` block of the
**Deploy** step in `learnovaBeast/.github/workflows/publish.yml`. GitHub's
`ubuntu-latest` runner has ~7 GB RAM, so a 6 GB old-space ceiling is safe
(leaves ~1 GB headroom for the kernel + git checkouts + Vercel CLI's
non-heap allocations). Targeted, ~1 line of YAML, fully reversible.
Mirrors the standard remediation for `vercel deploy --prebuilt` OOMs on
content-heavy projects.

**Rejected — Pin/upgrade Vercel CLI version.**
We currently install `vercel@latest`. Switching versions changes the
upload pipeline shape and risks introducing unrelated regressions; we
have no evidence a specific version fixes the heap issue.

**Rejected — Switch to non-prebuilt deploy (`vercel --prod` without
`--prebuilt`).**
Would shift the build to Vercel's builder, lose the explicit Build step,
and re-introduce a 45-minute deploy budget concern. Out of scope and a
larger architectural change.

## Files expected to change

- `learnovaBeast/.github/workflows/publish.yml` — add `NODE_OPTIONS`
  to the `Deploy` step `env:` block. (Note: lives at the **repo root** of
  `learnovaBeast`, not under `learnova-academy/`. The ticket's "files
  expected in `learnovaBeast/learnova-academy`" wording does not fit —
  the failing step runs the Vercel CLI against the prebuilt output from
  the repo root and there is nothing inside `learnova-academy/` that
  controls CLI memory. Flag for the Reviewer; **no `learnova-academy/`
  source files need to change.**)

Diff shape:

```yaml
      - name: Deploy
        env:
          VERCEL_TOKEN: ${{ secrets.VERCEL_TOKEN }}
          VERCEL_ORG_ID: ${{ secrets.VERCEL_ORG_ID }}
          VERCEL_PROJECT_ID: ${{ secrets.VERCEL_PROJECT_ID }}
          NODE_OPTIONS: --max-old-space-size=6144
        run: vercel deploy --prod --prebuilt --yes --token=$VERCEL_TOKEN
```

## Steps (Executor follows in order)

1. From `Koenig-Solutions-Private-Limited/learnovaBeast`, branch from
   the current implementation tip: `git checkout academy/redesign-v1 &&
   git pull --ff-only`. If `academy/redesign-v1` is not present locally,
   `git fetch origin && git checkout -b academy/redesign-v1
   origin/academy/redesign-v1`.
2. Cut a topic branch off it for the fix, e.g.
   `koea-1316/vercel-deploy-heap-bump`.
3. Edit `.github/workflows/publish.yml`: in the `Deploy` step `env:`
   block, add `NODE_OPTIONS: --max-old-space-size=6144` as the last key.
   Do not change Build, Pull, Checkout, or any other step. Do not modify
   `concurrency`, `run-name`, or trigger.
4. Commit with message `fix(ci): bump Node heap to 6GB on vercel deploy
   step to fix OOM (KOEA-1316)` and push.
5. Open PR `koea-1316/vercel-deploy-heap-bump → academy/redesign-v1`
   (NOT to `main`). PR body links KOEA-1316 + run 25747288480 as the
   failure cite.
6. After PR merge into `academy/redesign-v1`, do not merge to `main` in
   this phase; surface the resume action on KOEA-256 instead (see below).

## Verification plan (QA Verifier checks these)

- [ ] **V1 — workflow lint:** `actionlint
      .github/workflows/publish.yml` exits clean (or, lacking actionlint,
      `gh workflow view publish.yml` shows the updated YAML parsed).
- [ ] **V2 — live re-dispatch on `academy/redesign-v1`:** with the fix
      merged into `academy/redesign-v1` and the workflow file present on
      that branch's tip, fire a `repository_dispatch`
      `event_type=publish-ready` for issue
      `781ec769-d5e1-4239-b376-e465a49bdb14` (or any other
      `dispatch_failed` issue) targeted at the **branch** of the fix
      (the workflow `on:` is `repository_dispatch` which always runs the
      workflow definition from the **default branch**, so this only
      verifies once the fix has shipped via PR to wherever the active
      publish workflow lives — see V2 caveat below).

    **V2 caveat — critical for Executor + Reviewer to read.**
    GitHub's `repository_dispatch` event runs the workflow from the
    repository's **default branch**, not from `academy/redesign-v1`.
    Therefore the heap bump only takes effect once `publish.yml` is on
    the default branch. Two reviewer-time options:
    1. **Preferred — verify on a branch via `workflow_dispatch`:**
       temporarily add a `workflow_dispatch:` trigger on the PR branch,
       run the workflow manually from `academy/redesign-v1` against a
       safe issue payload, confirm Deploy succeeds, then drop the
       `workflow_dispatch` block before merge to default.
    2. **Alternative — staged rollout:** after merge to
       `academy/redesign-v1`, escalate to Chief Engineering for a
       fast-forward to the default branch since the publish path is
       gated on it. Document the expected default-branch promotion as
       the unblock action.
- [ ] **V3 — log signature gone:** in the resumed run, the Deploy step
      log contains no `FATAL ERROR: Reached heap limit` line and no
      `Error: Upload aborted` retry storm.
- [ ] **V4 — end-to-end resume:** publish-action.sh Phase 2 flips the
      issue `publish_state` from `dispatch_failed` → `published`, sets
      `published_url=https://academy.kspl.tech`, and POSTs the
      publish-verifier heartbeat (one log line per phase in
      `~/.paperclip/logs/publish-action.log`).
- [ ] **V5 — academy.kspl.tech smoke:** `curl -sI
      https://academy.kspl.tech/` returns 200 and the canonical post
      route for the resumed slug is reachable.

## Risk + mitigation

- **R1 — Runner OOM at the OS level.** `ubuntu-latest` is a 7 GB box; a
  6 GB heap leaves slim headroom for git, Vercel CLI's non-V8 alloc,
  and ephemeral child processes. *Mitigation:* if V2 still OOMs at the
  OS level (different signature, kernel `oom-killer` instead of V8
  FATAL), escalate to `ubuntu-latest-4-core` (16 GB) via
  `runs-on: ubuntu-latest-4-core`, but only as a second iteration —
  do not pre-emptively change runner type now.
- **R2 — Default-branch gating.** As noted in V2 caveat, the fix is
  inert until the workflow file is on the default branch. *Mitigation:*
  Executor must surface this explicitly in the PR description and call
  out the default-branch promotion as a blocking precondition for the
  publish-resume.
- **R3 — Convex boundary violation.** None — this PR touches only a
  workflow YAML; no Convex deploy is implied. Reviewer should still
  confirm no `npx convex deploy` line is added.
- **R4 — Cancel of in-flight publish.** The workflow's `concurrency`
  group is `publish-${issue_id}` with `cancel-in-progress: false`, so
  the change cannot abort a currently-running publish for the same
  issue.

## Rollback plan

- **If the new deploy still OOMs at the V8 level:** raise the heap
  further (`--max-old-space-size=7168`) in a follow-up PR; if it crosses
  the OS limit at 7168, switch to `runs-on: ubuntu-latest-4-core`.
- **If the new run breaks for an unrelated reason traceable to the
  env block:** revert the single-line addition. The change is one
  YAML key; revert is a trivial PR against `academy/redesign-v1`.
- **If the fix is shipped but cannot reach the default branch in
  time:** keep publish frozen, mark all `g4-approved` issues
  `publish_state=publish_blocked` via `scripts/publish-action.sh` —
  do **not** revert content G3/G4 approvals.

## Publish-resume handling for KOEA-256

KOEA-256 (publish state machine) needs explicit resume after this fix
ships to the default branch:

1. **Identify failed dispatches.** `curl -s
   "$PAPERCLIP_URL/api/companies/$COMPANY_ID/issues" | jq '.[] |
   select(.metadata.publish_state == "dispatch_failed") | {id, slug:
   .metadata.slug, reason: .metadata.dispatch_failure_reason}'`. At
   minimum this includes KOEA-256 (issue id
   `781ec769-d5e1-4239-b376-e465a49bdb14`, slug `secure-coding`) — the
   victim of run 25747288480.
2. **Reset state to re-trigger Phase 1.** For each, PATCH
   `metadata.publish_state` back to `g4-approved` and clear
   `dispatched_at` and `dispatch_failure_reason`:
   ```
   curl -sX PATCH "$PAPERCLIP_URL/api/issues/$ID" \
     -H "Content-Type: application/json" \
     -d '{"metadata":{"publish_state":"g4-approved",
                       "dispatched_at":null,
                       "dispatch_failure_reason":null}}'
   ```
   This is intentional and safe: `publish-action.sh` Phase 1 is
   idempotent and the workflow's `concurrency: publish-${issue_id}` with
   `cancel-in-progress: false` will not collide with anything (the prior
   run is already terminal=failure).
3. **Wait for next launchd tick (≤60 s).** Phase 1 re-dispatches,
   Phase 2 flips to `published` on success and POSTs the
   publish-verifier (G5) heartbeat. Confirm in
   `~/.paperclip/logs/publish-action.log`.
4. **Failure-mode recovery.** If Phase 2 still flips to
   `dispatch_failed` after the heap bump, do **not** retry blindly:
   fetch the new run's job log, file a follow-up incident issue, and
   leave `publish_state=publish_blocked` so the publisher does not
   hot-loop.
5. **Idempotency for the verifier.** The publish-verifier (G5) is
   already idempotent on `slug` per KOEA-812; a resumed publish for the
   same `issue_id` will not double-emit verification chains.

## Out of scope

- Defensive `NODE_OPTIONS` on the **Build** step. Build currently
  succeeds; we keep scope tight. Track as a future hardening ticket if
  Next.js build heap ever creeps up.
- Migrating off `vercel@latest` to a pinned CLI version. Worth
  considering for supply-chain reproducibility but unrelated to this OOM.
- Switching the runner image (`ubuntu-latest` → `ubuntu-latest-4-core`).
  Only revisit if R1 fires.
- Updating deprecated `actions/checkout@v4` / `pnpm/action-setup@v4` to
  Node 24. The deprecation notice is informational until June 2026;
  unrelated to OOM.
- Any change inside `learnovaBeast/learnova-academy/` source — the
  failure is in the Vercel CLI, not in the academy app.
- Any Convex schema/function deploy.
- Direct merge of `academy/redesign-v1` → `main`. Out of phase; subject
  to Chief Engineering gate.

## Handoff

- **Status flip:** KOEA-1317 (this planner ticket) →
  `done`/`ready-for-review`; KOEA-1316 → `ready-to-execute` (Executor).
- **Branch contract:** `koea-1316/vercel-deploy-heap-bump` →
  `academy/redesign-v1`.
- **Resume contract:** named in "Publish-resume handling for KOEA-256"
  above; QA Verifier runs V4–V5 only after the workflow file reaches
  the default branch.
