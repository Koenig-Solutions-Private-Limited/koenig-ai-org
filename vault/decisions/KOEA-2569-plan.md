---
ticket: KOEA-2569
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.35
planned_against_repo: learnovaBeast
planned_against_branch: academy/redesign-v1
planned_against_sha: b17526bc9e1ff20a6e6a4027a9fc1f72c73b4314
base_branch: academy/redesign-v1
basebranch_verified: true
chain_authorized_by_approval: 30c17613-2fcc-45b4-a9ea-4ef4cba8f39b
files_touched:
  - learnova-academy/src/lib/courses.ts
  - learnova-academy/src/app/learn/[slug]/page.tsx
---

# Plan: Render course slide resources instead of empty disclosure panels

## Goal

Chapters with generated slide metadata should expose the deck on the real chapter page, not on phantom `*-meta.md` chapters, and the "More learning resources" disclosure should never expand to an empty region. Success is observable on `/learn/claude-tool-use-from-zero` chapter 8 and `/learn/gemini-enterprise-agents` chapter 6: the chapter remains the content markdown chapter, the disclosure contains a visible slides download/open control, and an iframe is present when an embeddable source exists.

## Context

- Files to read first: `learnova-academy/src/lib/courses.ts:91-149`, `learnova-academy/src/lib/courses.ts:199-211`, `learnova-academy/src/app/learn/[slug]/page.tsx:480-518`, `learnova-academy/src/app/learn/[slug]/page.tsx:891-974`, `learnova-academy/scripts/sync-vault.mjs:103-172`.
- Relevant prior work: [KOEA-2569](/KOEA/issues/KOEA-2569) reports empty disclosure regions for `claude-tool-use-from-zero` and `gemini-enterprise-agents`; [KOEA-2637](/KOEA/issues/KOEA-2637) is the planning phase; [30c17613](/KOEA/approvals/30c17613-2fcc-45b4-a9ea-4ef4cba8f39b) authorized the harness chain.
- Constraints: plan mode only; do not edit production code in this stage; use `academy/redesign-v1` as the FE base branch; current visible FE worktree is dirty on another branch, so Executor should branch from `origin/academy/redesign-v1` or a clean worktree.
- Diagnosis: `readCourseOutline()` currently includes any `^\d+-[a-z0-9-]+\.md$`, so files like `08-legal-connectors-meta.md` pass as chapters. `chapterAssetUrls()` reads `chapter-meta.json` and legacy flat media only; it does not parse adjacent `08-legal-connectors-meta.md` sidecars that hold `slide_file`. The UI then relies on iframe viewers without rendering an always-visible control first.

## Approach (1 chosen, alternatives rejected)

**Chosen**: parse `*-meta.md` sidecars into the real chapter asset model, exclude those sidecars from the chapter list, and make `ChapterBottomDeck` render visible resource controls before optional iframes. This is the smallest code path that fixes both observed courses: the data layer stops creating phantom meta chapters and attaches `chNN-slides.pptx` to `NN-title.md`, while the UI avoids an empty expanded disclosure even when Office/PDF iframe rendering is delayed or blocked.

**Rejected**: UI-only empty-state patch: hides the symptom but keeps phantom `*-meta.md` chapters and misses sidecar metadata. JSON-only manifest migration: cleaner long term, but requires changing vault producer output beyond this frontend ticket. Replace Office/PDF embeds with a new deck-rendering library: too broad, risky, and unnecessary when public `.pptx`/PDF URLs already exist.

## Steps (Executor follows in order)

1. Branch from the verified FE base without touching the dirty visible branch: `git fetch origin && git worktree add -b koea-2569-course-resources ../wt-koea-2569 origin/academy/redesign-v1`, then work in `../wt-koea-2569/learnova-academy`.
2. In `src/lib/courses.ts`, tighten `chapterFiles` so `*-meta.md` files are excluded from `Course.chapters`; keep numbered content markdown such as `08-legal-connectors.md`.
3. In `src/lib/courses.ts`, add a small sidecar parser for `${chapterPrefix}-meta.md` using `gray-matter`; if it contains `slide_file`, map the basename to `/courses/${courseSlug}/${basename}` only when the corresponding file exists in `courseDir`. Preserve existing priority: `chapter-meta.json` first, sidecar `*-meta.md` second, legacy `chNN-slides.pptx` scan third.
4. In `src/app/learn/[slug]/page.tsx`, update `ChapterBottomDeck` so the expanded disclosure always renders visible controls for each available asset before iframes: at minimum an "Open slides" external link and "Download .pptx" link for `slidesUrl`, plus "Open PDF" for `slideDeckUrl`. Keep iframes as progressive embeds below those controls.
5. In `src/app/learn/[slug]/page.tsx`, guard iframe rendering separately from the controls: render the disclosure only when at least one resource URL exists, but render a concise unavailable state if an expected iframe source cannot be constructed. Do not add audio into this bottom disclosure unless `audio_url` is already present; existing audio playback stays in `ChapterHeroBar`.
6. Run `pnpm --dir learnova-academy typecheck`. If the environment can run Next locally, also run `pnpm --dir learnova-academy build` after `sync-vault` completes; otherwise record why build was skipped.
7. Browser-verify the two reported pages: expand the disclosure on `/learn/claude-tool-use-from-zero#ch-8-legal-connectors` and `/learn/gemini-enterprise-agents#ch-6-observability`; confirm the region contains a visible slides control and at least one `iframe` or explicit non-iframe fallback link.

## Verification (QA Verifier checks these)

- [ ] `/learn/claude-tool-use-from-zero` no longer renders `08-legal-connectors-meta.md` as a separate/empty chapter, and chapter 8 has a visible slides control in the disclosure.
- [ ] `/learn/gemini-enterprise-agents` chapter 6 disclosure expands to visible content: slides link plus iframe when Office viewer source is constructible.
- [ ] DOM inspection after expansion finds `a[href$="ch08-slides.pptx"]` or `a[href$="ch06-slides.pptx"]`; if an iframe is blocked by the external viewer, the visible link remains usable.
- [ ] `pnpm --dir learnova-academy typecheck` passes.

## Risk

- Mapping sidecar `slide_file` paths too broadly could expose stale or missing decks. Mitigation: use only the basename under the same course directory and require `fileExists(join(courseDir, basename))` before returning a public URL.

## Out of scope

- Regenerating slides/audio, fixing stale deck content, changing NotebookLM producer output, or implementing first-party `.pptx` rendering.
- Removing every historical `*-meta.md` file from the vault; the frontend should simply ignore them as chapters and read them as sidecars where useful.
