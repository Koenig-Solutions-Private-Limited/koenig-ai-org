---
ticket: KOEA-8154
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.34
base_branch: master
basebranch_verified: true
planning_issue: KOEA-10969
---

# Plan: Stop claude_local credential failures from spawning recovery cascades

## Goal
Credential/auth failures from `claude_local` should be classified as credential failures, not anonymous `adapter_failed` runs. When such a terminal failure leaves assigned work without an execution path, Paperclip should stop automatic recovery for that issue, block it visibly, and surface one board approval/comment that tells the operator to refresh Claude credentials before retrying.

## Context
- Files to read first: `packages/adapters/claude-local/src/server/parse.ts:9-149`, `packages/adapters/claude-local/src/server/execute.ts:621-822`, `server/src/services/heartbeat.ts:982-1020`, `server/src/services/heartbeat.ts:6410-6485`, `server/src/__tests__/heartbeat-process-recovery.test.ts:1003-1075`
- Relevant prior work: existing `claude_auth_required` classification and two-attempt credential refresh retry in `packages/adapters/claude-local/src/server/execute.ts:781-822`; existing no-nested `stranded_issue_recovery` guard in `server/src/services/heartbeat.ts:6444-6459`
- Constraints: no schema change; keep behavior company-scoped; preserve existing recovery for process loss, timeout, transient upstream, and non-credential adapter failures; CEO/Chief Engineering dispatch on KOEA-8154 satisfies authorization for this bounded mitigation, so no fresh pre-implementation board approval is required

## Approach (1 chosen, alternatives rejected)
**Chosen**: classify Claude credential failures earlier and add a credential-specific immediate-recovery stop. Extend the `claude_local` auth detector to catch the incident string (`Invalid authentication credentials`) and related token-expired/authentication-error outputs, then teach heartbeat terminal-run cleanup to treat `claude_auth_required` on `claude_local` as non-recoverable by automatic agent retry: block the source issue, add a sanitized operator-facing comment, and create-or-reuse one pending `request_board_approval` linked to the issue so the board sees the required credential action.

**Rejected**: only increase auth retries in the adapter - this does not break the recovery loop when credentials are truly stale; only rely on the existing no-nested recovery guard - it protects recovery issues but not source issues repeatedly retried by the same stale adapter; implement credential auto-refresh - larger operational surface and depends on operator-specific Claude login mechanics.

## Steps (Executor follows in order)
1. Update `packages/adapters/claude-local/src/server/parse.ts` so `detectClaudeLoginRequired()` recognizes `Invalid authentication credentials`, `authentication_error`, token-expired, and similar Claude credential output while still ignoring ordinary transient upstream messages.
2. Add focused parser/adapter tests in `packages/adapters/claude-local/src/server/test.ts` or the existing Claude adapter test file proving the incident string yields `requiresLogin: true` and execution result code `claude_auth_required`.
3. In `server/src/services/heartbeat.ts`, add a small helper near `didAutomaticRecoveryFail()` that identifies terminal `claude_local` credential failures from the latest run (`errorCode === "claude_auth_required"`).
4. In `releaseIssueExecutionAndPromote()` before queuing recovery, branch credential failures into the existing block-in-place path, using a new comment builder that says automatic recovery stopped because Claude credentials need operator action and includes sanitized latest-run detail.
5. Create or reuse a pending `request_board_approval` for the blocked issue with payload subtype `adapter_credential_action_required`, link it through `issue_approvals`, and keep it idempotent by querying for an existing pending approval for the same company/issue/subtype before inserting.
6. Extend `server/src/__tests__/heartbeat-process-recovery.test.ts` with a case where a failed `claude_auth_required` run on assigned work blocks the issue, creates no recovery run/issue, links exactly one pending board approval, and does not duplicate the approval on a second cleanup pass.
7. Hand implementation to Code Reviewer for Plan-Review before merge, calling out that the review should focus on recovery regressions, approval idempotency, and secret redaction.

## Verification (QA Verifier checks these)
- [ ] `pnpm --filter @paperclipai/claude-local test` or the nearest targeted Claude adapter test command passes for the new auth-detection coverage.
- [ ] `pnpm vitest server/src/__tests__/heartbeat-process-recovery.test.ts` passes, including the new credential-stop test and existing stranded recovery tests.
- [ ] Manual code inspection confirms non-credential failures still take the prior recovery path and `claude_auth_required` comments/approval payloads do not include raw credentials or bearer tokens.

## Risk
- The auth regex could over-classify unrelated text that happens to mention invalid credentials. Mitigation: keep the matcher scoped to Claude CLI result/stdout/stderr auth phrases and cover representative positive and negative parser cases.

## Out of scope
- Automatically running `claude login`, refreshing host OAuth files, changing non-Claude adapters, or redesigning the stranded-work guardian.
