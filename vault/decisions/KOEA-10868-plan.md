---
ticket: KOEA-10868
planner: planner
date: 2026-07-09
estimated_complexity: small
estimated_token_cost: $0.32
base_branch: academy/redesign-v1
basebranch_verified: true
chain_authorization_comment: f8acd330-ed4f-4de0-be41-c95e950ac481
---

# Plan: Fix Career Compass Resend `from` formatting

## Goal
Career Compass course-ready and lifecycle emails should be accepted by Resend again, without changing the activation logic or email content. Success is a provider-accepted analyze-to-course-ready email, no recurring `lifecycle.failed:welcome_d2` for the affected token, and Growth Lead seeing `email.failed:course-ready` stay at 0 for 3 consecutive daily checks.

## Context
- Files to read first: `learnova-academy/CLAUDE.md:50-83`, then in the live Career repo/worktree `src/app/api/career/check-requests/route.ts`, `src/app/api/career/lifecycle/route.ts`, `src/app/api/career/subscribe/route.ts`, `src/app/api/career/quiz/route.ts`, `src/lib/career/store.ts`.
- Relevant prior work: learnovaBeast commit `3e6ce36a` removed Career Compass from `academy/redesign-v1` and documents that live Career code moved to sibling repo `koenig-career-academy`; historical sender code is visible in commits `6b56123a` and `dc50f903`.
- Constraints: preserve the existing Resend API and R2 event-log contracts; do not touch PostHog funnel instrumentation; keep the implementation to the Career email sender paths only.
- Root-cause hypothesis: each failing path builds `from` as `Koenig AI Academy <${RESEND_FROM_EMAIL || "academy@kspl.tech"}>`. If the deployed env var already contains a display name, angle brackets, whitespace, or an unverified-domain mailbox, the final `from` becomes invalid or unauthorized for Resend. `course-ready` and `welcome_d2` share this same construction.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add one Career email sender helper in `src/lib/career/email.ts` that normalizes and validates the configured sender, then replace the raw `from: \`Koenig AI Academy <${from.trim()}>\`` call sites in course-ready, lifecycle, subscribe/report-link, and quiz-result sends. This keeps the fix small, makes the failure mode explicit in logs, and prevents the same malformed env value from breaking one path after another.

**Rejected**: Env-only change in Vercel — fastest, but it leaves fragile string construction in four paths and does not prevent recurrence; route-local string fixes — low risk but duplicates parsing/validation and can drift again.

## Steps (Executor follows in order)
1. Locate the live Career code first: use `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-be-agent/` if present; otherwise use the sibling `koenig-career-academy` checkout named in `learnova-academy/CLAUDE.md`. If neither exists and only current `learnovaBeast` is available, stop and file a repo-state blocker because current `academy/redesign-v1` only has redirects.
2. In the live Career repo, inspect all Resend senders with `rg -n "RESEND_FROM_EMAIL|from: .*Koenig AI Academy|api.resend.com/emails" src` and confirm the four target routes: `src/app/api/career/check-requests/route.ts`, `src/app/api/career/lifecycle/route.ts`, `src/app/api/career/subscribe/route.ts`, and `src/app/api/career/quiz/route.ts`.
3. Add `src/lib/career/email.ts` with a small `careerEmailFrom()` helper that treats `RESEND_FROM_EMAIL` as a mailbox, strips an accidental `Name <email>` wrapper when present, rejects malformed values, and returns exactly `Koenig AI Academy <mailbox>`.
4. Replace the four raw sender constructions with `careerEmailFrom()`; on validation failure, log a `career` email failure with enough non-secret detail to identify sender misconfiguration, and do not mark lifecycle stages sent.
5. Validate provider/domain identity outside code before deploy: confirm the Vercel env value is a bare verified mailbox for Resend, preferably on the deployed Career domain identity, and confirm the Resend domain is verified for that mailbox.
6. Run the smallest code checks from the live Career app directory: TypeScript check if available, plus the route-level command or dry-run endpoint for `/api/career/lifecycle?dry=1` with `CRON_SECRET`; avoid a full build unless the repo’s local instructions require it.
7. After deploy, trigger or observe one course-ready send and one lifecycle send; if provider accepts both, note a follow-up for back-notifying analysis completers who missed course-ready emails, but do not send that batch in this ticket.

## Verification (QA Verifier checks these)
- [ ] `rg -n "from: .*Koenig AI Academy <\\$\\{|RESEND_FROM_EMAIL" src/app/api/career src/lib/career` shows all Career Resend sends route through the new helper or an intentionally documented equivalent.
- [ ] A test analyze-to-course-ready flow reaches Resend provider acceptance and writes `email.sent` with `kind: "course-ready"` rather than `email.failed:course-ready`.
- [ ] `/api/career/lifecycle?dry=1` still plans `welcome_d2`, and a real authorized run for the affected token no longer writes `lifecycle.failed:welcome_d2`.
- [ ] Growth Lead KOEA-10867 observes `email.failed:course-ready` = 0 for 3 consecutive daily checks after deploy.

## Risk
- The main risk is fixing code while the deployed env remains invalid or points at an unverified Resend identity. Mitigation: make sender validation explicit, verify the provider/domain identity before deploy, and keep lifecycle idempotency unchanged so failed sends do not write sent markers.

## Out of scope
- PostHog funnel work, lifecycle content redesign, unsubscribe automation, and bulk back-notification to affected completers are out of scope; only identify whether back-notification is feasible as a follow-up.
