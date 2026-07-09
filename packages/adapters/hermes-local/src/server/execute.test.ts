import { describe, expect, it, vi, beforeEach } from "vitest";

const {
  ensureAdapterExecutionTargetCommandResolvable,
  resolveAdapterExecutionTargetCommandForLogs,
  runAdapterExecutionTargetProcess,
} = vi.hoisted(() => ({
  ensureAdapterExecutionTargetCommandResolvable: vi.fn(async () => undefined),
  resolveAdapterExecutionTargetCommandForLogs: vi.fn(async (command: string) => command),
  runAdapterExecutionTargetProcess: vi.fn(async () => ({
    exitCode: 2,
    signal: null,
    timedOut: false,
    stdout: "",
    stderr:
      "usage: hermes chat [-h] [-q QUERY] [--image IMAGE] [-m MODEL] [-t TOOLSETS]\n" +
      "hermes chat: error: argument --provider: invalid choice: 'lmstudio'\n",
  })),
}));

vi.mock("@paperclipai/adapter-utils/execution-target", async () => {
  const actual = await vi.importActual<typeof import("@paperclipai/adapter-utils/execution-target")>(
    "@paperclipai/adapter-utils/execution-target",
  );
  return {
    ...actual,
    adapterExecutionTargetIsRemote: vi.fn(() => false),
    adapterExecutionTargetPaperclipApiUrl: vi.fn(() => null),
    adapterExecutionTargetRemoteCwd: vi.fn((_target: unknown, cwd: string) => cwd),
    ensureAdapterExecutionTargetCommandResolvable,
    readAdapterExecutionTarget: vi.fn(() => null),
    resolveAdapterExecutionTargetCommandForLogs,
    runAdapterExecutionTargetProcess,
  };
});

import { execute } from "./execute.js";

async function executeHermes(config: Record<string, unknown>) {
  const result = await execute({
    runId: "run-1",
    agent: {
      id: "agent-1",
      companyId: "company-1",
      name: "Hermes Agent",
      adapterType: "hermes_local",
      adapterConfig: {},
    },
    runtime: {
      sessionId: null,
      sessionParams: null,
      sessionDisplayId: null,
      taskKey: null,
    },
    config: {
      command: "hermes",
      promptTemplate: "Implement the task.",
      yolo: false,
      acceptHooks: false,
      ...config,
    },
    context: {},
    onLog: async () => {},
  });

  const call = runAdapterExecutionTargetProcess.mock.calls[0] as unknown as
    | [string, unknown, string, string[]]
    | undefined;
  return { result, args: call?.[3] ?? [] };
}

function valueAfter(args: string[], flag: string) {
  const index = args.indexOf(flag);
  return index >= 0 ? args[index + 1] : undefined;
}

describe("hermes execute argv", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("suppresses unsupported lmstudio provider while preserving prompt, model, and toolsets", async () => {
    const { result, args } = await executeHermes({
      model: "qwopus3.6-35b-a3b-v1-mtp",
      provider: "lmstudio",
      toolsets: "write,read,search",
    });

    expect(args.slice(0, 3)).toEqual(["chat", "-q", "Implement the task."]);
    expect(valueAfter(args, "-m")).toBe("qwopus3.6-35b-a3b-v1-mtp");
    expect(valueAfter(args, "-t")).toBe("write,read,search");
    expect(args).not.toContain("--provider");
    expect(args).not.toContain("lmstudio");
    expect(result.errorMessage).toBe(
      "hermes chat: error: argument --provider: invalid choice: 'lmstudio'",
    );
  });

  it("passes supported openrouter provider", async () => {
    const { args } = await executeHermes({
      model: "anthropic/claude-sonnet-4.6",
      provider: "openrouter",
    });

    expect(valueAfter(args, "--provider")).toBe("openrouter");
  });

  it("suppresses unsupported openai provider alias", async () => {
    const { args } = await executeHermes({
      model: "openai/gpt-5.2",
      provider: "openai",
    });

    expect(args).not.toContain("--provider");
    expect(args).not.toContain("openai");
  });

  it("passes other supported Hermes providers", async () => {
    const { args } = await executeHermes({
      model: "gemini/gemini-2.5-pro",
      provider: "gemini",
    });

    expect(valueAfter(args, "--provider")).toBe("gemini");
  });
});
