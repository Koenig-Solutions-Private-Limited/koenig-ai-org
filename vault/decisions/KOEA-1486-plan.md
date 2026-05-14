---
ticket: KOEA-1486
planner_ticket: KOEA-1490
planner: planner
date: 2026-05-13
estimated_complexity: routing-only (no new implementation lane)
estimated_token_cost: $0.20
status: ready-for-plan-review
verdict: DUPLICATE of KOEA-1437 chain — recommend roll-up, do not spawn new Implementer
no_convex_deploy: true
---

# Plan: KOEA-1486 is a duplicate of the KOEA-1437 chain — route, do not re-implement

## Goal

Close [KOEA-1486](/KOEA/issues/KOEA-1486) by routing it as a duplicate of the already-active [KOEA-1437](/KOEA/issues/KOEA-1437) work, instead of dispatching a second Implementer / Code-Reviewer / G2-QA lane against the same root causes. After this plan lands:

- [KOEA-1486](/KOEA/issues/KOEA-1486) is `blockedBy=[KOEA-1442, KOEA-1469]` — both canonical fix tickets already in flight.
- No new executor branch, no new PR, no new content child issue is created from this plan.
- When the upstream tickets close and Publish Verifier re-sweeps, [KOEA-1486](/KOEA/issues/KOEA-1486) auto-resolves.

## Context

### Reconciliation table — every [KOEA-1486](/KOEA/issues/KOEA-1486) symptom maps 1:1 to KOEA-1437's plan

[KOEA-1437](/KOEA/issues/KOEA-1437)'s plan document at [`vault/decisions/KOEA-1437-plan.md`](./KOEA-1437-plan.md) already enumerates every symptom listed in [KOEA-1486](/KOEA/issues/KOEA-1486)'s body. The mapping is exact:

| [KOEA-1486](/KOEA/issues/KOEA-1486) symptom | KOEA-1437 fix surface | Verification row in KOEA-1437 plan |
|---|---|---|
| `2026-04-30-gpt-5-5-in-codex` slides not linked; `/slides/<slug>.pptx` 404 | Fix 3 (blog slides surface: `lib/vault.ts` `slides_url` + `scripts/sync-vault.mjs` blog-media mirror + `page.tsx` slides pill) | V8 (`grep -F 'download'` shows `<a download href="/blogs/.../slides.pptx">`); V9 (`curl -sI` returns 200) |
| `ai-coding-agent-supply-chain-threat-atlas-2026` returns 404 | Fix 1 (redeploy via [KOEA-1469](/KOEA/issues/KOEA-1469) flipping KOEA-366 `publish_state=g4-approved`) | V1 (`curl -sI` returns 200) |
| Same blog: meta description invalid | Direct consequence of #1 — Next.js `notFound()` short-circuits `generateMetadata`. Resolved by Fix 1 redeploy. | V2 (`grep -E 'name="description"'` matches) |
| Same blog: canonical missing | Same as above — `generateMetadata` emits canonical via `lib/seo.ts` once page renders | V2 (canonical found in HTML) |
| Same blog: JSON-LD lacks BlogPosting + BreadcrumbList | Same as above — `blogPostingLd` and `breadcrumbLd` script tags emit once page renders | V2 (`grep 'application/ld+json'` count ≥ 2) |

**Conclusion:** there is no [KOEA-1486](/KOEA/issues/KOEA-1486)-only symptom that requires a separate fix. The set is a strict subset of KOEA-1437's scope.

### State of the related chain (verified 2026-05-13)

- [KOEA-1437](/KOEA/issues/KOEA-1437) — Parent G5 BLOCK. `status: blocked`. Plan written at [`vault/decisions/KOEA-1437-plan.md`](./KOEA-1437-plan.md) (planner ticket was KOEA-1440).
- [KOEA-1442](/KOEA/issues/KOEA-1442) — KOEA-1437 Implementer. `status: blocked` (awaiting plan-review acceptance and the two child issues below).
- [KOEA-1468](/KOEA/issues/KOEA-1468) — Content child: hand-write `seo_description` for `2026-04-30-anthropic-creative-connectors`. `status: in_progress` (not relevant to KOEA-1486's two symptoms, but in the same chain).
- [KOEA-1469](/KOEA/issues/KOEA-1469) — Engineering child: flip KOEA-366 `publish_state=g4-approved` to trigger `publish-action.sh` redeploy of the supply-chain blog. `status: blocked` (same redeploy that closes KOEA-1486's 404 + SEO failures).
- [KOEA-1393](/KOEA/issues/KOEA-1393) — Verifier no-speculation skill patch. `status: done` at G3, **PR #21 still awaiting G4 human approval**. Confirmed by `grep -n "Probe-scope\|speculative\|do not invent" companies/learnova-academy/skills/verify-publish/SKILL.md` returning **no match** on the current branch (`koea-1404/publish-action-g4-guard-final`). Until that merges and a new poll cycle runs, the verifier will keep emitting the speculative `/slides/<slug>.pptx` BLOCK — which is exactly what triggered [KOEA-1486](/KOEA/issues/KOEA-1486)'s slides line.

### Why the verifier re-emitted a slides BLOCK after KOEA-1393

[KOEA-1393](/KOEA/issues/KOEA-1393)'s skill patch is G3-approved (see [`vault/decisions/KOEA-1393-g3-verifier-scope.md`](./KOEA-1393-g3-verifier-scope.md)) but PR #21 is on the human G4 gate. The Publish Verifier loaded its skill from `master` and the `Probe-scope rule (HARD)` section is absent there — so it continues to invent `/slides/<slug>.pptx` URLs and report them as 404 BLOCKs. The slides line in [KOEA-1486](/KOEA/issues/KOEA-1486) is the same hallucination pattern, this time on `2026-04-30-gpt-5-5-in-codex` instead of the original `2026-04-30-anthropic-creative-connectors` (memory: `project_publish_verifier_speculative_url_probes.md`).

This means [KOEA-1486](/KOEA/issues/KOEA-1486)'s slides BLOCK is BOTH:
- a real symptom that KOEA-1437 Fix 3 will close (by serving the slides + a real link in the page), AND
- a verifier-hallucination noise that KOEA-1393 PR #21 will silence at the skill level when it merges.

KOEA-1437's plan covers both: Fix 3 builds the feature and Fix 3 step 6–7 re-installs the no-speculation rule in `SKILL.md` and `SOUL.md` as a belt-and-braces.

### Files to read first (for the reviewer of THIS plan)

- [`vault/decisions/KOEA-1437-plan.md`](./KOEA-1437-plan.md) — the canonical plan whose scope KOEA-1486 fits inside.
- [`vault/decisions/KOEA-1393-g3-verifier-scope.md`](./KOEA-1393-g3-verifier-scope.md) — G3 sign-off that explains the verifier hallucination.

### Constraints honored

- **No new implementation branch.** Implementation lives on `academy/redesign-v1` (learnovaBeast) and `koea-1437/blog-template-and-verifier` (koenig-ai-org), both already opened against KOEA-1442. No second branch is needed.
- **No Convex deploy.** Inherited from KOEA-1437 plan.
- **No direct merge to main.** Same.
- **No other portal edits.** Same.
- **Per-task cap $1.** This is a routing decision; expected cost <$0.25.

## Approach (1 chosen, alternatives rejected)

**Chosen — Roll [KOEA-1486](/KOEA/issues/KOEA-1486) up under the existing KOEA-1437 chain via first-class blockers, file a `planner_chain_alert` to surface the duplicate-dispatch pattern to Chief Engineering, and exit without spawning a new Implementer.**

Why: every observable failure on [KOEA-1486](/KOEA/issues/KOEA-1486) is a strict subset of KOEA-1437's verification matrix. Spawning [KOEA-1491](/KOEA/issues/KOEA-1491) (plan-review) → an Implementer → Code-Reviewer → G2-QA for KOEA-1486 would (a) burn ~$1–$2 in compute on work that's already in flight, (b) potentially open a second PR that conflicts with KOEA-1442's PR on the same files, and (c) train the verifier-poll to keep re-emitting these duplicates because no dedup signal goes back. First-class blockers + a `planner_chain_alert` are the durable fix.

**Rejected alternatives:**

- *Write a fresh independent plan against KOEA-1486 from scratch.* — Rejected: produces a duplicate of [`vault/decisions/KOEA-1437-plan.md`](./KOEA-1437-plan.md). Two plans with the same content invite divergent implementation, and the second Executor would race the first.
- *Cancel [KOEA-1486](/KOEA/issues/KOEA-1486) outright.* — Rejected: KOEA-1486 is a real G5 report and we want it as the audit trail that proves the fix landed. Closing it without confirmation hides the regression. Blocked-by + post-merge re-sweep is the correct closure path.
- *Mark [KOEA-1486](/KOEA/issues/KOEA-1486) `done` immediately with a "see KOEA-1437" comment.* — Rejected: same reason. The G5 sweep that closes this should be evidence-based, not a manual judgment.
- *Open a narrower KOEA-1486-specific implementation that only redeploys the supply-chain blog (skip the slides surface).* — Rejected: that would split KOEA-1437's PR and force a coordination across two Executors. The redeploy is already in KOEA-1469's scope.
- *Wait for KOEA-1393 PR #21 to G4-merge first, then re-run the verifier and let it drop the slides line on its own.* — Rejected as a *full* solution because that only silences the verifier, it doesn't actually serve the slides file. KOEA-1437 Fix 3 is still required to fix the supply-chain 404 and (orthogonally) to build the real slides surface. But the PR-21 merge is a useful **complementary** path to silence the speculative noise faster — recommended as a separate routing step (see "Recommended durable routing" below).

## Steps (Chief Engineering / Watchdog follows in order)

These are not Executor steps — there is no implementation Executor for KOEA-1486. These are routing actions to be applied to existing tickets:

1. **Set first-class blockers on [KOEA-1486](/KOEA/issues/KOEA-1486):**
   ```
   PATCH /api/issues/KOEA-1486
   { "blockedByIssueIds": ["<KOEA-1442 uuid>", "<KOEA-1469 uuid>"], "status": "blocked" }
   ```
   This makes [KOEA-1486](/KOEA/issues/KOEA-1486) auto-wake on `issue_blockers_resolved` when both KOEA-1442 (Implementer PR merges) and KOEA-1469 (publish_state flip + successful redeploy) reach `done`.

2. **Cancel the speculative [KOEA-1491](/KOEA/issues/KOEA-1491) plan-review lane** (it was preallocated to review THIS planner's output; once this routing plan is accepted there is no implementation to gate). Reassign to chief-engineering with `status: cancelled` and a comment linking back to this plan document. Use `cancelled`, not `done`, because no review work was performed.

3. **Do NOT open any KOEA-1486-Implementer issue.** The G5 sweep that follows KOEA-1442 + KOEA-1469 merging will produce a fresh verifier report; if it still reports failures, *that* report opens a new ticket. KOEA-1486 itself just closes on the blocker resolution wake.

4. **File a `planner_chain_alert` approval** (this Planner files it as part of this heartbeat — see "Escalation" below). Purpose: surface the duplicate-dispatch pattern to Chief Engineering so future verifier-poll dispatches dedup against open G5 BLOCK tickets before spawning a planner.

5. **Complementary acceleration (optional, owned by board G4 gate):** approve [KOEA-1393](/KOEA/issues/KOEA-1393) PR #21 (the verifier no-speculation skill patch). Approval id on the G4 record is `7940c6ba-27c3-4eb9-b79d-0a7e51ce9ab3`. Once merged, the verifier stops inventing `/slides/<slug>.pptx` BLOCKs on subsequent polls — silences the noise even before KOEA-1437 ships the real slides surface. This is independent of and complementary to the KOEA-1437 work; it does not replace it.

## Verification (smallest useful proof the routing closed correctly)

This plan does not ship code, so the verification is the routing closure:

- [ ] **V1 — Blocker linkage exists.** After step 1, `GET /api/issues/KOEA-1486` returns `blockedBy: [{identifier: "KOEA-1442", ...}, {identifier: "KOEA-1469", ...}]`.
- [ ] **V2 — No new Implementer ticket spawned.** `GET /api/companies/{id}/issues?q=KOEA-1486+Implement&status=todo,in_progress` returns empty.
- [ ] **V3 — Auto-wake fires.** When BOTH KOEA-1442 and KOEA-1469 reach `done`, [KOEA-1486](/KOEA/issues/KOEA-1486)'s assignee gets a `PAPERCLIP_WAKE_REASON=issue_blockers_resolved` wake.
- [ ] **V4 — Closure is evidence-based.** On that wake, the chief-engineering assignee dispatches a focused G5 re-sweep on the two slugs from KOEA-1486's body:
  - `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 | head -1` → `HTTP/2 200`
  - `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 | grep -cE 'rel="canonical"|application/ld\+json'` → `≥ 2`
  - `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 | grep -oE 'name="description" content="[^"]+"' | awk -F\" '{print length($4)}'` → `≥ 80` and `≤ 160`
  - `curl -s https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex | grep -F 'download'` → matches `<a … download href="/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx" …>`
  - `curl -sI https://academy.kspl.tech/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx | head -1` → `HTTP/2 200`
  Only if ALL five pass, [KOEA-1486](/KOEA/issues/KOEA-1486) → `done` with the curl outputs in the closing comment.
- [ ] **V5 — `planner_chain_alert` filed.** Chief Engineering acknowledges the alert and (optionally) updates the publish-verifier-poll dedup logic so future G5 BLOCK tickets check for open same-symptom tickets before dispatching a planner.

## Risk

- **The KOEA-1437 chain stalls indefinitely.** If KOEA-1442/1469 don't merge in a reasonable window, KOEA-1486 stays blocked, the live page stays 404, and we accumulate stale-blocked SLA debt. **Mitigation:** chief-engineering's heartbeat already runs the blocked-SLA sweep (see KOEA-1486's dispatch comment — 41 stale blocked tickets cleared this run). Both blockers will surface through that sweep if they go stale.
- **A new G5 sweep emits a fresh "KOEA-1486-like" ticket.** Until [KOEA-1393](/KOEA/issues/KOEA-1393) PR #21 merges, the verifier may emit yet another speculative-slides BLOCK on a third slug — same pattern, third ticket. **Mitigation:** step 5 in this plan asks the board to accelerate the PR-21 G4 approval as the durable noise-silencer. Memory note `project_publish_verifier_speculative_url_probes.md` already tracks this pattern.
- **KOEA-1437's Fix 1 redeploy still depends on `publish-action.sh` being healthy.** Memory note `project_publish_action_broken_2026_05_12.md` records four prior failure modes there (launchd unloaded, missing `GH_PAT_DISPATCH`, no auth header, wrong `COMPANY_ID`). **Mitigation:** KOEA-1437 plan step 8 has a pre-flight check; KOEA-1469's executor must run that before claiming the redeploy succeeded. If publish-action is wedged, the unblock owner is the KOEA-1137 chain owner.
- **`learnovaBeast` worktree is not in this repo.** This routing plan does not touch `learnovaBeast` so the worktree status is irrelevant here. KOEA-1442 owns that change.

## Out of scope (restated)

- Reproducing or restating KOEA-1437's Fix 1/3/4 in this plan — they are owned by [`vault/decisions/KOEA-1437-plan.md`](./KOEA-1437-plan.md).
- The 13-blog `seo_description` backfill stream — owned by [KOEA-1247](/KOEA/issues/KOEA-1247).
- G0 Content Reviewer policy and commit-msg hook — also [KOEA-1247](/KOEA/issues/KOEA-1247).
- Audio podcast surfaces on blog pages — separate goal.
- Any change to `learnova-tc` (Convex) — explicit no-Convex-deploy constraint inherited.
- Touching KOEA-1442's PR, branches, or files. KOEA-1442 owns that lane.

## Handoff

Plan complete. Next actions, in order:

1. **This Planner files a `planner_chain_alert` approval** to Chief Engineering, payload includes `rootIssueId=KOEA-1437` and `chainIds=[KOEA-1437, KOEA-1486]` per the escalation protocol.
2. **This Planner posts a comment on [KOEA-1490](/KOEA/issues/KOEA-1490)** with the verdict ("DUPLICATE — route, do not spawn"), links to this plan document, and reassigns to chief-engineering with `status: in_review`.
3. **Chief Engineering** applies the four routing steps above on receipt of this plan + the approval, then cancels [KOEA-1491](/KOEA/issues/KOEA-1491).
4. **No Executor work happens against [KOEA-1486](/KOEA/issues/KOEA-1486).** Closure happens automatically when KOEA-1442 + KOEA-1469 both close + a re-sweep confirms (V4).
