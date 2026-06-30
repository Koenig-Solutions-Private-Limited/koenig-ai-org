---
ticket: KOEA-7102
planner_ticket: KOEA-7114
planner: planner
date: 2026-06-02
estimated_complexity: medium
estimated_token_cost: $0.42
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: 5635bcc3-027b-44fe-8c0a-c34226c0637f
---

# Plan: Wire privacy-first Academy analytics

## Goal
Replace the current mixed analytics stack with a single privacy-first, self-hosted analytics path for `academy.kspl.tech`. Success means the Academy records pageviews, referrers, bounce/session-duration proxies, scroll-depth milestones, dwell-time milestones, and key conversion events, with a dashboard at `analytics.kspl.tech` and daily metrics written to `vault/marketing/analytics/YYYY-MM-DD.md`.

## Context
- Files to read first: `learnova-academy/src/app/layout.tsx:77-116`, `learnova-academy/src/app/(site)/privacy/page.tsx:60-75`, `learnova-academy/src/components/_shared/blog-scroll.tsx:42-51`, `learnova-academy/src/components/_shared/tutor.tsx:140-224`, `learnova-academy/src/components/_shared/DigestOptIn.tsx:15-30`, `learnova-academy/src/lib/course-progress.ts:101-115`, `scripts/ga4-daily-pull.mjs:1-213`, `vault/marketing/gsc/2026-06-01.md:1-151`.
- Relevant prior work: KOEA-7102 parent scope; chain-alert approval `5635bcc3-027b-44fe-8c0a-c34226c0637f`; existing `scripts/ga4-daily-pull.mjs` already models the daily vault report shape; GSC report writes to `vault/marketing/gsc/YYYY-MM-DD.md`.
- Constraints: target `learnovaBeast` branch `academy/redesign-v1`; do not merge to main; do not deploy Convex; shared Learnova checkout currently has a stale `.claude/agent-lock` for KOEA-1977, so Executor must create/update the correct lock before branch edits.
- Provider facts checked against official docs: Umami supports Docker/Postgres install, no-cookie privacy posture, tracker script install through `next/script`, custom events via data attributes or `umami.track`, and API endpoints for website stats/events/sessions/reports. Plausible has polished stats and native `scroll_depth`, but self-hosting is a heavier operational surface for this "fastest reliable ship" task.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Self-host Umami and centralize Academy instrumentation in one client component. Add an Umami Docker/Postgres compose file, inject the tracker from the root layout, remove GA4/Vercel/Clarity from the page shell, and add a small client component that records scroll milestones, dwell milestones, delegated CTA clicks, tutor opens/posts, digest subscribe success, and course-progress updates without storing email, user identity, IP-derived IDs, or raw prompt text.

**Rejected**: Plausible self-hosted because it is more polished and has strong stats APIs, but the Docker stack is heavier than Umami for this phase. GA4/Clarity continuation is rejected because the ticket asks for "no GA4 if possible" and a privacy-first replacement. Vercel Analytics-only is rejected because it does not cover the requested conversion/event/reporting surface.

## Implementation Files
- `infra/docker-compose.analytics.yml` — new Umami + Postgres service, persistent volumes, health checks, and environment placeholders for `APP_SECRET`, `DATABASE_URL`, and public origin.
- `learnova-academy/src/app/layout.tsx` — remove `@vercel/analytics`, GA4, and Clarity scripts; mount the new analytics client only when `NEXT_PUBLIC_UMAMI_WEBSITE_ID` and `NEXT_PUBLIC_UMAMI_SRC` are present.
- `learnova-academy/src/components/_shared/AnalyticsClient.tsx` — new `"use client"` component for Umami script loading plus scroll/dwell/delegated conversion events.
- `learnova-academy/src/app/(site)/privacy/page.tsx` — update the analytics section to describe self-hosted Umami and remove GA4/Vercel/Clarity references.
- `scripts/umami-daily-pull.mjs` — new vault-side pull script that authenticates to Umami, fetches summary/page/referrer/event metrics, and writes `vault/marketing/analytics/YYYY-MM-DD.md`.

## Event Taxonomy
Use lowercase snake_case event names and non-PII properties only.

| Event | Trigger | Properties |
|---|---|---|
| `scroll_depth` | first reach of 25/50/75/90% on content pages | `path`, `depth` |
| `dwell_time` | first reach of 30/60/120 seconds active time | `path`, `seconds` |
| `catalog_open` | links to `/catalog` | `source_path` |
| `course_start` | links to `/learn/*` or `/courses/*` | `source_path`, `target_path` |
| `tutor_open` | Nova FAB or `/tutor` CTA | `source_path` |
| `tutor_message_sent` | successful `/api/tutor` POST starts | `source_path`, `surface` |
| `digest_subscribe_success` | `/api/digest/subscribe` returns 2xx | `source_path` |
| `course_progress_update` | `course-progress-updated` event | `source_path`, `course_slug` |
| `share_click` | share/copy rail actions | `source_path`, `channel` |

## Steps (Executor follows in order)
1. Prepare `learnovaBeast` safely: pull `origin academy/redesign-v1`, create a feature branch from `origin/academy/redesign-v1`, and replace `.claude/agent-lock` with KOEA-7116/Executor ownership before editing.
2. Add `infra/docker-compose.analytics.yml` for Umami + Postgres and document required runtime env values inline as comments; do not touch Convex or other portals.
3. Add `learnova-academy/src/components/_shared/AnalyticsClient.tsx` with Umami script loading, `window.umami` type guard, scroll/dwell milestones, delegated click tracking, fetch-success tracking for `/api/tutor` and `/api/digest/subscribe`, and `course-progress-updated` tracking.
4. Update `learnova-academy/src/app/layout.tsx` to remove Vercel Analytics, GA4, and Clarity, then mount `AnalyticsClient` behind `NEXT_PUBLIC_UMAMI_SRC`, `NEXT_PUBLIC_UMAMI_WEBSITE_ID`, and optional `NEXT_PUBLIC_UMAMI_HOST_URL`.
5. Update `learnova-academy/src/app/(site)/privacy/page.tsx` so the public privacy notice matches the new self-hosted Umami-only analytics behavior.
6. Add `scripts/umami-daily-pull.mjs` in `koenig-ai-org` mirroring the GA4 report style: env `UMAMI_BASE_URL`, `UMAMI_API_KEY`, `UMAMI_WEBSITE_ID`, optional `KOENIG_AI_ORG_ROOT`, output `vault/marketing/analytics/<date>.md`, and include summary, top pages, top referrers, scroll/dwell/conversion event counts.
7. Verify locally and with browser walkthrough: build Academy, run the site with env values against a staging Umami instance, confirm `/api/send` or event network requests fire for pageview/scroll/dwell/tutor/digest/course-start, run the daily pull script, and smoke-check `analytics.kspl.tech` dashboard access.

## Verification (QA Verifier checks these)
- [ ] `cd learnova-academy && pnpm typecheck && pnpm build` passes on the feature branch.
- [ ] Browser walkthrough on `/`, `/catalog`, `/blog/<slug>`, `/learn/<slug>`, and `/tutor` shows Umami pageviews and no GA4, Clarity, or Vercel Analytics network requests.
- [ ] Scroll to 25/50/75/90% on a blog or course page and confirm exactly one `scroll_depth` event per milestone.
- [ ] Stay active for 30 seconds and confirm a `dwell_time` event without prompt/email/user-identifying data.
- [ ] Open Nova, send one tutor message, start a course, and submit a digest signup in staging; confirm the corresponding event names and safe properties in Umami.
- [ ] `node scripts/umami-daily-pull.mjs` writes `vault/marketing/analytics/<date>.md` with summary, top pages, referrers, and event counts.
- [ ] Rollback check: removing `NEXT_PUBLIC_UMAMI_WEBSITE_ID` disables client analytics cleanly while the site still builds and renders.

## Risk
- Umami's built-in dashboard covers bounce, duration, referrers, and events, but scroll depth is a custom-event approximation rather than a native averaged metric. Mitigation: track first-hit milestones and have the daily report calculate milestone counts/rates by page.
- Fetch wrapping for tutor/digest conversion detection can be brittle if routes change. Mitigation: scope the wrapper narrowly to exact path prefixes and include a QA check for both routes.
- Removing GA4/Clarity/Vercel means old dashboards stop receiving data immediately. Mitigation: keep rollback env-gated and preserve this as an intentional replacement, not a silent parallel install.

## Rollback
Unset `NEXT_PUBLIC_UMAMI_WEBSITE_ID` and `NEXT_PUBLIC_UMAMI_SRC` in Vercel to disable client tracking, redeploy the previous Academy commit if needed, and stop the Umami compose stack without touching content or Convex. The daily vault script is additive; remove its scheduler entry to stop reports.

## Handoff Notes
Executor should create the implementation PR against `academy/redesign-v1` and keep changes within the five files above unless a blocker is discovered. If Cloudflare Tunnel or DNS credentials are missing for `analytics.kspl.tech`, implement the app-side/env-gated wiring and mark deployment blocked with unblock owner `operator` and action `provision analytics DNS/tunnel + Umami secrets`.

## Out of scope
- No GA4 property repair, Clarity heatmap replacement, A/B testing, paid analytics cloud subscription, Convex deployment, or optimization decisions before seven clean days of Umami data.
