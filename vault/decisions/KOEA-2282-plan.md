---
ticket: KOEA-2282
planner_ticket: KOEA-2286
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
approval_override: 8dc23e4f-051d-414f-af78-838378eaabcb
---

# Plan: Restore slide/audio runtime toolchain

## Goal
Restore the local Koenig `koenig-ai-org` runtime path so Slide + Audio Producer work can generate inspectable course assets again. Success means an Executor can produce a nonzero `.pptx` and `.mp3`, inspect slide count and audio duration/format, and unblock KOEA-2257 without touching `learnovaBeast` portals or Convex deployment.

## Context
- Files to read first: `scripts/generate_blog_slides.py:1-243`, `observability/open-notebook/docker-compose.yml:1-32`, `git show 0bbb6de84:scripts/generate_course_audio.py:1-182`, `vault/courses/picking-a-frontier-model-2026-q2/ch02-meta.md:1-24`, `vault/courses/mcp-from-first-principles-to-production/01-why-mcp-exists/01-why-mcp-exists-meta.md:1-77`
- Relevant prior work: commit `0bbb6de84` added `scripts/generate_course_audio.py` and a successful course audio artifact; existing metadata records prior tier-3 OpenAI TTS and open-notebook fallback runs.
- Constraints: scope is `koenig-ai-org` runtime/vault tooling only; do not edit `learnovaBeast`, academy portals, or Convex deploy config. Current probes show `ffmpeg`, `ffprobe`, and `notebooklm-py` missing from `PATH`; `scripts/generate_course_audio.py` missing; open-notebook not listening on `localhost:5055`; `OPENAI_API_KEY` present. Base branch verified from current remote as `origin/HEAD -> master` and `refs/heads/master` exists.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Restore the tiered runtime with the smallest durable patch: expose required binaries, restore `scripts/generate_course_audio.py` from git history with light validation/inspection hooks, and use open-notebook only as an optional fallback service. This keeps the production path deterministic for KOEA-2257 because OpenAI TTS is already credentialed, while still preserving the primary `notebooklm-py` and fallback `open-notebook` contract for future Slide + Audio Producer runs.

**Rejected**: Make open-notebook the only path - it is not currently listening on `5055` and has more service state to debug before any artifact can be produced; install/use `notebooklm-py` only - primary quality is preferred but the CLI is currently absent and may require account/session setup outside this patch; generate one-off assets manually without restoring tooling - that would unblock only one chapter and leave the next producer run broken.

## Steps (Executor follows in order)
1. Verify runtime prerequisites from repo root: `command -v ffmpeg ffprobe notebooklm-py || true`, `test -n "$OPENAI_API_KEY"`, `curl -fsS http://localhost:5055/api/health || true`, and record the exact before/after state in the issue comment.
2. Install or expose `ffmpeg` and `ffprobe` in the local agent runtime using the machine-appropriate package source, then verify `ffmpeg -version` and `ffprobe -version`; if package install is not allowed, block with owner/action instead of faking audio inspection.
3. Restore `scripts/generate_course_audio.py` from `git show 0bbb6de84:scripts/generate_course_audio.py`, preserving the OpenAI TTS tier-3 behavior (`python3 scripts/generate_course_audio.py <chapter.md> <out_dir>`), and add only minimal hardening needed for current APIs, deterministic output paths, and clear errors.
4. Bring one higher-tier producer path online: prefer installing/configuring `notebooklm-py` if credentials are already available; otherwise start `observability/open-notebook/docker-compose.yml` with Docker Compose and verify `curl -fsS http://localhost:5055/api/health`. If neither is viable, document tier-3 OpenAI TTS as the accepted active fallback for this unblock.
5. Run a scoped artifact smoke using an existing vault chapter and isolated temp/output directory: create PPTX via the existing slide generator or current chapter slide command, create MP3 via `scripts/generate_course_audio.py`, then normalize the MP3 with `ffmpeg -af loudnorm=I=-16:LRA=11:tp=-1.5 -ar 44100 -ac 2`.
6. Inspect outputs before handoff: use `python3 - <<'PY'` with `pptx.Presentation` to print slide count and file size, and `ffprobe -v error -show_entries format=duration,bit_rate -of json <audio.mp3>` plus `stat -f%z` to prove nonzero `.pptx` and `.mp3` assets.
7. Update the relevant course sidecar metadata or issue comment with tool path used, fallback reason if applicable, output paths, sizes, slide count, audio duration/bitrate, rollback cleanup (`rm -rf` temp output and stop open-notebook only if Executor started it), then hand off to Code Reviewer/QA through the existing KOEA-2287 through KOEA-2290 chain.

## Verification (QA Verifier checks these)
- [ ] `ffmpeg -version` and `ffprobe -version` both succeed in the same runtime that runs the producer.
- [ ] `python3 scripts/generate_course_audio.py <chapter.md> <out_dir>` creates a nonzero MP3 and fails clearly when `OPENAI_API_KEY` is absent.
- [ ] A scoped PPTX smoke creates a nonzero `.pptx`; `pptx.Presentation(<file>).slides` reports at least one slide and no open error.
- [ ] `ffprobe` reports MP3 duration greater than 30 seconds, a valid bitrate, and no parse error after loudness normalization.
- [ ] Issue handoff records whether the active path was `notebooklm-py`, `open-notebook`, or tier-3 OpenAI TTS, with rollback/cleanup notes.

## Risk
- Restoring from the historical helper may use an older OpenAI SDK surface; mitigate by running the smoke immediately and limiting any compatibility edits to the helper, not course content or unrelated runtime code.

## Out of scope
- Portal publishing, Convex deploys, `learnovaBeast` changes, new course content writing, NotebookLM account recovery, and broad redesign of the Slide + Audio Producer workflow.
