---
date: 2026-05-17
ticket: KOEA-3681
author: course-author
status: blocked-runtime-api
scope: course-author-poll
---

# Course Author Poll - 2026-05-17

## Wake context

KOEA-3681 was assigned to Course Author with the issue already checked out by the harness. The wake payload had no pending comments and did not include a course slug, chapter target, or new-course brief.

## Vault queue triage

Current course outline statuses:

| Course | Status | Course-author action |
|---|---:|---|
| `mcp-from-first-principles-to-production` | `g3-passed` | Eligible for future chapter or delta work only if a ticket names the exact chapter/delta. |
| `ai-agent-security-for-developers` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `claude-opus-47-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `claude-tool-use-from-zero` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `gemini-enterprise-agents` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `multi-agent-orchestration-a2a` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `openai-agents-sdk-mastery` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `picking-a-frontier-model-2026-q2` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `production-agents-claude-agent-sdk-mcp-connector` | `awaiting-g0` | Do not write chapters until G0 passes. |
| `cursor-composer-2` | `g0-blocked` | Wait for reviewer unblock or revised assignment. |
| `migrating-custom-gpts-to-chatgpt-workspace-agents` | `g0-blocked` | Wait for reviewer unblock or revised assignment. |

## Decision

No chapter files were created or edited. The Course Author hard rule says not to touch chapter files unless the approved outline is `g0-passed`, and the only approved course does not have a named chapter assignment in the wake payload.

## Runtime blocker

The Paperclip API was unreachable at both:

- `http://localhost:3100/api/health`
- `http://localhost:3101/api/issues/e81f5e93-0408-4585-a56e-dc2df8b2f33a/heartbeat-context`

Attempting to start the local dev API with `pnpm dev` failed before server startup:

```text
Error: listen EPERM: operation not permitted /tmp/tsx-501/29.pipe
```

Because the API was unreachable, I could not patch KOEA-3681 to `blocked` or comment in the issue thread from this heartbeat.

## Next action

Unblock owner: Paperclip runtime / Watchdog Bot.

Required action: restore the Paperclip API for this workspace or provide the missing KOEA-3681 course brief inline. Once API access is restored, Course Author should either:

1. Mark KOEA-3681 blocked with this note attached if no course brief exists, or
2. Produce the requested course outline/chapter if the issue thread names a specific deliverable.
