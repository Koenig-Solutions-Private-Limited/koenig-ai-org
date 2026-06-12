#!/usr/bin/env node
import assert from "node:assert/strict";
import {
  MARKER_COMPLIANCE_INCIDENT_TITLE,
  classifyMarkerComment,
  collectMarkerGaps,
  formatMarkerGapReport,
  hasStructuredBlockerMarker,
  hasValidMarker,
} from "./marker-compliance.mjs";

function test(name, fn) {
  try {
    fn();
    console.log(`ok — ${name}`);
  } catch (err) {
    console.error(`fail — ${name}`);
    throw err;
  }
}

test("stable incident title has no count suffix", () => {
  assert.equal(MARKER_COMPLIANCE_INCIDENT_TITLE, "[WATCHDOG] Escalation marker compliance gaps");
  assert.doesNotMatch(MARKER_COMPLIANCE_INCIDENT_TITLE, /\d+\s+comments?$/);
});

test("ordinary dependency-routing comments are ignored", () => {
  const samples = [
    "Blocked by KOEA-1406 until publish pipeline lands. Unblock owner: Chief Engineering.",
    "Dependency-blocked on KOEA-1853. Waiting on sibling ticket; no Executor action until KOEA-1251 closes.",
    "Harness dispatch: parent ticket remains blocked. Status unchanged; triage complete.",
    "QA Verifier rerun failed on blocked ticket KOEA-2603 — Chromium libs still missing.",
    "Continuation summary\n\nIssue status changed to blocked. Next action: wait for KOEA-5250.",
  ];

  for (const body of samples) {
    const result = classifyMarkerComment(body);
    assert.equal(result.needsMarker, false, `expected ignore: ${body.slice(0, 60)}`);
  }
});

test("No work performed variants are accepted markers", () => {
  for (const body of [
    "No work performed: blocked at step 1 — plan drift in target files.",
    "No work performed: status=blocked",
  ]) {
    const result = classifyMarkerComment(body);
    assert.equal(result.hasMarker, true, body);
    assert.equal(result.needsMarker, false, body);
  }
});

test("No escalation marker is accepted", () => {
  const result = classifyMarkerComment(
    "No escalation: duplicate Watchdog marker incident routed into existing chain.",
  );
  assert.equal(result.hasMarker, true);
  assert.equal(result.needsMarker, false);
});

test("structured blocker comments with both markers are accepted", () => {
  const body =
    "Block reason: runtime_env_block — CAREER_R2_* missing from .env.koenig.\nUnblock owner/action: operator must inject CAREER_R2 block additively.";
  assert.equal(hasStructuredBlockerMarker(body), true);
  assert.equal(hasValidMarker(body), true);
  const result = classifyMarkerComment(body);
  assert.equal(result.hasMarker, true);
  assert.equal(result.needsMarker, false);
  assert.equal(result.reason, "valid_marker");
});

test("partial structured blocker comments are not accepted markers", () => {
  for (const body of [
    "Block reason: missing env var only.",
    "Unblock owner/action: operator must fix env.",
    "Blocked at step 2. Block reason: plan drift without unblock line.",
  ]) {
    assert.equal(hasStructuredBlockerMarker(body), false, body);
    assert.equal(hasValidMarker(body), false, body);
  }
});

test("partial structured blocker on stand-down decision is still reported", () => {
  const body =
    "Standing down — blocked at step 1. Block reason: plan drift in target files.";
  const result = classifyMarkerComment(body);
  assert.equal(result.hasMarker, false);
  assert.equal(result.needsMarker, true);
});

test("unmarked stand-down decision is reported", () => {
  const body =
    "Standing down — plan cannot be executed literally without re-plan. Will route back to Planner.";
  const result = classifyMarkerComment(body);
  assert.equal(result.hasMarker, false);
  assert.equal(result.needsMarker, true);
  assert.equal(result.reason, "stand_down_or_escalation_decision");
});

test("collectMarkerGaps surfaces only missing-marker stand-down comments", () => {
  const gaps = collectMarkerGaps([
    {
      id: "c1",
      issueId: "i1",
      issueIdentifier: "KOEA-9999",
      body: "Blocked by KOEA-1406. Unblock owner: Chief Engineering.",
    },
    {
      id: "c2",
      issueId: "i2",
      issueIdentifier: "KOEA-8888",
      body: "Standing down — plan drift detected; filing board approval without marker text.",
    },
    {
      id: "c3",
      issueId: "i3",
      issueIdentifier: "KOEA-7777",
      body: "No work performed: blocked at step 2",
    },
  ]);

  assert.equal(gaps.length, 1);
  assert.equal(gaps[0].commentId, "c2");
  assert.match(formatMarkerGapReport(gaps), /KOEA-8888/);
});

test("collectMarkerGaps ignores structured blocker accountability comments", () => {
  const gaps = collectMarkerGaps([
    {
      id: "c-blocker",
      issueId: "i1",
      issueIdentifier: "KOEA-5152",
      body:
        "Block reason: dependency on sibling ticket.\nUnblock owner/action: Chief Engineering to close KOEA-1406 first.",
    },
    {
      id: "c-standdown",
      issueId: "i2",
      issueIdentifier: "KOEA-8888",
      body: "Standing down — plan drift; no structured blocker markers present.",
    },
  ]);

  assert.equal(gaps.length, 1);
  assert.equal(gaps[0].commentId, "c-standdown");
});

console.log("marker-compliance.test.mjs — all tests passed");
