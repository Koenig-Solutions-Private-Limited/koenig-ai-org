import { randomUUID } from "node:crypto";
import { and, eq, sql } from "drizzle-orm";
import { afterAll, afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import {
  activityLog,
  agents,
  agentRuntimeState,
  agentWakeupRequests,
  companies,
  companySkills,
  createDb,
  documentRevisions,
  documents,
  heartbeatRunEvents,
  heartbeatRuns,
  issueComments,
  issueRelations,
  issues,
} from "@paperclipai/db";
import {
  getEmbeddedPostgresTestSupport,
  startEmbeddedPostgresTestDatabase,
} from "./helpers/embedded-postgres.js";
import { heartbeatService, shouldAutoCheckoutIssueForWake } from "../services/heartbeat.ts";
import { issueService } from "../services/issues.ts";
import { runningProcesses } from "../adapters/index.ts";

const mockAdapterExecute = vi.hoisted(() =>
  vi.fn(async () => ({
    exitCode: 0,
    signal: null,
    timedOut: false,
    errorMessage: null,
    summary: "Blocked-status preservation test run.",
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
    `Skipping embedded Postgres heartbeat blocked-status preservation tests on this host: ${embeddedPostgresSupport.reason ?? "unsupported environment"}`,
  );
}

async function ensureIssueRelationsTable(db: ReturnType<typeof createDb>) {
  await db.execute(sql.raw(`
    CREATE TABLE IF NOT EXISTS "issue_relations" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      "company_id" uuid NOT NULL,
      "issue_id" uuid NOT NULL,
      "related_issue_id" uuid NOT NULL,
      "type" text NOT NULL,
      "created_by_agent_id" uuid,
      "created_by_user_id" text,
      "created_at" timestamptz NOT NULL DEFAULT now(),
      "updated_at" timestamptz NOT NULL DEFAULT now()
    );
  `));
}

async function waitForCondition(fn: () => Promise<boolean>, timeoutMs = 5_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    if (await fn()) return true;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  return fn();
}

describe("shouldAutoCheckoutIssueForWake blocked-status guard", () => {
  const agentId = randomUUID();

  it("does not auto-checkout blocked issues for generic wakes", () => {
    expect(
      shouldAutoCheckoutIssueForWake({
        contextSnapshot: { wakeReason: "issue_assigned" },
        issueStatus: "blocked",
        issueAssigneeAgentId: agentId,
        isDependencyReady: true,
        agentId,
      }),
    ).toBe(false);

    expect(
      shouldAutoCheckoutIssueForWake({
        contextSnapshot: { wakeReason: "missing_issue_comment" },
        issueStatus: "blocked",
        issueAssigneeAgentId: agentId,
        isDependencyReady: true,
        agentId,
      }),
    ).toBe(false);
  });

  it("allows auto-checkout from blocked only for blocker-resolution wakes", () => {
    expect(
      shouldAutoCheckoutIssueForWake({
        contextSnapshot: { wakeReason: "issue_blockers_resolved" },
        issueStatus: "blocked",
        issueAssigneeAgentId: agentId,
        isDependencyReady: true,
        agentId,
      }),
    ).toBe(true);
  });
});

describeEmbeddedPostgres("heartbeat blocked-status preservation on run finalization", () => {
  let db!: ReturnType<typeof createDb>;
  let heartbeat!: ReturnType<typeof heartbeatService>;
  let issuesSvc!: ReturnType<typeof issueService>;
  let tempDb: Awaited<ReturnType<typeof startEmbeddedPostgresTestDatabase>> | null = null;
  let previousPaperclipHome: string | undefined;

  beforeAll(async () => {
    previousPaperclipHome = process.env.PAPERCLIP_HOME;
    process.env.PAPERCLIP_HOME = `/tmp/paperclip-heartbeat-blocked-preservation-${randomUUID()}`;
    tempDb = await startEmbeddedPostgresTestDatabase("paperclip-heartbeat-blocked-preservation-");
    db = createDb(tempDb.connectionString);
    heartbeat = heartbeatService(db);
    issuesSvc = issueService(db);
    await ensureIssueRelationsTable(db);
  }, 20_000);

  afterEach(async () => {
    mockAdapterExecute.mockReset();
    mockAdapterExecute.mockImplementation(async () => ({
      exitCode: 0,
      signal: null,
      timedOut: false,
      errorMessage: null,
      summary: "Blocked-status preservation test run.",
      provider: "test",
      model: "test-model",
    }));
    runningProcesses.clear();
    let idlePolls = 0;
    for (let attempt = 0; attempt < 100; attempt += 1) {
      const runs = await db.select({ status: heartbeatRuns.status }).from(heartbeatRuns);
      const hasActiveRun = runs.some((run) => run.status === "queued" || run.status === "running");
      if (!hasActiveRun) {
        idlePolls += 1;
        if (idlePolls >= 3) break;
      } else {
        idlePolls = 0;
      }
      await new Promise((resolve) => setTimeout(resolve, 50));
    }
    await db.delete(activityLog);
    await db.delete(companySkills);
    await db.delete(issueComments);
    await db.delete(issueRelations);
    await db.delete(issues);
    await db.delete(documentRevisions);
    await db.delete(documents);
    await db.delete(heartbeatRunEvents);
    await db.delete(heartbeatRuns);
    await db.delete(agentWakeupRequests);
    await db.delete(agentRuntimeState);
    await db.delete(agents);
    await db.delete(companies);
  });

  afterAll(async () => {
    if (previousPaperclipHome === undefined) delete process.env.PAPERCLIP_HOME;
    else process.env.PAPERCLIP_HOME = previousPaperclipHome;
    await db?.$client?.end?.({ timeout: 0 });
    await tempDb?.cleanup();
  });

  it("keeps blocked status after PATCH during a running heartbeat", async () => {
    const companyId = randomUUID();
    const agentId = randomUUID();
    const issueId = randomUUID();
    let finishRun!: () => void;
    const runFinished = new Promise<void>((resolve) => {
      finishRun = resolve;
    });

    mockAdapterExecute.mockImplementationOnce(async () => {
      await runFinished;
      return {
        exitCode: 0,
        signal: null,
        timedOut: false,
        errorMessage: null,
        summary: "Run completed after deliberate blocked patch.",
        provider: "test",
        model: "test-model",
      };
    });

    await db.insert(companies).values({
      id: companyId,
      name: "Paperclip",
      issuePrefix: `T${companyId.replace(/-/g, "").slice(0, 6).toUpperCase()}`,
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
      runtimeConfig: {
        heartbeat: {
          wakeOnDemand: true,
          maxConcurrentRuns: 1,
        },
      },
      permissions: {},
    });
    await db.insert(issues).values({
      id: issueId,
      companyId,
      title: "Dependency-blocked implementation",
      status: "todo",
      priority: "medium",
      assigneeAgentId: agentId,
    });

    const wake = await heartbeat.wakeup(agentId, {
      source: "assignment",
      triggerDetail: "system",
      reason: "issue_assigned",
      payload: { issueId },
      contextSnapshot: { issueId, wakeReason: "issue_assigned" },
    });
    expect(wake).not.toBeNull();

    const runStarted = await waitForCondition(async () => {
      const run = await db
        .select({ status: heartbeatRuns.status })
        .from(heartbeatRuns)
        .where(eq(heartbeatRuns.id, wake!.id))
        .then((rows) => rows[0] ?? null);
      return run?.status === "running";
    });
    expect(runStarted).toBe(true);

    const adapterStarted = await waitForCondition(async () => mockAdapterExecute.mock.calls.length === 1);
    expect(adapterStarted).toBe(true);

    await issuesSvc.update(issueId, {
      status: "blocked",
      metadata: {
        unblock_owner: "planner",
        unblock_action: "merge dependency fix",
      },
    });

    const blockedMidRun = await db
      .select({ status: issues.status })
      .from(issues)
      .where(eq(issues.id, issueId))
      .then((rows) => rows[0] ?? null);
    expect(blockedMidRun?.status).toBe("blocked");

    finishRun();

    const runSucceeded = await waitForCondition(async () => {
      const run = await db
        .select({ status: heartbeatRuns.status })
        .from(heartbeatRuns)
        .where(eq(heartbeatRuns.id, wake!.id))
        .then((rows) => rows[0] ?? null);
      return run?.status === "succeeded";
    });
    expect(runSucceeded).toBe(true);

    const issueAfterFinalize = await db
      .select({ status: issues.status })
      .from(issues)
      .where(eq(issues.id, issueId))
      .then((rows) => rows[0] ?? null);
    expect(issueAfterFinalize?.status).toBe("blocked");
  }, 15_000);

  it("does not revive blocked dependency issues on generic assignment wakes", async () => {
    const companyId = randomUUID();
    const agentId = randomUUID();
    const blockerId = randomUUID();
    const blockedIssueId = randomUUID();

    await db.insert(companies).values({
      id: companyId,
      name: "Paperclip",
      issuePrefix: `T${companyId.replace(/-/g, "").slice(0, 6).toUpperCase()}`,
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
      runtimeConfig: {
        heartbeat: {
          wakeOnDemand: true,
          maxConcurrentRuns: 1,
        },
      },
      permissions: {},
    });
    await db.insert(issues).values([
      {
        id: blockerId,
        companyId,
        title: "Open blocker child",
        status: "todo",
        priority: "high",
      },
      {
        id: blockedIssueId,
        companyId,
        title: "Parent waiting on blocker",
        status: "blocked",
        priority: "medium",
        assigneeAgentId: agentId,
        metadata: {
          unblock_owner: "executor",
          unblock_action: "wait for KOEA-6430",
        },
      },
    ]);
    await db.insert(issueRelations).values({
      companyId,
      issueId: blockerId,
      relatedIssueId: blockedIssueId,
      type: "blocks",
    });

    const wake = await heartbeat.wakeup(agentId, {
      source: "assignment",
      triggerDetail: "system",
      reason: "issue_assigned",
      payload: { issueId: blockedIssueId },
      contextSnapshot: { issueId: blockedIssueId, wakeReason: "issue_assigned" },
    });
    expect(wake).toBeNull();

    const issueAfterWake = await db
      .select({ status: issues.status })
      .from(issues)
      .where(eq(issues.id, blockedIssueId))
      .then((rows) => rows[0] ?? null);
    expect(issueAfterWake?.status).toBe("blocked");

    const blockedRuns = await db
      .select({ count: sql<number>`count(*)::int` })
      .from(heartbeatRuns)
      .where(sql`${heartbeatRuns.contextSnapshot} ->> 'issueId' = ${blockedIssueId}`)
      .then((rows) => rows[0]?.count ?? 0);
    expect(blockedRuns).toBe(0);
  });
});
