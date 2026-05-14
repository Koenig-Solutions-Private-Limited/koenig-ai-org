---
ticket: KOEA-323
planner_ticket: KOEA-1643
supersedes_planner_ticket: KOEA-1588
planner: planner
date: 2026-05-13
revision: 2
triggered_by_approval: b0a7f66b-6c1f-47fd-82b3-9174ddda8c27
estimated_complexity: medium
estimated_token_cost: $1.20 (Executor + Code Reviewer + QA combined)
tags: [tts, kokoro, openai-tts, course-audio, plan, koea-323]
---

# Plan: KOEA-323 — Kokoro/OpenAI TTS PR #4 review + cutover

## Goal

Land a clean, reviewable PR for the production TTS pipeline that powers Academy course chapter audio, with Kokoro as the preferred local provider and OpenAI tts-1-hd as the automatic fallback. PR #4 was closed unmerged on 2026-05-13 and remains **not mergeable** as source material because it carries 11 unrelated commits that conflict with master. Success = a fresh, scope-clean PR containing only the TTS feature (script + Docker service + .env.example + the 4 already-produced chapter-meta.json sidecars from commit `8eaf61ca`), plus a documented Kokoro-vs-OpenAI quality decision based on a real sample chapter without making fresh publish-lane vault writes.

## Context

**PR source artifact:** [koenig-ai-org#4](https://github.com/Koenig-Solutions-Private-Limited/koenig-ai-org/pull/4) — branch `koea-323/production-tts-kokoro`, opened 2026-05-02 and closed unmerged 2026-05-13. Still useful as source material only: 1,391 additions / 130 deletions / 32 files, 12 commits ahead of master.

**Revision 2 note (KOEA-1643):** PR #4 is now closed unmerged, but its head commit `8eaf61ca` is still the source artifact. The Executor must port/cherry-pick the TTS files before running any command that depends on `scripts/generate-chapter-audio.mjs` or the `kokoro` Docker service. Fresh writes to `vault/courses/**/chapter-meta.json` are **not** authorized for Executor in this plan; only porting the four existing sidecar files from `8eaf61ca` is authorized. Any new regenerated course metadata must be routed to the Slide+Audio Producer / publish-action lane.

**Files to read first (master, not PR):**
- `scripts/` (does NOT contain `generate-chapter-audio.mjs` — PR is the source of truth) → `git show 8eaf61ca:scripts/generate-chapter-audio.mjs`
- `infra/docker-compose.koenig.yml:73-220` — current services; PR adds `kokoro:` block at +207
- `.env.example` — PR adds CLOUDFLARE_R2_PUBLIC_URL / KOKORO_TTS_URL / TTS_VOICE; also DROPS the GSC_* block (scope leak)
- `vault/courses/mcp-from-first-principles-to-production/02-json-rpc-over-stdio/chapter-meta.json` etc. — already on PR branch; the FE consumes this exact format
- `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:95-150` — FE reads `chapter-meta.json` sidecar from R2 paths (this is already shipped; FE side is DONE)
- `companies/learnova-academy/skills/slide-audio-produce/SKILL.md` — canonical agent that owns chapter assets end-to-end (uses notebooklm-py → open-notebook); the PR's script is a complementary "audio-only" path
- `companies/learnova-academy/agents/_archive/voice-producer/SOUL.md` — archived agent that originally described Kokoro/OmniVoice usage

**PR-branch state (12 commits ahead of master, `git log master..pr-4-koea323`):**

| # | SHA | Subject | In-scope? |
|---|-----|---------|-----------|
| 1 | `3a585e04` | V3.6: durable Hermes + Cursor binaries; TS regression fix | ❌ OUT (Dockerfile/infra) |
| 2 | `3471669c` | V3.7: upgrade hermes-paperclip-adapter 0.2.0 → 0.3.0 | ❌ OUT (already in master as `0576bf6f`) |
| 3 | `690a9985` | KOEA-307: complete issue.metadata feature | ❌ OUT (DB migration + server) |
| 4 | `9dcd732e` | URGENT #67: structural fix for Claude OAuth token rotation drift | ❌ OUT (server/auth/recovery) |
| 5 | `41d8d114` | feat(hermes-local): add missing server exports | ❌ OUT (adapter) |
| 6 | `35e8e0ae` | feat(server): swap hermes-paperclip-adapter npm → workspace | ❌ OUT (already in master as `0576bf6f`) |
| 7 | `8c3baad8` | chore: pnpm-lock for hermes-local workspace swap | ❌ OUT |
| 8 | `a113150f` | V4: kill restart cascade — auth UUID guard + recovery burst breaker | ❌ OUT (server/recovery) |
| 9 | `5fa23fa8` | V4: bake Pi v0.72.0 + bind-mount ~/.pi | ❌ OUT (Dockerfile/infra) |
| 10 | `39df0c62` | V4: blogs-skip-G4 + Course Author glossary spec | ❌ OUT (policy/SOULs) |
| 11 | `f413a028` | fix(publish-action): read KOENIG_COMPANY_ID from .env.koenig | ❌ OUT (script) |
| 12 | `8eaf61ca` | **feat(tts): production Kokoro TTS pipeline (KOEA-323)** | ✅ **IN — only this commit** |

Commits 1–11 are unrelated, mostly already in master via different SHAs, and merging the PR as-is would diverge or reintroduce stale code. Only commit 12 (7 files, +602 / −0) is the actual KOEA-323 work.

**Prior work history on KOEA-323:**
- 2026-05-02: Original Planner paused mid-flight; Executor (Vardaan97) took over with V3 plan context, generated audio for ch02-05 via OpenAI fallback (Kokoro container was down at the time), and opened PR #4.
- All 5 R2 audio URLs (ch01-05) verified HTTP 200 on R2 at the time of PR open. Ch01 pre-existed via the notebooklm-py / open-notebook path.
- 2026-05-13 reactivation note: Cartesia dependency dropped (KOEA-1528 cancelled), so Kokoro vs. OpenAI is the only remaining decision.

**Constraints (must preserve):**
- No ElevenLabs (CLAUDE.md cardinal rule 2). PR complies.
- No Convex deploy except from `learnova-tc`. PR touches no Convex/learnovaBeast code, so this is N/A.
- No direct main merge — must be reviewed PR. PR mechanism already in place.
- Don't touch upstream paperclip files. The TTS commit only touches our customisation paths (`scripts/`, `infra/`, `.env.example`, `vault/courses/...`). Compliant.
- Slide+Audio Producer is the canonical end-to-end course-asset owner (master commit `4f300ad1`). The script must be positioned as a *complementary audio-only utility*, not a competing pipeline.

## Approach (1 chosen, alternatives rejected)

**Chosen — "Port first, probe second, no fresh vault metadata writes"**
PR #4 is already closed. Cherry-pick or manually port only `8eaf61ca` (the TTS feature commit) onto a fresh `koea-323/tts-pipeline-clean` branch off current `master` before running Kokoro or the generation script. Resolve the `.env.example` conflict by preserving the `GSC_*` block (which PR #4 accidentally deletes). Open a new PR for the clean branch. After the script and Docker service exist on the clean branch, spin Kokoro locally and produce one non-destructive sample chapter to settle the quality question. The Executor may commit the four `chapter-meta.json` files already present in `8eaf61ca`; the Executor must not regenerate and commit new `vault/courses/**/chapter-meta.json` content. If Kokoro quality is good and regenerated metadata is desired, route that publish mutation to Slide+Audio Producer / publish-action as follow-up work.

Why: PR #4 is impossible to clean review (1,391 LOC across 12 commits, 11 unrelated). Cherry-picking the one TTS commit gives the reviewer a focused 602-line diff. Doing it before any Kokoro/script probe fixes the original operation-order drift. Limiting vault writes to the already-produced sidecars keeps Executor inside this ticket's explicit scope while respecting the publish-action lane for fresh course metadata.

**Rejected — "Rebase PR #4 onto master and drop the 11 unrelated commits with `git rebase -i`"**
Equivalent end state, but operationally messier: the PR branch lacks signing/co-author boundaries on individual commits, and the chapter-meta.json files in commit 12 reference R2 URLs that were uploaded against an outdated config (R2 endpoint moved 2026-05-04 — needs spot-check). Easier to start from the feature commit on a fresh branch than to surgically rewrite history on a stale branch.

**Rejected — "Merge PR #4 as-is and follow up"**
The 11 unrelated commits would reintroduce already-fixed bugs (heap size, Docker image baking) and conflict with master changes (`0576bf6f` swap-hermes-adapter, `1ef79c77` bwrap fix). Almost certainly breaks the container build.

## Steps (Executor follows in order)

1. **Create the clean branch and port the TTS commit first.** From current `master`: `git checkout -b koea-323/tts-pipeline-clean master`; cherry-pick or manually restore only the seven files from `8eaf61ca`: `.env.example`, `infra/docker-compose.koenig.yml`, `scripts/generate-chapter-audio.mjs`, and the four MCP `chapter-meta.json` sidecars. Resolve `.env.example` by preserving the `GSC_SERVICE_ACCOUNT_JSON` / `GSC_SITE_URL` block and adding the TTS env section. Do not port any of PR #4's 11 unrelated commits.
2. **Verify R2 asset liveness from the ported sidecars.** After Step 1, read the five chapter audio URLs (ch01 existing + ch02-ch05 sidecars from the port) and run `curl -sI <url>`. If any URL is non-200, record it in the PR description and stop short of replacing metadata; fresh vault metadata changes are not authorized here.
3. **Spin up Kokoro from the clean branch and verify it serves.** With the ported `infra/docker-compose.koenig.yml` present, run `docker compose -f infra/docker-compose.koenig.yml up kokoro -d`; wait for image pull (~2 GB); `curl -s http://localhost:8888/v1/models` should return 200 with model list. If pull fails or container exits, mark Kokoro decision as "deferred — keep OpenAI primary" and document the blocker in the PR.
4. **Produce one non-destructive Kokoro sample.** With the ported script present, run `node scripts/generate-chapter-audio.mjs --course mcp-from-first-principles-to-production --chapter 2 --dry-run` first. If doing a real Kokoro sample, write to a temporary R2 key or local temp output that does **not** overwrite `audio.mp3` and does **not** update/commit `vault/courses/**/chapter-meta.json`. Play locally; compare to the OpenAI sample on the same chapter. Decision artifact: append a 2-line "Kokoro-vs-OpenAI" note to the new PR description.
5. **Commit only the authorized clean diff.** Commit the seven ported files from `8eaf61ca` plus conflict-resolution edits needed to preserve existing `.env.example` content. Do not commit regenerated ch02-ch05 metadata. If the Kokoro sample proves replacement audio should become canonical, create or request follow-up publish-lane work for Slide+Audio Producer / publish-action to regenerate and write course metadata.
6. **Open the new PR.** Title: `[KOEA-323] Production TTS — Kokoro primary + OpenAI fallback (clean port of PR #4)`. Body includes: link to closed PR #4, the Kokoro-vs-OpenAI decision note or deferral, all 5 R2 URLs with status/size/provider where available, the verification curl block from Step 2, and an explicit note that fresh `vault/courses/**/chapter-meta.json` generation is out of Executor scope. Push branch and open against `master`. Do not request auto-merge.

## Verification (QA Verifier checks these)

- [ ] **Diff hygiene.** New PR contains exactly 7 files: `.env.example`, `infra/docker-compose.koenig.yml`, `scripts/generate-chapter-audio.mjs`, and 4 ported `vault/courses/.../chapter-meta.json` sidecars from `8eaf61ca`. No Dockerfile, hermes-local, DB-migration, server, generated fresh vault metadata, or SOUL.md changes.
- [ ] **GSC env block preserved.** `grep -c GSC_ .env.example` ≥ 2 on the new branch.
- [ ] **All 5 chapter audio URLs return HTTP 200.** Curl each `audio_url` from the chapter-meta.json files; record bytes and content-type `audio/mpeg`.
- [ ] **Kokoro service starts.** `docker compose -f infra/docker-compose.koenig.yml up kokoro -d` then `curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/v1/models` returns 200 within 90s.
- [ ] **Script dry-run is non-destructive.** `node scripts/generate-chapter-audio.mjs --course mcp-from-first-principles-to-production --all --skip-existing --dry-run` exits 0, lists 5 chapters as "would generate" / "already set", and uploads nothing.
- [ ] **Fallback works without vault mutation.** Stop Kokoro container; re-run the script against a throwaway/temp output path; confirm the Kokoro-unavailable fallback log line and successful upload/output without committing a changed `chapter-meta.json`.
- [ ] **FE wires up.** On a Vercel preview build of `learnova-academy` (sibling repo), `academy.kspl.tech/learn/mcp-from-first-principles-to-production` shows the ▶ audio badge on all 5 chapters, and the audio player loads (5-second spot-check).
- [ ] **No ElevenLabs.** `grep -ri "eleven" scripts/generate-chapter-audio.mjs infra/docker-compose.koenig.yml .env.example` returns nothing.

## Code / security / dependency review points (Code Reviewer focus)

- **R2 SigV4 implementation** (`scripts/generate-chapter-audio.mjs:84-130`) is hand-rolled, not via `@aws-sdk/client-s3`. Check: canonical-headers ordering, payload sha256 inclusion, signed-headers list, AWS4 prefix on signing key. Reviewer should mentally walk through the canonical-request construction and compare against an AWS reference.
- **Secret handling.** OPENAI_API_KEY, R2 keys come from env — never logged. Confirm no `console.log` paths leak them. (Quick grep: `grep -n "console.log.*KEY\|console.log.*SECRET" scripts/generate-chapter-audio.mjs` should be empty.)
- **Kokoro auth.** Script sends `Authorization: Bearer kokoro` to Kokoro — that's the dummy token; kokoro-fastapi accepts any. OK for trusted localhost; flag if image is ever exposed beyond loopback.
- **Path injection.** `r2Key = courses/<courseSlug>/<chapterId>/audio.mp3` — chapterId comes from filename listing of trusted vault directory. Low risk but worth a sentence in the review.
- **No new npm dependencies.** Script uses node:fs, node:crypto, node:util, node:path, global fetch (Node 20+). Verify `pnpm-lock.yaml` is untouched on the clean branch.
- **Markdown stripping correctness** (`markdownToText` at `:148-187`). Edge case: fenced code blocks are stripped entirely — confirm this is intentional (chapter prose still reads correctly without code).
- **Chunk boundary at sentence end** — if no `[.!?] ` match found, falls back to last whitespace. Acceptable; flag if chapter has run-on prose.
- **Dependency: `ghcr.io/remsky/kokoro-fastapi-cpu:latest`.** Pin to a tag (release version) rather than `:latest` for reproducibility. Suggest fix in review.

## Cutover / rollback criteria

**Cutover (Kokoro becomes primary, OpenAI fallback):**
- Triggers automatically on merge. Container starts via `docker compose up`; script probes it first.
- Future chapter authoring runs will use Kokoro without code change.

**Rollback to OpenAI-primary:**
- Soft: set `KOKORO_TTS_URL=http://kokoro-disabled:9999` in `.env.koenig`. Probe fails fast; falls back to OpenAI. No code redeploy.
- Hard: comment out the `kokoro:` block in `infra/docker-compose.koenig.yml` and `docker compose up -d --remove-orphans`.

**Rollback to pre-PR state (chapter audio is unrecoverable):**
- `git revert <new-PR-merge-commit>`; FE will fall back from missing chapter-meta.json to the legacy flat layout (`/courses/<slug>/ch01-audio-v2.mp3`), which still serves ch01 from the existing public/ folder. Ch02-05 will stop showing the audio badge.

## Worktree ownership

- **Repo:** `koenig-ai-org` only. **No `learnovaBeast` changes required** — the FE consumer (`learnova-academy/src/lib/courses.ts`) already reads the `chapter-meta.json` sidecar format that this PR produces (shipped 2026-04-30). Flag this in the PR body so the reviewer doesn't go hunting for a sibling repo PR.
- **Lane / specialty:** BE / Infra / scripting. Not FE. Not Convex. The `learnova-tc` Convex-deploy guard rule does not apply here.
- **Executor assignment recommendation:** Executor agent (`paperclip-adapter-claude-local` or `codex-local`) with shell + docker access. Needs Docker daemon reachable, R2 + OpenAI env vars from `.env.koenig`. Estimated ~45 min of active work + 5–10 min waiting on Kokoro image pull.
- **Code Reviewer assignment:** the dedicated Code Reviewer agent (Sonnet 4.6) is appropriate; the review surface is small (one 476-line script + a Docker service block) but the SigV4 hand-roll deserves careful eyes.
- **QA Verifier assignment:** Haiku 4.5 QA agent for the 8 verification checks above; can run all of them via shell + curl, no UI automation needed.

## Estimated token / work budget

| Role | Tokens (est) | Wall time | $ (est) |
|------|--------------|-----------|---------|
| Executor (Sonnet 4.6 or DeepSeek V4 Pro) — Steps 1-7 incl. Docker probe + cherry-pick + new PR | ~120k in / ~20k out | 60-75 min (incl. Kokoro image pull) | $0.55 |
| Code Reviewer (Sonnet 4.6) — diff review (602 LOC) + SigV4 audit + PR comment | ~80k in / ~6k out | 15-20 min | $0.30 |
| QA Verifier (Haiku 4.5) — 8 verification checks | ~40k in / ~4k out | 10-15 min | $0.10 |
| **Total** | | **~90 min E2E** | **~$0.95** |

Within KOEA-323's "1-2 days, standard engineering cap" envelope.

## Risk

- **Kokoro image pull fails on Vardaan's box / VPS** (size ~2 GB, GHCR availability). Mitigation: script has working OpenAI fallback; Step 3 explicitly tolerates this and downgrades the cutover to "OpenAI primary + Kokoro deferred" without blocking the PR.
- **Kokoro audio quality is materially worse than OpenAI tts-1-hd "nova"** for technical-jargon-heavy MCP chapters. Mitigation: the Kokoro-vs-OpenAI A/B in Step 4 is non-destructive (temporary sample only, leaves canonical `audio.mp3` and committed `chapter-meta.json` untouched). If unacceptable, merge with OpenAI-as-primary in code and Kokoro as opt-in only.
- **R2 SigV4 hand-roll has a subtle bug.** Mitigation: Steps 1 + Verification check confirm the 5 already-uploaded URLs return 200 with correct MIME, which retroactively validates the implementation against R2's parser. If verification fails for the regenerated set, fall back to `@aws-sdk/client-s3` in a follow-up commit on the same branch (one-line dep add, ~30 LOC delta).
- **Fresh Kokoro regeneration belongs to the publish lane.** This plan authorizes Executor to port the existing four `chapter-meta.json` sidecars from `8eaf61ca` because they are already part of the scoped PR artifact. It does not authorize new regenerated vault/course metadata. Mitigation: route desired replacement audio + metadata through Slide+Audio Producer / publish-action follow-up work.

## Out of scope

- **Migrating `slide-audio-producer` skill** to call this script instead of notebooklm-py. The two pipelines coexist; slide-audio-producer still owns the full asset bundle; this script is the cheap audio-only path. Separate ticket if we ever want to unify.
- **The 11 unrelated PR #4 commits.** Almost all are already in master via different commits. Any genuinely missing work should be rediscovered through normal triage, not extracted from this PR. Filing follow-up issues for each is *not* this ticket's job.
- **Re-archiving the `_archive/voice-producer/` SOUL** to reflect the new Kokoro-as-script reality. Doc-only cleanup.
- **GSC env block restoration audit.** The PR drops GSC_SERVICE_ACCOUNT_JSON; we preserve it in Step 1. If KOEA-708's owner wants a separate "ensure GSC vars stay" ticket, that's their call.
- **Docker image pinning policy.** The `:latest` → tagged-version change for `kokoro-fastapi-cpu` will be flagged in review but is a one-line tightening, not a separate planning exercise.
- **Pricing / per-chapter cost accounting.** Already documented in the reactivation note ($0.015/1k chars OpenAI, $0 Kokoro). No re-derivation needed.
