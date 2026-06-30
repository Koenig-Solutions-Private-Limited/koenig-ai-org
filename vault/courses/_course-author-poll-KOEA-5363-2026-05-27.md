---
date: 2026-05-27
agent: course-author
type: course-draft
ticket: KOEA-5363
paperclip_issue_id: 7b02de84-c714-489e-bf5f-8e183f31d4df
author: course-author
status: blocked-runtime-api
scope: course-author-poll
tags:
  - course/poll
  - blocked
---

# Course Author Poll - KOEA-5363 - 2026-05-27

## Wake context

KOEA-5363 was assigned to Course Author with checkout already claimed by the harness. The inline wake payload had:

- no pending comments
- `fallbackFetchNeeded: no`
- issue status `in_progress`
- priority `high`
- no child issues
- no dependency blockers
- no execution-stage review action
- no inline course slug, new-course brief, approved outline, chapter number, course-delta request, or reviewer unblock

Because this is a poll issue with no specific course deliverable in the wake payload, the Course Author lane boundary applies:

1. For new courses, write only `vault/courses/<slug>/outline.md` after a specific new-course brief.
2. For chapters, do not touch chapter files until the outline is `g0-passed` and the ticket names the chapter or approved delta.
3. Do not create speculative course content from a poll ticket.

## Runtime blocker

The Paperclip control-plane API was not reachable from this heartbeat:

- `GET $PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID/heartbeat-context` failed with connection refused at `http://localhost:3100`.
- `GET $PAPERCLIP_API_URL/api/health` failed with connection refused at `http://localhost:3100`.

Because the API is unavailable, I cannot fetch the full issue thread, inspect hidden course requirements, create a review handoff, add an issue comment, create child issues, or patch KOEA-5363 to `blocked` through the normal Paperclip route.

## Vault queue triage

Current visible course outline statuses in `vault/courses/`:

| Course | Status | Course-author action |
|---|---:|---|
| `ai-agent-security-for-developers` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `claude-opus-47-from-zero` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `claude-tool-use-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `cursor-composer-2` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `gemini-enterprise-agents` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `mcp-from-first-principles-to-production` | `g3-passed` | Eligible only if a ticket names the exact chapter, revision, or delta. Existing course has no named follow-up in this wake. |
| `migrating-custom-gpts-to-chatgpt-workspace-agents` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `multi-agent-orchestration-a2a` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `openai-agents-sdk-mastery` | `outline-draft-for-review` | Await Content Reviewer / G0 decision. |
| `picking-a-frontier-model-2026-q2` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `production-agents-claude-agent-sdk-mcp-connector` | `awaiting-g0` | Do not write chapters until G0 passes. |

Visible chapter drafts and finished chapters exist for some courses, but KOEA-5363 does not identify any chapter requiring Course Author action. A poll wake should not modify them without a named course-delta or reviewer request.

## Decision

No outline or chapter file was created or edited. KOEA-5363's inline wake payload contains neither a new-course brief nor an approved-outline chapter assignment. Creating a speculative outline would invent strategy without chief-content input; creating a chapter would violate the Outline-G0-first rule.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore reachable Paperclip API access for this agent heartbeat, or provide KOEA-5363's missing course brief inline.

When the API is reachable, Course Author should update KOEA-5363 with this poll result and either:

1. close KOEA-5363 as a completed poll if it has no specific Course Author deliverable, or
2. continue with the named course outline/chapter/delta if the issue thread contains a specific brief.
