---
ticket: KOEA-3057
planning_issue: KOEA-3060
revision_issue: KOEA-5234
supersedes_plan_date: 2026-05-14
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Fix escalation marker watchdog false positives

## Goal
Watchdog Bot should report missing escalation markers only when a blocked-ticket comment is actually a stand-down or escalation decision that lacks an audit marker. Success means ordinary dependency-routing comments, QA rerun notes, reviewer telemetry, and Chief correction comments no longer create marker-compliance incidents, while true stand-down/escalation comments still require one approved marker.

## Context
- Files to read first: `watchdog/watchdog.mjs:1-329`, `watchdog/start-watchdog.sh:1-37`, `infra/launchd/com.koenig.watchdog.plist:7-34`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:19-36`, `vault/decisions/KOEA-2522-plan.md:24-35`, `vault/decisions/KOEA-3047-plan.md:34-47`.
- Relevant prior work: KOEA-5060 blocker comment `10f89c4f-b297-4e8b-9282-4eb7f13efc3b` found the prior plan targeted `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs`, which are absent from a clean `origin/master` worktree. KOEA-5191 is fresh evidence that the old live scanner still creates count-suffixed duplicates and flags ordinary blocked-ticket comments.
- Constraints: implement against tracked `origin/master` files only. `git ls-remote --heads origin master` returned `eae0c05...`; `origin/main` is absent. The dirty local `packages/db/watchdog_run*.mjs` files may explain the live alert but are not implementation targets unless Executor intentionally creates tracked replacements, which this plan does not require.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Move the marker-compliance behavior into the tracked watchdog daemon path with a small testable helper under `watchdog/`. The helper classifies comments into `hasMarker`, `needsMarker`, and `reason`, accepts `Approval filed:`, `No escalation:`, and any `No work performed:` prefix, ignores routine operational comments, and gives `watchdog/watchdog.mjs` one stable Watchdog-owned incident title without a count suffix.

**Rejected**: Edit `packages/db/watchdog_run_safe.mjs` / `packages/db/watchdog_run.mjs` because they are not tracked on `origin/master`, which already blocked KOEA-5060. **Rejected**: Disable marker compliance entirely because real stand-down/escalation comments still need audit markers. **Rejected**: Enforce only `No work performed: status=<X>` because live instructions allow reasonable variants and the false positives come from that over-narrow predicate.

## Steps (Executor follows in order)
1. Add `watchdog/marker-compliance.mjs` exporting `classifyMarkerComment(body)` and a small collector/formatter helper; valid markers are `Approval filed:`, `No escalation:`, and `No work performed:` with any suffix.
2. In the helper, mark comments as `needsMarker` only for clear stand-down/escalation decisions such as `standing down`, `will not plan`, `will not execute`, `blocked at step`, `plan cannot be executed literally`, `plan drift`, or explicit approval/escalation language; ignore ordinary dependency-routing, rerun, telemetry, and status-summary comments.
3. Add `watchdog/marker-compliance.test.mjs` with fixtures covering KOEA-5191-style ordinary routing comments, accepted `No work performed: blocked at step 1`, accepted `No work performed: status=blocked`, and an unmarked stand-down/escalation decision that must report.
4. Update `watchdog/watchdog.mjs` to call the helper during `tick()`: fetch the engineering-agent ids, scan recent blocked issues/comments through the Paperclip API with bounded limits, filter to `needsMarker && !hasMarker`, and keep the existing agent-health checks intact.
5. Add or reuse a Watchdog issue helper in `watchdog/watchdog.mjs` so marker gaps create/update one stable active issue titled `[WATCHDOG] Escalation marker compliance gaps`, with count, reasons, sample comment ids, and issue identifiers in the description or follow-up comment.
6. Update `companies/learnova-academy/agents/watchdog-bot/SOUL.md` to document the scanner contract: only stand-down/escalation decision comments are audited, `No work performed:` variants are valid, and duplicate count-suffixed marker incidents are obsolete.
7. Leave `packages/db/watchdog_run*.mjs` out of the patch unless Executor discovers a tracked runtime reference on `origin/master`; if such a reference exists, stop and file plan drift with the exact tracked caller.

## Verification (QA Verifier checks these)
- [ ] `git ls-tree -r --name-only origin/master | rg 'packages/db/watchdog_run|watchdog/watchdog.mjs|watchdog/start-watchdog.sh'` confirms the implementation targets are tracked and the old `packages/db/watchdog_run*.mjs` files are absent.
- [ ] `node --check watchdog/watchdog.mjs watchdog/marker-compliance.mjs watchdog/marker-compliance.test.mjs` passes.
- [ ] `node watchdog/marker-compliance.test.mjs` passes and proves ordinary dependency-routing/reviewer telemetry comments are ignored.
- [ ] The fixture test proves both `No work performed: blocked at step 1` and `No work performed: status=blocked` are accepted markers.
- [ ] The fixture test proves a true unmarked stand-down/escalation decision is reported.
- [ ] `rg -n "No work performed: status=|Marker missing|Escalation marker compliance gaps" watchdog companies/learnova-academy/agents/watchdog-bot/SOUL.md packages/db` shows no active status-only marker predicate in tracked watchdog files and no count-suffixed marker incident title in the patched tracked path.

## Risk
- A heuristic classifier can miss ambiguous stand-down language. Mitigate by keeping the report reasons explicit, matching only clear non-action operational comments as exclusions, and covering both ignored false positives and reported true positives in the fixture test.

## Out of scope
- Editing untracked local `packages/db/watchdog_run*.mjs`, changing Paperclip core permissions, bulk-closing historical marker tickets, broad Watchdog rewrites outside marker compliance, or modifying `learnovaBeast`.
