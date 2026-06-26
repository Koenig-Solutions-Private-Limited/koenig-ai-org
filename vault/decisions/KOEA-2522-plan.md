---
ticket: KOEA-2522
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.36
base_branch: master
basebranch_verified: true
preflight: "status=in_progress assigned_to_planner=true root_ticket_sibling_check=n/a acceptance_spec=pass"
---

# Plan: Route Watchdog alerts through least-privilege ownership

## Goal
Watchdog Bot should be able to leave heartbeat summaries and alert evidence without gaining blanket permission to comment on other agents' issues. Success means the recurring Watchdog flow posts to a Watchdog-owned `Watchdog Health` issue, routes source-ticket nudges through deterministic handoff issues when the source ticket is foreign-assigned, and leaves the existing issue mutation guard intact.

## Context
- Files to read first: `server/src/routes/issues.ts:595-660`, `server/src/routes/issues.ts:3348-3456`, `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts:440-454`, `scripts/slide-fake-done-auditor.py:75-144`, `scripts/slide-fake-done-auditor.py:331-335`, `scripts/slide-fake-done-auditor.py:476-491`, `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md:14-74`, `companies/learnova-academy/agents/watchdog-bot/SOUL.md:21-36`.
- Relevant prior work: `vault/decisions/KOEA-2321-auditor-followup-plan.md` rejected broad Watchdog mutation privileges and favored owner-routed recovery issues; KOEA-2722 is the same `Watchdog Health` permission symptom; KOEA-2379 is the current closed, Chief-assigned `Watchdog Health` issue that the script may select.
- Constraints: preserve the least-privilege route guard and existing peer-mutation test; do not grant Watchdog a board token, `canCreateAgents`, or `tasks:manage_active_checkouts`; keep the change under the plan-only budget and under 5 files.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Watchdog-owned health issue plus handoff issues. Keep Paperclip core permissions unchanged, make Watchdog's heartbeat target deterministic and commentable by ensuring an active `Watchdog Health` issue assigned to Watchdog Bot, and revise Watchdog nudge behavior so foreign-assigned source tickets receive separate assigned handoff issues rather than direct comments.

**Rejected**: Add a core `comment_any_issue` or reuse `tasks:manage_active_checkouts` for Watchdog — this broadens the permission surface and conflicts with the existing least-privilege tests; use a delegated board/service token — this weakens actor attribution and bypasses the agent guard; only reassign the historical `Watchdog Health` issue — this fixes one symptom but leaves future stale-marker/source-ticket nudges failing with the same 403.

## Steps (Executor follows in order)
1. Update `scripts/slide-fake-done-auditor.py` so `get_watchdog_health_issue` becomes a deterministic `get_or_create_watchdog_health_issue`: prefer an active `Watchdog Health` issue assigned to `WATCHDOG_AGENT_ID`, ignore closed or foreign-assigned matches, and create a Watchdog-assigned health issue when no commentable target exists.
2. Keep `PaperclipApi.can_comment` as the final guard before posting heartbeat summaries, and log a clear blocked summary if creation or lookup fails instead of trying to comment on a foreign-assigned issue.
3. Update the active Watchdog Bot instructions in `/paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md` so direct comments are allowed only on unassigned or Watchdog-assigned issues; for marker-compliance, stale-ticket, and approval-age nudges on foreign-assigned issues, create or update deterministic handoff issues assigned to the source assignee or Chief Engineering.
4. Update `companies/learnova-academy/agents/watchdog-bot/SOUL.md` with the same policy: Watchdog may create alert and handoff issues, but must not comment directly on issues assigned to another agent.
5. Leave `server/src/routes/issues.ts` and `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` unchanged unless verification reveals an implementation mismatch; the intended fix is configuration/workflow plus watchdog script routing, not a Paperclip core permission change.
6. In the implementation handoff comment, identify KOEA-2722 as a symptom of this same route and do not open a separate core-permission fix for it.

## Verification (QA Verifier checks these)
- [ ] `python3 -m py_compile scripts/slide-fake-done-auditor.py` passes.
- [ ] A mocked or dry-run health lookup proves a closed or Chief-assigned `Watchdog Health` issue is ignored and an active Watchdog-assigned health issue is selected or created.
- [ ] `rg -n "foreign-assigned|handoff|Watchdog Health|can_comment" scripts/slide-fake-done-auditor.py /paperclip/instances/default/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/agents/55ec4a3a-7c32-4436-a231-e0accd51a548/instructions/AGENTS.md companies/learnova-academy/agents/watchdog-bot/SOUL.md` shows the new routing rule in both runtime instructions and repo mirror.
- [ ] Existing peer-mutation behavior remains intact: foreign-assigned source tickets are not directly commented on by Watchdog, and `server/src/__tests__/issue-agent-mutation-ownership-routes.test.ts` does not need expectation changes.

## Risk
- Handoff issues could become noisy if every heartbeat creates a fresh issue; mitigate with deterministic titles, open-issue lookup, and a cooldown/update path before creating a new handoff.

## Out of scope
- Granting Watchdog broad cross-issue comment privileges, changing the core issue mutation guard, using board-level credentials for routine Watchdog comments, resolving the historical backlog of Watchdog alerts, or changing the publish-action freshness parser covered by KOEA-2713.
