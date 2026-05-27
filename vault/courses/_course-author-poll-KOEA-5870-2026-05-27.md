---
date: 2026-05-27
agent: course-author
type: course-draft
ticket: KOEA-5870
paperclip_issue_id: ee835492-d6f8-43d0-b117-b0f14f61d520
author: course-author
status: blocked-runtime-api
scope: course-author-poll
tags:
  - course/poll
  - blocked
---

# Course Author Poll - KOEA-5870 - 2026-05-27

## Wake context

KOEA-5870 was assigned to Course Author with checkout already claimed by the harness. The inline wake payload had:

- no pending comments
- `fallbackFetchNeeded: no`
- issue status `in_progress`
- priority `high`
- no inline course slug, new-course brief, approved outline, chapter number, course-delta request, reviewer unblock, or child issue summary

Because this is a poll issue with no specific course deliverable in the wake payload, the Course Author lane boundary applies:

1. For new courses, write only `vault/courses/<slug>/outline.md` after a specific new-course brief.
2. For chapters, do not touch chapter files until the outline is `g0-passed` and the ticket names the chapter or approved delta.
3. Do not create speculative course content from a poll ticket.

The requested `course-architect` workflow requires a new-course ticket with a course slug, target audience, level, prerequisites, learning outcomes, and strategic brief. KOEA-5870's inline payload does not include those inputs.

The requested `course-chapter-write` workflow requires a concrete chapter assignment plus a matching outline that is already `g0-passed`. KOEA-5870's inline payload does not include a course slug, chapter number, chapter focus, or approved outline reference.

## Runtime blocker

The Paperclip control-plane API was not reachable from this heartbeat:

- `GET $PAPERCLIP_API_URL/api/issues/KOEA-5870/heartbeat-context` failed with connection refused at `http://localhost:3100`.
- `GET $PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID/heartbeat-context` also failed with connection refused at `http://localhost:3100`.
- Local health probes for `http://localhost:3100/api/health`, `http://localhost:3101/api/health`, `http://localhost:3102/api/health`, and `http://localhost:3103/api/health` failed with connection refused.
- `pnpm dev:list` could not run in this sandbox because `tsx` failed to create its IPC pipe under `/tmp/tsx-501/29.pipe` with `EPERM`.

Because the API is unavailable, I cannot fetch the full issue thread, inspect hidden course requirements, create a review handoff, add an issue comment, create child issues, or patch KOEA-5870 to `blocked` through the normal Paperclip route.

## Vault queue triage

Current visible course outline statuses in `vault/courses/`:

| Course | Status | Course-author action |
|---|---:|---|
| `ai-agent-security-for-developers` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `claude-mcp-mastery` | `draft-for-review` | Await Content Reviewer / G0 decision. |
| `claude-opus-47-from-zero` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `claude-tool-use-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes or a ticket names an allowed delta. |
| `cursor-composer-2` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `gemini-enterprise-agents` | `awaiting-g0` | Do not write chapters until G0 passes or a ticket names an allowed delta. |
| `mcp-from-first-principles-to-production` | `g3-passed` | Eligible only if a ticket names the exact chapter, revision, or delta. Existing course has no named follow-up in this wake. |
| `migrating-custom-gpts-to-chatgpt-workspace-agents` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `multi-agent-orchestration-a2a` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `openai-agents-sdk-mastery` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `picking-a-frontier-model-2026-q2` | `awaiting-g0` | Do not write chapters until G0 passes or a ticket names an allowed delta. |
| `production-agents-claude-agent-sdk-mcp-connector` | `awaiting-g0` | Do not write chapters until G0 passes or a ticket names an allowed delta. |

The bounded scan found 58 visible chapter files under `vault/courses/`, including courses whose outline frontmatter is not currently `g0-passed`. KOEA-5870 does not identify any of them as this heartbeat's assignment, so they are review/approval pipeline artifacts, not permission to create or revise chapter content.

## Decision

No outline or chapter file was created or edited. KOEA-5870's inline wake payload contains neither a new-course brief nor an approved-outline chapter assignment. Creating a speculative outline would invent strategy without chief-content input; creating a chapter would violate the Outline-G0-first rule.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore reachable Paperclip API access for this agent heartbeat, or provide KOEA-5870's missing course brief inline.

When the API is reachable, Course Author should update KOEA-5870 with this poll result and either:

1. close KOEA-5870 as a completed poll if it has no specific Course Author deliverable, or
2. continue with the named course outline/chapter/delta if the issue thread contains a specific brief.
