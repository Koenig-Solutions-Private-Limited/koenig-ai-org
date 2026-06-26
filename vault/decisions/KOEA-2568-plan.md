---
ticket: KOEA-2568
planner: planner
date: 2026-05-14
estimated_complexity: medium
estimated_token_cost: $0.24
type: decision
tags:
  - decision
  - course/gemini-enterprise-agents
  - course/claude-tool-use-from-zero
base_branch: academy/redesign-v1
triggered_by_approval: 47db893a-f59c-4ed9-bf01-3186f14fa818
---

# Plan: Fix course-player sidecar chapters

## Goal
The Academy course player must render only usable course chapters, not `*-meta.md` production sidecars. Success means `/learn/gemini-enterprise-agents` and `/learn/claude-tool-use-from-zero` show no phantom sidecar chapters, no raw filename titles, no duplicate numbering caused by sidecars, no empty 0-minute sidecar sections, and chapter counts match the rendered usable chapter list.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:152-180`, `learnova-academy/src/lib/courses.ts:199-224`, `learnova-academy/src/app/learn/[slug]/page.tsx:90-102`, `learnova-academy/src/app/learn/[slug]/page.tsx:118-121`, `learnova-academy/src/app/learn/[slug]/page.tsx:184-188`, `learnova-academy/src/app/learn/[slug]/page.tsx:266-333`, `learnova-academy/src/app/learn/[slug]/page.tsx:394-401`, `learnova-academy/src/app/catalog/page.tsx:29-43`, `learnova-academy/src/app/llms-full.txt/route.ts:34-72`, `learnova-academy/scripts/sync-vault.mjs:103-172`.
- Relevant prior work: KOEA-2568 parent bug report; Chief Engineering comment `f8c7e117-a602-4804-abbd-b9d6bd431ac8` resolved the planner chain alert and confirmed the sibling phase gates are intentional.
- Constraints: Use `/paperclip/instances/default/workspaces/learnovaBeast-koea-2568`; branch `koea-2568/course-player-meta-sidecars`; PR base `academy/redesign-v1`; respect `.claude/agent-lock`; public website scope only, no Convex deploy and no student/sales/admin/tc portal changes.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Fix the course data contract in `learnova-academy/src/lib/courses.ts`. Add a small chapter-file predicate that accepts real numbered chapter markdown and excludes `*-meta.md` sidecars before `readChapter()` runs. Treat `*-meta.md` as production metadata sidecars, not content to merge into the chapter body; the existing asset path contract should remain `chapter-meta.json` nested sidecars plus legacy flat media files. Normalize the returned chapter contract so titles use frontmatter when present and otherwise use a humanized filename fallback, counts use `chapters.length` after filtering, and all UI/SEO/LLM routes receive the same corrected `Course.chapters` data.
**Rejected**: Patch only `src/app/learn/[slug]/page.tsx` to hide sidecars, because catalog, JSON-LD, llms-full, Nova grounding, and thumbnails would still see polluted loader data. **Rejected**: Rename or delete vault `*-meta.md` files, because they are valid slide/audio production records and the bug is in read semantics. **Rejected**: Parse and merge every `*-meta.md` into its parent chapter now, because current sidecars carry production metadata and no learner-facing chapter body; merging expands scope and risks confusing asset handling already served by `chapterAssetUrls()`.

## Steps (Executor follows in order)
1. In `/paperclip/instances/default/workspaces/learnovaBeast-koea-2568`, verify `.claude/agent-lock` still names KOEA-2568 and stay on `koea-2568/course-player-meta-sidecars`; stop blocked if the lock changes.
2. Update `learnova-academy/src/lib/courses.ts` to add explicit helpers such as `isChapterMarkdownFile(file)` and `chapterSlugFromFile(file)`, then replace the broad `^\d+-[a-z0-9-]+\.md$` filter so `NN-*-meta.md` sidecars are excluded while real `NN-*.md` chapters remain sorted by prefix.
3. In `readChapter()`, keep `chapter_num` derived from frontmatter or numeric filename, but normalize `title` so a missing frontmatter title cannot surface a raw `.md` filename; use a readable slug-derived fallback only after sidecars are excluded.
4. In `readCourseOutline()`, set `chapter_count` to the filtered `chapters.length` for the runtime contract, and only use outline/frontmatter counts for non-authoritative metadata if the Executor finds a separate display need. Do not change `total_duration_min` unless needed to keep existing course-level semantics stable.
5. Add a narrow regression check for the systemic case, preferably a no-network script or test under `learnova-academy` that loads the real vault courses and asserts `gemini-enterprise-agents`, `claude-tool-use-from-zero`, and one additional sidecar-bearing course contain no chapter whose slug/title ends in `-meta`, no raw `.md` titles, no duplicate chapter numbers, and `chapter_count === chapters.length`.
6. Run targeted verification from `learnova-academy`: the new regression check, `npm run typecheck`, and `npm run build` using the existing `prebuild` vault sync. If build is too slow in the worktree, at minimum run typecheck plus the regression check and report why build was skipped.
7. Browser-check the built/dev Academy app at `/learn/gemini-enterprise-agents` and `/learn/claude-tool-use-from-zero`, plus one additional sidecar-bearing course such as `/learn/production-agents-claude-agent-sdk-mcp-connector`, confirming the header badge, chapter index, floating TOC, rendered sections, duration chips, and obvious JSON-LD/llms-full chapter output all reflect filtered usable chapters.

## Verification (QA Verifier checks these)
- [ ] `/learn/gemini-enterprise-agents` shows 8 usable chapters, no `*-meta.md` entries, no duplicate 5/6/7/8 caused by sidecars, and no empty 0-minute sidecar section.
- [ ] `/learn/claude-tool-use-from-zero` shows real chapter titles for chapters 1-9, no `06/07/08/09-*-meta.md` phantom rows, and the header count matches the rendered chapter index.
- [ ] One additional sidecar-bearing course, for example `/learn/production-agents-claude-agent-sdk-mcp-connector`, passes the same no-sidecar/no-raw-filename/count-match checks.
- [ ] Targeted automated regression check passes and `npm run typecheck` passes in `learnova-academy`.

## Risk
- Filtering too broadly could hide legitimate chapter markdown whose title happens to end with `meta`; mitigate with a precise `/-meta\.md$/` exclusion on numbered chapter files and a regression check over current sidecar-bearing vault courses.

## Out of scope
- Do not edit course content, delete or rename vault sidecar files, deploy Convex, change non-Academy portals, or redesign the course player UI.

## Pre-flight
- `basebranch_verified=true` for `origin/academy/redesign-v1`.
- `agent_lock_verified=true` for KOEA-2568 at `/paperclip/instances/default/workspaces/learnovaBeast-koea-2568/.claude/agent-lock`.
- `planner_chain_alert_resolved=true` via Chief Engineering comment `f8c7e117-a602-4804-abbd-b9d6bd431ac8`; approval `47db893a-f59c-4ed9-bf01-3186f14fa818`.
