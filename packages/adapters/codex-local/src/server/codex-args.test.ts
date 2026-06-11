import { describe, expect, it } from "vitest";
import { buildCodexExecArgs } from "./codex-args.js";

const CODEX_BYPASS_FLAG = "--dangerously-bypass-approvals-and-sandbox";

function countBypassFlags(args: string[]): number {
  return args.filter((arg) => arg === CODEX_BYPASS_FLAG).length;
}

describe("buildCodexExecArgs", () => {
  it("enables Codex fast mode overrides for GPT-5.4", () => {
    const result = buildCodexExecArgs({
      model: "gpt-5.4",
      search: true,
      fastMode: true,
    });

    expect(result.fastModeRequested).toBe(true);
    expect(result.fastModeApplied).toBe(true);
    expect(result.fastModeIgnoredReason).toBeNull();
    expect(result.args).toEqual([
      "--search",
      "exec",
      "--json",
      "--model",
      "gpt-5.4",
      "-c",
      'service_tier="fast"',
      "-c",
      "features.fast_mode=true",
      "-",
    ]);
  });

  it("enables Codex fast mode overrides for manual models", () => {
    const result = buildCodexExecArgs({
      model: "gpt-5.5",
      fastMode: true,
    });

    expect(result.fastModeRequested).toBe(true);
    expect(result.fastModeApplied).toBe(true);
    expect(result.fastModeIgnoredReason).toBeNull();
    expect(result.args).toEqual([
      "exec",
      "--json",
      "--model",
      "gpt-5.5",
      "-c",
      'service_tier="fast"',
      "-c",
      "features.fast_mode=true",
      "-",
    ]);
  });

  it("deduplicates bypass flag when boolean and extraArgs both request it", () => {
    const result = buildCodexExecArgs({
      dangerouslyBypassApprovalsAndSandbox: true,
      extraArgs: [CODEX_BYPASS_FLAG],
    });

    expect(countBypassFlags(result.args)).toBe(1);
    expect(result.args).toEqual(["exec", "--json", CODEX_BYPASS_FLAG, "-"]);
  });

  it("keeps one bypass flag when only extraArgs request it", () => {
    const result = buildCodexExecArgs({
      dangerouslyBypassApprovalsAndSandbox: false,
      extraArgs: [CODEX_BYPASS_FLAG],
    });

    expect(countBypassFlags(result.args)).toBe(1);
    expect(result.args).toEqual(["exec", "--json", CODEX_BYPASS_FLAG, "-"]);
  });

  it("deduplicates repeated bypass flags in legacy args and preserves unrelated args", () => {
    const result = buildCodexExecArgs({
      args: [CODEX_BYPASS_FLAG, "--foo", CODEX_BYPASS_FLAG, "--bar"],
    });

    expect(countBypassFlags(result.args)).toBe(1);
    expect(result.args).toEqual([
      "exec",
      "--json",
      CODEX_BYPASS_FLAG,
      "--foo",
      "--bar",
      "-",
    ]);
  });

  it("ignores fast mode for unsupported models", () => {
    const result = buildCodexExecArgs({
      model: "gpt-5.3-codex",
      fastMode: true,
    });

    expect(result.fastModeRequested).toBe(true);
    expect(result.fastModeApplied).toBe(false);
    expect(result.fastModeIgnoredReason).toContain(
      "currently only supported on gpt-5.4 or manually configured model IDs",
    );
    expect(result.args).toEqual([
      "exec",
      "--json",
      "--model",
      "gpt-5.3-codex",
      "-",
    ]);
  });
});
