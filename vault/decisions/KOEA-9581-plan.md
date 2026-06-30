---
ticket: KOEA-9581
planner: planner
date: 2026-06-30
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: academy/redesign-v1
preflight: vault_pull=true; basebranch_verified=true; chain_alert_cooldown=ee74600c-e3a5-44b3-b6b8-c804c08398c6
---

# Plan: Instrument five missing Academy funnel events

## Goal
Make the W27 Academy funnel events observable in PostHog for both `academy.koenig-solutions.com` and `academy.kspl.tech`. Success means the frontend emits `toc_approved`, `chapter_check_passed`, `certificate_claimed`, `certificate_shared`, and `certificate_linkedin_add` at user-journey touchpoints with course, chapter, host, and path context, without breaking the anonymous-by-default Academy model.

## Context
- Files to read first: `learnova-academy/src/lib/track.ts:1-10`, `learnova-academy/src/components/_shared/AnalyticsProvider.tsx:1-29`, `learnova-academy/src/app/layout.tsx:100-113`, `learnova-academy/src/components/CourseProgressSection.tsx:15-30`, `learnova-academy/src/components/CourseChapterList.tsx:20-50`, `learnova-academy/src/components/course/ChapterQuizGate.tsx:256-260`, `learnova-academy/src/components/_shared/share-rail.tsx:59-78`
- Relevant prior work: KOEA-9572 confirmed PostHog read access and found the five events have zero all-time records; KOEA-9581 is the engineering escalation for those missing events.
- Constraints: work in `learnovaBeast/learnova-academy` only, branch `academy/redesign-v1`; do not add auth, server certificate issuance, or PII; keep events client-side through the existing PostHog `track()` wrapper.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Host-aware client funnel instrumentation plus a small completion certificate panel. Extend the existing `track()` wrapper to attach `host` and `path`, emit `toc_approved` from the existing course chapter-list start/TOC surface, keep the current `chapter_check_passed` quiz-gate event while improving its props through the wrapper, and add a client-only course completion panel that handles certificate claim/share/LinkedIn clicks.

**Rejected**: Umami-only tracking via `AnalyticsClient` because the WBR reads PostHog HogQL; server-side certificate issuance because the Academy app is static and anonymous-by-default; instrumenting `analysis_completed`, `course_requested`, or `report_shared` because those are noted sparse events, not this ticket's five missing events.

## Steps (Executor follows in order)
1. Update `learnova-academy/src/lib/track.ts` so every PostHog capture merges non-PII defaults: `host`, `path`, and optionally `origin`, while preserving the defensive no-op behavior when PostHog is absent.
2. Add idempotent client event helpers in `learnova-academy/src/lib/track.ts` or a small sibling module, using localStorage keys scoped by course/event so `toc_approved` and `certificate_claimed` do not fire repeatedly on reload.
3. Instrument `learnova-academy/src/components/CourseChapterList.tsx` to fire `toc_approved` once per course when the learner starts from the generated chapter list, passing `course`, `chapter`, `total_chapters`, and `surface: "course_chapter_list"`.
4. Review `learnova-academy/src/components/course/ChapterQuizGate.tsx` and keep the existing `track("chapter_check_passed", ...)` at the real quiz-pass boundary; only adjust props if needed for consistent `chapter`, `total_chapters`, and `surface`.
5. Create a client component such as `learnova-academy/src/components/course/CourseCertificatePanel.tsx` that appears when all course chapters are complete, displays a lightweight verified-completion certificate card, and fires `certificate_claimed` when the certificate is generated/displayed by user action.
6. Wire the certificate panel from `learnova-academy/src/app/(site)/learn/[slug]/client-shell.tsx` and `page.tsx`, passing `slug`, `title`, and chapter count; use the existing inline `ShareRail` with `trackEvent="certificate_shared"` and add a LinkedIn add-to-profile link whose click handler fires `certificate_linkedin_add`.
7. Keep styles minimal in existing Academy CSS or component-local classes, preserving anonymous-by-default copy and avoiding any learner-name/email collection.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm typecheck && pnpm lint` passes.
- [ ] In a local browser with `window.posthog.capture` stubbed or PostHog env vars set, starting from the course chapter list emits `toc_approved` once with `host` and `path`.
- [ ] Passing a chapter quiz emits `chapter_check_passed` with course/chapter props and does not re-fire only because saved progress hydrates.
- [ ] Completing all chapters, claiming the certificate, sharing it, and clicking the LinkedIn add-to-profile link emit `certificate_claimed`, `certificate_shared`, and `certificate_linkedin_add`.
- [ ] Within 24h of deployment to both Academy hosts, HogQL can return non-zero rows for each of the five events grouped by host.

## Risk
- `toc_approved` is semantically weak because this app has no explicit auto-generated outline approval workflow; mitigate by treating the existing generated chapter list start action as the current approval touchpoint and keeping the event idempotent per course.

## Out of scope
- Adding authenticated learner certificates, persistent certificate IDs, learner names, backend issuance, PostHog dashboard changes, or instrumentation for the three sparse non-zero events.
