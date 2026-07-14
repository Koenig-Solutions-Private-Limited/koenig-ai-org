---
ticket: KOEA-12995
planner: planner
date: 2026-07-14
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: academy/redesign-v1
basebranch_verified: true
---

# Plan: Fix 5 PostHog funnel events never firing (toc_approved / chapter_check_passed / cert*)

## Goal

All 5 events exist in the codebase and fire at the correct lifecycle point. The root causes
are (a) a `trackOnce` localStorage-poisoning bug that permanently suppresses events when
PostHog is not yet loaded on first interaction, (b) a missing `track()` call in the
quiz auto-pass path, and (c) zero quiz data in production courses which prevents
`chapter_check_passed` from ever firing. After the fixes, `toc_approved` and the 3
certificate events will reliably capture on every user's first interaction, and
`chapter_check_passed` will capture on auto-pass in addition to manual quiz completion.

## Context

- Files to read first:
  - `learnova-academy/src/lib/track.ts:15-40` — `track()` and `trackOnce()`
  - `learnova-academy/src/components/course/ChapterQuizGate.tsx:193-207` — auto-pass useEffect
  - `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:706-725` — quiz gate mounting condition
- Relevant prior work: KOEA-10164 confirmed PostHog query path + top-of-funnel events work.
- Constraints: All changes are contained to `learnova-academy/`; no schema/infra/auth surface.

## Root Cause Analysis (per event)

### `toc_approved` — RC1: trackOnce localStorage-poisoning
**File:** `src/lib/track.ts:34-35`

`trackOnce` calls `track()` (which silently no-ops when `window.posthog` is undefined) and
then UNCONDITIONALLY writes the dedup flag to localStorage. If a user clicks a TOC chapter
link before `AnalyticsProvider`'s `useEffect` sets `window.posthog`, the event is
permanently suppressed for that user+course combination on every future visit.

The component IS rendered: `CourseChapterList` is mounted via `CourseProgressSection`
(at `src/components/CourseProgressSection.tsx:29,36`) which is mounted in `page.tsx:366`.

### `chapter_check_passed` — RC2: No quiz data in any production course + RC3: auto-pass omits track()
**RC2 (primary):** `page.tsx:706` mounts `ChapterQuizGate` only when `ch.quiz || ch.quiz_url`.
Audit of vault/courses confirms NO course has `quiz:` frontmatter and NO quiz sidecar JSON
files exist. `ChapterQuizGate` NEVER renders → event can never fire.

**RC3 (secondary):** `ChapterQuizGate.tsx:200-206` — when a `quizUrl` fetch fails, the
effect calls `markQuizPassed()` + `setPassed(true)` WITHOUT calling `track()`. If courses
do gain quiz URLs but those URLs fail, the auto-pass path silently skips the event.

### `certificate_claimed` — RC1 (same trackOnce bug as toc_approved)
`CourseCertificatePanel.tsx:51` uses `trackOnce("certificate_claimed", slug, ...)` via
`handleClaim`. Same localStorage-poisoning applies: button click during a PostHog-unavailable
window poisons the flag, and `CourseCertificatePanel`'s own `useState` initializer
(line 39) reads the same key to skip showing the "Claim" button on future visits.

The panel itself IS correctly gated: it returns null until all chapter checkboxes are
manually checked (`allDone` at line 45-47). This is expected behavior, not a bug.

### `certificate_shared` / `certificate_linkedin_add` — dependent on certificate panel rendering
These fire via plain `track()` (not `trackOnce`), so no localStorage-poisoning. They
only fire inside the `claimed=true` branch of `CourseCertificatePanel` (lines 122-189)
which is unreachable until `handleClaim` succeeds. With RC1 poisoning `certificate_claimed`,
users who had a failed first claim never see the share UI. Fix RC1 → fixes these downstream.

## Approach

**Chosen: Fix `trackOnce` to gate localStorage write on PostHog availability + add RC3 track() call**

Change `track()` return type from `void` to `boolean` (returns `true` when PostHog captured,
`false` when not available). Change `trackOnce()` to only write localStorage when `track()`
returns `true`. Add `track()` call in `ChapterQuizGate` auto-pass effect. These are minimal,
self-contained fixes with zero risk of breaking existing event callers.

**Rejected alt: Replace trackOnce with a server-side dedup log** — over-engineering; the
only issue is the race window, not the dedup concept itself.

**Rejected alt: Switch persistence from "memory" to "localStorage"** — would break the
anonymous-by-default promise (CLAUDE.md §7). Not in scope.

**Note on RC2 (no quiz data):** Adding quiz questions to course frontmatter is a content
operation, not a code fix. Out of scope for this PR. The code fix (RC3) ensures the event
fires at minimum when the auto-pass path triggers.

## Steps (Executor follows in order)

1. **`learnova-academy/src/lib/track.ts`** — change `track()` signature to return `boolean`:
   - After the existing `try` block entry, if `ph` is nullish, return `false` (no capture).
   - After the `ph.capture()` call, return `true`.
   - In the `catch` block, return `false` (unchanged behavior, just typed).

2. **`learnova-academy/src/lib/track.ts`** — fix `trackOnce()` to gate localStorage write:
   - Replace `track(event, props)` call with `const fired = track(event, props)`.
   - Change `localStorage.setItem(lsKey, "1")` to be conditional: `if (fired) localStorage.setItem(lsKey, "1")`.
   - Change return values: `return fired` (was `return true`); catch block unchanged (`return false`).

3. **`learnova-academy/src/components/course/ChapterQuizGate.tsx`** — add `track()` to auto-pass effect:
   - In the `useEffect` at lines 200-206, after `markQuizPassed(...)` and `setPassed(true)`,
     add: `track("chapter_check_passed", { course: courseSlug, chapter: chapterNum, total_chapters: totalChapters, score: "auto/0", surface: "chapter_quiz_gate" });`
   - `track` is already imported at line 18.

4. **Verify** no TypeScript errors introduced:
   - `track()` returning `boolean` is a non-breaking widening of the return type; all
     call sites that ignore the return value continue to work. `trackOnce()` consuming it
     is the only new reference.

5. **Manual smoke-test** (Executor): Open a course page, open DevTools console, confirm
   `window.posthog` exists after page load, click a TOC chapter link, and verify in PostHog
   Live Events that `toc_approved` appears. Clear localStorage key
   `tracked-once:toc_approved:<slug>` and repeat to confirm event fires again.

## Verification (QA Verifier checks these)

- [ ] `track()` returns `false` when `window.posthog` is undefined (verifiable by temporarily
  removing `window.posthog` in console before firing a TOC click)
- [ ] `trackOnce()` does NOT write to localStorage when `track()` returns `false`
  (verify: check localStorage before/after clicking TOC link with PostHog blocked)
- [ ] `trackOnce()` DOES write to localStorage when `track()` returns `true`
  (verify: confirm key is set after a successful TOC click)
- [ ] `chapter_check_passed` fires with `score: "auto/0"` when quiz load fails
  (simulate by passing an invalid `quizUrl` to `ChapterQuizGate` in dev)
- [ ] TypeScript build: `pnpm tsc --noEmit` passes in `learnova-academy/`

## Risk

- **trackOnce behavioral change**: Existing users whose localStorage has a poisoned
  `tracked-once:toc_approved:<slug>` key will NOT see a re-fire — the key persists.
  New users get the correct behavior immediately. Old poisoned keys self-expire when
  users clear localStorage or use a new device. Mitigation: this is acceptable
  (PostHog n=0 is worse than a one-time re-fire for a small cohort).

## Out of scope

- Adding quiz questions to course frontmatter (content operation; opens `chapter_check_passed`
  pipeline but is tracked separately).
- Changing `persistence: "memory"` (breaks anonymous-by-default guarantee).
- Investigating why no users have completed all chapters (product/UX question, not code bug).
- `posthog.identify()` — intentionally absent per anonymous-by-default policy.
