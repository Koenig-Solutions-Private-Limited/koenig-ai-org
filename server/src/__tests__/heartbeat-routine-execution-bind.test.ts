import { randomUUID } from "node:crypto";
import { and, eq } from "drizzle-orm";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import {
  agentWakeupRequests,
  agents,
  companies,
  createDb,
  heartbeatRunEvents,
  heartbeatRuns,
  issues,
} from "@paperclipai/db";
import {
  getEmbeddedPostgresTestSupport,
  startEmbeddedPostgresTestDatabase,
} from "./helpers/embedded-postgres.js";
import { heartbeatService } from "../services/heartbeat.ts";
import { ROUTINE_EXECUTION_CONFLICT_ERROR_CODE } from "../services/routine-execution-bind.ts";

const mockAdapterExecute = vi.hoisted(() =>
  vi.fn(async () => ({
    exitCode: 0,
    signal: null,
    timedOut: false,
    errorMessage: null,
    summary: "Routine bind guard test run.",
    provider: "test",
    model: "test-model",
  })),
);

vi.mock("../adapters/index.ts", async () => {
  const actual = await vi.importActual<typeof import("../adapters/index.ts")>("../adapters/index.ts");
  return {
    ...actual,
    getServerAdapter: vi.fn(() => ({
      supportsLocalAgentJwt: false,
      execute: mockAdapterExecute,
    })),
  };
});

const embeddedPostgresSupport = await getEmbeddedPostgresTestSupport();
const describeEmbeddedPostgres = embeddedPostgresSupport.supported ? describe : describe.skip;

if (!embeddedPostgresSupport.supported) {
  console.warn(
    `Skipping embedded Postgres routine execution bind guard tests on this host: ${embeddedPostgresSupport.reason ?? "unsupported environment"}`,
  );
}

describeEmbeddedPostgres("heartbeat routine execution bind guard", () => {
  let db!: ReturnType<typeof createDb>;
  let tempDb: Awaited<ReturnType<typeof startEmbeddedPostgresTestDatabase>> | null = null;

  beforeAll(async () => {
    tempDb = await startEmbeddedPostgresTestDatabase("paperclip-routine-exec-bind-");
    db = createDb(tempDb.connectionString);
  }, 20_000);

  afterEach(async () => {
    mockAdapterExecute.mockClear();
    await db.delete(heartbeatRunEvents);
    await db.delete(heartbeatRuns);
    await db.delete(agentWakeupRequests);
    await db.delete(issues);
    await db.delete(agents);
    await db.delete(companies);
  });

  afterAll(async () => {
    await tempDb?.cleanup();
  });

  async function seedAgentFixture() {
    const companyId = randomUUID();
    const agentId = randomUUID();
    const issuePrefix = `T${companyId.replace(/-/g, "").slice(0, 6).toUpperCase()}`;

    await db.insert(companies).values({
      id: companyId,
      name: "Paperclip",
      issuePrefix,
      requireBoardApprovalForNewAgents: false,
    });

    await db.insert(agents).values({
      id: agentId,
      companyId,
      name: "Executor",
      role: "engineer",
      status: "active",
      adapterType: "codex_local",
      adapterConfig: {},
      runtimeConfig: {},
      permissions: {},
    });

    return { companyId, agentId, issuePrefix };
  }

  async function seedActiveRoutineExecution(input: {
    companyId: string;
    agentId: string;
    issuePrefix: string;
    routineId: string;
    fingerprint: string;
    issueNumber: number;
  }) {
    const activeRunId = randomUUID();
    const activeIssueId = randomUUID();

    await db.insert(heartbeatRuns).values({
      id: activeRunId,
      companyId: input.companyId,
      agentId: input.agentId,
      invocationSource: "assignment",
      triggerDetail: "system",
      status: "running",
      startedAt: new Date(),
      contextSnapshot: {
        issueId: activeIssueId,
        taskId: activeIssueId,
        wakeReason: "issue_assigned",
      },
    });

    await db.insert(issues).values({
      id: activeIssueId,
      companyId: input.companyId,
      title: "Active routine execution",
      status: "in_progress",
      priority: "medium",
      assigneeAgentId: input.agentId,
      originKind: "routine_execution",
      originId: input.routineId,
      originRunId: randomUUID(),
      originFingerprint: input.fingerprint,
      executionRunId: activeRunId,
      executionLockedAt: new Date(),
      issueNumber: input.issueNumber,
      identifier: `${input.issuePrefix}-${input.issueNumber}`,
    });

    return { activeIssueId, activeRunId };
  }

  it("cancels a queued same-fingerprint routine resume without adapter_failed", async () => {
    const { companyId, agentId, issuePrefix } = await seedAgentFixture();
    const routineId = randomUUID();
    const fingerprint = "cron:0 9 * * *";
    const { activeIssueId, activeRunId } = await seedActiveRoutineExecution({
      companyId,
      agentId,
      issuePrefix,
      routineId,
      fingerprint,
      issueNumber: 1,
    });

    const resumeIssueId = randomUUID();
    const queuedRunId = randomUUID();
    const wakeupRequestId = randomUUID();

    await db.insert(issues).values({
      id: resumeIssueId,
      companyId,
      title: "Stale routine execution resume",
      status: "todo",
      priority: "medium",
      assigneeAgentId: agentId,
      originKind: "routine_execution",
      originId: routineId,
      originRunId: randomUUID(),
      originFingerprint: fingerprint,
      issueNumber: 2,
      identifier: `${issuePrefix}-2`,
    });

    await db.insert(agentWakeupRequests).values({
      id: wakeupRequestId,
      companyId,
      agentId,
      source: "automation",
      triggerDetail: "system",
      reason: "issue_commented",
      payload: { issueId: resumeIssueId },
      status: "queued",
      requestedByActorType: "user",
      requestedByActorId: "user-1",
    });

    await db.insert(heartbeatRuns).values({
      id: queuedRunId,
      companyId,
      agentId,
      invocationSource: "automation",
      triggerDetail: "system",
      status: "queued",
      wakeupRequestId,
      contextSnapshot: {
        issueId: resumeIssueId,
        taskId: resumeIssueId,
        wakeReason: "issue_commented",
        wakeCommentId: randomUUID(),
      },
    });

    const heartbeat = heartbeatService(db);
    await heartbeat.resumeQueuedRuns();

    const cancelledRun = await db
      .select()
      .from(heartbeatRuns)
      .where(eq(heartbeatRuns.id, queuedRunId))
      .then((rows) => rows[0] ?? null);
    expect(cancelledRun?.status).toBe("cancelled");
    expect(cancelledRun?.errorCode).toBe(ROUTINE_EXECUTION_CONFLICT_ERROR_CODE);
    expect(cancelledRun?.error).toContain("Routine execution already active");
    expect(cancelledRun?.resultJson).toMatchObject({
      activeIssueId,
      activeRunId,
      targetIssueId: resumeIssueId,
    });

    const activeRun = await db
      .select()
      .from(heartbeatRuns)
      .where(eq(heartbeatRuns.id, activeRunId))
      .then((rows) => rows[0] ?? null);
    expect(activeRun?.status).toBe("running");

    const activeIssue = await db
      .select()
      .from(issues)
      .where(eq(issues.id, activeIssueId))
      .then((rows) => rows[0] ?? null);
    expect(activeIssue?.executionRunId).toBe(activeRunId);

    const resumeIssue = await db
      .select()
      .from(issues)
      .where(eq(issues.id, resumeIssueId))
      .then((rows) => rows[0] ?? null);
    expect(resumeIssue?.executionRunId).toBeNull();

    const wakeup = await db
      .select()
      .from(agentWakeupRequests)
      .where(eq(agentWakeupRequests.id, wakeupRequestId))
      .then((rows) => rows[0] ?? null);
    expect(wakeup?.status).toBe("cancelled");

    expect(mockAdapterExecute).not.toHaveBeenCalled();
  });

  it("cancels deferred promotion when another same-fingerprint routine execution is active", async () => {
    const { companyId, agentId, issuePrefix } = await seedAgentFixture();
    const routineId = randomUUID();
    const fingerprint = "cron:0 9 * * *";
    await seedActiveRoutineExecution({
      companyId,
      agentId,
      issuePrefix,
      routineId,
      fingerprint,
      issueNumber: 1,
    });

    const resumeIssueId = randomUUID();
    const finishingRunId = randomUUID();
    const deferredWakeupId = randomUUID();

    await db.insert(heartbeatRuns).values({
      id: finishingRunId,
      companyId,
      agentId,
      invocationSource: "assignment",
      triggerDetail: "system",
      status: "running",
      startedAt: new Date(),
      contextSnapshot: {
        issueId: resumeIssueId,
        taskId: resumeIssueId,
        wakeReason: "issue_assigned",
      },
    });

    await db.insert(issues).values({
      id: resumeIssueId,
      companyId,
      title: "Routine issue awaiting deferred comment wake",
      status: "blocked",
      priority: "medium",
      assigneeAgentId: agentId,
      originKind: "routine_execution",
      originId: routineId,
      originRunId: randomUUID(),
      originFingerprint: fingerprint,
      issueNumber: 2,
      identifier: `${issuePrefix}-2`,
    });

    await db.insert(agentWakeupRequests).values({
      id: deferredWakeupId,
      companyId,
      agentId,
      source: "automation",
      triggerDetail: "system",
      reason: "issue_commented",
      payload: {
        issueId: resumeIssueId,
        _paperclipWakeContext: {
          issueId: resumeIssueId,
          wakeReason: "issue_commented",
          wakeCommentId: randomUUID(),
        },
      },
      status: "deferred_issue_execution",
      requestedByActorType: "user",
      requestedByActorId: "user-1",
    });

    const heartbeat = heartbeatService(db);
    await heartbeat.cancelRun(finishingRunId);

    const deferredWake = await db
      .select()
      .from(agentWakeupRequests)
      .where(eq(agentWakeupRequests.id, deferredWakeupId))
      .then((rows) => rows[0] ?? null);
    expect(deferredWake?.status).toBe("cancelled");
    expect(deferredWake?.error).toContain("Routine execution already active");

    const promotedRuns = await db
      .select()
      .from(heartbeatRuns)
      .where(
        and(
          eq(heartbeatRuns.companyId, companyId),
          eq(heartbeatRuns.agentId, agentId),
        ),
      );
    expect(promotedRuns.some((run) => run.status === "queued")).toBe(false);
    expect(promotedRuns.some((run) => run.wakeupRequestId === deferredWakeupId)).toBe(false);
  });
});
