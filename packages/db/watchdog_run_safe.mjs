import fs from "fs";
import path from "path";
import postgres from "postgres";

const API = process.env.PAPERCLIP_API_URL;
const KEY = process.env.PAPERCLIP_API_KEY;
const CID = process.env.PAPERCLIP_COMPANY_ID;
const SELF = process.env.PAPERCLIP_AGENT_ID;
const TASK = process.env.PAPERCLIP_TASK_ID;
const NOW = new Date();
const CD = 4 * 60 * 60 * 1000;
const sql = postgres(process.env.DATABASE_URL);

const issues = await (
  await fetch(`${API}/api/companies/${CID}/issues?limit=800`, {
    headers: { Authorization: `Bearer ${KEY}` },
  })
).json();
const fresh = (t) => NOW - new Date(t) <= CD;
const post = async (p, b) => {
  const r = await fetch(`${API}${p}`, {
    method: "POST",
    headers: { Authorization: `Bearer ${KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify(b),
  });
  if (!r.ok) throw new Error(`${p} ${r.status} ${await r.text()}`);
  return r.json();
};
const safePost = async (p, b) => {
  try {
    return await post(p, b);
  } catch {
    return null;
  }
};

const agents = await sql`select id,name from agents where company_id=${CID}`;
const chief = agents.find((a) => (a.name || "").toLowerCase() === "chief engineering");

const ensureIssue = async (title, description, priority = "high") => {
  const dup = issues.find((i) => i.title === title && fresh(i.createdAt));
  if (dup) return { created: false, id: dup.id };
  const created = await post(`/api/companies/${CID}/issues`, {
    title,
    description,
    priority,
    status: "blocked",
    assigneeAgentId: chief?.id,
  });
  return { created: true, id: created.id };
};

const hasRecentMarkerComment = async (issueId, marker) => {
  const rows = await sql`
    select id
    from issue_comments
    where issue_id = ${issueId}
      and author_agent_id = ${SELF}
      and created_at >= now() - interval '4 hours'
      and coalesce(body, '') ilike ${`%${marker}%`}
    limit 1`;
  return rows.length > 0;
};

const tryDirectComment = async (issueId, body, marker) => {
  if (!issueId) return false;
  if (await hasRecentMarkerComment(issueId, marker)) return true;
  const commentBody = `${marker}\n\n${body}`;
  const result = await safePost(`/api/issues/${issueId}/comments`, { body: commentBody });
  return Boolean(result);
};

let meta = issues.find(
  (i) => i.title === "Watchdog Health" && !i.hiddenAt && !["done", "cancelled"].includes(i.status),
);
if (!meta) {
  meta = await post(`/api/companies/${CID}/issues`, {
    title: "Watchdog Health",
    description: "Meta issue for Watchdog heartbeat summaries and fallback alerts.",
    priority: "medium",
    assigneeAgentId: SELF,
  });
}

let publishStatus = "OK";
let approvalsAlert = "no";
let spikesFiled = 0;

// 1 publish-action
let lastTick = "none";
let publishStale = true;
const log = "/paperclip/logs/publish-action.log";
if (fs.existsSync(log)) {
  const line =
    fs
      .readFileSync(log, "utf8")
      .split("\n")
      .slice(-200)
      .filter((l) => /TICK|published/.test(l))
      .at(-1) || "";
  const m = line.match(/\[(.*?)\]/) || line.match(/(20\d\d-\d\d-\d\d[ T]\d\d:\d\d:\d\d(?:Z| UTC)?)/);
  if (m) {
    const d = new Date(m[1].replace(" UTC", "Z").replace(" ", "T"));
    if (!Number.isNaN(+d)) {
      lastTick = d.toISOString();
      publishStale = NOW - d > 10 * 60 * 1000;
    }
  }
}
if (publishStale) {
  publishStatus = "FAILING (alerting)";
  if (process.env.TELEGRAM_BOT_TOKEN && process.env.TELEGRAM_CHAT_ID) {
    const txt = encodeURIComponent(
      `Watchdog alert: publish-action.sh silent >10min. Last tick: ${lastTick}`,
    );
    await fetch(
      `https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${process.env.TELEGRAM_CHAT_ID}&text=${txt}`,
      { method: "POST" },
    ).catch(() => {});
  }
  await ensureIssue(
    `[WATCHDOG] publish-action.sh silent >10min — last tick: ${lastTick}`,
    "Watchdog detected no publish-action success tick in last 10 minutes.",
    "critical",
  );
} else {
  publishStatus = `OK (last tick: ${Math.floor((NOW - new Date(lastTick)) / 60000)}min ago)`;
}

// 2 approvals
const [{ pending_total }] =
  await sql`select count(*)::int as pending_total from approvals where company_id=${CID} and status='pending'`;
const oldApprovals = await sql`
  select id,payload->>'issueId' as issue_id
  from approvals
  where company_id=${CID}
    and status='pending'
    and created_at < now()-interval '48 hours'
  order by created_at asc`;
for (const a of oldApprovals) {
  const marker = "[WATCHDOG:approval>48h]";
  const body = `Approval ${a.id} has been pending >48h. Guidance: cancel if obsolete, else triage in daily-engineering-triage.`;
  const commented = await tryDirectComment(a.issue_id, body, marker);
  if (!commented) {
    await ensureIssue(
      `[WATCHDOG] Approval >48h pending (${a.id})`,
      `Approval ${a.id} has been pending >48h. Related issueId: ${a.issue_id || "unknown"}. Guidance: cancel if obsolete, else triage in daily-engineering-triage.`,
      "medium",
    );
  }
}
if (Number(pending_total) > 10) {
  const r = await ensureIssue(
    "[WATCHDOG] Approval backlog exceeded 10 pending. Operator may want to triage.",
    `Pending approvals total: ${pending_total}.`,
    "high",
  );
  approvalsAlert = r.created ? "yes" : "no";
}

// 3 marker compliance
const missingMarkers = await sql`
with eng as (
  select id
  from agents
  where company_id=${CID}
    and lower(name) in ('planner','executor','code reviewer','qa verifier','chief engineering')
),
blocked as (select id from issues where company_id=${CID} and status='blocked'),
cand as (
  select c.id,c.issue_id,c.body,c.created_at
  from issue_comments c
  where c.issue_id in (select id from blocked)
    and c.author_agent_id in (select id from eng)
  order by c.created_at desc
  limit 100
)
select id,issue_id
from cand
where coalesce(body,'') not ilike '%Approval filed:%'
  and coalesce(body,'') not ilike '%No escalation:%'
  and coalesce(body,'') not ilike '%No work performed: status=%'`;
let markerDirectComments = 0;
let markerFallbackNeeded = false;
for (const row of missingMarkers.slice(0, 20)) {
  const marker = "[WATCHDOG:marker-compliance]";
  const body = `Escalation marker compliance gap detected on comment ${row.id}. Add an approved stand-down/escalation marker before closing the blocked cycle.`;
  const commented = await tryDirectComment(row.issue_id, body, marker);
  if (commented) markerDirectComments++;
  else markerFallbackNeeded = true;
}
if (missingMarkers.length && markerFallbackNeeded) {
  const sample = missingMarkers
    .slice(0, 20)
    .map((r) => `- comment ${r.id} on issue ${r.issue_id}`)
    .join("\n");
  await ensureIssue(
    `[WATCHDOG] Escalation marker compliance gaps — ${missingMarkers.length} comments`,
    `Marker-missing comments found in blocked issues (last 100 engineering comments):\n${sample}`,
    "medium",
  );
}

// 4 stale blocked
const staleRows = await sql`
  select id,identifier,title,updated_at
  from issues
  where company_id=${CID}
    and status='blocked'
    and updated_at < now()-interval '7 days'
    and hidden_at is null
  order by updated_at asc
  limit 20`;
let staleDirectComments = 0;
let staleFallbackNeeded = false;
for (const s of staleRows) {
  const marker = "[WATCHDOG:stale-blocked]";
  const body = `${s.identifier}: ${s.title} has been blocked >7 days (updated ${s.updated_at.toISOString()}). Please triage or unblock.`;
  const commented = await tryDirectComment(s.id, body, marker);
  if (commented) staleDirectComments++;
  else staleFallbackNeeded = true;
}
if (staleRows.length && staleFallbackNeeded) {
  const sample = staleRows
    .map((s) => `- ${s.identifier}: ${s.title} (updated ${s.updated_at.toISOString()})`)
    .join("\n");
  await ensureIssue(
    `[WATCHDOG] Stale blocked tickets >7d (${staleRows.length})`,
    `These blocked tickets are stale >7 days and need triage:\n${sample}`,
    "high",
  );
}

// 5 failure spikes
const spikes = await sql`
with recent_failed as (
  select a.adapter_type,left(coalesce(nullif(hr.error,''),nullif(hr.stderr_excerpt,''),nullif(hr.error_code,''),nullif(hr.result_json->>'error',''),'unknown_failure'),60) as signature
  from heartbeat_runs hr join agents a on a.id=hr.agent_id
  where hr.company_id=${CID} and hr.created_at>=now()-interval '1 hour' and hr.status='failed'
)
select adapter_type,signature,count(*)::int as fail_count
from recent_failed
group by adapter_type,signature
having count(*)>=5
order by fail_count desc,adapter_type,signature`;
for (const s of spikes) {
  const r = await ensureIssue(
    `[WATCHDOG] Failure spike: ${s.adapter_type} hitting "${s.signature}" — ${s.fail_count} fails in 1h. Owner: Chief Engineering.`,
    "Watchdog detected adapter failure spike in heartbeat_runs over the last hour.",
    "high",
  );
  if (r.created) spikesFiled++;
}

// 6 slide auditor
const candidates = await sql`
  select id,identifier,title,status,assignee_agent_id,coalesce(metadata->>'fake_done_audited','false') as fake_done_audited
  from issues
  where company_id=${CID}
    and hidden_at is null
    and title like '[SLIDES] % ch%'
    and (
      (status='done' and coalesce(metadata->>'fake_done_audited','false')<>'true')
      or (status in ('blocked','reverted') and coalesce(metadata->>'fake_done_audited','false')='true')
    )
  order by updated_at desc
  limit 20`;
const ws = "/paperclip/instances/default/workspaces";
const wn = fs.existsSync(ws) ? fs.readdirSync(ws) : [];
const kRoots = wn.filter((n) => n.startsWith("koenig-ai-org-")).map((n) => `${ws}/${n}/vault/courses`);
const lRoots = wn.filter((n) => n.startsWith("learnovaBeast-")).map((n) => `${ws}/${n}/learnova-academy/public/courses`);
let scanned = 0;
let found = 0;
let missing = 0;
let recoveryCreated = 0;
let recoveryUpdated = 0;
for (const c of candidates) {
  scanned++;
  const m = c.title.match(/^\[SLIDES\]\s+([a-z0-9-]+)\s+(ch\d+)/i);
  if (!m) continue;
  const slug = m[1];
  const ch = m[2].toLowerCase();
  const paths = [
    `/paperclip/tmp/koea1551/koenig-ai-org/vault/courses/${slug}`,
    ...kRoots.map((r) => `${r}/${slug}`),
    ...lRoots.map((r) => `${r}/${slug}`),
  ];
  let fp = "";
  for (const p of paths) {
    if (!fs.existsSync(p)) continue;
    for (const f of fs.readdirSync(p)) {
      if (f.startsWith(`${ch}-slides`) && f.endsWith(".pptx")) {
        const full = path.join(p, f);
        if (fs.statSync(full).size > 1000) {
          fp = full;
          break;
        }
      }
    }
    if (fp) break;
  }
  if (fp) found++;
  else missing++;
  const needs =
    (c.status === "done" && c.fake_done_audited !== "true") ||
    ((c.status === "blocked" || c.status === "reverted") && c.fake_done_audited === "true" && !!fp);
  if (!needs) continue;
  const title = fp
    ? `[Recovery] Restore ${c.identifier} after slide artifact found`
    : `[Recovery] Verify missing slide artifact for ${c.identifier}`;
  const body = `Source issue:\n- id: ${c.id}\n- identifier: ${c.identifier}\n- title: ${c.title}\n- status: ${c.status}\n\nArtifact evidence:\n- discovered: ${fp || "none"}\n- searched_paths:\n${paths.map((p) => `  - ${p}`).join("\n")}\n\nRequested owner action:\n${fp ? `- set status to \`done\` (if currently blocked/reverted due to fake-done)\n- set \`metadata.fake_done_audited=false\`\n- set \`metadata.auditor_recovered_at=${NOW.toISOString()}\`` : `- verify producer output and only keep ticket done when \`${ch}-slides*.pptx\` exists (>1000 bytes)\n- if still missing, keep blocked and request producer rerun`}\n\nConstraint:\n- Watchdog Bot must not mutate another agent's issue directly.\n\nRoutine: slide-fake-done-auditor`;
  const existing = issues.find(
    (i) => i.title === title && ["todo", "in_progress", "in_review", "blocked"].includes(i.status),
  );
  if (!existing) {
    await post(`/api/companies/${CID}/issues`, {
      title,
      description: body,
      priority: "high",
      status: "blocked",
      assigneeAgentId: (agents.find((a) => a.id === c.assignee_agent_id) || chief)?.id,
    });
    recoveryCreated++;
  } else {
    const marker = "[WATCHDOG:slide-recovery]";
    const updated = await tryDirectComment(
      existing.id,
      `Recovery evidence update (${NOW.toISOString()}):\n\n${body}\n\nAuditor recovery — slide file located at ${fp || "none"}. Reverting status back to done.`,
      marker,
    );
    if (updated) recoveryUpdated++;
  }
}

const stamp = NOW.toISOString().slice(0, 16).replace("T", " ");
const summary = `Watchdog heartbeat — ${stamp} UTC
- publish-action: ${publishStatus}
- pending approvals >48h: ${oldApprovals.length} (alert posted: ${approvalsAlert})
- missing markers found: ${missingMarkers.length} (direct comments: ${markerDirectComments}, fallback: ${markerFallbackNeeded ? "yes" : "no"})
- stale-blocked >7d: ${staleRows.length} (direct comments: ${staleDirectComments}, fallback: ${staleFallbackNeeded ? "yes" : "no"})
- failure spikes: ${spikes.length} (filed: ${spikesFiled})
- slide-fake-done-auditor: scanned=${scanned} found=${found} missing=${missing} recovery_issues_created=${recoveryCreated} recovery_issues_updated=${recoveryUpdated}`;

const healthMarker = "[WATCHDOG:health-summary]";
const metaComment = meta
  ? await (async () => {
      if (await hasRecentMarkerComment(meta.id, healthMarker)) return { skipped: true };
      return safePost(`/api/issues/${meta.id}/comments`, { body: `${healthMarker}\n\n${summary}` });
    })()
  : null;
const taskComment = TASK
  ? await safePost(`/api/issues/${TASK}/comments`, {
      body: `Heartbeat complete.\n\n${summary}${metaComment ? "" : "\n\nNote: could not write summary to Watchdog Health due to issue-assignment permissions; summary logged here."}`,
    })
  : null;
if (!taskComment && !metaComment) {
  console.warn("watchdog_run_safe: could not post summary comment to task or meta issue");
}

console.log(summary);
await sql.end();
