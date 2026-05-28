import { and, desc, eq, inArray, isNull, ne, or, sql } from "drizzle-orm";
import type { Db } from "@paperclipai/db";
import { heartbeatRuns, issues } from "@paperclipai/db";

export const ROUTINE_EXECUTION_CONFLICT_ERROR_CODE = "routine_execution_already_active" as const;

export const OPEN_ROUTINE_EXECUTION_ISSUE_STATUSES = [
  "backlog",
  "todo",
  "in_progress",
  "in_review",
  "blocked",
] as const;

export const ROUTINE_EXECUTION_LIVE_RUN_STATUSES = ["queued", "running", "scheduled_retry"] as const;

export type RoutineExecutionConflict = {
  errorCode: typeof ROUTINE_EXECUTION_CONFLICT_ERROR_CODE;
  targetIssueId: string;
  activeIssueId: string;
  activeIssueIdentifier: string | null;
  activeRunId: string | null;
  originId: string;
  originFingerprint: string;
};

export function buildRoutineExecutionConflictMessage(conflict: RoutineExecutionConflict): string {
  const activeLabel = conflict.activeIssueIdentifier ?? conflict.activeIssueId;
  return `Routine execution already active on ${activeLabel}; coalesced duplicate wake for same routine fingerprint`;
}

export function buildRoutineExecutionConflictDetails(
  conflict: RoutineExecutionConflict,
  extra?: Record<string, unknown>,
): Record<string, unknown> {
  return {
    errorCode: conflict.errorCode,
    targetIssueId: conflict.targetIssueId,
    activeIssueId: conflict.activeIssueId,
    activeIssueIdentifier: conflict.activeIssueIdentifier,
    activeRunId: conflict.activeRunId,
    originId: conflict.originId,
    originFingerprint: conflict.originFingerprint,
    ...extra,
  };
}

function isRoutineExecutionIssue(
  issue: Pick<typeof issues.$inferSelect, "originKind" | "originId">,
): boolean {
  return issue.originKind === "routine_execution" && !!issue.originId;
}

export async function findRoutineExecutionBindConflict(
  executor: Db,
  issue: Pick<
    typeof issues.$inferSelect,
    "id" | "companyId" | "originKind" | "originId" | "originFingerprint"
  >,
  opts?: { bindingRunId?: string },
): Promise<RoutineExecutionConflict | null> {
  if (!isRoutineExecutionIssue(issue)) return null;

  const openStatusList = [...OPEN_ROUTINE_EXECUTION_ISSUE_STATUSES];
  const liveRunStatusList = [...ROUTINE_EXECUTION_LIVE_RUN_STATUSES];

  const executionBound = await executor
    .select({
      id: issues.id,
      identifier: issues.identifier,
      executionRunId: issues.executionRunId,
    })
    .from(issues)
    .innerJoin(
      heartbeatRuns,
      and(
        eq(heartbeatRuns.id, issues.executionRunId),
        inArray(heartbeatRuns.status, liveRunStatusList),
      ),
    )
    .where(
      and(
        eq(issues.companyId, issue.companyId),
        eq(issues.originKind, "routine_execution"),
        eq(issues.originId, issue.originId!),
        eq(issues.originFingerprint, issue.originFingerprint),
        inArray(issues.status, openStatusList),
        isNull(issues.hiddenAt),
        ne(issues.id, issue.id),
      ),
    )
    .orderBy(desc(issues.updatedAt))
    .limit(1)
    .then((rows) => rows[0] ?? null);

  if (executionBound) {
    if (opts?.bindingRunId && executionBound.executionRunId === opts.bindingRunId) {
      return null;
    }
    return {
      errorCode: ROUTINE_EXECUTION_CONFLICT_ERROR_CODE,
      targetIssueId: issue.id,
      activeIssueId: executionBound.id,
      activeIssueIdentifier: executionBound.identifier,
      activeRunId: executionBound.executionRunId,
      originId: issue.originId!,
      originFingerprint: issue.originFingerprint,
    };
  }

  const contextBound = await executor
    .select({
      id: issues.id,
      identifier: issues.identifier,
      runId: heartbeatRuns.id,
    })
    .from(issues)
    .innerJoin(
      heartbeatRuns,
      and(
        eq(heartbeatRuns.companyId, issues.companyId),
        inArray(heartbeatRuns.status, liveRunStatusList),
        sql`${heartbeatRuns.contextSnapshot} ->> 'issueId' = cast(${issues.id} as text)`,
        opts?.bindingRunId ? ne(heartbeatRuns.id, opts.bindingRunId) : undefined,
      ),
    )
    .where(
      and(
        eq(issues.companyId, issue.companyId),
        eq(issues.originKind, "routine_execution"),
        eq(issues.originId, issue.originId!),
        eq(issues.originFingerprint, issue.originFingerprint),
        inArray(issues.status, openStatusList),
        isNull(issues.hiddenAt),
        ne(issues.id, issue.id),
      ),
    )
    .orderBy(desc(issues.updatedAt))
    .limit(1)
    .then((rows) => rows[0] ?? null);

  if (contextBound) {
    return {
      errorCode: ROUTINE_EXECUTION_CONFLICT_ERROR_CODE,
      targetIssueId: issue.id,
      activeIssueId: contextBound.id,
      activeIssueIdentifier: contextBound.identifier,
      activeRunId: contextBound.runId,
      originId: issue.originId!,
      originFingerprint: issue.originFingerprint,
    };
  }

  return null;
}

export async function stampRoutineExecutionRunId(
  executor: Db,
  input: {
    issue: Pick<
      typeof issues.$inferSelect,
      | "id"
      | "companyId"
      | "originKind"
      | "originId"
      | "originFingerprint"
      | "assigneeAgentId"
      | "executionRunId"
    >;
    runId: string;
    agentNameKey: string | null;
    lockedAt: Date;
    assigneeAgentId: string;
  },
): Promise<{ ok: true } | { ok: false; conflict: RoutineExecutionConflict }> {
  if (isRoutineExecutionIssue(input.issue)) {
    const conflictResult = await findRoutineExecutionBindConflict(executor, input.issue, {
      bindingRunId: input.runId,
    });
    if (conflictResult) {
      return { ok: false, conflict: conflictResult };
    }
  }

  await executor
    .update(issues)
    .set({
      executionRunId: input.runId,
      executionAgentNameKey: input.agentNameKey,
      executionLockedAt: input.lockedAt,
      updatedAt: input.lockedAt,
    })
    .where(
      and(
        eq(issues.id, input.issue.id),
        eq(issues.companyId, input.issue.companyId),
        eq(issues.assigneeAgentId, input.assigneeAgentId),
        or(isNull(issues.executionRunId), eq(issues.executionRunId, input.runId)),
      ),
    );

  return { ok: true };
}
