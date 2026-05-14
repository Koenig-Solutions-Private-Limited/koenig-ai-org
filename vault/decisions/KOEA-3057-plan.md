---
ticket: KOEA-3057
planning_issue: KOEA-3060
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.38
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true active_siblings=0 acceptance_spec=pass basebranch_verified=true"
---

# Plan: Fix escalation marker watchdog false positives

## Goal
Watchdog Bot should report missing escalation markers only when a blocked-ticket comment is actually a stand-down or escalation decision that lacks an audit marker. Success means ordinary dependency-routing comments, QA rerun notes, reviewer telemetry, and Chief correction comments no longer create marker-compliance incidents, while true stand-down comments still require one of the approved markers.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:60-80`, `packages/db/watchdog_run.mjs:64-78`, `packages/db/watchdog_run_safe.mjs:17-21`, `packages/db/watchdog_run.mjs:18-21`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:19-36`, `vault/decisions/KOEA-2522-plan.md:24-35`, `vault/decisions/KOEA-2713-plan.md:24-35`, `vault/decisions/KOEA-2521-plan.md:24-36`.
- Relevant prior work: KOEA-2522 established least-privilege Watchdog routing through Watchdog-owned alert/handoff issues; KOEA-2713 and KOEA-2521 show the same watchdog-script pattern of brittle inline checks and unstable duplicate titles.
- Constraints: fix belongs primarily in the runtime watchdog scripts and the Watchdog Bot repo mirror. Do not edit Paperclip core permissions, do not touch `learnovaBeast`, and do not mass-edit Planner/Executor/Reviewer instructions unless Executor finds a direct scanner contract there. Use `origin/master`; `origin/main` is absent in this fork.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a small marker-compliance classifier shared by both watchdog scripts. Replace the current broad SQL predicate with a classifier that only audits comments whose body indicates an actual blocked/stand-down/escalation decision, accepts any `No work performed:` prefix plus `Approval filed:` and `No escalation:`, excludes routine operational updates such as dependency/rerun/telemetry comments, and files one stable Watchdog issue with actionable evidence instead of count-specific duplicate titles.

**Rejected**: Require every agent to use only `No work performed: status=<X>` because live instructions and comments already contain reasonable variants; this would preserve the false-positive pressure. **Rejected**: Disable marker compliance entirely because true stand-down comments still need auditability. **Rejected**: Patch only `watchdog_run_safe.mjs` because `watchdog_run.mjs` still contains the old direct-nudge implementation and could regress if invoked.

## Steps (Executor follows in order)
1. Add a local helper in `packages/db/watchdog_run_safe.mjs` that classifies marker compliance from `body`: `hasMarker`, `needsMarker`, and `reason`, where valid markers are `Approval filed:`, `No escalation:`, and `No work performed:` with any suffix.
2. Replace the marker SQL in `packages/db/watchdog_run_safe.mjs` with a narrower candidate query that returns recent blocked-issue comments from Engineering agents, then filter in JavaScript so only `needsMarker && !hasMarker` rows become gaps.
3. Change `ensureIssue` usage for marker gaps in `packages/db/watchdog_run_safe.mjs` to use a stable active title such as `[WATCHDOG] Escalation marker compliance gaps`, include count/sample bodies/issue identifiers in the description or follow-up comment, and avoid recreating the incident just because the count changes.
4. Apply the same classifier and stable incident behavior to `packages/db/watchdog_run.mjs`; also remove its direct source-ticket marker nudges so both scripts honor KOEA-2522's Watchdog-owned alert routing.
5. Update `companies/learnova-academy/agents/watchdog-bot/SOUL.md` with the scanner contract: marker compliance audits only stand-down/escalation decision comments, accepts `No work performed:` variants, and reports through one Watchdog-owned incident.
6. Add a small smoke test script or inline fixture test under the existing `watchdog/` area that exercises false positives from KOEA-3057: dependency-routing comments are ignored, `No work performed: blocked at step 1` is accepted, and a real stand-down comment without a marker is reported.
7. After verification, comment on KOEA-3057 that the fix is operational-script scoped, no human board approval is required, and historical marker-missing tickets should be treated as superseded by the stable incident key after the patch lands.

## Verification (QA Verifier checks these)
- [ ] `node --check packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs` passes.
- [ ] The new smoke test passes and proves normal dependency-routing comments like "wait on KOEA-3052" and reviewer telemetry comments are ignored.
- [ ] The smoke test proves `No work performed: blocked at step 1` and `No work performed: status=blocked` are both accepted markers.
- [ ] The smoke test proves a true stand-down/escalation decision without `Approval filed:`, `No escalation:`, or `No work performed:` is still reported.
- [ ] `rg -n "No work performed: status=|Marker missing|Escalation marker compliance gaps" packages/db/watchdog_run_safe.mjs packages/db/watchdog_run.mjs companies/learnova-academy/agents/watchdog-bot/SOUL.md watchdog` shows no remaining status-only marker predicate and no direct source-ticket marker nudge path.
- [ ] Running the marker classifier against the current KOEA-3057 sample comment IDs produces zero gaps for ordinary routing comments and at most one active Watchdog-owned incident for real gaps.

## Risk
- The classifier could become too permissive and miss a genuinely ambiguous blocked-ticket comment. Mitigate by matching only clear operational noise as exclusions, preserving a reported `reason`, and keeping fixture coverage for both ignored routing comments and reported unmarked stand-down decisions.

## Out of scope
- Broad Paperclip permission changes, human board approvals for marker cleanup, edits to `learnovaBeast`, bulk-closing the historical marker backlog, or rewriting unrelated publish-action/stale-blocked/failure-spike watchdog checks.
