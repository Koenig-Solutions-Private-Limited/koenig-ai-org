#!/usr/bin/env node
/**
 * Academy admin-dashboard exporter.
 *
 * Production Vercel cannot reach the local Paperclip control plane, so this
 * script (run every few minutes via launchd/routine, or ad hoc) snapshots
 * the whole content org into one JSON and pushes it to R2 at
 * `admin/status.json` on the academy bucket. The /admin dashboard reads it.
 *
 * Snapshot contents:
 *  - courses: per vault course — chapters written, sidecars, per-asset
 *    presence, outline status/publish_state, live URL guess
 *  - pipelines: per active course-build parent issue (career-v3) — child
 *    ticket counts by kind+status
 *  - agents: name, status, last heartbeat, monthly budget/spend
 *  - batches: /tmp/*batch*.out tails (NotebookLM operator batches)
 */

import { readFileSync, writeFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { execSync } from "node:child_process";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(
  "/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/package.json",
);
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const VAULT = join(ROOT, "vault", "courses");

function env() {
  return Object.fromEntries(
    readFileSync(join(ROOT, ".env.koenig"), "utf8")
      .split("\n")
      .map((l) => l.match(/^([A-Z0-9_]+)=(.*)$/))
      .filter(Boolean)
      .map((m) => [m[1], m[2]]),
  );
}

function psql(sql) {
  try {
    const out = execSync(
      `docker exec paperclip-db psql -U paperclip -d paperclip -t -A -F'\t' -c ${JSON.stringify(sql)}`,
      { encoding: "utf8", timeout: 20000 },
    );
    return out
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((l) => l.split("\t"));
  } catch {
    return [];
  }
}

// ── courses from the vault ─────────────────────────────────────────────
const ASSET_KEYS = [
  "audio_url", "slide_deck_url", "video_url", "quiz_url", "quiz_challenge_url",
  "flashcards_url", "study_guide_url", "infographic_url", "mind_map_url",
];
const courses = [];
for (const slug of readdirSync(VAULT)) {
  const dir = join(VAULT, slug);
  try {
    if (!statSync(dir).isDirectory()) continue;
  } catch {
    continue;
  }
  const outlinePath = join(dir, "outline.md");
  if (!existsSync(outlinePath)) continue;
  const outline = readFileSync(outlinePath, "utf8");
  const fm = (key) => outline.match(new RegExp(`^${key}:\\s*"?([^"\\n]+)"?`, "m"))?.[1]?.trim();
  const chapterFiles = readdirSync(dir).filter((f) => /^\d+-.*\.md$/.test(f));
  const chapters = chapterFiles.map((f) => {
    const prefix = f.replace(/\.md$/, "");
    const metaPath = join(dir, prefix, "chapter-meta.json");
    let assets = {};
    if (existsSync(metaPath)) {
      try {
        assets = JSON.parse(readFileSync(metaPath, "utf8")).assets ?? {};
      } catch {
        assets = {};
      }
    }
    const status = readFileSync(join(dir, f), "utf8").match(/^status:\s*(\S+)/m)?.[1] ?? "?";
    return {
      file: prefix,
      status,
      assets: Object.fromEntries(ASSET_KEYS.map((k) => [k.replace("_url", ""), Boolean(assets[k])])),
      asset_count: ASSET_KEYS.filter((k) => assets[k]).length,
    };
  });
  courses.push({
    slug,
    title: fm("title") ?? slug,
    status: fm("status") ?? "?",
    publish_state: fm("publish_state") ?? null,
    live: ["g4-approved", "dispatching", "published"].includes(fm("publish_state") ?? ""),
    course_track: fm("course_track") ?? null,
    chapter_count_planned: Number(fm("chapter_count")) || chapterFiles.length,
    chapters_written: chapterFiles.length,
    sidecars: chapters.filter((c) => c.asset_count > 0).length,
    chapters,
  });
}

// ── active career-v3 pipelines from Paperclip ──────────────────────────
const pipelineRows = psql(
  "select p.identifier, p.title, coalesce(substring(i.title from '\\[([A-Z]+)\\]'), 'OTHER'), i.status, count(*) from issues i join issues p on p.id = i.parent_id where (p.title like '%[career-v3]%' or p.title like 'Course build:%' or p.title like 'Course request:%') and p.created_at > now() - interval '14 days' group by 1,2,3,4 order by 1",
);
const pipelines = {};
for (const [ident, title, kind, status, count] of pipelineRows) {
  pipelines[ident] ??= { identifier: ident, title, kinds: {} };
  pipelines[ident].kinds[kind] ??= {};
  pipelines[ident].kinds[kind][status] = Number(count);
}

// ── agents ─────────────────────────────────────────────────────────────
const agentRows = psql(
  "select a.name, a.status, a.budget_monthly_cents, coalesce((select sum(c.cost_cents) from cost_events c where c.agent_id = a.id and c.occurred_at > date_trunc('month', now())), 0), coalesce(to_char((select max(h.created_at) from heartbeat_runs h where h.agent_id = a.id), 'YYYY-MM-DD HH24:MI'), '') from agents a where a.company_id = '2a77f89b-33f0-4133-a20c-77ddaac5e744' order by a.name",
);
const agents = agentRows.map(([name, status, budget, spent, lastRun]) => ({
  name, status,
  budget_cents: Number(budget) || 0,
  spent_cents: Number(spent) || 0,
  last_run: lastRun || null,
}));

// ── operator NotebookLM batches ────────────────────────────────────────
const batches = [];
try {
  for (const f of readdirSync("/tmp").filter((f) => /batch.*\.out$/.test(f))) {
    const p = `/tmp/${f}`;
    const tail = execSync(`tail -3 ${JSON.stringify(p)}`, { encoding: "utf8" }).trim();
    batches.push({ file: f, done: tail.includes("BATCH DONE"), tail: tail.split("\n").pop() });
  }
} catch {
  // /tmp scan is best-effort
}

const snapshot = {
  generated_at: new Date().toISOString(),
  courses: courses.sort((a, b) => b.chapters_written - a.chapters_written),
  pipelines: Object.values(pipelines),
  agents,
  batches,
};

const e = env();
const s3 = new S3Client({
  region: "auto",
  endpoint: `https://${e.CAREER_R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  credentials: { accessKeyId: e.CAREER_R2_ACCESS_KEY_ID, secretAccessKey: e.CAREER_R2_SECRET_ACCESS_KEY },
});
await s3.send(
  new PutObjectCommand({
    Bucket: e.CAREER_R2_BUCKET,
    Key: "admin/status.json",
    Body: JSON.stringify(snapshot),
    ContentType: "application/json",
  }),
);
console.log(
  `exported: ${courses.length} courses, ${Object.keys(pipelines).length} pipelines, ${agents.length} agents, ${batches.length} batches`,
);
