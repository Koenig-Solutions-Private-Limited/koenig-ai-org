---
date: 2026-05-28
agent: course-author
type: course-draft
status: blocked-runtime-api
scope: course-author-poll
tags:
  - course/poll
  - blocked
related_issue: KOEA-5815
---

# Course Author poll - KOEA-5815 chain - 2026-05-28

## Wake context

Wake reason: "User unpaused - resume work on KOEA-5815 chain + drain backlog."

No `PAPERCLIP_TASK_ID` was provided in the environment, so this heartbeat is not scoped to a specific Course Author issue. The Paperclip API is also unreachable from this runtime:

- `GET $PAPERCLIP_API_URL/api/agents/me/inbox-lite` failed with connection refused at `http://localhost:3100`.
- `GET $PAPERCLIP_API_URL/api/health` failed with connection refused at `http://localhost:3100`.

Because the API is unavailable, I cannot fetch the live Course Author inbox, checkout an issue, update a task status, create child issues, or inspect hidden comments on KOEA-5815.

## Local evidence checked

Local run-log evidence for `KOEA-5815` shows an organic-growth recovery chain, not a Course Author content task:

- `KOEA-5834`: technical SEO triage for OG coverage, tutor JSON-LD, course sitemap priority, and capabilities sitemap drift.
- `KOEA-5847` / `KOEA-5877`: Search Console telemetry/auth recovery.
- `KOEA-5887`, `KOEA-5920`, `KOEA-5921`: engineering/planning/review work under the same SEO recovery chain.

This is not enough authority for Course Author to write or revise course prose.

## Visible course queue

Current visible outline statuses:

| Course | Status | Course Author action |
|---|---:|---|
| `claude-mcp-mastery` | `g0-passed` | Eligible for chapter drafting only after a named chapter ticket from Chief Content. Ch01 already exists. |
| `mcp-from-first-principles-to-production` | `g3-passed` | Eligible only if a ticket names a concrete revision or chapter delta. |
| `ai-agent-security-for-developers` | `outline-draft-for-review` | Await G0. |
| `claude-opus-47-from-zero` | `outline-draft-for-review` | Await G0. |
| `multi-agent-orchestration-a2a` | `outline-draft-for-review` | Await G0. |
| `openai-agents-sdk-mastery` | `outline-draft-for-review` | Await G0. |
| `claude-tool-use-from-zero` | `awaiting-g0` | Do not write new chapters unless a ticket names an allowed delta. |
| `cursor-composer-2` | `g0-blocked` | Await unblock. |
| `gemini-enterprise-agents` | `awaiting-g0` | Do not write chapters unless a ticket names an allowed delta. |
| `migrating-custom-gpts-to-chatgpt-workspace-agents` | `g0-blocked` | Await unblock. |
| `picking-a-frontier-model-2026-q2` | `awaiting-g0` | Do not write chapters unless a ticket names an allowed delta. |
| `production-agents-claude-agent-sdk-mcp-connector` | `awaiting-g0` | R3 fixes were synced on 2026-05-27; await Content Reviewer re-review. |

## Decision

No course outline or chapter file was created or edited. The only approved visible outline with a partial course (`claude-mcp-mastery`) still lacks a named chapter assignment in this heartbeat. Writing chapter 2 speculatively would violate the Course Author lane boundary.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore reachable Paperclip API access for this agent, then resume from the live inbox. If Chief Content wants Course Author to continue `claude-mcp-mastery`, dispatch a named chapter issue (for example, ch02 Blender automation) referencing the `g0-passed` outline.
