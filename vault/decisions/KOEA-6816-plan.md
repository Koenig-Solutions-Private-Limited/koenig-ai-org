---
ticket: KOEA-6816
planner_ticket: KOEA-6817
planner: planner
date: 2026-07-01
type: decision
tags:
  - decision
  - course/claude-mcp-mastery
  - slide-audio
estimated_complexity: small
estimated_token_cost: $0.55
base_branch: master
basebranch_verified: true
status: ready-for-plan-review
---

# Plan: Restore the Claude MCP Mastery chapter 1 audio path

## Goal
Restore one reliable audio-generation path so KOEA-5799 can finish the Claude MCP Mastery chapter 1 slide/audio task. Success is observable when `vault/courses/claude-mcp-mastery/ch01-audio.mp3` exists, parses as MP3 with positive duration, and the issue handoff names which tier produced it.

## Context
- Files to read first: `scripts/generate_course_audio.py:1-268`, `scripts/notebooklm-batch-chapters.sh:1-120`, `scripts/upload-chapter-assets.mjs:1-290`, `observability/open-notebook/docker-compose.yml:1-32`, `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer.md:1-120`, `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer-meta.md:1-8`, `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer/chapter-meta.json:1-29`.
- Relevant prior work: `vault/decisions/KOEA-7801-audio-toolchain-recovery-plan.md` used the same tiered model: NotebookLM first, Open-Notebook fallback, OpenAI TTS fallback. Current probes for KOEA-6817 found no `notebooklm`, `notebooklm-py`, `open-notebook`, `docker`, `ffmpeg`, or `ffprobe` on PATH; `OPENAI_API_KEY` is set; `curl http://localhost:5055/api/health` fails; `vault/courses/claude-mcp-mastery/ch01-slides.pptx` exists; `vault/courses/claude-mcp-mastery/ch01-audio.mp3` is missing.
- Constraints: Do not deploy Convex. Do not change Paperclip core packages. Keep this runtime-only unless a listed helper is broken. Do not push koenig-ai-org changes; publish-action owns vault sync. Preserve unrelated dirty vault files in the worktree.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Restore and use the tier-3 local OpenAI TTS fallback for this chapter, after installing or otherwise making `ffmpeg` and `ffprobe` available in the runtime. This is the smallest reliable unblock because `scripts/generate_course_audio.py` already exists, `OPENAI_API_KEY` is present, the target chapter source exists, and the required local artifact is a single MP3 file.

**Rejected**: Install/configure `notebooklm-py` first - higher quality, but currently no CLI is on PATH and account/session setup is slower and more brittle. Start Open-Notebook first - viable only if Docker is available, but current runtime has no `docker` binary and the service is not healthy on `:5055`. Patch the producer architecture - out of scope for a one-chapter unblock.

## Steps (Executor follows in order)
1. Re-run preflight probes from repo root and record them in the KOEA-6819/implementation issue comment: `git pull origin master --rebase=false`, `git status --short`, `command -v notebooklm notebooklm-py open-notebook docker ffmpeg ffprobe || true`, `curl -fsS --max-time 2 http://localhost:5055/api/health || true`, `test -n "$OPENAI_API_KEY"`, `test -s vault/courses/claude-mcp-mastery/ch01-slides.pptx`, and `test ! -e vault/courses/claude-mcp-mastery/ch01-audio.mp3`.
2. If NotebookLM is unexpectedly available and authenticated, run the narrow NotebookLM path for only chapter 1 with `scripts/notebooklm-batch-chapters.sh claude-mcp-mastery 01-use-mcp-as-the-creative-workflow-layer`, then download/copy the produced audio to `vault/courses/claude-mcp-mastery/ch01-audio.mp3` if the batch only populated the per-chapter sidecar.
3. If NotebookLM is unavailable but Open-Notebook is healthy or Docker is available, bring up `observability/open-notebook/docker-compose.yml`, verify `curl -fsS http://localhost:5055/api/health`, generate a podcast/audio artifact for `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer.md`, and save it as `vault/courses/claude-mcp-mastery/ch01-audio.mp3`.
4. If neither higher tier is available, restore the tier-3 prerequisite first: install or expose `ffmpeg` and `ffprobe` using the runtime package manager (`apt-get install -y ffmpeg` if permitted in this environment). If package installation is not permitted, block with `unblock_owner=operator` and `unblock_action=install ffmpeg/ffprobe or provide an equivalent runtime image`.
5. Run the tier-3 generator: `python3 scripts/generate_course_audio.py vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer.md vault/courses/claude-mcp-mastery --output-name ch01-audio.mp3`, then normalize only if `ffmpeg` is available and normalization does not overwrite the only good copy.
6. Update the legacy chapter meta file, not the course prose: set `assets_generated: true`, `tool: generate_course_audio.py (OpenAI TTS alloy)` or the tier actually used, and `produced_at: <UTC timestamp>` in `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer-meta.md`. Do not remove the existing per-chapter `chapter-meta.json` R2 URLs; there is no central `vault/_schemas/flashcards.schema.json` in this checkout, and flashcards are represented as optional `flashcards.json`/`flashcards_url` assets through `scripts/upload-chapter-assets.mjs`.
7. Complete the implementation issue with evidence and wake the original slide/audio task owner: include the tier used, exact command, `ls -lh vault/courses/claude-mcp-mastery/ch01-audio.mp3`, `file vault/courses/claude-mcp-mastery/ch01-audio.mp3`, `ffprobe -v error -show_entries format=duration,bit_rate -of json vault/courses/claude-mcp-mastery/ch01-audio.mp3`, and a note that KOEA-5799 can resume.

## Verification (QA Verifier checks these)
- [ ] `vault/courses/claude-mcp-mastery/ch01-audio.mp3` exists and is larger than 10 KB.
- [ ] `file vault/courses/claude-mcp-mastery/ch01-audio.mp3` reports MP3/MPEG audio.
- [ ] `ffprobe -v error -show_entries format=duration,bit_rate -of json vault/courses/claude-mcp-mastery/ch01-audio.mp3` returns a positive duration.
- [ ] `vault/courses/claude-mcp-mastery/01-use-mcp-as-the-creative-workflow-layer-meta.md` has `assets_generated: true`, a concrete `tool`, and a UTC `produced_at`.
- [ ] Executor comment names the tier used and states that KOEA-5799 can resume.

## Risk
- The tier-3 path depends on `OPENAI_API_KEY` quota and ffmpeg availability. Mitigation: Executor must probe both before generation and block with the exact missing prerequisite instead of editing helper code under pressure.

## Out of scope
- Regenerating chapter prose, regenerating slides, changing Learnova rendering, deploying Convex, redesigning the Slide + Audio Producer, and producing assets for later Claude MCP Mastery chapters.
