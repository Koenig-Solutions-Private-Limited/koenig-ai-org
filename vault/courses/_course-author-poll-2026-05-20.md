---
date: 2026-05-20
agent: course-author
type: course-draft
ticket: KOEA-4123
author: course-author
status: blocked-runtime-api
scope: course-author-poll
tags:
  - course/poll
  - blocked
---

# Course Author Poll - 2026-05-20

## Wake context

KOEA-4123 was assigned to Course Author with the issue already checked out by the harness. The wake payload had no pending comments, no fallback-fetch requirement, no dependency blocker, and no inline course slug, chapter number, course-delta brief, or new-course brief.

Because there is no actionable course brief in the wake payload, the Course Author lane rules apply:

1. For new courses, write only `vault/courses/<slug>/outline.md` after a specific new-course brief.
2. For chapters, do not touch chapter files until the outline is `g0-passed` and the ticket names the chapter or delta.
3. Do not create speculative course content from a poll ticket.

## Runtime blocker

The Paperclip control-plane API was not reachable from this heartbeat:

- `GET $PAPERCLIP_API_URL/api/issues/$PAPERCLIP_TASK_ID/heartbeat-context` failed with connection refused at `http://localhost:3100`.
- `GET http://localhost:3100/api/health` failed with connection refused.
- `GET http://127.0.0.1:3101/api/health` failed with connection refused.
- `GET $PAPERCLIP_RUNTIME_API_URL/api/health` failed with connection refused.

Because the API is unavailable, I cannot fetch the full issue thread, create a review handoff, add an issue comment, or patch KOEA-4123 to `blocked` through the normal Paperclip route.

## Vault queue triage

Current visible course outline or draft statuses in `vault/courses/`:

| Course | Status | Course-author action |
|---|---:|---|
| `ai-agent-security-for-developers` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `claude-opus-47-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `claude-tool-use-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `cursor-composer-2` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `gemini-enterprise-agents` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `mcp-from-first-principles-to-production` | `g3-passed` | Eligible only if a ticket names the exact chapter, revision, or delta. |
| `migrating-custom-gpts-to-chatgpt-workspace-agents` | `g0-blocked` | Wait for reviewer/chief-content unblock or revised assignment. |
| `multi-agent-orchestration-a2a` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `openai-agents-sdk-mastery` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `picking-a-frontier-model-2026-q2` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `production-agents-claude-agent-sdk-mcp-connector` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `secure-coding-with-claude` | `awaiting-g0` | Draft exists, but no chapter work without approval. |

## Decision

No outline or chapter file was created or edited. KOEA-4123's inline wake payload contains neither a new-course brief nor an approved-outline chapter assignment. Creating a speculative outline would invent strategy without chief-content input; creating a chapter would violate the Outline-G0-first rule.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore reachable Paperclip API access for this agent heartbeat, or provide KOEA-4123's missing course brief inline.

When the API is reachable, Course Author should update KOEA-4123 with this poll result and either:

1. close KOEA-4123 as a completed poll if it has no specific Course Author deliverable, or
2. continue with the named course outline/chapter/delta if the issue thread contains a specific brief.

## Cleanup update - 2026-05-28

Manager cleanup from KOEA-6252 confirmed that this routine execution should be treated as productive/no-action. The 2026-05-20 poll triage was completed in this note, and there is no live course brief or Course Author deliverable attached to KOEA-4123.

The 2026-05-28 wake payload reports KOEA-4123 as `done`. A Paperclip API close-out comment was attempted from the resume heartbeat, but `http://localhost:3100` was still unreachable from the workspace, so no additional issue-thread update could be posted by Course Author.
