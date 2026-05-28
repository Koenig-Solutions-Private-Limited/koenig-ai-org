---
ticket: KOEA-6114
planning_ticket: KOEA-6156
planner: planner
agent: planner
date: 2026-05-28
type: decision
tags:
  - decision
  - engineering
  - watchdog
estimated_complexity: small
estimated_token_cost: "$0.28"
base_branch: master
basebranch_verified: true
revision: 1
preflight_status_verified: true
preflight_chain_ok: true
preflight_spec_ok: true
---

# Plan: Fix watchdog marker compliance false positives for structured blocked comments

## Goal
Stop KOEA-6114-style watchdog noise by teaching the marker-compliance detector that structured blocked-work comments with `Block reason:` and `Unblock owner/action:` are valid audit markers. Success means the watchdog no longer opens or nudges marker-compliance work for accountable blocker comments, while still flagging blocked issue comments that lack any accepted escalation/stand-down/accountability marker.

## Context
- Files to read first: `packages/db/watchdog_run_safe.mjs:60-80`, `packages/db/watchdog_run.mjs:64-78`, `packages/db/tmp-watchdog-heartbeat.mjs:83-106`, `scripts/koenig-cron-driver.py:11-18`, `doc/SPEC-implementation.md:31-42`.
- Live sample evidence: KOEA-5152 comment `aa05f2aa-88a7-4fcd-834a-5c41bc0ff505` includes `Block reason:` and `Unblock owner/action:` but is currently flagged; KOEA-2170 comments `49ae81b7-1c2b-4d14-891b-294e54fdeb75` and `9541b32d-3590-47df-b4ec-64549ed42229` use close variants such as `No escalation filed` and should remain a policy decision for Code Reviewer, not a backfill target.
- Relevant prior work: Chief Engineering dispatch comment on KOEA-6114 confirmed this is detector/marker-policy drift, not 72 independent board escalations. Existing detector accepts only `Approval filed:`, `No escalation:`, and `No work performed: status=`.
- Constraints: work only in `koenig-ai-org`; do not touch `learnovaBeast`; do not add marker comments to dozens of historical issues; preserve company-scoped SQL filtering and Watchdog Bot's non-mutating posture on other agents' issue statuses.

## Approach (1 chosen, alternatives rejected)
**Chosen**: broaden the marker detector to accept structured blocker-accountability comments. Update the SQL predicate in the active watchdog scripts so a comment is compliant when it contains any existing literal marker or both `Block reason:` and `Unblock owner/action:`. Keep the accepted literal markers unchanged for standing down, approval filing, and status-only no-op comments, and add a focused regression test or fixture so future edits do not silently return to literal-only matching.

**Rejected**: add noisy marker comments to the 72 historical samples - this treats valid blocked comments as bad data and creates audit churn; cancel KOEA-6114 without a code fix - the next watchdog run would recreate the same false-positive class; replace the watchdog with a schema-backed marker table - too broad for this operational bug and unnecessary for V1.

## Steps (Executor follows in order)
1. Confirm the active watchdog entrypoints in this checkout, then update `packages/db/watchdog_run_safe.mjs:60-80` and `packages/db/watchdog_run.mjs:64-78` so marker compliance means `(Approval filed:) OR (No escalation:) OR (No work performed: status=) OR (Block reason: AND Unblock owner/action:)`.
2. Check `packages/db/tmp-watchdog-heartbeat.mjs:83-106`; if it is still used by launchd/manual recovery, apply the same predicate there, otherwise add a short comment or issue note explaining why it is intentionally left untouched.
3. Add the smallest regression coverage available in this repo, preferably a pure marker-policy helper plus Vitest cases for accepted literal markers, accepted structured blocker comments, and rejected comments that have only one of `Block reason:` / `Unblock owner/action:`.
4. Run a read-only live SQL/API verification against the KOEA-6114 samples: prove KOEA-5152 comment `aa05f2aa-88a7-4fcd-834a-5c41bc0ff505` is no longer counted, while a synthetic/body fixture without accepted markers is still counted.
5. Re-run targeted verification: `pnpm --filter @paperclipai/db typecheck` plus the new/updated Vitest target if one was added; if coverage lives outside `packages/db/src`, run the narrow command that exercises it and document the command.
6. Open/update the implementation PR against `origin/master` with rollback notes: revert the watchdog predicate/helper change to restore literal-only detection. Do not include historical marker-comment backfills in the PR.
7. After merge/deploy or local watchdog reload, comment on KOEA-6114 with current detector evidence and close it only if the live missing-marker count no longer includes structured blocker comments; use a valid closeout marker such as `No escalation: detector policy fixed; no board approval required.`

## Verification (QA Verifier checks these)
- [ ] `packages/db/watchdog_run_safe.mjs` and `packages/db/watchdog_run.mjs` both preserve company scoping and engineering-agent scoping while accepting structured blocker comments.
- [ ] Regression coverage proves `Approval filed:`, `No escalation:`, `No work performed: status=`, and `Block reason:` + `Unblock owner/action:` are accepted, and partial structured comments are rejected.
- [ ] KOEA-5152 comment `aa05f2aa-88a7-4fcd-834a-5c41bc0ff505` is excluded by the revised detector without adding a new marker comment to KOEA-5152.
- [ ] `pnpm --filter @paperclipai/db typecheck` passes, plus the narrow test command added for the marker-policy coverage.
- [ ] No new watchdog issue/comment fanout is created for the KOEA-6114 historical sample set during verification.

## Risk
- The active runtime might use `packages/db/tmp-watchdog-heartbeat.mjs` or a copied script outside git instead of the two observed files. Mitigation: Executor must confirm the launchd/cron invocation path before editing, then include an operational reload/check step and note any out-of-repo script copy that also needs the same predicate.

## Out of scope
- Redesigning the watchdog subsystem, adding approval-schema migrations, changing Planner/Executor/Reviewer instructions, mutating historical blocked comments, or changing Learnova portal code.

## Plan-Review Handoff
Code Reviewer should review this as a detector-policy correction, not a historical-data cleanup. The key question is whether `Block reason:` plus `Unblock owner/action:` is sufficiently accountable to satisfy Watchdog's marker purpose without weakening the real escalation requirement for comments that need board approval or explicit no-op status.
