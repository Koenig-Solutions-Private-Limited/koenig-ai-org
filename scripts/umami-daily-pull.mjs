#!/usr/bin/env node
/**
 * Pull Umami daily metrics for academy.kspl.tech and write vault/marketing/analytics/<YYYY-MM-DD>.md
 *
 * Env (runtime secrets only — never commit):
 *   UMAMI_BASE_URL       Umami origin, e.g. https://analytics.kspl.tech
 *   UMAMI_API_KEY        API key from Umami dashboard (Settings → API keys)
 *   UMAMI_WEBSITE_ID     Website UUID from Umami
 *   KOENIG_AI_ORG_ROOT   repo root (default: parent of scripts/)
 */
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = process.env.KOENIG_AI_ORG_ROOT ?? path.resolve(__dirname, "..");

const CONVERSION_EVENTS = [
  "scroll_depth",
  "dwell_time",
  "catalog_open",
  "course_start",
  "tutor_open",
  "tutor_message_sent",
  "digest_subscribe_success",
  "course_progress_update",
  "share_click",
];

function yesterdayUtc() {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

function dayBoundsUtc(dateStr) {
  const start = new Date(`${dateStr}T00:00:00.000Z`);
  const end = new Date(`${dateStr}T23:59:59.999Z`);
  return { startAt: start.getTime(), endAt: end.getTime() };
}

function normalizeBaseUrl(raw) {
  return String(raw ?? "").trim().replace(/\/+$/, "");
}

async function umamiFetch(baseUrl, apiKey, pathname, searchParams = {}) {
  const url = new URL(`${baseUrl}/api${pathname}`);
  for (const [key, value] of Object.entries(searchParams)) {
    if (value !== undefined && value !== null) url.searchParams.set(key, String(value));
  }
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${apiKey}`,
      Accept: "application/json",
    },
  });
  const json = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = json.message ?? json.error ?? JSON.stringify(json).slice(0, 300);
    throw new Error(`Umami ${pathname} failed (${res.status}): ${msg}`);
  }
  return json;
}

function formatPercent(numerator, denominator) {
  if (!denominator) return "—";
  return `${((numerator / denominator) * 100).toFixed(1)}%`;
}

function buildMarkdown({
  reportDate,
  websiteId,
  stats,
  topPages,
  topReferrers,
  eventCounts,
}) {
  const pageviews = stats?.pageviews?.value ?? stats?.pageviews ?? 0;
  const visitors = stats?.visitors?.value ?? stats?.visitors ?? 0;
  const visits = stats?.visits?.value ?? stats?.visits ?? 0;
  const bounces = stats?.bounces?.value ?? stats?.bounces ?? 0;
  const totalTime = stats?.totaltime?.value ?? stats?.totaltime ?? 0;
  const avgSessionSec =
    visits > 0 ? Math.round(Number(totalTime) / Number(visits)) : 0;
  const bounceRate = visits > 0 ? formatPercent(Number(bounces), Number(visits)) : "—";

  const lines = [
    "---",
    "type: umami-daily",
    `date: ${reportDate}`,
    "property: academy.kspl.tech",
    "tags:",
    "  - marketing/analytics",
    "  - seo",
    "---",
    "",
    `# Umami daily — ${reportDate}`,
    "",
    `> Automated pull via \`scripts/umami-daily-pull.mjs\`. Website \`${websiteId}\`.`,
    "",
    "## Summary",
    "",
    "| Metric | Value |",
    "| --- | --- |",
    `| Pageviews | ${pageviews} |`,
    `| Visitors | ${visitors} |`,
    `| Visits | ${visits} |`,
    `| Bounce rate | ${bounceRate} |`,
    `| Avg session (sec) | ${avgSessionSec} |`,
    "",
    "## Top pages",
    "",
    "| Path | Views |",
    "| --- | ---: |",
  ];

  if (!topPages.length) {
    lines.push("| _no rows_ | |");
  } else {
    for (const row of topPages) {
      const label = (row.x ?? row.url ?? row.name ?? "").replace(/\|/g, "\\|");
      const count = row.y ?? row.value ?? row.count ?? 0;
      lines.push(`| ${label} | ${count} |`);
    }
  }

  lines.push("", "## Top referrers", "", "| Referrer | Visits |", "| --- | ---: |");
  if (!topReferrers.length) {
    lines.push("| _no rows_ | |");
  } else {
    for (const row of topReferrers) {
      const label = (row.x ?? row.referrer ?? row.name ?? "(direct)").replace(/\|/g, "\\|");
      const count = row.y ?? row.value ?? row.count ?? 0;
      lines.push(`| ${label} | ${count} |`);
    }
  }

  lines.push("", "## Engagement & conversion events", "", "| Event | Count |", "| --- | ---: |");
  for (const name of CONVERSION_EVENTS) {
    lines.push(`| ${name} | ${eventCounts[name] ?? 0} |`);
  }
  lines.push("");
  return `${lines.join("\n")}\n`;
}

export async function pullUmamiDaily(options = {}) {
  const baseUrl = normalizeBaseUrl(options.baseUrl ?? process.env.UMAMI_BASE_URL);
  const apiKey = String(options.apiKey ?? process.env.UMAMI_API_KEY ?? "").trim();
  const websiteId = String(options.websiteId ?? process.env.UMAMI_WEBSITE_ID ?? "").trim();
  if (!baseUrl) throw new Error("UMAMI_BASE_URL is required");
  if (!apiKey) throw new Error("UMAMI_API_KEY is required");
  if (!websiteId) throw new Error("UMAMI_WEBSITE_ID is required");

  const reportDate = options.reportDate ?? yesterdayUtc();
  const { startAt, endAt } = dayBoundsUtc(reportDate);
  const params = { startAt, endAt };

  const stats = await umamiFetch(baseUrl, apiKey, `/websites/${websiteId}/stats`, params);
  const topPages = await umamiFetch(baseUrl, apiKey, `/websites/${websiteId}/metrics`, {
    ...params,
    type: "url",
    limit: 25,
  });
  const topReferrers = await umamiFetch(baseUrl, apiKey, `/websites/${websiteId}/metrics`, {
    ...params,
    type: "referrer",
    limit: 25,
  });

  const eventCounts = {};
  for (const eventName of CONVERSION_EVENTS) {
    try {
      const eventStats = await umamiFetch(
        baseUrl,
        apiKey,
        `/websites/${websiteId}/stats`,
        { ...params, event: eventName },
      );
      eventCounts[eventName] =
        eventStats?.pageviews?.value ??
        eventStats?.pageviews ??
        eventStats?.events?.value ??
        eventStats?.events ??
        0;
    } catch {
      eventCounts[eventName] = 0;
    }
  }

  const pageRows = Array.isArray(topPages) ? topPages : topPages?.data ?? [];
  const referrerRows = Array.isArray(topReferrers) ? topReferrers : topReferrers?.data ?? [];

  const markdown = buildMarkdown({
    reportDate,
    websiteId,
    stats,
    topPages: pageRows,
    topReferrers: referrerRows,
    eventCounts,
  });

  const outDir = options.outDir ?? path.join(repoRoot, "vault", "marketing", "analytics");
  const outFile = path.join(outDir, `${reportDate}.md`);
  await fs.mkdir(outDir, { recursive: true });
  await fs.writeFile(outFile, markdown, "utf8");
  return {
    reportDate,
    outFile,
    pageviews: stats?.pageviews?.value ?? stats?.pageviews ?? 0,
  };
}

async function main() {
  try {
    const result = await pullUmamiDaily();
    console.log(`Wrote ${result.outFile} (${result.pageviews} pageviews)`);
  } catch (err) {
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
