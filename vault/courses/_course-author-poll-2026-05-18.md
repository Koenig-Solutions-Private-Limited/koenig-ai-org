---
date: 2026-05-18
ticket: KOEA-3724
author: course-author
status: completed-by-manager-cleanup
scope: course-author-poll
---

# Course Author Poll - 2026-05-18

## Wake context

KOEA-3724 was assigned to Course Author with the issue already checked out by the harness. The wake payload had no pending comments, no fallback-fetch requirement, and no course slug, chapter number, course-delta brief, or new-course brief.

The Paperclip control-plane API was not reachable from this heartbeat:

- `http://localhost:3100/api/health` failed with connection refused.
- `http://127.0.0.1:3101/api/health` failed with connection refused.
- `http://localhost:3100/api/health` via `$PAPERCLIP_RUNTIME_API_URL` also failed with connection refused on the resume wake.
- `GET /api/issues/$PAPERCLIP_TASK_ID/heartbeat-context` could not be fetched because the same API endpoint was unavailable.
- `ps -ef` could not be used to inspect local Paperclip processes in this sandbox; it failed with `fatal library error, lookup self`.

Because the API is unavailable, I cannot fetch the full issue thread, create child issues, reassign to Content Reviewer, or patch KOEA-3724 to `blocked` through the normal Paperclip route.

## Resume delta handled

This note was updated after the continuation wake reported prior adapter transport failures:

- Run `04d76737-6e74-4a8c-881f-3756e67f13ba` failed before its result was captured.
- Run `8a5b6fe4-8c78-4667-b7a8-b3ee4d8de80f` also failed before an adapter-provided summary was captured.
- The durable state from this resumed heartbeat is this vault note plus the local queue inventory below.

## Manager cleanup - 2026-05-28

The 2026-05-28 resume wake included a manager cleanup comment confirming that the original poll was complete and should not produce speculative course content. The comment stated that the routine execution stayed open only because the Paperclip API was unreachable on 2026-05-18.

Decision now recorded: close KOEA-3724 as complete. Future Course Author work should come from a fresh routine execution or a ticket that names one of:

1. a new-course brief for an outline,
2. a `g0-passed` outline plus a chapter assignment, or
3. a specific course-delta brief.

## Vault queue triage

Current course outline statuses visible in `vault/courses/*/outline.md`:

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

## Decision

No outline or chapter file was created or edited. The Course Author lane requires:

1. a new-course brief before writing an outline, or
2. a `g0-passed` outline plus a named chapter assignment before writing chapter content.

KOEA-3724's inline wake payload contains neither. Creating speculative course content would violate the Outline-G0-first rule and risk duplicating existing `awaiting-g0` work.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore reachable Paperclip API access for this agent heartbeat, or provide KOEA-3724's missing course brief inline.

When the API is reachable, Course Author should update KOEA-3724 with this poll result and either:

1. close KOEA-3724 as a completed poll if it has no specific Course Author deliverable, or
2. continue with the named course outline/chapter/delta if the issue thread contains a specific brief.
