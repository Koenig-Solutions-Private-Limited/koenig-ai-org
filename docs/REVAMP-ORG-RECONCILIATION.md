# Org Reconciliation Plan — Career Compass Revamp (board-owned)

**Context**: An external Fable instance is implementing the 3-pillar revamp of koenig-career-academy via a 12-PR train (plan: that repo's `docs/FABLE-UX-REVAMP-PLAN.md`, PR #12). The board reviews/merges every PR. During the train, the org's Engineering + Learning lanes and Watchdog are **paused** (pause_reason `REVAMP WINDOW 2026-07-16`); CEO, CMO, Blog Author, Content Reviewer, Growth Lead, and the Meeting agents stay active. This document is the board's checklist for what changes in the org as the train lands — so the org resumes with a correct picture of the product it operates.

## A. Changes tied to specific PRs (board executes in that PR's merge window)

### PR 11 window — course-generation contract change (the big one)
1. **`scripts/career-reconcile.mjs`**: remove the 24h TOC auto-approve. New behavior: stale unapproved outlines stay `needs approval`, get ONE reminder (via the app's notification path, not a Paperclip escalation), never dispatch, never occupy the build slot. The reconciler's remaining duties: mirror Paperclip stage transitions to the Neon read-model (via the app's status endpoint or R2 record update — confirm mechanism from the PR), detect stalled builds, file recovery tickets.
2. **Chief Learning bundle + repo mirror**: new lifecycle (`needs approval → queued → building → reviewing → publishing → ready | delayed | cancelled`), spec-hash dedupe (extends gap_key), one-active-build-per-target rule, "silence is not consent", where the user-facing status lives (Neon read-model — org never writes it directly; Paperclip stages drive it).
3. **Course Architect + chapter-authors + domain-researcher bundles**: unchanged production mechanics (vault, G-gates, NotebookLM, sidecars) — add one paragraph: the parent ticket now arrives ONLY after explicit user approval; the spec-hash in the ticket is a HARD contract; never start work from a request lacking it.
4. **Verify end-to-end** with one synthetic request: outline → approve → exactly one parent ticket → build → read-model advances → ready email.

### PR 3/4 window — funnel semantics
5. **Growth Lead bundle**: new metric definitions (acquisition = completed signup; activation = CV upload + completed first target), new event names, Lead-pixel semantics as finally decided (flag: PR 4 proposes Lead at upload+target vs plan's report-generated — board forces consistency at review), 30-day baseline rule. Daily digest template updated to the new funnel stages.
6. **CMO bundle**: new landing structure + which surfaces are SEO-relevant (landing, /blog unchanged, sample-report page), pixel contract, campaign planning against the new funnel. Keyword lane unchanged.

### PR 5 window — dashboard
7. No org change; note for QA Verifier (at unpause): new surfaces map (dashboard, targets, workspaces) for future G2 journeys.

### PR 12 window — handoff + rollout
8. Board reviews `docs/PAPERCLIP-AGENT-HANDOFF.md` for accuracy BEFORE accepting; it becomes the org's product contract, superseding stale parts of FABLE-HANDOFF.md.

## B. At end of train (unpause + reconciliation)

1. **Unpause order**: Engineering chain first (they absorb the new codebase map + release of UI hold + revised express-lane boundaries: worker service, migrations, auth surfaces are NEVER express-lane) → Watchdog (new fake-done audit surfaces: resume exports labeled correctly, course read-model states truthful vs Paperclip stages) → Learning dept (against the new contract from §A).
2. **Bundle updates** (dual-write: live bundle + repo mirror, same pattern as 2026-07-14 rewrite):
   - Engineering chain: new routes/entities map (targets, resumes+versions, analysis runs, interview sessions/turns, course requests, outbox), `/api/career/v2` namespace, flags system, worker service ownership, migration discipline.
   - QA Verifier: new Playwright suites locations; journey e2e still paid — final-verification only.
   - Watchdog: resume-export and course-read-model audit lanes replace slide-fake-done as primary.
3. **One familiarization ticket per affected chief** (Chief Engineering, Chief Learning, CMO — Growth Lead gets its bundle update only): read handoff doc, confirm in a close-out comment, exit-invariant applies. No broadcast tickets to workers.
4. **Close KOEA-13226** (UI hold); announce on KOEA-12813 (CMO) that the new funnel is live for campaign planning.
5. **Routines**: reactivate paused routines; re-point `career-toc-reconciler` at its new duties (§A.1); consider retiring `slide-fake-done-auditor` into Watchdog's new audit routine.

## C. Post-revamp org operating goals (founder directive)

The org must autonomously: generate courses on user approval (new contract), keep testing the product (QA journeys per release), improve it (express-lane fixes + CMO-driven experiments through gates), and report daily (Growth Lead digest on the new funnel). The board remains merge authority for `main`.

## Status log
- 2026-07-16: doc created; selective pause executed (12 agents + 9 routines); CMO budget-cap auto-pause found and lifted ($40→$150 synthetic cap). In-flight KOEA-6813 (NotebookLM assets, in_review) parked safely with the pause.
