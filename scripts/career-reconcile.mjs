#!/usr/bin/env node
/**
 * Career Compass ⇄ Paperclip reconciler (course-gen v3).
 *
 * Domain split (2026-06-12): the Career Compass vertical now serves from
 * https://academy.koenig-solutions.com (repo
 * Koenig-Solutions-Private-Limited/koenig-career-academy). The organic academy
 * stays at academy.kspl.tech (learnovaBeast). Course-build issues dispatched
 * from here carry course_track: career and publish to the new domain; the
 * readiness-poller URL below points there.
 *
 * R2 (career/requests/*.json on the academy `lms` bucket) is the only shared
 * state plane between Vercel and the local org. Every 30 min (Chief
 * Learning routine) this script, idempotently:
 *
 *   1. toc_status "proposed" older than 24h        → PUT toc_status: auto-approved
 *   2. toc_status approved|auto-approved AND no
 *      paperclip_parent_issue                       → POST parent issue to the
 *      Course Architect with the TOC inlined, then PUT the record back with
 *      paperclip_parent_issue (dedupe marker). If the PUT-back fails after
 *      issue creation, prints the exact manual fix instead of risking a dup.
 *
 * Creds: CAREER_R2_* from .env.koenig. Paperclip: PAPERCLIP_API_URL/BOARD
 * token from env or docker exec fallback. Exit 0 ok, 2 creds missing.
 */

import { readFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

// NOTE (domain split 2026-06-12): the Career Compass serving app is now
// koenig-career-academy (academy.koenig-solutions.com). This createRequire path
// still resolves @aws-sdk/client-s3 via the learnova-academy package.json — that
// repo still exists and is used only as a node_modules resolution anchor here,
// not as the serving app.
const require = createRequire(
  "/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json",
);
const { S3Client, ListObjectsV2Command, GetObjectCommand, PutObjectCommand } =
  require("@aws-sdk/client-s3");

// Load-check guard: exits 0 immediately after S3 import succeeds, before any
// credential reads or mutations. Used by CI/scheduler health checks.
if (process.env.CAREER_RECONCILE_LOAD_CHECK === "1") {
  console.log("career-reconcile: S3 import OK — load check passed");
  process.exit(0);
}

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const COMPANY_ID = "2a77f89b-33f0-4133-a20c-77ddaac5e744";
const COURSE_ARCHITECT_ID = "650d2c01-dff7-4b69-8082-cda31f37c3bd";
const PAPERCLIP_URL = process.env.PAPERCLIP_API_URL || "http://localhost:3100";
const AUTO_APPROVE_HOURS = 24;

function loadEnv() {
  const env = {};
  for (const line of readFileSync(join(ROOT, ".env.koenig"), "utf8").split("\n")) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) env[m[1]] = m[2].replace(/^["']|["']$/g, "").trim();
  }
  return env;
}

function paperclipToken() {
  if (process.env.PAPERCLIP_BOARD_TOKEN) return process.env.PAPERCLIP_BOARD_TOKEN;
  try {
    return execSync("docker exec paperclip-server sh -c 'echo $PAPERCLIP_BOARD_TOKEN'", {
      encoding: "utf8",
    }).trim();
  } catch {
    return "";
  }
}

const env = loadEnv();
for (const k of ["CAREER_R2_ACCOUNT_ID", "CAREER_R2_ACCESS_KEY_ID", "CAREER_R2_SECRET_ACCESS_KEY", "CAREER_R2_BUCKET"]) {
  if (!env[k] || env[k] === "TODO") {
    console.error(`reconcile: ${k} not configured in .env.koenig`);
    process.exit(2);
  }
}
const token = paperclipToken();
if (!token) {
  console.error("reconcile: no Paperclip board token reachable");
  process.exit(2);
}

const s3 = new S3Client({
  region: "auto",
  endpoint: `https://${env.CAREER_R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: env.CAREER_R2_ACCESS_KEY_ID,
    secretAccessKey: env.CAREER_R2_SECRET_ACCESS_KEY,
  },
});
const Bucket = env.CAREER_R2_BUCKET;

async function getJson(Key) {
  const r = await s3.send(new GetObjectCommand({ Bucket, Key }));
  return JSON.parse(await r.Body.transformToString());
}
async function putJson(Key, obj) {
  await s3.send(
    new PutObjectCommand({ Bucket, Key, Body: JSON.stringify(obj), ContentType: "application/json" }),
  );
}

async function paperclip(path, method, body) {
  const res = await fetch(`${PAPERCLIP_URL}${path}`, {
    method,
    headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`paperclip ${method} ${path} -> ${res.status}: ${await res.text()}`);
  return res.json();
}

function issueDescription(rec) {
  const toc = rec.toc;
  const chapters = toc.chapters
    .map(
      (c) =>
        `${c.n}. **${c.title}** (~${c.est_minutes} min)\n   ${c.what_youll_learn}\n   Objectives: ${c.objectives.join("; ")}`,
    )
    .join("\n");
  const prefs = rec.artifact_prefs ?? { video: true, challenge_quiz: true, flashcards: true };
  return [
    `## Course request — Career Compass v3 (candidate-approved TOC)`,
    ``,
    `**Course title:** ${toc.course_title}`,
    `**Slug (HARD CONTRACT):** \`${rec.suggested_slug}\``,
    `**Gap:** ${rec.gap_label} · **Audience:** ${rec.target_audience}`,
    `**TOC status:** ${rec.toc_status} (${rec.toc_decided_at ?? "auto"}) · version ${toc.version}`,
    `**Artifact prefs:** video=${prefs.video} challenge_quiz=${prefs.challenge_quiz} flashcards=${prefs.flashcards}`,
    toc.koenig_recommendation ? `**Koenig closing recommendation:** ${toc.koenig_recommendation.title} (${toc.koenig_recommendation.url})` : ``,
    ``,
    `### Approved table of contents`,
    chapters,
    ``,
    `### Your job (Course Architect)`,
    `Validate this TOC, expand it into vault/courses/${rec.suggested_slug}/toc.json + outline.md (set course_track: career) per your AGENTS.md, and dispatch the research/write/review/assets child tree. The readiness poller watches https://academy.koenig-solutions.com/learn/${rec.suggested_slug} — slug is non-negotiable.`,
  ].join("\n");
}

const now = Date.now();
const listed = await s3.send(new ListObjectsV2Command({ Bucket, Prefix: "career/requests/" }));
let acted = 0;
for (const obj of listed.Contents ?? []) {
  if (!obj.Key.endsWith(".json")) continue;
  let rec;
  try {
    rec = await getJson(obj.Key);
  } catch (e) {
    console.error(`skip ${obj.Key}: unreadable (${e.message})`);
    continue;
  }

  // 1. auto-approve stale proposals
  if (rec.toc_status === "proposed" && rec.toc?.proposed_at) {
    const ageH = (now - new Date(rec.toc.proposed_at).getTime()) / 3_600_000;
    if (ageH > AUTO_APPROVE_HOURS) {
      rec.toc_status = "auto-approved";
      rec.toc_decided_at = new Date().toISOString();
      await putJson(obj.Key, rec);
      console.log(`auto-approved: ${rec.gap_key} (proposed ${ageH.toFixed(1)}h ago)`);
      acted++;
    }
  }

  // 2. dispatch approved TOCs that have no parent issue yet
  if (
    (rec.toc_status === "approved" || rec.toc_status === "auto-approved") &&
    rec.toc &&
    !rec.paperclip_parent_issue
  ) {
    const issue = await paperclip(`/api/companies/${COMPANY_ID}/issues`, "POST", {
      title: `Course build: ${rec.toc.course_title} [career-v3]`,
      description: issueDescription(rec),
      status: "todo",
      assigneeAgentId: COURSE_ARCHITECT_ID,
    });
    const ident = issue.identifier ?? issue.id ?? "created";
    rec.paperclip_parent_issue = ident;
    try {
      await putJson(obj.Key, rec);
      console.log(`dispatched: ${rec.gap_key} -> ${ident}`);
    } catch (e) {
      console.error(
        `CRITICAL: issue ${ident} created but R2 marker write FAILED for ${obj.Key}. ` +
          `Manually set "paperclip_parent_issue": "${ident}" on that record to prevent a duplicate. (${e.message})`,
      );
      process.exit(4);
    }
    acted++;
  }
}
console.log(`reconcile complete: ${(listed.Contents ?? []).length} records scanned, ${acted} actions`);
