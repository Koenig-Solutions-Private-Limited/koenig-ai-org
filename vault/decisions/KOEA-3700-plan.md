---
ticket: KOEA-3700
planner: planner
date: 2026-05-18
estimated_complexity: small
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
target_repo: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org
target_worktree: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org
triggered_by_approval: 87f651ce-88d6-4d5d-a9a4-1f4cc615a685
---

# Plan: De-duplicate Codex bypass flag in local adapter invocations

## Goal
Fix the immediate runtime failure where a local agent invocation exits before work starts because `--dangerously-bypass-approvals-and-sandbox` appears more than once. Success means Paperclip still runs unattended Codex local agents with sandbox bypass enabled, but the generated CLI argv contains that bypass flag at most once even when adapter config also supplies it through `extraArgs` or legacy `args`.

This is a Paperclip core package change in `packages/adapters/codex-local`; Chief Engineering already authorized continuing this planning chain via approval `87f651ce-88d6-4d5d-a9a4-1f4cc615a685`.

## Context
- Files to read first: `packages/adapters/codex-local/src/server/codex-args.ts:31-63`, `packages/adapters/codex-local/src/server/codex-args.test.ts:1-70`, `packages/adapters/codex-local/src/server/execute.ts:44-45`, `packages/adapters/codex-local/src/ui/build-config.ts:87-106`, `packages/adapters/codex-local/src/index.ts:43-75`
- Relevant prior work: KOEA-3700 parent issue records the recovery failure `the argument '--dangerously-bypass-approvals-and-sandbox' cannot be used multiple times`; KOEA-3700 comment at 2026-05-18T05:42:50Z dispatches Planner, Plan-Reviewer, Executor, Code Reviewer, and QA chain for this fix.
- Constraints: Do not modify production code in Planner. Keep the fix limited to core Codex adapter argument construction unless Executor finds the duplicate originates from persisted agent config only. Preserve unattended local execution defaults.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Canonicalize the Codex bypass flag inside `buildCodexExecArgs`. Add a local constant for `--dangerously-bypass-approvals-and-sandbox`, read `extraArgs`/legacy `args` as today, detect and remove any occurrences of that exact flag from the user-supplied list, then add one canonical bypass flag when either the boolean config or user args request it. This keeps the public config surface unchanged and fixes every caller because `execute.ts` already funnels Codex argv through this helper.

**Rejected**: UI-only validation in `AgentConfigForm` because existing persisted agents and API-created agents can still pass duplicate args; **Rejected**: mutate current Planner/Researcher adapter configs to remove the extra flag because that unblocks one agent but leaves the adapter bug in place; **Rejected**: remove the boolean bypass default because unattended Codex heartbeats rely on it and this would change security/runtime behavior beyond the ticket scope.

## Steps (Executor follows in order)
1. Update `packages/adapters/codex-local/src/server/codex-args.ts` to define the bypass flag once and normalize `extraArgs`/`args` so the final argv includes it at most once.
2. Preserve behavior where `dangerouslyBypassApprovalsAndSandbox: true` adds the flag even with no extra args, and where `dangerouslyBypassApprovalsAndSandbox: false` plus `extraArgs: ["--dangerously-bypass-approvals-and-sandbox"]` still includes one flag.
3. Add regression tests in `packages/adapters/codex-local/src/server/codex-args.test.ts` for boolean-plus-extra duplicate input and duplicate legacy `args` input.
4. Run the targeted adapter test for `codex-args.test.ts`; if the workspace test command cannot target that file cleanly, run the smallest package-level Vitest command that includes it.
5. Inspect command metadata from a local Codex heartbeat or unit-level argv output to confirm only one bypass flag is emitted.
6. After the fix is merged/deployed, rerun the previously blocked Anthropic runtime probe chain issue (`KOEA-3695`/`KOEA-3700`) and confirm it no longer fails immediately with the duplicate `--dangerously-bypass-approvals-and-sandbox` collision.

## Verification (QA Verifier checks these)
- [ ] `buildCodexExecArgs({ dangerouslyBypassApprovalsAndSandbox: true, extraArgs: ["--dangerously-bypass-approvals-and-sandbox"] })` returns argv with exactly one bypass flag.
- [ ] Legacy `args` input with repeated bypass flags also returns argv with exactly one bypass flag and still preserves unrelated extra args.
- [ ] The Anthropic recovery/probe heartbeat that previously failed with `the argument '--dangerously-bypass-approvals-and-sandbox' cannot be used multiple times` starts past CLI argument parsing and does not reproduce that error.

## Risk
- Normalizing the bypass flag moves a user-supplied duplicate into Paperclip's canonical position before model/extra args. Mitigation: limit normalization to the exact bypass flag and preserve all unrelated extra args in their original relative order.

## Out of scope
- Do not redesign agent sandbox policy, change Claude local `--dangerously-skip-permissions`, edit persisted company agent configs, or alter UI adapter configuration forms except if Executor discovers tests require a direct type/export adjustment.
