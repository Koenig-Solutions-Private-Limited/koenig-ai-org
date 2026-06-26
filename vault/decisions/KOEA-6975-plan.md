---
ticket: KOEA-6975
planner: planner
date: 2026-06-10
estimated_complexity: medium
estimated_token_cost: $0.38
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_authorization: 97786727 resolved operationally in comment f450b87c-57a9-46d9-a993-a29a7cfb3255
---

# Plan: Daily AI brief anonymous email opt-in

## Goal
Anonymous visitors can subscribe with only an email address, receive a Resend confirmation quickly, and then receive the daily 3-bullet AI brief at 8am UTC. Success also means every outbound email has an unsubscribe link and the app enforces a hard 100-email-per-UTC-day cap before calling Resend.

## Context
- Files to read first: `learnova-academy/src/app/api/digest/subscribe/route.ts:1-127`, `learnova-academy/src/components/_shared/DigestOptIn.tsx:1-128`, `learnova-academy/src/components/_shared/footer.tsx:1-99`, `learnova-academy/vercel.json:1-8`, `learnova-tc/convex/schema.ts:1-130`, `vault/research/_daily/2026-05-27.md:1-40`
- Relevant prior work: existing KOEA-7008 partial digest opt-in added `/api/digest/subscribe` and `DigestOptIn`; CE resolved planner chain alert `97786727` and authorized this plan despite active sibling UIUX work.
- Constraints: use `learnovaBeast` production branch `academy/redesign-v1`; Academy remains anonymous-by-default and has no WorkOS; Convex master schema/functions must be edited under `learnova-tc/convex/`; Resend free tier is 100 emails/day, so confirmation and daily sends both count toward the same hard cap.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Convex subscriber ledger + Academy server routes + Vercel cron. Make Convex the source of truth for subscribers, unsubscribe state, and daily send reservations; keep Resend as delivery only. Rework the existing subscribe route to write Convex, send the confirmation email with an unsubscribe token, and reserve quota before each Resend call. Add one cron route that reads the existing Research Editor daily brief artifact from `vault/research/_daily/<date>.md`, extracts three public bullets, sends at most the remaining daily quota at 8am UTC, and records per-recipient results.
**Rejected**: Resend Audiences as the only subscriber store, because the app still needs first-party quota enforcement, unsubscribe state, and send history. **Rejected**: R2 or vault JSON storage for subscribers, because the ticket explicitly asks for a Convex subscriber schema and concurrent cron/send safety is easier in Convex. **Rejected**: Auth-gated subscription, because the feature is explicitly anonymous-by-default.

## Steps (Executor follows in order)
1. Add `dailyBriefSubscribers` and `dailyBriefSendEvents` tables to `learnova-tc/convex/schema.ts`, indexed by normalized email, unsubscribe token/hash, active status, UTC send date, and email type.
2. Add `learnova-tc/convex/dailyBriefs.ts` with public/internal Convex functions for idempotent subscribe, unsubscribe-by-token, active subscriber paging, UTC daily quota reservation up to 100 total emails, and send-result recording.
3. Update `learnova-academy/src/app/api/digest/subscribe/route.ts` to run on the Node runtime, validate/honeypot/rate-limit the existing POST, call Convex as source of truth, reserve one confirmation-send slot, send the Resend confirmation email within the request, and expose a GET unsubscribe handler for email links.
4. Add `learnova-academy/src/app/api/digest/send/route.ts` guarded by `CRON_SECRET`; it should read the latest daily brief markdown from the vault reader path, reduce it to exactly three bullets, page active subscribers from Convex, reserve quota before each Resend send, include the unsubscribe URL in every email, and stop before the 100/day cap.
5. Update `learnova-academy/vercel.json` with a second cron entry for `/api/digest/send` at `0 8 * * *`; keep the existing Career Compass cron intact.
6. Keep the existing footer `DigestOptIn` placement as the canonical sitewide form; verify it renders on `/`, `/blog`, and `/blog/[slug]` through the root layout, and only adjust copy if needed without adding new page-level widgets.
7. Regenerate/deploy Convex from `learnova-tc` per repo rules, without editing generated `_generated` files manually.

## Verification (QA Verifier checks these)
- [ ] POST `/api/digest/subscribe` with a valid email and no login returns 200, creates/updates one Convex subscriber, reserves one send slot, and Resend receives a confirmation request within 30s.
- [ ] Visiting the unsubscribe URL from the confirmation/daily email marks the subscriber inactive and future cron sends skip that email.
- [ ] Triggering `/api/digest/send` with the cron bearer token sends a three-bullet daily brief and records per-recipient send events; triggering without the token returns 401.
- [ ] Seeding more than 100 eligible sends for one UTC date never produces more than 100 Resend email API calls across confirmation plus daily brief sends.
- [ ] `/`, `/blog`, and one `/blog/<slug>` page all expose the email opt-in without requiring auth and without mobile layout overflow.

## Risk
- The daily brief markdown format may drift, producing weak email bullets. Mitigation: keep extraction conservative: prefer `## Hot today` bullets, then `## Recommendations`, then first plain summary paragraph; if fewer than three bullets can be produced, log and skip sends instead of emailing malformed content.

## Out of scope
- Building a preference center, marketing segmentation, rich email templates, Resend broadcast campaigns, or a new account/auth flow.
