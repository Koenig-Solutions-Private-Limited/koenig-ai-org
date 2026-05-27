const HOURLY_PREFIX = 'hourly-worker-dispatch';

function toIso(v) {
  if (!v) return 'n/a';
  const d = v instanceof Date ? v : new Date(v);
  if (Number.isNaN(+d)) return String(v);
  return d.toISOString();
}

export function formatStaleBlockedDigest(rows) {
  if (!rows?.length) return 'none';
  return rows
    .map((r) => {
      const movement = toIso(r.last_movement_at ?? r.lastMovementAt ?? r.updated_at ?? r.updatedAt);
      const updated = toIso(r.updated_at ?? r.updatedAt);
      const assignee = r.assignee_agent_id ?? r.assigneeAgentId ?? 'unassigned';
      return `- ${r.identifier}: ${r.title} (assignee=${assignee}; updated=${updated}; last_movement=${movement}; id=${r.id})`;
    })
    .join('\n');
}

export function classifyFixtureRowsForTests(rows, { now = new Date(), staleDays = 7 } = {}) {
  const nowMs = +(now instanceof Date ? now : new Date(now));
  const staleMs = staleDays * 24 * 60 * 60 * 1000;
  const byFingerprint = new Map();
  for (const r of rows) {
    const key = `${r.company_id}::${r.origin_kind}::${r.origin_id ?? ''}::${r.origin_fingerprint ?? ''}`;
    const list = byFingerprint.get(key) ?? [];
    list.push(r);
    byFingerprint.set(key, list);
  }
  for (const list of byFingerprint.values()) list.sort((a, b) => +new Date(a.created_at) - +new Date(b.created_at));

  const nudge = [];
  const cleanup = [];
  for (const r of rows) {
    if (r.status !== 'blocked' || r.hidden_at) continue;
    const lastMovement = +new Date(r.last_movement_at ?? r.updated_at);
    if (!Number.isFinite(lastMovement) || nowMs - lastMovement < staleMs) continue;
    const key = `${r.company_id}::${r.origin_kind}::${r.origin_id ?? ''}::${r.origin_fingerprint ?? ''}`;
    const newer = (byFingerprint.get(key) ?? []).filter((x) => +new Date(x.created_at) > +new Date(r.updated_at));
    const isHourlyRoutine =
      r.origin_kind === 'routine_execution' &&
      String(r.title || '').toLowerCase().startsWith(HOURLY_PREFIX) &&
      r.origin_id &&
      r.origin_fingerprint;
    if (
      isHourlyRoutine &&
      newer.some((x) => ['todo', 'in_progress', 'in_review', 'done'].includes(x.status)) &&
      !r.checkout_run_id &&
      !r.execution_run_id
    ) {
      const sup = newer.findLast((x) => ['todo', 'in_progress', 'in_review', 'done'].includes(x.status));
      cleanup.push({ ...r, superseding_identifier: sup?.identifier, superseding_status: sup?.status });
      continue;
    }
    nudge.push(r);
  }
  return { nudge, cleanup };
}

export async function listStaleBlockedNudgeCandidates(
  sql,
  { companyId, now = new Date(), staleDays = 7, limit = 20, issueId = null } = {},
) {
  const nowIso = (now instanceof Date ? now : new Date(now)).toISOString();
  return sql`
with base as (
  select
    i.id,
    i.identifier,
    i.title,
    i.assignee_agent_id,
    i.updated_at,
    i.origin_kind,
    i.origin_id,
    i.origin_fingerprint,
    greatest(
      i.updated_at,
      coalesce((
        select max(c.created_at)
        from issue_comments c
        where c.issue_id = i.id
      ), to_timestamp(0))
    ) as last_movement_at
  from issues i
  where i.company_id = ${companyId}
    and i.status = 'blocked'
    and i.hidden_at is null
    and (${issueId}::uuid is null or i.id = ${issueId}::uuid)
), stale as (
  select *
  from base
  where last_movement_at < (${nowIso}::timestamptz - (${staleDays}::int * interval '1 day'))
), superseded_hourly as (
  select s.id
  from stale s
  where s.origin_kind = 'routine_execution'
    and coalesce(s.origin_id, '') <> ''
    and coalesce(s.origin_fingerprint, '') <> ''
    and lower(s.title) like ${HOURLY_PREFIX + '%'}
    and exists (
      select 1
      from issues newer
      where newer.company_id = ${companyId}
        and newer.id <> s.id
        and newer.origin_kind = 'routine_execution'
        and newer.origin_id = s.origin_id
        and newer.origin_fingerprint = s.origin_fingerprint
        and newer.created_at > s.updated_at
    )
)
select
  s.id,
  s.identifier,
  s.title,
  s.assignee_agent_id,
  s.updated_at,
  s.last_movement_at
from stale s
where not exists (select 1 from superseded_hourly h where h.id = s.id)
order by s.last_movement_at asc
limit ${limit};`;
}

export async function listSupersededHourlyDispatchCleanupCandidates(
  sql,
  { companyId, now = new Date(), staleDays = 7, limit = 50, issueId = null } = {},
) {
  const nowIso = (now instanceof Date ? now : new Date(now)).toISOString();
  return sql`
with base as (
  select
    i.id,
    i.identifier,
    i.title,
    i.status,
    i.updated_at,
    i.origin_kind,
    i.origin_id,
    i.origin_fingerprint,
    i.checkout_run_id,
    i.execution_run_id,
    greatest(
      i.updated_at,
      coalesce((
        select max(c.created_at)
        from issue_comments c
        where c.issue_id = i.id
      ), to_timestamp(0))
    ) as last_movement_at
  from issues i
  where i.company_id = ${companyId}
    and i.status = 'blocked'
    and i.hidden_at is null
    and i.origin_kind = 'routine_execution'
    and coalesce(i.origin_id, '') <> ''
    and coalesce(i.origin_fingerprint, '') <> ''
    and lower(i.title) like ${HOURLY_PREFIX + '%'}
    and (${issueId}::uuid is null or i.id = ${issueId}::uuid)
), stale as (
  select *
  from base
  where last_movement_at < (${nowIso}::timestamptz - (${staleDays}::int * interval '1 day'))
), superseded as (
  select
    s.*,
    newer.identifier as superseding_identifier,
    newer.id as superseding_id,
    newer.status as superseding_status,
    newer.created_at as superseding_created_at,
    row_number() over (partition by s.id order by newer.created_at desc) as rn
  from stale s
  join issues newer
    on newer.company_id = ${companyId}
   and newer.id <> s.id
   and newer.origin_kind = 'routine_execution'
   and newer.origin_id = s.origin_id
   and newer.origin_fingerprint = s.origin_fingerprint
   and newer.created_at > s.updated_at
   and newer.status in ('todo', 'in_progress', 'in_review', 'done')
)
select
  sp.id,
  sp.identifier,
  sp.title,
  sp.updated_at,
  sp.last_movement_at,
  sp.superseding_id,
  sp.superseding_identifier,
  sp.superseding_status
from superseded sp
where sp.rn = 1
  and sp.checkout_run_id is null
  and sp.execution_run_id is null
order by sp.last_movement_at asc
limit ${limit};`;
}
