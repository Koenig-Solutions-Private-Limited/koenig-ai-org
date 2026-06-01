#!/usr/bin/env node
/**
 * Pull GA4 daily metrics for academy.kspl.tech and write vault/marketing/ga4/<YYYY-MM-DD>.md
 *
 * Env (runtime secrets only — never commit):
 *   GA4_PROPERTY_ID          numeric GA4 property ID
 *   GSC_CREDENTIALS_PATH     OAuth client JSON (default: /paperclip/.secrets/gsc-client.json)
 *   GSC_TOKEN_PATH           OAuth token JSON (default: /paperclip/.secrets/gsc-token.json)
 *   GOOGLE_APPLICATION_CREDENTIALS  optional service-account JSON fallback
 *   KOENIG_AI_ORG_ROOT       repo root (default: parent of scripts/)
 */
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = process.env.KOENIG_AI_ORG_ROOT ?? path.resolve(__dirname, "..");
const GA4_SCOPE = "https://www.googleapis.com/auth/analytics.readonly";

function yesterdayUtc() {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

function resolvePropertyId(raw) {
  const trimmed = String(raw ?? "").trim();
  if (!trimmed) return null;
  return trimmed.replace(/^properties\//, "");
}

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, "utf8");
  return JSON.parse(raw);
}

async function loadOAuthClient(credentialsPath) {
  const data = await readJson(credentialsPath);
  const block = data.installed ?? data.web ?? data;
  return {
    client_id: block.client_id,
    client_secret: block.client_secret,
    token_uri: block.token_uri ?? "https://oauth2.googleapis.com/token",
  };
}

async function refreshAccessToken(client, tokenData) {
  const params = new URLSearchParams({
    client_id: client.client_id,
    client_secret: client.client_secret,
    refresh_token: tokenData.refresh_token,
    grant_type: "refresh_token",
  });
  const res = await fetch(client.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`OAuth refresh failed (${res.status}): ${body.slice(0, 200)}`);
  }
  const json = await res.json();
  return {
    ...tokenData,
    access_token: json.access_token,
    expires_at: Math.floor(Date.now() / 1000) + (json.expires_in ?? 3600),
  };
}

async function getAccessToken() {
  const credentialsPath =
    process.env.GSC_CREDENTIALS_PATH?.trim() ?? "/paperclip/.secrets/gsc-client.json";
  const tokenPath = process.env.GSC_TOKEN_PATH?.trim() ?? "/paperclip/.secrets/gsc-token.json";

  const client = await loadOAuthClient(credentialsPath);
  let tokenData = await readJson(tokenPath);
  const now = Math.floor(Date.now() / 1000);
  if (!tokenData.access_token || now >= (tokenData.expires_at ?? 0) - 60) {
    if (!tokenData.refresh_token) {
      throw new Error("OAuth token expired and no refresh_token present");
    }
    tokenData = await refreshAccessToken(client, tokenData);
  }
  return tokenData.access_token;
}

async function runReport(accessToken, propertyId, body) {
  const url = `https://analyticsdata.googleapis.com/v1beta/properties/${propertyId}:runReport`;
  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) {
    const msg = json.error?.message ?? JSON.stringify(json).slice(0, 300);
    throw new Error(`GA4 runReport failed (${res.status}): ${msg}`);
  }
  return json;
}

function metricValue(row, index) {
  return row?.metricValues?.[index]?.value ?? "0";
}

function formatPercent(raw) {
  const n = Number(raw);
  if (Number.isNaN(n)) return raw;
  return `${(n * 100).toFixed(1)}%`;
}

function buildMarkdown({ reportDate, propertyId, summary, topPages }) {
  const pageViews = metricValue(summary.rows?.[0], 0);
  const bounceRate = formatPercent(metricValue(summary.rows?.[0], 1));
  const sessions = metricValue(summary.rows?.[0], 2);

  const lines = [
    "---",
    "type: ga4-daily",
    `date: ${reportDate}`,
    "property: academy.kspl.tech",
    "tags:",
    "  - marketing/ga4",
    "  - seo",
    "---",
    "",
    `# GA4 daily — ${reportDate}`,
    "",
    `> Automated pull via \`scripts/ga4-daily-pull.mjs\`. Property ID \`${propertyId}\` (redacted in shared logs).`,
    "",
    "## Summary",
    "",
    "| Metric | Value |",
    "| --- | --- |",
    `| Screen page views | ${pageViews} |`,
    `| Bounce rate | ${bounceRate} |`,
    `| Sessions | ${sessions} |`,
    "",
    "## Top pages",
    "",
    "| Page path | Page title | Views | Bounce rate |",
    "| --- | --- | ---: | ---: |",
  ];

  const rows = topPages.rows ?? [];
  if (rows.length === 0) {
    lines.push("| _no rows_ | | | |");
  } else {
    for (const row of rows) {
      const pagePath = row.dimensionValues?.[0]?.value ?? "";
      const pageTitle = (row.dimensionValues?.[1]?.value ?? "").replace(/\|/g, "\\|");
      const views = metricValue(row, 0);
      const bounce = formatPercent(metricValue(row, 1));
      lines.push(`| ${pagePath} | ${pageTitle} | ${views} | ${bounce} |`);
    }
  }

  lines.push("");
  return `${lines.join("\n")}\n`;
}

export async function pullGa4Daily(options = {}) {
  const propertyId = resolvePropertyId(options.propertyId ?? process.env.GA4_PROPERTY_ID);
  if (!propertyId) {
    throw new Error("GA4_PROPERTY_ID is required");
  }

  const reportDate = options.reportDate ?? yesterdayUtc();
  const accessToken = await getAccessToken();
  const dateRange = [{ startDate: reportDate, endDate: reportDate }];

  const summary = await runReport(accessToken, propertyId, {
    dateRanges: dateRange,
    metrics: [
      { name: "screenPageViews" },
      { name: "bounceRate" },
      { name: "sessions" },
    ],
  });

  const topPages = await runReport(accessToken, propertyId, {
    dateRanges: dateRange,
    dimensions: [{ name: "pagePath" }, { name: "pageTitle" }],
    metrics: [{ name: "screenPageViews" }, { name: "bounceRate" }],
    orderBys: [{ metric: { metricName: "screenPageViews" }, desc: true }],
    limit: 25,
  });

  const markdown = buildMarkdown({ reportDate, propertyId, summary, topPages });
  const outDir = options.outDir ?? path.join(repoRoot, "vault", "marketing", "ga4");
  const outFile = path.join(outDir, `${reportDate}.md`);
  await fs.mkdir(outDir, { recursive: true });
  await fs.writeFile(outFile, markdown, "utf8");
  return { reportDate, outFile, pageViews: metricValue(summary.rows?.[0], 0) };
}

async function main() {
  try {
    const result = await pullGa4Daily();
    console.log(`Wrote ${result.outFile} (${result.pageViews} page views)`);
  } catch (err) {
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
