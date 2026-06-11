---
ticket: KOEA-6830
plan_issue: KOEA-7360
planner: planner
date: 2026-06-05
estimated_complexity: small
estimated_token_cost: $0.24
base_branch: master
basebranch_verified: true
planned_against_branch: master
planned_against_sha: 5bcb133a9875908cf23c91af73c19e16d2a861f6
---

# Plan: restore course audio fallback runtime for NotebookLM lane

## Goal
Restore a reliable audio fallback path for Slide + Audio Producer when `notebooklm-py` fails or rate-limits. Success means a producer has a documented, runnable fallback command that creates `audio.mp3`, normalizes it to -16 LUFS, records the fallback in chapter metadata, and does not depend on an unavailable live service without a Tier-3 escape hatch.

## Context
- Files to read first: `companies/learnova-academy/agents/slide-audio-producer/AGENTS.md:17-38`, `companies/learnova-academy/skills/slide-audio-produce/SKILL.md:33-62`, `observability/open-notebook/docker-compose.yml:1-29`, `README.koenig.md:106-108`, `scripts/generate_course_audio.py:1-75`, `vault/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/01-why-mcp-exists-meta.md:1-77`, `vault/courses/picking-a-frontier-model-2026-q2/ch01-meta.md:1-33`.
- Relevant prior work: `vault/decisions/72560da6-f8d0-48e9-b7aa-309aa9400ade-plan.md` documents the live open-notebook API shape previously verified on 2026-05-12, including `/health`, `/api/podcasts/generate`, podcast job polling, and audio download endpoints.
- Current state: `curl http://127.0.0.1:5055/health` fails; `docker` is not available in this Planner environment; `scripts/generate_course_audio.py` exists only as an untracked worktree file, so the repo still lacks the Tier-3 script from the lane contract.
- Constraints: no source chapter edits; no ElevenLabs; `notebooklm-py` remains primary; open-notebook fallback ships audio only and must flag skipped Studio assets; use `master` for koenig-ai-org work because `origin/master` exists and is the remote HEAD.

## Approach (1 chosen, alternatives rejected)
**Chosen**: codify a three-tier fallback ladder and commit the missing Tier-3 runtime. Executor should keep `notebooklm-py` as Tier 1, keep open-notebook on `127.0.0.1:5055` as Tier 2 when Docker/service health is available, and add a tracked `scripts/generate_course_audio.py` Tier-3 script that uses OpenAI TTS to synthesize a chapter markdown file into `audio.mp3` when open-notebook is unavailable or lacks a podcast endpoint. This is the smallest restoration path because it fixes the missing repo artifact and removes the single point of failure without inventing a new adapter or changing course content ownership.

**Rejected**: open-notebook-only restoration — current environment cannot even run `docker`, and historical metadata shows port 5055 can be up while podcast support is absent; adapter implementation — larger than this blocker and already covered by older planning work; route to Voice Producer — contradicts the current Slide + Audio Producer ownership rule that this agent owns chapter assets end-to-end.

## Steps (Executor follows in order)
1. Create a clean branch from verified base `master`, preferably in a fresh worktree because the current checkout has unrelated dirty vault/blog files and an untracked draft `scripts/generate_course_audio.py`.
2. Track and harden `scripts/generate_course_audio.py`: keep the existing markdown-cleaning/chunking shape, add explicit `--voice`, `--model`, `--output-name`, and `--max-chars` options, write chunk files safely, concatenate with `ffmpeg` when available instead of raw byte append, and fail clearly when `OPENAI_API_KEY` is missing.
3. Update `companies/learnova-academy/skills/slide-audio-produce/SKILL.md` so fallback order is explicit: after two `notebooklm-py` failures, health-check open-notebook with `curl -fsS http://127.0.0.1:5055/health`; if healthy, use the documented open-notebook podcast route; otherwise run `python3 scripts/generate_course_audio.py vault/courses/<slug>/<chapter>.md vault/courses/<slug>/<chapter>-assets --output-name audio.mp3`.
4. Update `companies/learnova-academy/agents/slide-audio-producer/AGENTS.md` to match the same fallback ladder and state that Tier-3 is OpenAI TTS, not ElevenLabs, and is allowed only for outage windows with metadata noting `tool_fallback_reason`.
5. Update `README.koenig.md` and `.env.koenig.example` with the operational commands: boot open-notebook via `docker compose -f observability/open-notebook/docker-compose.yml up -d`, verify `curl -fsS http://127.0.0.1:5055/health`, and ensure `OPENAI_API_KEY` is present for Tier-3 script fallback.
6. Add or update a short metadata example in the skill docs showing `tool: open-notebook` or `tool: openai-tts`, `tool_fallback_reason`, `duration_audio_sec`, `audio_lufs`, and the skipped Studio assets note when fallback audio is shipped.

## Verification (QA Verifier checks these)
- [ ] `python3 scripts/generate_course_audio.py --help` prints usage and exits 0 without requiring `OPENAI_API_KEY`.
- [ ] With `OPENAI_API_KEY` set, a tiny markdown fixture can generate `audio.mp3`; `ffprobe` sees a valid MP3, then `ffmpeg -af loudnorm=I=-16:LRA=11:tp=-1.5` produces a normalized file.
- [ ] If Docker is available, `docker compose -f observability/open-notebook/docker-compose.yml up -d` followed by `curl -fsS http://127.0.0.1:5055/health` succeeds; if Docker is unavailable, Executor documents that Tier-3 verification covered the local environment.
- [ ] `rg -n "generate_course_audio|open-notebook|notebooklm-py|OPENAI_API_KEY" companies/learnova-academy README.koenig.md .env.koenig.example scripts` shows a consistent fallback ladder with no ElevenLabs reference.

## Risk
- OpenAI TTS output may be shorter and less conversational than NotebookLM dual-narrator audio; mitigation is to mark `tool_fallback_reason` in metadata, normalize loudness, and queue a `notebooklm-py` re-run when the primary path recovers.

## Out of scope
- Implementing the full `notebooklm-driver` adapter, generating or uploading production course assets, changing source chapter markdown, or replacing the primary `notebooklm-py` lane.
