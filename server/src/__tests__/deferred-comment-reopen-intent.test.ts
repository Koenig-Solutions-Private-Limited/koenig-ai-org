import { describe, expect, it } from "vitest";
import { hasExplicitDeferredCommentReopenIntent } from "../services/heartbeat.ts";

describe("hasExplicitDeferredCommentReopenIntent", () => {
  it("rejects plain issue_commented wakes without explicit intent", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        { wakeReason: "issue_commented" },
        "issue_commented",
      ),
    ).toBe(false);
  });

  it("rejects user-authored deferred context without reopen metadata", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        { wakeReason: "issue_commented", commentId: "c1" },
        "issue_commented",
      ),
    ).toBe(false);
  });

  it("accepts issue_reopened_via_comment with resumeIntent", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        {
          wakeReason: "issue_reopened_via_comment",
          resumeIntent: true,
        },
        "issue_reopened_via_comment",
      ),
    ).toBe(true);
  });

  it("accepts issue_reopened_via_comment with followUpRequested", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        {
          wakeReason: "issue_reopened_via_comment",
          followUpRequested: true,
        },
        "issue_reopened_via_comment",
      ),
    ).toBe(true);
  });

  it("accepts issue_reopened_via_comment with reopenedFrom", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        {
          wakeReason: "issue_reopened_via_comment",
          reopenedFrom: "done",
        },
        "issue_reopened_via_comment",
      ),
    ).toBe(true);
  });

  it("rejects issue_reopened_via_comment without intent markers", () => {
    expect(
      hasExplicitDeferredCommentReopenIntent(
        { wakeReason: "issue_reopened_via_comment" },
        "issue_reopened_via_comment",
      ),
    ).toBe(false);
  });
});
