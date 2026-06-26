---
ticket: KOEA-8870
planner: planner
date: 2026-06-17
estimated_complexity: small
estimated_token_cost: $0.23
planning_ticket: KOEA-8871
base_branch: master
basebranch_verified: true
---

# Plan: Fix Watchdog marker scanner to honor repair comments

## Goal
Watchdog marker compliance should stop reporting a historical stand-down/escalation comment once a later comment on the same issue explicitly repairs that exact comment id and includes a valid audit marker. Success means the existing marker rules still catch unmarked stand-down decisions, while KOEA-4857-style repair comments suppress only the named historical gap.

## Context
- Files to read first: `watchdog/marker-compliance.mjs:69-127`, `watchdog/watchdog.mjs:220-278`, `watchdog/marker-compliance.test.mjs:91-165`.
- Relevant prior work: `5f9d31194 [KOEA-6114] Fix watchdog marker compliance false positives`; `vault/decisions/KOEA-3057-plan.md` introduced the current tracked scanner contract; KOEA-8870 comment `95080941-b772-4cca-9c79-18c7e893447e` confirms the live false positive on KOEA-4857 comment `72a8e3d0-1f47-428b-b97d-a27ac0b0f50f` despite repair comment `440e84ca-7bd5-4776-b0ca-8c0d6e29f500`.
- Constraints: planning only in KOEA-8871; keep scope limited to tracked Watchdog marker compliance files and tests; do not mutate KOEA-4857, delete historical comments, or weaken normal marker enforcement. Current checkout has unrelated dirty changes in `watchdog/watchdog.mjs` around Resend email alert fallback, so Executor should preserve them.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add explicit issue-local repair suppression inside the marker gap collector. Keep `classifyMarkerComment()` and `hasValidMarker()` as the source of truth for valid markers, add a small helper that extracts repaired comment ids only from valid-marker comments that explicitly reference a comment UUID, and suppress a gap only when the repair comment belongs to the same issue and is later than the offending comment. This keeps the behavior testable in `marker-compliance.mjs` and requires only one caller adjustment to include `createdAt`.

**Rejected**: Manually close or edit KOEA-4857/KOEA-8870, because that treats one incident and leaves the detector broken. **Rejected**: Treat any later valid marker on an issue as repairing all earlier gaps, because it would let unrelated status comments hide real audit gaps. **Rejected**: Broaden operational exclusions or weaken stand-down detection, because the ticket explicitly requires preserving enforcement for unmarked decisions.

## Steps (Executor follows in order)
1. Update `watchdog/watchdog.mjs:267-272` so `candidateComments` carries `createdAt: comment.createdAt ?? comment.created_at` along with id, body, issue id, and issue identifier.
2. In `watchdog/marker-compliance.mjs`, add a UUID/comment-reference helper near `hasValidMarker()` that returns target comment ids only when the body has a valid marker and explicitly refers to a comment id, for example `comment 72a8e3d0-...` or `offending comment id 72a8e3d0-...`.
3. Refactor `collectMarkerGaps(comments)` to make one lightweight pass over normalized comments, build same-issue repair references from valid repair comments, and suppress a candidate gap only if a repair targets `comment.id`, shares the same `issueId` or `issueIdentifier`, and is later by `createdAt` when timestamps exist.
4. Preserve current fallback behavior when timestamps are missing by treating the existing input order as newest-first, matching `fetchIssueComments(... order=desc)` in `watchdog/watchdog.mjs:220-222`; document this with one short comment in the collector.
5. Extend `watchdog/marker-compliance.test.mjs` with focused fixtures for unrepaired gap still reports, repaired same-issue gap is suppressed, unrelated valid marker does not suppress an older gap, and cross-issue repair references do not suppress.
6. Run `node watchdog/marker-compliance.test.mjs` and include the output in the Executor handoff/PR verification.

## Verification (QA Verifier checks these)
- [ ] `node watchdog/marker-compliance.test.mjs` passes with regression coverage for unrepaired, repaired, unrelated-marker, and cross-issue cases.
- [ ] A fixture matching KOEA-4857 comment `72a8e3d0-1f47-428b-b97d-a27ac0b0f50f` plus later repair comment `440e84ca-7bd5-4776-b0ca-8c0d6e29f500` produces zero marker gaps for that specific historical comment.
- [ ] Existing tests for ordinary dependency-routing comments, `No work performed:` markers, structured blocker markers, and unmarked stand-down decisions still pass unchanged.

## Risk
- A repair-comment parser that is too loose could hide real audit gaps. Mitigation: require both a valid marker and an explicit comment-id reference, scope suppression to the same issue, and add negative tests for unrelated valid marker comments and cross-issue references.

## Out of scope
- Changing Watchdog incident assignment/routing, mutating KOEA-4857 or KOEA-8870 status, deleting historical comments, broadening the marker taxonomy, or touching unrelated Watchdog alerting changes already present in the dirty worktree.
