---
ticket: KOEA-10691
parent_ticket: KOEA-10690
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.45
basebranch_verified: n/a
authorized_by_approval: 3ae0ecc6-f91a-4ac3-8b54-704af06fa54b
revision: 2
---

# Plan: Guard routine dispatch from ineligible agents

## Goal
Prevent scheduled, manual, API, and webhook routine runs from creating routine execution issues for agents that are paused, errored, pending approval, terminated, budget-paused, or still over a hard budget stop. Success is observable as routine creation/update/run paths rejecting or recording failed runs before issue creation, while the scheduler continues ticking without crashing.

## Context
- Files to read first: `/app/server/src/services/routines.ts:398-409`, `/app/server/src/services/routines.ts:800-1035`, `/app/server/src/services/routines.ts:1199-1293`, `/app/server/src/services/routines.ts:1445-1558`, `/app/server/src/services/routines.ts:1632-1696`, `/app/server/src/services/budgets.ts:716-812`, `/app/server/src/__tests__/routines-service.test.ts:72-178`, `/app/server/src/__tests__/routines-e2e.test.ts:376-418`, `/app/server/src/__tests__/budgets-service.test.ts:154-193`
- Relevant prior work: Chief Engineering approval `3ae0ecc6-f91a-4ac3-8b54-704af06fa54b` authorized this plan despite chain depth 4.
- Constraints: Do not edit Learnova portals. Keep this to Paperclip control-plane server behavior and focused tests. `/app` is not a git checkout in this runtime, so base branch verification is n/a.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Centralize routine assignee eligibility in `server/src/services/routines.ts` with explicit routine-owned status and pause checks first, then layer `budgetService.getInvocationBlock()` for budget policy hard stops. Expand `assertAssignableAgent()` into a helper that loads `pauseReason` and rejects `status in (paused, error, pending_approval, terminated)` plus `pauseReason=budget`; do not rely on budget service for those generic status checks, because it only covers budget-owned pauses and policy overages. After those routine-specific checks pass, call the budget invocation block for the candidate agent/project so an active agent that is over a hard budget stop is also blocked. Call the same guard for create/update assignment and for the resolved assignee inside `dispatchRoutineRun()` before issue creation; dispatch should record a failed routine run with a clear `failureReason` and no `linkedIssueId` so schedule/webhook ticks do not throw or create work for an ineligible agent.
**Rejected**: Scheduler-only filter in `tickScheduledTriggers()` — misses manual/API/webhook runs and routine activation paths. **Rejected**: Relying only on `budgetService.getInvocationBlock()` — catches budget hard stops but does not reject generic `paused`, `error`, `pending_approval`, or `terminated` routine assignees. **Rejected**: Immediate data-only pause of the three routines — reduces current noise but leaves the software defect.

## Steps (Executor follows in order)
1. Update `server/src/services/routines.ts` to instantiate `budgetService(db)` and extend `assertAssignableAgent()` into a single routine assignee eligibility helper that selects `id`, `companyId`, `status`, and `pauseReason`; rejects same-company violations, `status in (paused, error, pending_approval, terminated)`, and `pauseReason=budget`; then calls `budgetService.getInvocationBlock(companyId, agentId, { projectId })` for hard-stop budget/company/project blocks.
2. In `create()` and `update()`, pass the effective project id into that helper so active routines cannot be created, assigned, re-assigned, or re-enabled with an ineligible default assignee.
3. In `runRoutine()`, keep validating one-off override assignees, and rely on the dispatch-level resolved-assignee check for default-assignee runs.
4. In `dispatchRoutineRun()`, after resolving `projectId` and `assigneeAgentId` but before `issueSvc.create()`, run the helper against the resolved assignee; if it fails after a `routineRuns` row is created, finalize that run as `failed` with the helper error message, update routine/trigger touched state, and return without creating an issue or queueing a wakeup.
5. Add focused tests in `server/src/__tests__/routines-service.test.ts` for paused, error, pending approval, terminated, `pauseReason=budget`, and still-over-hard-stop agents; include manual default-assignee, API-source, webhook, and scheduled dispatch expectations that no issue is created and the routine run is failed.
6. Add route or e2e coverage in `server/src/__tests__/routines-e2e.test.ts` for create/update/run paths rejecting or failing with ineligible assignees, preserving the existing draft routine override behavior for eligible one-off assignees.
7. Add a post-deploy operator step: board/admin should pause or reassign the currently active routines `cb73d346-a225-4c80-a536-a888de52cdfc`, `940e79d1-db4d-460c-82c9-e8ae1000a21e`, and `91a6d6e5-eed8-4fec-9cdc-1faf55bf7efb`; the code guard prevents new issues, but without this cleanup their future triggers will continue to record failed routine runs.

## Verification (QA Verifier checks these)
- [ ] `pnpm --filter @paperclipai/server test -- routines-service.test.ts` passes with new cases showing no routine execution issue is created for paused/error/pending/terminated/budget-blocked assignees.
- [ ] `pnpm --filter @paperclipai/server test -- routines-e2e.test.ts routines-routes.test.ts` passes with create/update/run behavior covered.
- [ ] A simulated scheduled trigger for an active routine whose default assignee is `status=error` returns a failed `routineRuns` row, advances/touches the trigger according to existing behavior, and does not call `issueSvc.create()` or queue a wakeup.
- [ ] A simulated routine run with an eligible override assignee for a draft/no-default routine still creates the execution issue as before.

## Risk
- The helper may block more routine starts when `budgetService.getInvocationBlock()` detects company/project hard stops, not only agent pauses. Mitigate by keeping the error message specific, adding tests for the agent hard-stop case, and treating company/project budget blocks as consistent with existing "new work cannot start" policy.

## Out of scope
- Raising Anthropic credits, changing agent budgets, modifying Rohit-facing content, or editing Learnova portal code.
