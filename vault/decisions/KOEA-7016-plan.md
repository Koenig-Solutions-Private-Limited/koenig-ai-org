---
ticket: KOEA-7016
planner: planner
date: 2026-07-09
estimated_complexity: medium
estimated_token_cost: $0.22
base_branch: academy/redesign-v1
basebranch_verified: true
worktree_recommendation: FE worktree
---

# Plan: Add chapter video metadata and conditional VideoObject JSON-LD

## Goal
Academy course chapter sidecars expose video metadata in the existing `chapter-meta.json` asset contract, and the course publish path emits schema.org `VideoObject` only for chapters with a usable `video_url`. Existing audio narration, slide deck PDFs, slide images, and same-origin legacy course media continue to resolve exactly as they do today.

## Context
- Files to read first: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts:21-126`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/seo.ts:46-113`, `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/learn/[slug]/page.tsx:104-153`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/upload-chapter-assets.mjs:188-296`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/notebooklm-batch-chapters.sh:54-125`, `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/academy-status-export.mjs:70-105`.
- Relevant prior work: `vault/decisions/KOEA-2462-plan.md` for course asset validation, `vault/decisions/koea-7075-plan.md` for extending `chapter-meta.json`, and current sidecars under `vault/courses/microsoft-advertising-bing-ads/*/chapter-meta.json` showing `assets.video_url` already exists in producer output.
- Constraints: implement against `learnovaBeast` production branch `academy/redesign-v1` (verified on origin); use the frontend/Academy worktree because no Convex/API migration is needed; do not bulk rewrite all existing sidecars; preserve `assets.audio_url`, `assets.slide_deck_url`, `slides`, and legacy flat media fallbacks.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Extend the current R2-backed sidecar contract and Academy static reader. Treat `assets.video_url?: string | null` as the canonical nullable video URL field because the upload script and existing 22 sidecars already use `assets.*`; add optional `assets.video_duration_seconds?: number` when duration is known, while allowing the reader to also accept `asset_metadata.video.duration_seconds` as a compatibility fallback. Thread those fields through `CourseChapter`, add a pure `VideoObject` JSON-LD helper in `src/lib/seo.ts`, and include one `VideoObject` per chapter in `/learn/[slug]` only when `video_url` is present.

**Rejected**: Add a Convex/database field - Academy course pages are built from vault files, and the ticket is about static `chapter-meta.json` publishing. **Rejected**: Add top-level `video_url` beside `assets.video_url` - that creates two competing manifests and fights the established `assets.*` contract. **Rejected**: Add video playback UI now - useful later, but not required for VideoObject schema activation and increases UX/testing scope.

## Steps (Executor follows in order)
1. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/courses.ts`, extend `CourseChapter` and `ChapterAssetUrls` with `video_url?: string`, `video_duration_seconds?: number`, and `video_upload_date?: string`; parse them from `chapter-meta.json` by reading `meta.assets.video_url`, `meta.assets.video_duration_seconds`, fallback `meta.asset_metadata.video.duration_seconds`, and `meta.generated_at`, while preserving the current fallback behavior on JSON parse failure.
2. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/lib/seo.ts`, add a `videoObjectLd` helper that returns a valid `VideoObject` with `contentUrl`, chapter/course `name`, `description`, `thumbnailUrl` from chapter infographic or `/api/og`, `uploadDate` from sidecar `generated_at` when available, `isAccessibleForFree: true`, and ISO-8601 `duration` only when `video_duration_seconds` is a positive integer.
3. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/src/app/learn/[slug]/page.tsx`, import the helper and append `course.chapters.filter((ch) => ch.video_url).map(...)` to the existing JSON-LD array; do not render VideoObject for chapters without `video_url`.
4. In `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/upload-chapter-assets.mjs`, when `video.mp4` is uploaded, populate `assets.video_url` as today and attempt to derive duration with `ffprobe` if available; write the integer to `assets.video_duration_seconds` and `asset_metadata.video.duration_seconds`, but continue uploading video without duration when `ffprobe` is missing or fails.
5. In `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/academy-status-export.mjs`, include `video_duration_seconds` in the chapter snapshot when present so publish/ops views can see whether duration was captured; keep the boolean `video` asset presence check unchanged.
6. Update `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/README.md` SEO table to list conditional `VideoObject` for lesson pages and document that it appears only when chapter sidecars provide `assets.video_url`.
7. Add a small fixture or script-level verification path using an existing sidecar with `assets.video_url` to confirm `getCourse()` exposes the video fields and the serialized `/learn/[slug]` JSON-LD includes `VideoObject`; prefer a focused Node/Next check over broad UI changes.

## Verification (QA Verifier checks these)
- [ ] `cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && npm run typecheck` passes after the `CourseChapter` and SEO helper changes.
- [ ] A course with an existing `assets.video_url` sidecar, such as `microsoft-advertising-bing-ads`, renders `/learn/<slug>` JSON-LD containing at least one `{"@type":"VideoObject"}` with `contentUrl` equal to the sidecar video URL.
- [ ] A course/chapter without `assets.video_url` emits no `VideoObject`, while existing `audio_url`, `slide_deck_url`, `slides_url`, and slide-image behavior remains unchanged.
- [ ] Running `node /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/scripts/upload-chapter-assets.mjs` against a temp artifact dir containing `video.mp4` preserves existing asset keys and adds duration only when `ffprobe` can determine it.

## Risk
- VideoObject rich-result eligibility can be rejected if `thumbnailUrl` or `uploadDate` is absent. Mitigation: source `thumbnailUrl` from the chapter infographic when available with `/api/og` fallback, source `uploadDate` from `chapter-meta.json.generated_at`, and omit only duration when unknown.

## Out of scope
- Backfilling all 78 existing `chapter-meta.json` files with explicit `null` video fields or computed durations; adding video playback UI; changing R2 bucket layout; touching Convex schemas, WorkOS auth, or non-Academy Learnova portals.
