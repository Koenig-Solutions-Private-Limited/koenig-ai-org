---
ticket: KOEA-12779
planner: Planner (50970ac0-a67b-47e1-97fe-b872985f4bb8)
date: 2026-07-14
estimated_complexity: small (1 file, ~20 LOC delta)
estimated_token_cost: $0.20
---

# Plan

## Goal

Fix `dispatchRoutineRun` in `server/src/services/routines.ts` so that a PostgreSQL
unique-constraint violation on `issues_open_routine_execution_uq` (error 23505)
is fully absorbed and never propagates out of the function as an uncaught exception.

## Context

### Files to read first

- `server/src/services/routines.ts` — lines 824–1059 (`dispatchRoutineRun`)
- `server/src/services/issues.ts` — lines 2682–2750 (`issueSvc.create`)
- `packages/db/src/schema/issues.ts` — lines 86–94 (constraint definition)
- `packages/db/src/migrations/0062_routine_run_dispatch_fingerprint.sql` (constraint SQL)
- `server/src/__tests__/routines-service.test.ts` (existing concurrency tests)

### Prior work

- Migration 0062 added `origin_fingerprint` column (DEFAULT `'default'`) and
  changed the unique index from `(company_id, origin_kind, origin_id)` to
  `(company_id, origin_kind, origin_id, origin_fingerprint)` with a partial WHERE
  requiring `execution_run_id IS NOT NULL AND status IN open_statuses`.
- Board mitigation on 2026-07-13: cancelled all 977 open legacy
  `routine_execution` issues (those with `origin_fingerprint = 'default'` from
  pre-migration rows) to stop the crash loop.
- The current code has a `try/catch` at line 957–1015 that attempts to handle
  23505, but it is defective (see crash path below).

### Crash path (why 23505 escapes as uncaught)

`issueSvc.create` calls `db.transaction()` internally. Drizzle-orm propagates
the outer transaction context via `AsyncLocalStorage`, so this becomes a
**nested transaction** (SAVEPOINT). When the INSERT fails with 23505:

1. Drizzle rolls back to the savepoint, but leaves the outer `tx` connection in
   an aborted PostgreSQL state (`25P02 — in failed sql transaction`).
2. The inner `catch` at line 977 catches the 23505 and then calls
   `findOpenExecutionIssue(input.routine, txDb, dispatchFingerprint)` using the
   now-aborted `txDb` → this throws `25P02`.
3. The `25P02` error escapes the inner catch and hits the outer catch at line
   1040, which also tries `txDb.delete` and `finalizeRun(..., txDb)` → both also
   throw `25P02`.
4. The entire `db.transaction` rejects with `25P02`.
5. In `tickScheduledTriggers` (line 1717), `await dispatchRoutineRun(...)` is
   inside a bare `for` loop with no `try/catch`. The rejection propagates out of
   `tickScheduledTriggers`.
6. `tickScheduledTriggers` is called via `void routines.tickScheduledTriggers().catch(...)` 
   at `server/src/index.ts:732-741`. The `.catch` catches the error and **only 
   logs it** — process stays up for this tick.
7. **However**: during server startup the catch-up scheduler fires many back-logged 
   routines rapidly. If a crash-path race inside the transaction pool causes an 
   unhandled rejection *before* the `.catch` is attached (void + async gap), or if 
   the heartbeat's wakeup path (line 1018, using main `db` not `txDb`) sets 
   `executionRunId` on the new issue before the outer transaction commits — thereby 
   triggering the constraint on the UPDATE rather than the INSERT — the exception 
   lands outside any catch boundary → process crash.

The net effect: 119 server restarts on 2026-07-14, one per scheduler tick that
re-dispatched the same stuck routines.

### Constraints

- `server/` is upstream code — deviation justified because this is board priority
  #1 and a production crash loop.
- Do **not** modify `issueSvc.create` signature or the schema; keep the change
  local to `dispatchRoutineRun`.

## Approach

### Chosen: SAVEPOINT wrap around `issueSvc.create` (Approach 1)

Before the `issueSvc.create` call, issue an explicit `SAVEPOINT sp_issue_create`
on `txDb`. If the insert fails:
- `ROLLBACK TO SAVEPOINT sp_issue_create` restores the outer transaction to a live
  state (the `25P02` issue goes away)
- `RELEASE SAVEPOINT sp_issue_create` cleans up the savepoint slot
- The existing `findOpenExecutionIssue` + coalesce/skip logic runs normally on
  the still-alive `txDb`

This replaces the broken catch-and-retry with a PostgreSQL-native recovery
that keeps the outer transaction usable throughout.

### Rejected alternative: Approach 2 — `ON CONFLICT DO NOTHING` in issueSvc.create

Would require modifying `issueSvc.create` to accept a conflict-resolution hint,
touching a broader interface. Also, the partial index WHERE clause requires
`execution_run_id IS NOT NULL`, but the newly inserted row has `execution_run_id
= NULL` — so the new row is never in the partial index scope and `ON CONFLICT`
would never fire for it. This approach misunderstands the constraint mechanics.

### Rejected alternative: Approach 3 — Catch outside the transaction

Move issue creation outside the outer `db.transaction`, then catch 23505 at the
outer level. Breaks atomicity: if the outer transaction rolls back, the created
issue would remain committed (orphan). The existing cleanup in the outer catch
relies on the issue creation and run creation being in the same transaction.

## Steps

1. **Read** `server/src/services/routines.ts` lines 957–1015 to confirm exact
   indentation and surrounding structure before editing.

2. **Replace** the bare `issueSvc.create` try/catch block (lines 957–1015) with a
   SAVEPOINT-guarded version:
   ```typescript
   // Before issueSvc.create:
   await txDb.execute(sql`savepoint sp_issue_create`);
   try {
     createdIssue = await issueSvc.create(input.routine.companyId, { ... });
     await txDb.execute(sql`release savepoint sp_issue_create`);
   } catch (error) {
     await txDb.execute(sql`rollback to savepoint sp_issue_create`);
     await txDb.execute(sql`release savepoint sp_issue_create`);
     // Existing 23505-check and coalesce/skip logic follows, using txDb
     // which is now alive again thanks to the savepoint rollback.
     const isOpenExecutionConflict = ...;
     if (!isOpenExecutionConflict || input.routine.concurrencyPolicy === "always_enqueue") {
       throw error;
     }
     const existingIssue = await findOpenExecutionIssue(input.routine, txDb, dispatchFingerprint);
     if (!existingIssue) throw error;
     // ... rest of coalesce/skip as now ...
     return updated ?? createdRun;
   }
   ```
   File: `server/src/services/routines.ts`, replacing approximately lines 957–1015.
   Net delta: ~6 lines added, no lines removed (savepoint wrap around existing block).

3. **Verify** that `sql` (already imported at the top of `routines.ts`) is used for
   the raw `savepoint`/`rollback to savepoint`/`release savepoint` statements —
   consistent with the `FOR UPDATE` lock pattern already used at line 883.

4. **Add regression test** in `server/src/__tests__/routines-service.test.ts`:
   - Set up a routine with `concurrencyPolicy = 'coalesce_if_active'` (or
     `skip_if_active`).
   - Dispatch once → issue created; then directly set `executionRunId` and open
     status on that issue to make it match the constraint scope.
   - Dispatch again → second dispatch must resolve (not throw), status must be
     `"coalesced"` (or `"skipped"`), and only one open execution issue must exist.
   - Assert no unhandled rejection and that the routine run record shows the
     expected terminal status.

5. **Smoke-test** the `always_enqueue` path: ensure a dispatch with
   `always_enqueue` and a conflicting open issue still creates a second run (the
   existing inner-catch guard `|| always_enqueue` remains: rethrows so the outer
   catch marks it `failed`, which is the current behaviour for this edge case —
   do NOT silently swallow `always_enqueue` conflicts).

6. **Commit** with message:
   `fix(routines): savepoint-guard dispatchRoutineRun to survive 23505 constraint violation (KOEA-12779)`

7. **Open PR** targeting `main` in `Koenig-Solutions-Private-Limited/koenig-career-academy`
   (upstream fork base); assign to Chief Engineering for review chain.

## Verification

- [ ] New test in `routines-service.test.ts` passes: second dispatch on a routine
  with an existing open execution issue (executionRunId set) coalesces without
  throwing.
- [ ] Existing concurrency tests (`skip_if_active`, `coalesce_if_active`,
  `always_enqueue`) still pass — no regression.
- [ ] Grep `server/src/` for any bare `issueSvc.create` inside a `db.transaction`
  without savepoint guard — confirm only `dispatchRoutineRun` was affected.
- [ ] QA G2: `docker compose build paperclip` succeeds; server boots; scheduler
  tick with a pre-existing open routine_execution issue does NOT crash the
  process (observable via logs: "routine scheduler tick enqueued/skipped runs"
  not "routine scheduler tick failed" with 25P02 or 23505).

## Risk

| Risk | Mitigation |
|------|-----------|
| SAVEPOINT inside outer transaction changes the savepoint slot counter (each nested `db.transaction` may already use internal savepoints) | Use a uniquely named savepoint `sp_issue_create`; PostgreSQL savepoint names are session-scoped and can coexist with Drizzle-generated `sp1`, `sp2`, etc. |
| `RELEASE SAVEPOINT` on error path is redundant if `ROLLBACK TO SAVEPOINT` already keeps the savepoint — releasing is optional but harmless | Keep the release for cleanliness; PostgreSQL allows release after rollback-to |
| `always_enqueue` still results in the outer catch marking the run `failed` rather than inserting | This is pre-existing behaviour preserved intentionally; a separate ticket can address always_enqueue 23505 handling if needed |
| Modifying upstream `server/` | Justified by crash-loop severity; change is surgical (~20 LOC), no schema changes, no API surface changes |

## Out of scope

- Changing `issueSvc.create` signature or adding ON CONFLICT support to it.
- Fixing the `always_enqueue` + 23505 path beyond keeping it non-crashing.
- Addressing legacy `origin_fingerprint = 'default'` backfill — the board mitigation
  (cancelling 977 issues) has already drained the legacy set.
- Any schema migration.
- Related issue KOEA-6432 (routine dispatch status-flip orphans) — separate ticket.
