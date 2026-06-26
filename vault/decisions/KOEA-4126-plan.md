---
ticket: KOEA-4130
source_incident: KOEA-4126
planner: planner
date: 2026-05-27
estimated_complexity: medium
estimated_token_cost: $0.48
base_branch: master
basebranch_verified: true
triggered_by_approval: e9af5037-db48-4fc2-bbd3-faec45b46429
revision: 2
revision_reason: KOEA-4131 requested explicit retained events and excerpt coverage
---

# Plan: contain secret exposure in retained heartbeat run logs

## Goal
Contain the source run-log exposure without copying any secret values into code, docs, comments, tests, or fixtures. Success means retained run logs, retained `/events` records, stored run excerpts, run-log API responses, transcript UI surfaces, and feedback/export bundles redact secret-like command output, while credential rotation remains tracked through the existing CEO lane.

## Context
- Files to read first: `server/src/services/heartbeat.ts:2942-2964`, `server/src/services/heartbeat.ts:5436-5461`, `server/src/services/heartbeat.ts:7507-7513`, `server/src/services/run-log-store.ts:109-145`, `server/src/routes/agents.ts:2725-2744`, `server/src/routes/agents.ts:2747-2764`, `server/src/redaction.ts:71-79`, `server/src/services/feedback.ts:1544-1550`, `ui/src/adapters/transcript.ts:97-136`, `ui/src/components/transcript/useLiveRunTranscripts.ts:398-401`, `ui/src/pages/AgentDetail.tsx:3447-3458`, `ui/src/pages/AgentDetail.tsx:3992-4012`.
- Relevant prior work: KOEA-4126 parent incident; source run `c45a6a32-738b-4149-b9f0-7459c602f088`; chain approval `e9af5037-db48-4fc2-bbd3-faec45b46429`; KOEA-4131 plan review requested explicit retained `/events`, stored event, and excerpt coverage.
- Constraints: do not paste secret values; preserve company scoping on run-log and event access; keep incident containment ahead of broader logging refactors; `origin/master` exists and is the verified fork base branch.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Reuse the existing `redactSensitiveText` helper at every server boundary that stores or returns run-output-derived text. Executor should apply secret text redaction before persisted run chunks, `stdoutExcerpt`/`stderrExcerpt`, stored heartbeat event messages/payloads, and live event payloads are written, then keep read-path safeguards for retained pre-fix logs and retained `/events` responses. This covers old and new logs, API responses, UI transcripts/excerpt panels that consume those APIs, stored event/excerpt surfaces, and feedback bundles without inventing a new redaction subsystem.

**Rejected**: One-off edit/delete of the source run-log file only - contains the incident but leaves future agent env dumps exposed. UI-only redaction - hides transcript views but leaves API/export/event surfaces exposed. New redaction subsystem - unnecessary because `server/src/redaction.ts` already covers env assignments, bearer tokens, JSON secret fields, common API keys, GitHub tokens, and JWT-looking text.

## Steps (Executor follows in order)
1. Update `server/src/services/heartbeat.ts` so run-output sanitization applies `redactSensitiveText(redactCurrentUserText(...))` before `compactRunLogChunk`, `stdoutExcerpt`/`stderrExcerpt`, `runLogStore.append`, and last-output metadata updates receive content.
2. Update heartbeat event persistence in `server/src/services/heartbeat.ts:2942-2964` so `event.message`, string payload leaves, and the live `heartbeat.run.event` publish payload use the same secret-text redaction pipeline after bounding and current-user redaction.
3. Add read-path safeguards in `server/src/services/heartbeat.ts` and/or `server/src/routes/agents.ts` so `/api/heartbeat-runs/:runId/log` and `/api/heartbeat-runs/:runId/events` redact retained pre-fix log content, event messages, and event payload string values before returning JSON.
4. Add a small shared server helper if needed to avoid duplicating the run-output redaction pipeline; keep public API response shapes unchanged and preserve company access checks.
5. Confirm `server/src/services/feedback.ts` still sanitizes `paperclip/run-log.ndjson` and stored event exports; patch only if retained run events or excerpts can enter feedback/export bundles without `redactSensitiveText`.
6. Add targeted server tests proving fake env-style assignments, bearer tokens, JSON secret fields, GitHub-token-shaped strings, and JWT-shaped strings are redacted from log API content, `/events` API content, stored event message/payload surfaces, and `stdoutExcerpt`/`stderrExcerpt`.
7. Record the containment result on KOEA-4126 using key names only; leave credential rotation to KOEA-4135 and do not perform vendor credential mutation from Executor unless CEO/board explicitly authorizes that lane.

## Verification (QA Verifier checks these)
- [ ] `GET /api/heartbeat-runs/c45a6a32-738b-4149-b9f0-7459c602f088/log` no longer returns any raw secret value, while preserving key names such as `RESEND_API_KEY`.
- [ ] `GET /api/heartbeat-runs/c45a6a32-738b-4149-b9f0-7459c602f088/events` redacts retained event `message` and `payload` text, including pre-fix stored records.
- [ ] Agent run transcript UI, issue/latest-run surfaces, and excerpt panels that derive from heartbeat run logs or `stdoutExcerpt`/`stderrExcerpt` show the redaction marker instead of raw secret-like values.
- [ ] Feedback/export bundle files, including `paperclip/run-log.ndjson` and any run-event material, do not include raw secret-like values.
- [ ] Targeted Vitest coverage passes for server run-log, event, and excerpt redaction behavior.

## Risk
- Existing log byte offsets and `nextOffset` can become approximate if redaction changes response byte length; mitigate by preserving the current offset semantics from the raw file and treating redacted response content as display/export content, not a byte-identical file mirror.

## Out of scope
- Rotating the actual `RESEND_API_KEY` credential; KOEA-4135 owns provider-side revoke/replace and deployment secret-store updates.
- Replacing the full logging architecture, introducing role-based secret visibility, or broadening company access semantics.
- Publishing raw source-run excerpts in comments, fixtures, screenshots, or PR descriptions.
