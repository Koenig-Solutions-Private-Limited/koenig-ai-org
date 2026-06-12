/**
 * Classifies engineering comments on blocked tickets for escalation-marker audit.
 * Only stand-down / escalation decisions require markers; routine operational
 * comments are ignored to prevent KOEA-3057-style false positives.
 */

export const MARKER_COMPLIANCE_INCIDENT_TITLE = "[WATCHDOG] Escalation marker compliance gaps";

const ENGINEERING_AGENT_NAMES = new Set([
  "planner",
  "executor",
  "code reviewer",
  "qa verifier",
  "chief engineering",
]);

const STAND_DOWN_PATTERNS = [
  /\bstanding down\b/i,
  /\bstand down\b/i,
  /\bwill not plan\b/i,
  /\bwill not execute\b/i,
  /\bblocked at step\b/i,
  /\bplan cannot be executed\b/i,
  /\bplan drift\b/i,
  /\bfile(?:d|ing)?\s+(?:a\s+|an\s+|the\s+)?(?:board\s+)?approval\b/i,
  /\brequest(?:ing|ed)?\s+(?:board\s+)?approval\b/i,
  /\bescalat(?:e|ing|ion)\b/i,
  /\broute(?:d)?\s+back\s+to\s+(?:planner|chief)\b/i,
];

const OPERATIONAL_EXCLUSION_PATTERNS = [
  /\bblocked by\b/i,
  /\bdependency[- ]block/i,
  /\bwaiting on\b/i,
  /\bdepends on\b/i,
  /\bharness dispatch\b/i,
  /\bwake payload\b/i,
  /\bcontinuation summary\b/i,
  /\bpre[- ]flight\b/i,
  /\bExecutor:\s+implemented=/i,
  /\bheartbeat[- ]close\b/i,
  /\bQA (?:rerun|failure|verify|verifier)\b/i,
  /\btests:\s*\d+\/\d+/i,
  /\btriage complete\b/i,
  /\bapprovals? backlog\b/i,
  /\bworktree=/i,
  /\bqueue_depth=/i,
  /\bstatus summary\b/i,
  /\bissue status changed\b/i,
];

export function hasStructuredBlockerMarker(body) {
  const text = String(body ?? "");
  return text.includes("Block reason:") && text.includes("Unblock owner/action:");
}

export function hasValidMarker(body) {
  const text = String(body ?? "");
  if (text.includes("Approval filed:")) return true;
  if (text.includes("No escalation:")) return true;
  if (text.includes("No work performed:")) return true;
  if (hasStructuredBlockerMarker(text)) return true;
  return false;
}

/**
 * @returns {{ hasMarker: boolean, needsMarker: boolean, reason: string }}
 */
export function classifyMarkerComment(body) {
  const text = String(body ?? "").trim();
  if (!text) {
    return { hasMarker: false, needsMarker: false, reason: "empty" };
  }

  if (hasValidMarker(text)) {
    return { hasMarker: true, needsMarker: false, reason: "valid_marker" };
  }

  for (const pattern of OPERATIONAL_EXCLUSION_PATTERNS) {
    if (pattern.test(text)) {
      return { hasMarker: false, needsMarker: false, reason: "operational_routine" };
    }
  }

  for (const pattern of STAND_DOWN_PATTERNS) {
    if (pattern.test(text)) {
      return { hasMarker: false, needsMarker: true, reason: "stand_down_or_escalation_decision" };
    }
  }

  return { hasMarker: false, needsMarker: false, reason: "not_audited" };
}

export function isEngineeringAgentName(name) {
  return ENGINEERING_AGENT_NAMES.has(String(name ?? "").trim().toLowerCase());
}

export function collectMarkerGaps(comments) {
  const gaps = [];
  for (const comment of comments) {
    const classification = classifyMarkerComment(comment.body);
    if (classification.needsMarker && !classification.hasMarker) {
      gaps.push({
        commentId: comment.id,
        issueId: comment.issueId ?? comment.issue_id,
        issueIdentifier: comment.issueIdentifier ?? comment.issue_identifier,
        reason: classification.reason,
        bodyPreview: String(comment.body ?? "").slice(0, 120),
      });
    }
  }
  return gaps;
}

export function formatMarkerGapReport(gaps) {
  if (gaps.length === 0) {
    return "Marker compliance scan: no stand-down/escalation comments missing audit markers.";
  }

  const lines = [
    `Marker compliance scan found ${gaps.length} stand-down/escalation comment(s) missing audit markers.`,
    "",
    "Required markers: `Approval filed:`, `No escalation:`, any `No work performed:` variant, or structured blocker accountability (`Block reason:` + `Unblock owner/action:`).",
    "",
  ];

  for (const gap of gaps.slice(0, 20)) {
    const target = gap.issueIdentifier ?? gap.issueId ?? "unknown-issue";
    lines.push(`- comment ${gap.commentId} on ${target}: ${gap.reason}`);
    if (gap.bodyPreview) {
      lines.push(`  preview: ${gap.bodyPreview.replace(/\s+/g, " ")}`);
    }
  }

  if (gaps.length > 20) {
    lines.push(`… and ${gaps.length - 20} more`);
  }

  return lines.join("\n");
}
