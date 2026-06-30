---
ticket: KOEA-7453
parent_ticket: KOEA-7345
planner: planner
date: 2026-06-10
estimated_complexity: small
estimated_token_cost: "$0.22"
base_branch: master
basebranch_verified: true
planned_against_branch: origin/master
planned_against_sha: 72edebe0f8fb05f5290e2777579df67fbbea9e4a
plan_artifact: vault/decisions/KOEA-7345-seo-google-scripts-plan.md
---

# Plan: Restore seo-google credential-check script

## Goal
Restore the minimum missing `seo-google/scripts/` artifact required for Search Visibility Optimizer to verify Google credentials after provisioning. Success means `/paperclip/.claude/skills/seo-google/scripts/google_auth.py --check --json` exists, runs without embedding secrets, and reports the configured credential tier from file/env inputs.

## Context
- Files to read first:
  - `/paperclip/.claude/skills/seo-google/SKILL.md:30-58` - credential check contract and tier definitions.
  - `/paperclip/.claude/skills/seo-google/SKILL.md:120-149` - GSC command references that depend on the same auth layer.
  - `/paperclip/.claude/skills/seo-google/references/auth-setup.md:82-134` - config path, verification command, and env var alternatives.
  - `/paperclip/.claude/skills/claude-seo/CLAUDE.md:43-45` and `/paperclip/.claude/skills/claude-seo/CLAUDE.md:84-100` - upstream bundle layout showing `seo-google/` as the skill and `scripts/google_auth.py` as the canonical execution script.
  - `/paperclip/.claude/skills/seo/scripts/google_auth.py:1-120` - local canonical source script already present in the broader `seo` bundle.
  - `/paperclip/.claude/skills/seo/requirements.txt:23-28` - Google Python dependency expectations.
- Relevant prior work: KOEA-7345 established that credentials are not provisioned yet and that `/paperclip/.claude/skills/seo-google/` has `SKILL.md`, templates, and references but no `scripts/` directory.
- Constraints: do not touch Google credentials, service-account JSON, OAuth tokens, API keys, or `~/.config/claude-seo/google-api.json`; do not invent a new auth contract; keep this to script restoration for the credential preflight only. Pre-flight branch check verified `origin/master` exists for the `koenig-ai-org` plan artifact.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Restore `google_auth.py` into `seo-google/scripts/` from the already-installed canonical source at `/paperclip/.claude/skills/seo/scripts/google_auth.py`. This is the smallest safe path because the source script already implements the tiered credential model described by `seo-google/SKILL.md`, supports config-file and environment-variable secrets, and was locally smoke-tested with `--check --json` to return structured "No credentials configured" output without needing any secret material.

**Rejected**: Copy every Google API script from `/paperclip/.claude/skills/seo/scripts/` now - it would touch many files and exceed the current unblock scope, which is only the SVO credential check. **Rejected**: Regenerate `google_auth.py` from references - unnecessary and riskier because a canonical implementation already exists locally. **Rejected**: Symlink `seo-google/scripts` to `seo/scripts` - less portable for skill packaging and could couple future `seo-google` updates to unrelated main `seo` scripts.

## Steps (Executor follows in order)
1. Confirm the current target still has no script with `test ! -e /paperclip/.claude/skills/seo-google/scripts/google_auth.py` and confirm the source exists with `test -f /paperclip/.claude/skills/seo/scripts/google_auth.py`.
2. Create `/paperclip/.claude/skills/seo-google/scripts/` and copy `/paperclip/.claude/skills/seo/scripts/google_auth.py` to `/paperclip/.claude/skills/seo-google/scripts/google_auth.py`, preserving executable mode if present and otherwise setting mode `0755`.
3. Do not create, edit, print, or validate any real secret file. If testing with no credentials, allow the script to report missing credentials; if credentials already exist, only report tier/service availability, not secret values or service-account JSON contents.
4. Run `python3 -m py_compile /paperclip/.claude/skills/seo-google/scripts/google_auth.py` to prove the restored script parses in place.
5. Run `python3 /paperclip/.claude/skills/seo-google/scripts/google_auth.py --check --json`; expected no-credential result is valid JSON with a missing-credentials tier, while post-provisioning success for KOEA-7345 is tier `>= 1` with GSC available.
6. Comment on KOEA-7453 and KOEA-7345 with the restored path, verification output summary, and the exact post-credential command for SVO: `python3 /paperclip/.claude/skills/seo-google/scripts/google_auth.py --check --json`.
7. Route through Plan-Reviewer first; after G_plan approval, Executor may perform the one-file restoration. If full `seo-google` command restoration is required later, request a separate ticket for the remaining scripts.

## Verification (QA Verifier checks these)
- [ ] `/paperclip/.claude/skills/seo-google/scripts/google_auth.py` exists and is executable.
- [ ] `python3 -m py_compile /paperclip/.claude/skills/seo-google/scripts/google_auth.py` passes.
- [ ] `python3 /paperclip/.claude/skills/seo-google/scripts/google_auth.py --check --json` emits parseable JSON and does not print credential material.
- [ ] With service-account credentials provisioned for KOEA-7345, the same command reports tier `>= 1` and `gsc.available == true`.

## Risk
- The canonical source may drift from the standalone `seo-google` skill if copied once and never tracked. Mitigation: document the source path in the issue comment and open a follow-up only if Chief Engineering wants the full Google script suite or a packaged skill-sync mechanism.

## Out of scope
- Creating or modifying Google Cloud projects, GSC permissions, GA4 property IDs, OAuth tokens, API keys, service-account JSON, or `~/.config/claude-seo/google-api.json`.
- Restoring every `seo-google` command script (`gsc_query.py`, `gsc_inspect.py`, `ga4_report.py`, PageSpeed/CrUX, YouTube, NLP, Keyword Planner).
- Changing Paperclip core, Learnova application code, SEO reporting logic, or SVO audit conclusions.

## Plan-Reviewer Handoff Checklist
- [ ] Confirm the one-file restore matches KOEA-7453's stated credential-check objective.
- [ ] Confirm the plan does not require secret creation, secret disclosure, or credential file edits.
- [ ] Confirm full `seo-google` command restoration is intentionally out of scope for this unblock ticket.
