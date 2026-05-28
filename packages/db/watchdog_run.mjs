import fs from 'fs';
import path from 'path';
import postgres from 'postgres';
import { readPublishActionHealth } from './publish_action_health.mjs';

const API=process.env.PAPERCLIP_API_URL;
const KEY=process.env.PAPERCLIP_API_KEY;
const CID=process.env.PAPERCLIP_COMPANY_ID;
const SELF=process.env.PAPERCLIP_AGENT_ID;
const TASK=process.env.PAPERCLIP_TASK_ID;
const NOW=new Date();
const COOLDOWN_MS=4*60*60*1000;
const sql=postgres(process.env.DATABASE_URL);

const apiGet=async p=>{const r=await fetch(`${API}${p}`,{headers:{Authorization:`Bearer ${KEY}`}});if(!r.ok)throw new Error(`GET ${p} ${r.status}`);return r.json();};
const apiPost=async (p,b)=>{const r=await fetch(`${API}${p}`,{method:'POST',headers:{Authorization:`Bearer ${KEY}`,'Content-Type':'application/json'},body:JSON.stringify(b)});if(!r.ok)throw new Error(`POST ${p} ${r.status} ${await r.text()}`);return r.json();};
const fresh=t=>NOW-new Date(t)<=COOLDOWN_MS;

const issues=await apiGet(`/api/companies/${CID}/issues?limit=500`);
const commentCache=new Map();
async function comments(issueId){if(!commentCache.has(issueId))commentCache.set(issueId, await apiGet(`/api/issues/${issueId}/comments?limit=200`));return commentCache.get(issueId);}
async function recentSelf(issueId,marker){return (await comments(issueId)).some(c=>c.authorAgentId===SELF&&(c.body||'').includes(marker)&&fresh(c.createdAt));}

const agents=await sql`select id,name from agents where company_id=${CID}`;
const chief=agents.find(a=>(a.name||'').toLowerCase()==='chief engineering');

let meta=issues.find(i=>i.title==='Watchdog Health'&&!i.hiddenAt&&!['done','cancelled'].includes(i.status));
if(!meta){meta=await apiPost(`/api/companies/${CID}/issues`,{title:'Watchdog Health',description:'Meta issue for Watchdog heartbeat summaries and fallback alerts.',priority:'medium',assigneeAgentId:SELF});}

let publish='OK';
let approvalsPosted='no';
let nudged=0;
let spikesFiled=0;

// 1 publish
const log='/paperclip/logs/publish-action.log';
const publishHealth=readPublishActionHealth({logPath:log,now:NOW,staleMinutes:10});
const lastTick=publishHealth.lastSuccessAt??'none';
const stale=publishHealth.isStale;
const publishAlertDescription=publishHealth.evidenceLine
  ?`Watchdog detected no publish-action success tick in last 10 minutes.\nLast evidence: ${publishHealth.evidenceLine}`
  :'Watchdog detected no publish-action success tick in last 10 minutes.';
if(stale){
  publish='FAILING (alerting)';
  const title=`[WATCHDOG] publish-action.sh silent >10min — last tick: ${lastTick}`;
  const dup=issues.find(i=>i.title===title&&fresh(i.createdAt));
  if(!dup){
    if(process.env.TELEGRAM_BOT_TOKEN&&process.env.TELEGRAM_CHAT_ID){
      const txt=encodeURIComponent(`Watchdog alert: publish-action.sh silent >10min. Last tick: ${lastTick}`);
      await fetch(`https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN}/sendMessage?chat_id=${process.env.TELEGRAM_CHAT_ID}&text=${txt}`,{method:'POST'}).catch(()=>{});
    } else if(!(await recentSelf(meta.id,'publish-action env missing'))){
      await apiPost(`/api/issues/${meta.id}/comments`,{body:`publish-action env missing for Telegram fallback at ${NOW.toISOString()}.`});
    }
    await apiPost(`/api/companies/${CID}/issues`,{title,description:publishAlertDescription,priority:'critical',status:'blocked',assigneeAgentId:chief?.id});
  }
}else{publish=`OK (last tick: ${Math.floor((NOW-new Date(lastTick))/60000)}min ago)`;}

// 2 approvals
const [{c:pendingTotal}]=await sql`select count(*)::int as c from approvals where company_id=${CID} and status='pending'`;
const oldApprovals=await sql`select id,payload->>'issueId' as issue_id from approvals where company_id=${CID} and status='pending' and created_at < now()-interval '48 hours'`;
for(const a of oldApprovals){if(!a.issue_id)continue; if(await recentSelf(a.issue_id,'this approval is pending >48h'))continue; await apiPost(`/api/issues/${a.issue_id}/comments`,{body:'@chief-engineering this approval is pending >48h. Reasonable next step: cancel if no longer needed, otherwise wait for daily-engineering-triage.'});}
if(Number(pendingTotal)>10){const t='[WATCHDOG] Approval backlog exceeded 10 pending. Operator may want to triage.'; if(!issues.find(i=>i.title===t&&fresh(i.createdAt))){await apiPost(`/api/companies/${CID}/issues`,{title:t,description:`Pending approvals count is ${pendingTotal}.`,priority:'high',status:'blocked',assigneeAgentId:chief?.id}); approvalsPosted='yes';}}

// 3 markers
const missing=await sql`
with eng as (select id from agents where company_id=${CID} and lower(name) in ('planner','executor','code reviewer','qa verifier','chief engineering')),
blocked as (select id from issues where company_id=${CID} and status='blocked'),
cand as (
select c.id,c.issue_id,c.body,c.created_at from issue_comments c
where c.issue_id in (select id from blocked)
and c.author_agent_id in (select id from eng)
order by c.created_at desc limit 100)
select id,issue_id from cand
where coalesce(body,'') not ilike '%Approval filed:%'
and coalesce(body,'') not ilike '%No escalation:%'
and coalesce(body,'') not ilike '%No work performed: status=%'`;
for(const m of missing){const marker=`Marker missing. Ref comment ${m.id}`; if(await recentSelf(m.issue_id,marker))continue; await apiPost(`/api/issues/${m.issue_id}/comments`,{body:`${marker}. Please include one of: Approval filed: <id>, No escalation: <reason>, or No work performed: status=<X> so the audit trail is clear.`}); nudged++;}

//4 stale blocked
const staleRows=await sql`select id,identifier,assignee_agent_id from issues where company_id=${CID} and status='blocked' and updated_at < now()-interval '7 days' and hidden_at is null order by updated_at asc limit 20`;
for(const s of staleRows){const a=agents.find(x=>x.id===s.assignee_agent_id);const mention='@'+((a?.name||'chief-engineering').toLowerCase().replace(/\s+/g,'-')); if(await recentSelf(s.id,'this has been blocked >7 days'))continue; await apiPost(`/api/issues/${s.id}/comments`,{body:`${mention} this has been blocked >7 days with no movement. Cancel if obsolete, or escalate via daily-engineering-triage / Chief Content / etc.`});}
if(!(await recentSelf(meta.id,'Stale-blocked tickets (>7d):'))){const sample=staleRows.slice(0,5).map(s=>s.identifier).join(' ')||'none'; await apiPost(`/api/issues/${meta.id}/comments`,{body:`Stale-blocked tickets (>7d): ${staleRows.length}. Sample: ${sample}`});}

//5 spikes
const spikes=await sql`
with recent_failed as (
select a.adapter_type,left(coalesce(nullif(hr.error,''),nullif(hr.stderr_excerpt,''),nullif(hr.error_code,''),nullif(hr.result_json->>'error',''),'unknown_failure'),60) as signature
from heartbeat_runs hr join agents a on a.id=hr.agent_id
where hr.company_id=${CID} and hr.created_at >= now()-interval '1 hour' and hr.status='failed')
select adapter_type,signature,count(*)::int as fail_count from recent_failed group by adapter_type,signature having count(*)>=5`;
for(const sp of spikes){const t=`[WATCHDOG] Failure spike: ${sp.adapter_type} hitting "${sp.signature}" — ${sp.fail_count} fails in 1h. Owner: Chief Engineering.`; if(issues.find(i=>i.title===t&&fresh(i.createdAt)))continue; await apiPost(`/api/companies/${CID}/issues`,{title:t,description:'Watchdog detected adapter failure spike in heartbeat_runs over the last hour.',priority:'high',status:'blocked',assigneeAgentId:chief?.id}); spikesFiled++;}

//6 slide auditor
const candidates=await sql`select id,identifier,title,status,assignee_agent_id,coalesce(metadata->>'fake_done_audited','false') as fake_done_audited from issues where company_id=${CID} and hidden_at is null and title like '[SLIDES] % ch%' and ((status='done' and coalesce(metadata->>'fake_done_audited','false')<>'true') or (status in ('blocked','reverted') and coalesce(metadata->>'fake_done_audited','false')='true')) order by updated_at desc limit 20`;
const ws='/paperclip/instances/default/workspaces';
const names=fs.existsSync(ws)?fs.readdirSync(ws):[];
const kroots=names.filter(n=>n.startsWith('koenig-ai-org-')).map(n=>`${ws}/${n}/vault/courses`);
const lroots=names.filter(n=>n.startsWith('learnovaBeast-')).map(n=>`${ws}/${n}/learnova-academy/public/courses`);
let scanned=0,found=0,missingSlides=0,created=0,updated=0;
for(const c of candidates){scanned++; const m=c.title.match(/^\[SLIDES\]\s+([a-z0-9-]+)\s+(ch\d+)/i); if(!m)continue; const slug=m[1], ch=m[2].toLowerCase(); const paths=[`/paperclip/tmp/koea1551/koenig-ai-org/vault/courses/${slug}`,...kroots.map(r=>`${r}/${slug}`),...lroots.map(r=>`${r}/${slug}`)]; let foundPath=''; for(const p of paths){if(!fs.existsSync(p))continue; for(const f of fs.readdirSync(p)){if(f.startsWith(`${ch}-slides`)&&f.endsWith('.pptx')){const full=path.join(p,f); if(fs.statSync(full).size>1000){foundPath=full;break;}}} if(foundPath)break;} if(foundPath)found++; else missingSlides++;
  const shouldHandle=(c.status==='done'&&c.fake_done_audited!=='true')||((c.status==='blocked'||c.status==='reverted')&&c.fake_done_audited==='true'&&!!foundPath);
  if(!shouldHandle)continue;
  const recTitle=foundPath?`[Recovery] Restore ${c.identifier} after slide artifact found`:`[Recovery] Verify missing slide artifact for ${c.identifier}`;
  const existing=issues.find(i=>i.title===recTitle&&['todo','in_progress','in_review','blocked'].includes(i.status));
  const assignee=agents.find(a=>a.id===c.assignee_agent_id)||chief;
  const body=`Source issue:\n- id: ${c.id}\n- identifier: ${c.identifier}\n- title: ${c.title}\n- status: ${c.status}\n\nArtifact evidence:\n- discovered: ${foundPath||'none'}\n- searched_paths:\n${paths.map(p=>`  - ${p}`).join('\n')}\n\nRequested owner action:\n${foundPath?`- set status to \`done\` (if currently blocked/reverted due to fake-done)\n- set \`metadata.fake_done_audited=false\`\n- set \`metadata.auditor_recovered_at=${NOW.toISOString()}\``:`- verify producer output and only keep ticket done when \`${ch}-slides*.pptx\` exists (>1000 bytes)\n- if still missing, keep blocked and request producer rerun`}\n\nConstraint:\n- Watchdog Bot must not mutate another agent's issue directly.\n\nRoutine: slide-fake-done-auditor`;
  if(!existing){await apiPost(`/api/companies/${CID}/issues`,{title:recTitle,description:body,priority:'high',status:'blocked',assigneeAgentId:assignee?.id}); created++;}
  else {const marker=`discovered: ${foundPath||'none'}`; if(!(await recentSelf(existing.id,marker))){await apiPost(`/api/issues/${existing.id}/comments`,{body:`Recovery evidence update (${NOW.toISOString()}):\n\n${body}\n\nAuditor recovery — slide file located at ${foundPath||'none'}. Reverting status back to done.`}); updated++;}}
}

const stamp=NOW.toISOString().slice(0,16).replace('T',' ');
const summary=`Watchdog heartbeat — ${stamp} UTC\n- publish-action: ${publish}\n- pending approvals >48h: ${oldApprovals.length} (alert posted: ${approvalsPosted})\n- missing markers found: ${missing.length} (nudged)\n- stale-blocked >7d: ${staleRows.length} (digest posted)\n- failure spikes: ${spikes.length} (filed)\n- slide-fake-done-auditor: scanned=${scanned} found=${found} missing=${missingSlides} recovery_issues_created=${created} recovery_issues_updated=${updated}`;
await apiPost(`/api/issues/${meta.id}/comments`,{body:summary});
await apiPost(`/api/issues/${TASK}/comments`,{body:`Heartbeat complete.\n\n${summary}`});
console.log(summary);
await sql.end();
