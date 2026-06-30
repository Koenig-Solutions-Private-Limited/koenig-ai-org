---
ticket: KOEA-7801
planner_ticket: KOEA-7802
revision_ticket: KOEA-7807
revision_ticket_2: KOEA-7809
planner: planner
date: 2026-06-11
revision: 3
triggered_by_approval: 332321ab-513c-4c2f-b2a2-052bf1a3a4fd
estimated_complexity: small
estimated_token_cost: $0.45
base_branch: "academy/redesign-v1 for any learnovaBeast helper patch; runtime-only path needs no branch"
basebranch_verified: true
chain_guardrail_approval: 517cad21-6cd9-4bed-8e9c-42c9bd09b7c9
revision_2_chain_guardrail_approval: ac9f8ec2-a142-4f77-a981-04bec4342d86
revision_3_chain_guardrail_approval: 332321ab-513c-4c2f-b2a2-052bf1a3a4fd
runtime_only: true
required_worktree_path: /Users/vardaankoenig/Documents/Paperclip/learnovaBeast-be-agent
status: ready-for-plan-review
---

# Plan: Recover audio for Cursor Composer 2 chapter 5

## Goal
Unblock KOEA-7797 by producing one valid `audio.mp3` for `cursor-composer-2/05-multitask-parallel-agents` or by restoring one audio tier and explicitly re-dispatching KOEA-7797 to finish generation. Success is observable when the sidecar keeps the current `assets.slide_deck_url`, gains `assets.audio_url`, and the public audio URL returns playable MP3 content.

## Context
- Files to read first: `companies/learnova-academy/skills/slide-audio-produce/SKILL.md:1`, `companies/learnova-academy/agents/slide-audio-producer/AGENTS.md:1`, `observability/open-notebook/docker-compose.yml:1`, `scripts/upload-chapter-assets.mjs:1`, `scripts/generate_course_audio.py:1`, `vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter.md:1`, `vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter-meta.json:1`, `vault/decisions/72560da6-f8d0-48e9-b7aa-309aa9400ade-plan.md:30`
- Relevant prior work: KOEA-7801 preflight confirmed `notebooklm` absent, `localhost:5055` unreachable, and OpenAI TTS quota exhausted. Existing `chapter-meta.json` already has `assets.slide_deck_url` from R2. `scripts/upload-chapter-assets.mjs` merges new assets into the existing sidecar, so an audio-only upload preserves the current slide deck URL. KOEA-7804 blocks KOEA-7805, KOEA-7805 blocks KOEA-7801, and KOEA-7801 blocks KOEA-7797; KOEA-7804's Executor must not PATCH another agent's issue directly.
- Constraints: Keep this as runtime-only recovery unless a tracked helper is genuinely broken. Before any repo/runtime command outside `koenig-ai-org`, Executor must use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-be-agent`, create/check `.claude/agent-lock`, and record `pwd` plus `git status --short`. If that required path is missing, block KOEA-7804 for operator-provided checkout instead of substituting another worktree. If a helper patch becomes necessary, branch from verified `origin/academy/redesign-v1`, not `origin/master`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Restore and use the existing Open-Notebook fallback service first, then either upload the generated audio directly or re-dispatch KOEA-7797 once the tier is healthy. This remains the least-risk route because `observability/open-notebook/docker-compose.yml` is already checked in, the Slide + Audio Producer already treats Open-Notebook as the outage fallback, direct OpenAI TTS is known quota-exhausted, and `notebooklm-py` is absent in the current preflight.

**Rejected**: Direct OpenAI TTS first - only acceptable after a funded `OPENAI_API_KEY` is confirmed because KOEA-7801 recorded `insufficient_quota`. Install `notebooklm-py` first - higher-quality path, but it depends on account/session setup and is slower than starting the checked-in fallback service. Patch producer architecture - out of scope for a one-chapter unblock.

## Steps (Executor follows in order)
1. From `koenig-ai-org`, record current probes without changing files: `command -v notebooklm notebooklm-py || true`, `curl -fsS http://localhost:5055/health || true`, `curl -fsS http://localhost:5055/api/auth/status || true`, `test -f vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter-meta.json`, and `jq '.assets' vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter-meta.json`.
2. Enforce the KOEA-7804 lock before any repo/runtime-changing command: `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast-be-agent`, `pwd`, `mkdir -p .claude`, create `.claude/agent-lock` if absent with the current issue/run id, print its contents if present, and run `git status --short`. Do not run cleanup/revert commands. If runtime artifacts are needed, place them under `/tmp/koea-7801-audio/` or the chapter artifact directory only.
3. Start the fallback service only if it is not already healthy: `docker compose -f observability/open-notebook/docker-compose.yml up -d`, then verify `docker compose -f observability/open-notebook/docker-compose.yml ps` and `curl -fsS http://localhost:5055/health`. Determine auth once with `AUTH_JSON=$(curl -fsS http://localhost:5055/api/auth/status || echo '{}')`; use `AUTH_HEADER=(-H "Authorization: Bearer $OPEN_NOTEBOOK_API_KEY")` only when that response says auth is required/enabled, otherwise omit the authorization header. If Docker is unavailable or health never becomes ready, skip to the fallback order in step 5.
4. Generate the chapter podcast through the verified Open-Notebook API surface from `vault/decisions/72560da6-f8d0-48e9-b7aa-309aa9400ade-plan.md`: upload the markdown source with `SOURCE_JSON=$(curl -fsS -X POST http://localhost:5055/api/sources "${AUTH_HEADER[@]}" -F type=text --form-string "title=Cursor Composer 2 Ch5" --form-string "content=$(< vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter.md)" -F embed=false -F async_processing=false)` and `SOURCE_ID=$(jq -r '.id' <<<"$SOURCE_JSON")`. Then start the podcast with `jq -n --rawfile content vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter.md '{episode_profile:"solo_expert",speaker_profile:"solo_expert",episode_name:"Cursor Composer 2 Ch5 /multitask and Parallel Agents",content:$content}' | curl -fsS -X POST http://localhost:5055/api/podcasts/generate "${AUTH_HEADER[@]}" -H "Content-Type: application/json" --data-binary @-`. Save `.job_id`, poll `GET /api/podcasts/jobs/<job_id>` until `status == "completed"` or `failed`, save `.episode_id`, and download `GET /api/podcasts/episodes/<episode_id>/audio` to `/tmp/koea-7801-audio/audio.mp3`.
5. If Open-Notebook cannot produce audio, use this fallback order: first run `python3 scripts/generate_course_audio.py vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter.md /tmp/koea-7801-audio/` only after a funded `OPENAI_API_KEY` is confirmed; second install/configure `notebooklm-py` only if the NotebookLM account/session is already available. If all three tiers fail, keep KOEA-7804 blocked with the exact failing command, log excerpt, and owner action required.
6. Inspect and upload audio if an MP3 exists: `test -s /tmp/koea-7801-audio/audio.mp3`, `file /tmp/koea-7801-audio/audio.mp3`, and `ffprobe -v error -show_entries format=duration,bit_rate -of json /tmp/koea-7801-audio/audio.mp3`. Normalize with `ffmpeg -af loudnorm=I=-16:LRA=11:tp=-1.5 -ar 44100 -ac 2` when available. Then upload only the audio with `node scripts/upload-chapter-assets.mjs --course cursor-composer-2 --chapter 05-multitask-parallel-agents --dir /tmp/koea-7801-audio --title "/multitask and Parallel Agents: Running a Fleet"` and verify `jq -er '.assets.slide_deck_url and .assets.audio_url' vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter-meta.json`, `AUDIO_URL=$(jq -r '.assets.audio_url' vault/courses/cursor-composer-2/05-multitask-parallel-agents/chapter-meta.json)`, `curl -fsSI "$AUDIO_URL"`, and `ffprobe -v error "$AUDIO_URL"` if remote probing is supported.
7. Complete the Paperclip handoff only through issues KOEA-7804's Executor is allowed to mutate. Do not PATCH KOEA-7801 or KOEA-7797 directly. Instead, add the final result to KOEA-7804 and mark KOEA-7804 done. If audio was uploaded directly, the KOEA-7804 completion comment must include the `audio_url`, the preserved `slide_deck_url`, and the `jq`, `curl -fsSI`, and `ffprobe` evidence; KOEA-7805 is blocked by KOEA-7804 and will wake to verify the filled sidecar. If only an audio tier was restored and no audio was uploaded, the KOEA-7804 completion comment must name the healthy tier and state that KOEA-7801's owner should close the toolchain blocker or re-dispatch KOEA-7797 once QA/owner review accepts the result. The downstream flow is: KOEA-7804 done wakes KOEA-7805, KOEA-7805 done unblocks KOEA-7801, and KOEA-7801 done unblocks KOEA-7797. If an immediate downstream notification is still required, create a child issue assigned to the relevant owner or request an interaction/approval; do not use cross-assignee PATCH as a shortcut.

## Verification (QA Verifier checks these)
- [ ] `chapter-meta.json` contains both the pre-existing `assets.slide_deck_url` and a new non-empty `assets.audio_url`.
- [ ] `curl -fsSI "$audio_url"` returns `200` with `content-type: audio/mpeg`, `audio/mp3`, or equivalent MP3 content type.
- [ ] `ffprobe` reports a positive duration and no parse error for the produced MP3.
- [ ] Executor comment states which tier succeeded (`open-notebook`, direct OpenAI TTS, or `notebooklm-py`) and includes the service/credential assumption used.
- [ ] KOEA-7804 is marked done with the handoff evidence on KOEA-7804 itself, and there is no Executor-authored direct PATCH/comment on KOEA-7801 or KOEA-7797.
- [ ] The blocker chain is preserved for wakeups: KOEA-7804 done wakes KOEA-7805, KOEA-7805 remains the QA gate, KOEA-7805 done unblocks KOEA-7801, and KOEA-7801 done unblocks KOEA-7797.
- [ ] The KOEA-7804 execution log includes `pwd`, `.claude/agent-lock` contents or creation, and `git status --short` from `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-be-agent` before runtime-changing commands.

## Risk
- Open-Notebook may still depend on provider credentials stored in its local DB. Mitigation: Executor must test health/auth first, log whether auth is required, and fall back cleanly rather than modifying Docker or producer code under pressure.

## Out of scope
- Regenerating slides, changing course copy, fixing `learnovaBeast` rendering, broad Slide + Audio Producer redesign, and committing unrelated dirty worktree files.
