---
ticket: KOEA-7097
planning_ticket: KOEA-7122
revision_ticket: KOEA-7542
review_ticket: KOEA-7123
planner: planner
agent: planner
date: 2026-06-10
type: decision
tags:
  - decision
estimated_complexity: medium
estimated_token_cost: $0.20
base_branch: academy/redesign-v1
implementation_branch: koea-7097/kokoro-blog-audio
basebranch_verified: true
---

# Plan: Kokoro Audio for Academy Blog Posts

## Goal
Add a deterministic publish-time audio path for Academy blog posts so blogs in the explicit audio-ready status set have Kokoro-generated MP3s in R2 and render a working audio player. Success means the frontend never shows a dead player: it renders only from a generated success manifest, while Kokoro generation remains local/free, idempotent, retryable, and outside Convex/Vercel build steps.

## Context
- Files to read first: `learnova-academy/package.json:1-33`, `learnova-academy/src/lib/vault.ts:1-230`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:75-184`, `learnova-academy/src/app/(site)/blog/[slug]/page.tsx:199-725`, `learnova-academy/scripts/sync-vault.mjs:1-180`, `learnova-admin/src/lib/r2/client.ts:8-45`, `learnova-admin/src/lib/r2/client.ts:213-220`.
- Relevant prior work: course pages already render native audio controls and AudioObject schema when chapter `audio_url` exists; `sync-vault.mjs` already uses `KOENIG_VAULT_ROOT` with a local fallback to make the separate `koenig-ai-org/vault` checkout available; Plan-Reviewer feedback on KOEA-7123 requested this revision because the prior plan hardcoded `vault/blogs/<slug>/draft.md`, mixed publishable status sets, and did not define failed-generation behavior.
- Constraints: implement only in `learnova-academy` unless Executor proves an external child handoff is required; base from `origin/academy/redesign-v1`; use the reserved FE workspace `/paperclip/instances/default/workspaces/learnovaBeast-KOEA-7003` if available; do not deploy Convex; do not run TTS inside Vercel/Next build because generation mutates R2 and needs native/runtime dependencies; keep R2 MP3 keys under `courses/blogs/<slug>/audio.mp3`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a script-driven Academy blog-audio pipeline plus a manifest-gated client player. Executor should add local-only tooling under `learnova-academy/scripts/blog-audio/` that resolves blog markdown through the same `KOENIG_VAULT_ROOT` contract as `src/lib/vault.ts`, reads a single shared audio policy allowlist, generates/uploads Kokoro MP3s, and writes a success manifest. The frontend should render the player only when the post status is in the same allowlist and the slug has a manifest entry produced after a successful R2 upload or verified matching `HeadObject`.

**Rejected**: Put generation in `prebuild` or `sync-vault.mjs` - Vercel builds should not require Kokoro/espeak/ffmpeg or mutate R2. Store audio metadata in every blog frontmatter file - this creates vault churn and still needs a readiness source. Derive player URLs directly from slug - deterministic URLs alone can ship broken players when generation or upload fails.

## Steps (Executor follows in order)
1. Create a clean branch/worktree for `learnovaBeast` from `origin/academy/redesign-v1` named `koea-7097/kokoro-blog-audio`, using the reserved workspace path if available; preserve unrelated dirty files in the default checkout.
2. Add `learnova-academy/blog-audio.config.json` with one exact audio eligibility allowlist, initially `["g0-passed", "g3-passed", "published"]`, and import/read it from both script code and frontend/build-time helpers; do not treat `draft-for-review`, `awaiting-g0`, `g*-approved`, or `g*-revision` as audio-ready unless Chief Engineering expands this config in a later ticket.
3. In `learnova-academy/scripts/blog-audio/`, implement a vault-source helper that resolves `VAULT_ROOT` as `process.env.KOENIG_VAULT_ROOT ?? "/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault"` and reads each blog from `join(VAULT_ROOT, "blogs", slug, "draft.md")` with `index.md` fallback, matching `src/lib/vault.ts`; the cleaner must parse frontmatter with `gray-matter`, require the shared audio-ready status allowlist, drop the duplicate H1, code fences including mermaid, HTML/MDX component blocks, sources/references/navigation sections, citation markers, raw URLs, and image syntax, then collapse whitespace into sentence-friendly text.
4. In `generate-blog-audio.mjs` and a small Python helper if needed, generate audio locally with Kokoro, concatenate chunks, transcode to MP3 with `ffmpeg`, and fail with actionable prerequisite messages for missing `python`, `kokoro>=0.9.2`, `soundfile`, `espeak-ng`, or `ffmpeg`; compute `sha256(cleanText + voice + generatorVersion)` before generation.
5. Add R2 upload and manifest support using `@aws-sdk/client-s3` configured from `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_R2_ACCESS_KEY_ID`, `CLOUDFLARE_R2_SECRET_ACCESS_KEY`, `CLOUDFLARE_R2_BUCKET_NAME`, and `CLOUDFLARE_R2_PUBLIC_DOMAIN`; `HeadObject` `courses/blogs/<slug>/audio.mp3` and skip when object metadata hash matches unless `--force`, otherwise upload with `Content-Type: audio/mpeg` plus metadata for source hash, voice, duration seconds, generator, and generated-at; after each success, write/update `learnova-academy/public/blog-audio-manifest.json` with `{ slug, status, url, key, hash, durationSeconds, generatedAt }`.
6. Define the failure-state contract in scripts and docs: batch backfill continues through all eligible slugs, records failed slugs, omits failed slugs from `public/blog-audio-manifest.json`, and exits non-zero if any eligible slug failed; add `pnpm audio:blog:verify-manifest` to fail when any slug in the shared allowlist lacks a manifest entry or when a manifest entry status is outside the allowlist. Merge remains blocked until the backfill and verify-manifest commands pass, and the frontend must still hide players for missing manifest entries.
7. Update `learnova-academy/package.json` with narrowly named commands such as `audio:blog`, `audio:blog:backfill`, and `audio:blog:verify-manifest`; add `src/components/BlogAudioPlayer.tsx` as a client component with native controls, localStorage resume key `blog-audio:${slug}:position`, near-ended clearing, and optional 1x/1.25x/1.5x rate buttons; in `src/lib/vault.ts`/`blog/[slug]/page.tsx`, expose audio data only when both the post status is in `blog-audio.config.json` and the manifest has that slug, then render the player immediately after the byline and before learning objectives/body.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm audio:blog -- --slug 2026-05-12-ai-agent-observability-langfuse --dry-run` reads the blog through `KOENIG_VAULT_ROOT`, prints the cleaned text character count, prints target key `courses/blogs/2026-05-12-ai-agent-observability-langfuse/audio.mp3`, and does not upload.
- [ ] With R2 env and local Kokoro tools configured, `pnpm audio:blog:backfill` uploads or skips every blog whose frontmatter status is exactly `g0-passed`, `g3-passed`, or `published`; a second run skips unchanged objects by matching metadata hash, and `--force --slug <slug>` regenerates one slug.
- [ ] `pnpm audio:blog:verify-manifest` passes only when every shared-allowlist slug has a `public/blog-audio-manifest.json` entry with a matching allowlisted status and public URL; intentionally removing one manifest entry makes the command fail.
- [ ] `pnpm typecheck` and `pnpm build` pass from `learnova-academy`; `curl -I "$PUBLIC_AUDIO_URL"` for at least one manifest entry returns `200` and `content-type: audio/mpeg`.
- [ ] A local Academy blog with a manifest entry renders the audio player between byline and article body, plays the R2 MP3, supports resume after reload, and does not render the player for a public blog whose status is outside the audio allowlist or whose slug is absent from the manifest.

## Risk
- Kokoro native dependencies may not be present on Executor/CI machines; mitigate by keeping generation script-only/local-only with actionable prerequisite failures and keeping Next typecheck/build independent of Kokoro.
- The shared audio allowlist intentionally excludes some statuses that `listPublishableBlogs()` currently renders; mitigate by gating player visibility and backfill eligibility on the same config so excluded statuses render as normal text blogs without dead players.
- Rollback: revert the Academy PR to remove the player, scripts, config, and manifest; leave R2 objects in place because they are inert public assets, or delete `courses/blogs/*/audio.mp3` with an R2 bulk delete only if Chief Engineering asks for storage cleanup.

## Out of scope
- No Convex deployment or schema work, no `learnova-tc` changes, no course/chapter audio cleanup, no ElevenLabs/OpenAI fallback, no podcast/audio overview UX, and no automatic Slide+Audio Producer implementation in this PR. Future publish automation should be a child handoff for Slide+Audio Producer or publish-action to run `pnpm audio:blog -- --slug <slug>` after G0 approval and before marking the blog audio-ready.

## Pre-flight Footer
- `koenig-ai-org` vault sync: `git pull origin master --rebase=false` passed on 2026-06-10.
- Ticket preflight: KOEA-7542 status `in_progress`, assigned to Planner; active sibling count excluding KOEA-7542 is 1; ancestor chain depth is 2 (`KOEA-7542` under `KOEA-7097`); ticket body contains three required revision criteria.
- `learnovaBeast` base branch check: `git ls-remote --heads origin academy/redesign-v1` returned `dc2da825b34f62530fed16249218b4744d198b64`.
- `basebranch_verified=true`
