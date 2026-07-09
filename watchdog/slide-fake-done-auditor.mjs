#!/usr/bin/env node
// Slide Artifact Post-Close Auditor (Check 6 — AGENTS.md)
// Runs every 10 min: scan [SLIDES] tickets marked done in last 90min,
// verify <slug>/chNN-slides*.pptx exists in canonical paths.
// If missing, create recovery issue + comment.

import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(__dirname, "..");

const PAPERCLIP_HOST = process.env.PAPERCLIP_HOST ?? "http://localhost:3100";
const PAPERCLIP_API_KEY = process.env.PAPERCLIP_API_KEY ?? "";
const COMPANY_ID = process.env.KOENIG_COMPANY_ID ?? "2a77f89b-33f0-4133-a20c-77ddaac5e744";
const MAX_TICKETS_PER_RUN = 20;
const COOLDOWN_HOURS = 4;

function authHeaders() {
  return PAPERCLIP_API_KEY ? { authorization: `Bearer ${PAPERCLIP_API_KEY}` } : {};
}

async function apiGet(pathname) {
  const res = await fetch(`${PAPERCLIP_HOST}${pathname}`, { headers: authHeaders() });
  if (!res.ok) throw new Error(`paperclip ${pathname} → ${res.status}`);
  return res.json();
}

async function apiPost(pathname, body) {
  const res = await fetch(`${PAPERCLIP_HOST}${pathname}`, {
    method: "POST",
    headers: { "content-type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`paperclip POST ${pathname} → ${res.status} ${text}`);
  }
  return res.json();
}

async function apiPatch(pathname, body) {
  const res = await fetch(`${PAPERCLIP_HOST}${pathname}`, {
    method: "PATCH",
    headers: { "content-type": "application/json", ...authHeaders() },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const text = await res.text().catch(() => "");
    throw new Error(`paperclip PATCH ${pathname} → ${res.status} ${text}`);
  }
  return res.json();
}

// Extract slug from [SLIDES] title: "[SLIDES] cursor-composer-2 ch01 ..." → "cursor-composer-2"
function extractSlugFromTitle(title) {
  const match = title.match(/^\[SLIDES\]\s+(.+?)\s+ch\d+/i);
  if (!match) return null;
  // Normalize: lowercase, replace spaces with hyphens, remove special chars
  return match[1]
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .trim()
    .replace(/\s+/g, "-");
}

// Extract chapter number: "[SLIDES] slug ch42-title" → "ch42", "chapter 5" → "ch5"
function extractChapterFromTitle(title) {
  // Match "ch" followed by digits (case-insensitive)
  const chMatch = title.match(/(ch\d+)/i);
  if (chMatch) return chMatch[1].toLowerCase();

  // Also match "chapter" followed by a number and convert to "ch" format
  const chapterMatch = title.match(/chapter\s+(\d+)/i);
  if (chapterMatch) return `ch${chapterMatch[1]}`;

  return null;
}

// Search for artifact file in canonical paths
async function findArtifactFile(slug, chNum) {
  const searchPaths = [
    `/paperclip/tmp/koea1551/koenig-ai-org/vault/courses/${slug}`,
  ];

  // Add dynamic koenig workspaces
  try {
    const workspacesDir = "/paperclip/instances/default/workspaces";
    const entries = await fs.readdir(workspacesDir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.isDirectory() && entry.name.startsWith("koenig-ai-org-")) {
        searchPaths.push(path.join(workspacesDir, entry.name, "vault", "courses", slug));
      }
      if (entry.isDirectory() && entry.name.startsWith("learnovaBeast-")) {
        searchPaths.push(path.join(workspacesDir, entry.name, "learnova-academy", "public", "courses", slug));
      }
    }
  } catch (err) {
    console.warn(`Failed to scan workspaces: ${err.message}`);
  }

  // Search each path
  for (const searchPath of searchPaths) {
    try {
      const files = await fs.readdir(searchPath);
      const pattern = new RegExp(`^${chNum}-slides.*\\.pptx$`);
      for (const file of files) {
        if (pattern.test(file)) {
          const fullPath = path.join(searchPath, file);
          const stat = await fs.stat(fullPath);
          if (stat.size > 1000) {
            return { found: true, path: fullPath, size: stat.size };
          }
        }
      }
    } catch (err) {
      // Path doesn't exist or not readable — continue to next
    }
  }

  return { found: false, paths: searchPaths };
}

// Query for candidates: newly done or recovery candidates
async function fetchCandidates() {
  const now = new Date();
  const ninetyMinutesAgo = new Date(now.getTime() - 90 * 60 * 1000);

  // Query: newly done slides that haven't been audited yet
  const newlyDoneUrl =
    `/api/companies/${COMPANY_ID}/issues?` +
    `status=done&` +
    `limit=${MAX_TICKETS_PER_RUN}&` +
    `q=[SLIDES]`;

  let candidates = [];
  try {
    const data = await apiGet(newlyDoneUrl);
    const issues = Array.isArray(data) ? data : (data.issues ?? data.items ?? []);
    for (const issue of issues) {
      if (!issue.title?.match(/^\[SLIDES\]/i)) continue;
      if (issue.updatedAt && new Date(issue.updatedAt) < ninetyMinutesAgo) continue;
      // Check if already audited
      const audited = issue.metadata?.fake_done_audited === "true" || issue.metadata?.fake_done_audited === true;
      if (!audited) {
        candidates.push({ ...issue, auditType: "newly-done" });
      }
    }
  } catch (err) {
    console.warn(`Failed to fetch newly-done candidates: ${err.message}`);
  }

  // Query: recovery candidates (blocked/reverted that were previously audited)
  for (const status of ["blocked", "reverted"]) {
    try {
      const url = `/api/companies/${COMPANY_ID}/issues?status=${status}&limit=${MAX_TICKETS_PER_RUN}&q=[SLIDES]`;
      const data = await apiGet(url);
      const issues = Array.isArray(data) ? data : (data.issues ?? data.items ?? []);
      for (const issue of issues) {
        if (!issue.title?.match(/^\[SLIDES\]/i)) continue;
        const audited = issue.metadata?.fake_done_audited === "true" || issue.metadata?.fake_done_audited === true;
        if (audited) {
          candidates.push({ ...issue, auditType: "recovery-candidate" });
        }
      }
    } catch (err) {
      console.warn(`Failed to fetch ${status} candidates: ${err.message}`);
    }
  }

  return candidates.slice(0, MAX_TICKETS_PER_RUN);
}

// Check if recovery issue already exists
async function findExistingRecoveryIssue(sourceIssueId, slug, chNum) {
  try {
    const q = encodeURIComponent(`[Recovery] ${sourceIssueId.substring(0, 8)} ${slug} ${chNum}`);
    const url = `/api/companies/${COMPANY_ID}/issues?q=${q}&limit=5`;
    const data = await apiGet(url);
    const issues = Array.isArray(data) ? data : (data.issues ?? data.items ?? []);
    return issues.find(
      (issue) =>
        issue.title?.includes(`[Recovery]`) &&
        !issue.hiddenAt &&
        ["todo", "in_progress", "in_review", "blocked"].includes(issue.status),
    );
  } catch (err) {
    console.warn(`Failed to search for existing recovery issue: ${err.message}`);
    return null;
  }
}

// Create or update recovery issue
async function ensureRecoveryIssue(sourceIssue, slug, chNum, artifactInfo) {
  const sourceId = sourceIssue.identifier || sourceIssue.id;
  const existing = await findExistingRecoveryIssue(sourceId, slug, chNum);
  const now = new Date().toISOString();

  const searchedPaths = artifactInfo.paths || [];
  const searchPathsMarkdown = searchedPaths.map((p) => `  - ${p}`).join("\n");

  const recoveryBody =
    `Source issue:\n` +
    `- id: ${sourceId}\n` +
    `- status: ${sourceIssue.status}\n\n` +
    `Artifact evidence:\n` +
    `- discovered: ${artifactInfo.found ? artifactInfo.path : "none"}\n` +
    `- size: ${artifactInfo.found ? artifactInfo.size : "N/A"} bytes\n` +
    `- searched_paths:\n${searchPathsMarkdown}\n\n` +
    `Requested owner action:\n` +
    (artifactInfo.found
      ? `- Slide file located at: \`${artifactInfo.path}\`\n` +
        `- Consider restoring source status to done and setting metadata.auditor_recovered_at=<NOW>\n\n` +
        `Routine: slide-fake-done-auditor\n` +
        `Updated: ${now}`
      : `- Artifact missing; verify producer output\n` +
        `- Only keep ticket done when \`${chNum}-slides*.pptx\` exists (>1000 bytes)\n` +
        `- If still missing, keep blocked and request producer rerun\n\n` +
        `Routine: slide-fake-done-auditor\n` +
        `Scanned: ${now}`);

  if (existing) {
    // Update with new evidence
    await apiPost(`/api/issues/${existing.id}/comments`, {
      body: recoveryBody,
    });
    return { created: false, updated: true, id: existing.id };
  } else {
    // Create new recovery issue
    const created = await apiPost(`/api/companies/${COMPANY_ID}/issues`, {
      title: `[Recovery] Verify slide artifact for ${sourceId} ${slug} ${chNum}`,
      description: recoveryBody,
      priority: "medium",
      status: "blocked",
      parentIssueId: sourceIssue.id,
    });
    return { created: true, updated: false, id: created.id };
  }
}

// Mark issue as audited
async function markAudited(issueId) {
  try {
    await apiPatch(`/api/issues/${issueId}`, {
      metadata: {
        fake_done_audited: "true",
        auditor_last_checked_at: new Date().toISOString(),
      },
    });
  } catch (err) {
    console.warn(`Failed to mark ${issueId} as audited: ${err.message}`);
  }
}

// Handle recovered artifact
async function handleRecoveredArtifact(sourceIssue) {
  try {
    // If artifact is found and issue is blocked/reverted, flip back to done
    if (sourceIssue.status === "blocked" || sourceIssue.status === "reverted") {
      await apiPatch(`/api/issues/${sourceIssue.id}`, {
        status: "done",
        metadata: {
          fake_done_audited: "false",
          auditor_recovered_at: new Date().toISOString(),
        },
      });
      return true;
    }
  } catch (err) {
    console.warn(`Failed to recover ${sourceIssue.id}: ${err.message}`);
  }
  return false;
}

async function runAudit() {
  const runStartTime = new Date();
  const stats = {
    scanned: 0,
    found: 0,
    missing: 0,
    recovered: 0,
    recovery_issues_created: 0,
    recovery_issues_updated: 0,
    errors: 0,
  };

  console.log(`\n=== Slide Fake-Done Auditor [${runStartTime.toISOString()}] ===`);

  try {
    const candidates = await fetchCandidates();
    console.log(`Found ${candidates.length} candidates to audit`);
    stats.scanned = candidates.length;

    for (const issue of candidates) {
      try {
        const slug = extractSlugFromTitle(issue.title);
        const chNum = extractChapterFromTitle(issue.title);

        if (!slug || !chNum) {
          console.log(`SKIP ${issue.identifier}: Could not parse slug/chapter from title`);
          continue;
        }

        console.log(`Auditing ${issue.identifier}: ${slug}/${chNum}`);
        const artifactInfo = await findArtifactFile(slug, chNum);

        if (artifactInfo.found) {
          console.log(`  ✓ FOUND: ${artifactInfo.path}`);
          stats.found += 1;

          // If this is a recovery candidate and artifact is found, flip back to done
          if (issue.auditType === "recovery-candidate") {
            const recovered = await handleRecoveredArtifact(issue);
            if (recovered) {
              console.log(`  → Recovered: status flipped to done`);
              stats.recovered += 1;
            }
          }
        } else {
          console.log(`  ✗ MISSING: ${chNum}-slides*.pptx not found`);
          stats.missing += 1;

          // Create recovery issue
          const recovery = await ensureRecoveryIssue(issue, slug, chNum, artifactInfo);
          if (recovery.created) {
            stats.recovery_issues_created += 1;
            console.log(`  → Created recovery issue: ${recovery.id}`);
          } else if (recovery.updated) {
            stats.recovery_issues_updated += 1;
            console.log(`  → Updated recovery issue: ${recovery.id}`);
          }
        }

        // Mark as audited
        await markAudited(issue.id);
      } catch (err) {
        console.error(`ERROR processing ${issue.identifier}: ${err.message}`);
        stats.errors += 1;
      }
    }
  } catch (err) {
    console.error(`FATAL: ${err.message}`);
    stats.errors += 1;
  }

  const runTime = ((new Date() - runStartTime) / 1000).toFixed(1);
  console.log(
    `\n✓ Audit complete (${runTime}s): ` +
    `scanned=${stats.scanned} found=${stats.found} missing=${stats.missing} ` +
    `recovered=${stats.recovered} created=${stats.recovery_issues_created} ` +
    `updated=${stats.recovery_issues_updated} errors=${stats.errors}`,
  );

  return stats;
}

async function main() {
  try {
    await runAudit();
  } catch (err) {
    console.error("Auditor crashed:", err);
    process.exit(1);
  }
}

main();
