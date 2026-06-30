#!/usr/bin/env node
// press-publish-ping.mjs — notify search engines when a press release publishes.
//
// Submits URLs to IndexNow (Bing + Yandex consume it directly), which is the
// reliable autonomous fast-index signal for the owned newsroom. The owned
// /press pages + IndexNow are the autonomous SEO value; external wires are
// handled separately (see vault/_brand/PRESS-PLAYBOOK.md).
//
// Usage:
//   node scripts/press-publish-ping.mjs <slug> [<slug> ...]
//   node scripts/press-publish-ping.mjs --all      # ping the /press index only
//
// The IndexNow key file must be served at:
//   https://academy.koenig-solutions.com/<KEY>.txt
// (committed in the career app repo under public/<KEY>.txt)

const HOST = "academy.koenig-solutions.com";
const KEY = process.env.INDEXNOW_KEY || "b226b1a8e96b63b70ff5af2399569d20";
const KEY_LOCATION = `https://${HOST}/${KEY}.txt`;
const BASE = `https://${HOST}`;

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("usage: node scripts/press-publish-ping.mjs <slug> [<slug> ...] | --all");
  process.exit(1);
}

const urlList = [`${BASE}/press`];
for (const a of args) {
  if (a === "--all") continue;
  urlList.push(`${BASE}/press/${a}`);
}

async function pingIndexNow() {
  const body = { host: HOST, key: KEY, keyLocation: KEY_LOCATION, urlList };
  const res = await fetch("https://api.indexnow.org/indexnow", {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=utf-8" },
    body: JSON.stringify(body),
  });
  // IndexNow returns 200 (accepted) or 202 (accepted, pending). Both are success.
  console.log(`IndexNow: HTTP ${res.status} for ${urlList.length} URL(s)`);
  if (res.status !== 200 && res.status !== 202) {
    const txt = await res.text().catch(() => "");
    console.error(`  warn: ${txt.slice(0, 200)}`);
  }
}

pingIndexNow().catch((e) => {
  console.error("ping failed:", e.message);
  process.exit(1);
});
