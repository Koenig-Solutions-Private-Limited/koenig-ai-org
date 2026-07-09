---
ticket: KOEA-10675
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: master
basebranch_verified: true
chain_depth_approval: c26f4be7-55b6-4a0c-bee9-b2efc8dad929
plan_revision: 2
revised_after_review: KOEA-10680
---

# Plan: Repair NotebookLM runtime and nested chapter batch path

## Goal
Restore the approved NotebookLM batch lane so the Slide + Audio Producer can run the Pi agent chapter through the existing NotebookLM plus R2 upload pipeline. Success means `notebooklm --help` works in the producer runtime, `scripts/notebooklm-batch-chapters.sh pi-agent-setup-and-usage-2026 01-what-is-pi-agent` reads `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter.md`, and the upload script writes/updates the canonical nested `chapter-meta.json` without manual media files.

## Context
- Files to read first: `scripts/notebooklm-batch-chapters.sh:1-120`, `scripts/upload-chapter-assets.mjs:1-90`, `scripts/upload-chapter-assets.mjs:240-290`, `companies/learnova-academy/agents/slide-audio-producer/AGENTS.md:17-50`, `companies/learnova-academy/agents/slide-audio-producer/AGENTS.md:73-90`, `README.koenig.md:101-104`, `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter.md:1-90`.
- Current facts verified by Planner: `notebooklm --help` returns `command not found`; the batch script adds only `$HOME/.local/bin` to `PATH` and reads chapter markdown from `vault/courses/$COURSE/$CH.md`; the Pi chapter exists only at `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter.md`; the uploader already writes sidecars under `vault/courses/<course>/<chapter>/chapter-meta.json` but still derives headings and `source_file` from the old flat `<chapter>.md` path.
- CLI identity verified by Planner: the approved NotebookLM source in repo docs is `teng-lin/notebooklm-py` / PyPI package `notebooklm-py`; this runtime has Python package `notebooklm-py` version `0.4.1` installed under `/paperclip/.local/lib/python3.13/site-packages`, with console entry point `notebooklm = notebooklm.notebooklm_cli:main`, but `/paperclip/.local/bin/notebooklm` is missing from PATH.
- Shell fact verified by Plan Reviewer: `/bin/zsh` is missing in this runtime, so the current `#!/bin/zsh` script cannot execute as `scripts/notebooklm-batch-chapters.sh`; `bash -n scripts/notebooklm-batch-chapters.sh` succeeds, so a narrow bash shebang conversion is the lowest-risk shell remediation.
- Relevant prior work: `vault/decisions/koea-7075-plan.md` established `chapter-meta.json` as the slide metadata contract, and `vault/decisions/KOEA-7801-audio-toolchain-recovery-plan.md` recorded the same NotebookLM-first producer recovery lane.
- Constraints: preserve the NotebookLM-only production path for this repair; do not recommend manual or ad hoc vault media writes; keep changes in `koenig-ai-org`; base branch `origin/master` verified on 2026-07-09.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add nested chapter path resolution to the two existing producer scripts, restore the `teng-lin/notebooklm-py` CLI entry point in the producer runtime, and convert the batch script from a missing `/bin/zsh` shebang to portable bash. Executor should keep the shell batch as the orchestration entrypoint, introduce a small `chapter.md` vs legacy `<chapter>.md` resolver in `scripts/notebooklm-batch-chapters.sh`, mirror that resolver in `scripts/upload-chapter-assets.mjs` for heading extraction and `source_file`, and make the runtime use a persistent `/paperclip/.local/bin/notebooklm` binary backed by `notebooklm-py==0.4.1` before any batch run.

**Rejected**: Create a one-off Pi chapter media bundle by hand - violates the approved NotebookLM pipeline and would not repair future chapters; move the course back to flat markdown - churns content layout and sidecar conventions instead of fixing the tool; replace the batch path with Open-Notebook or OpenAI TTS fallback - lower fidelity and outside this ticket because Chief Engineering asked for NotebookLM CLI/runtime restoration.

## Steps (Executor follows in order)
1. Verify and restore the exact approved runtime CLI without editing vault media: from `koenig-ai-org`, run `python3 -m pip show notebooklm-py`, confirm version `0.4.1`, and confirm the console entry point with `python3 - <<'PY'` using `importlib.metadata` to print `notebooklm = notebooklm.notebooklm_cli:main`; if `command -v notebooklm` is missing, run `PYTHONUSERBASE=/paperclip/.local python3 -m pip install --user --force-reinstall 'notebooklm-py==0.4.1'`, then verify `command -v notebooklm` returns `/paperclip/.local/bin/notebooklm` and `notebooklm --help` exits 0. Run `notebooklm login` only if the verified CLI reports an auth/session blocker.
2. Update `scripts/notebooklm-batch-chapters.sh` with the narrow shell remediation: change the shebang from `#!/bin/zsh` to `#!/usr/bin/env bash`, keep the current bash-compatible arrays/associative arrays, set PATH to prefer `/paperclip/.local/bin:$HOME/.local/bin:$PATH`, then add a resolver that prefers `$VAULT/$CH/chapter.md` and falls back to `$VAULT/$CH.md`; use the resolved path for title extraction, `notebooklm source add`, frontmatter source URL extraction, and the final upload title.
3. Keep the batch output and upload contract unchanged: still call `node "$ROOT/scripts/upload-chapter-assets.mjs" --course "$COURSE" --chapter "$CH" --dir "$WORK/$CH" --notebook ... --title ...`; do not write large binaries into the vault except through the existing R2 upload and sidecar path.
4. Update `scripts/upload-chapter-assets.mjs` with the same nested-first chapter resolver; use it in `chapterH2Headings()` and set `source_file` to `vault/courses/<course>/<chapter>/chapter.md` when that file exists, preserving the legacy flat path fallback for older courses.
5. Run cheap checks before any real NotebookLM generation: `command -v bash`, `bash -n scripts/notebooklm-batch-chapters.sh`, `head -1 scripts/notebooklm-batch-chapters.sh` showing `#!/usr/bin/env bash`, `node --check scripts/upload-chapter-assets.mjs`, `test -f vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter.md`, `test ! -f vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent.md`, `python3 -m pip show notebooklm-py | grep -E '^Version: 0\\.4\\.1$'`, `command -v notebooklm`, and `notebooklm --help`.
6. Run the concrete unblock invocation for KOEA-10386: `scripts/notebooklm-batch-chapters.sh pi-agent-setup-and-usage-2026 01-what-is-pi-agent`; capture the batch log path, resulting notebook id, and `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter-meta.json` diff in the Executor handoff.
7. Hand off with evidence: Plan Reviewer approves this plan before execution; Code Reviewer reviews only the script/runtime diff and verification output; QA Verifier checks the generated nested `chapter-meta.json`, public R2 URLs, and absence of ad hoc vault media writes before KOEA-10386 is unblocked.

## Verification (QA Verifier checks these)
- [ ] `notebooklm --help` succeeds in the Slide + Audio Producer runtime with the same PATH that the batch script uses, and `python3 -m pip show notebooklm-py` reports version `0.4.1`.
- [ ] `bash -n scripts/notebooklm-batch-chapters.sh` and `node --check scripts/upload-chapter-assets.mjs` pass, and the batch script shebang is `#!/usr/bin/env bash`.
- [ ] The Pi chapter batch invocation uses `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter.md`, not a missing flat `.md` file.
- [ ] `vault/courses/pi-agent-setup-and-usage-2026/01-what-is-pi-agent/chapter-meta.json` exists after the run, has `source_file` pointing at the nested `chapter.md`, and contains NotebookLM/R2 asset URLs produced by `upload-chapter-assets.mjs`.
- [ ] KOEA-10386 receives the exact invocation, batch log location, notebook id, and QA evidence needed to resume or close its slide/audio work.

## Risk
- Runtime restoration may still require operator action if `/paperclip/.local/bin` is not writable, `notebooklm-py==0.4.1` cannot be reinstalled, or Google auth requires an interactive browser. Mitigation: keep KOEA-10675 blocked with the exact failing command (`PYTHONUSERBASE=/paperclip/.local python3 -m pip install --user --force-reinstall 'notebooklm-py==0.4.1'`, `notebooklm --help`, or `notebooklm login`), name the operator as unblock owner, and do not fall back to manual media generation.

## Out of scope
- Redesigning the Slide + Audio Producer workflow, changing Learnova frontend rendering, generating assets outside NotebookLM, broad course layout migration, or editing unrelated existing vault/course files.
