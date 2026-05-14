import { afterEach, describe, expect, it } from "vitest";
import {
  __setDiscoveryImplForTests,
  discoverOpenCodeModelsCached,
  ensureOpenCodeModelConfiguredAndAvailable,
  listOpenCodeModels,
  resetOpenCodeModelsCacheForTests,
} from "./models.js";

describe("openCode models", () => {
  afterEach(() => {
    delete process.env.PAPERCLIP_OPENCODE_COMMAND;
    resetOpenCodeModelsCacheForTests();
    __setDiscoveryImplForTests(null);
  });

  it("returns an empty list when discovery command is unavailable", async () => {
    process.env.PAPERCLIP_OPENCODE_COMMAND = "__paperclip_missing_opencode_command__";
    await expect(listOpenCodeModels()).resolves.toEqual([]);
  });

  it("rejects when model is missing", async () => {
    await expect(
      ensureOpenCodeModelConfiguredAndAvailable({ model: "" }),
    ).rejects.toThrow("OpenCode requires `adapterConfig.model`");
  });

  it("rejects when discovery cannot run for configured model", async () => {
    process.env.PAPERCLIP_OPENCODE_COMMAND = "__paperclip_missing_opencode_command__";
    await expect(
      ensureOpenCodeModelConfiguredAndAvailable({
        model: "openai/gpt-5",
      }),
    ).rejects.toThrow("Failed to start command");
  });

  it("coalesces concurrent cache-miss callers into one discovery", async () => {
    let discoveryCount = 0;
    const models = [
      { id: "providerA/m1", label: "providerA/m1" },
      { id: "providerB/m2", label: "providerB/m2" },
    ];
    __setDiscoveryImplForTests(async () => {
      discoveryCount += 1;
      await new Promise((resolve) => setTimeout(resolve, 0));
      return models;
    });

    const results = await Promise.all(Array.from({ length: 6 }, () => discoverOpenCodeModelsCached({})));

    expect(discoveryCount).toBe(1);
    expect(results).toHaveLength(6);
    for (const result of results) {
      expect(result).toBe(models);
    }
  });

  it("failed concurrent discovery rejects all followers and clears in-flight for retry", async () => {
    let discoveryCount = 0;
    const error = new Error("discovery failed");
    const models = [
      { id: "providerA/m1", label: "providerA/m1" },
      { id: "providerB/m2", label: "providerB/m2" },
    ];
    __setDiscoveryImplForTests(async () => {
      discoveryCount += 1;
      await new Promise((resolve) => setTimeout(resolve, 0));
      if (discoveryCount === 1) throw error;
      return models;
    });

    const failures = await Promise.allSettled(
      Array.from({ length: 6 }, () => discoverOpenCodeModelsCached({})),
    );

    expect(discoveryCount).toBe(1);
    for (const failure of failures) {
      expect(failure.status).toBe("rejected");
      if (failure.status === "rejected") {
        expect(failure.reason).toBe(error);
      }
    }

    await expect(discoverOpenCodeModelsCached({})).resolves.toBe(models);
    expect(discoveryCount).toBe(2);
  });
});
