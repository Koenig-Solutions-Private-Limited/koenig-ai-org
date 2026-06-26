---
title: Comprehensive harness-discipline + ticket-recovery plan
date: 2026-05-01
status: in_progress
tags: [decisions, harness, gates, roles, cleanup, hermes, plan]
---

# Comprehensive harness-discipline + ticket-recovery plan

## What Vardaan asked for (2026-05-01 ~14:25 IST)

1. Confirm which agents use Hermes today + decide model + dashboard-test it (no local-model wiring yet — Qwen/Gemma deferred).
2. Fix the harness so EVERY engineering ticket gets Code Review + QA — no skips.
3. Hard-stop Chief Engineering from doing the work itself.
4. Hard-stop Executor from reviewing — execute only.
5. Audit every stuck/blocked/in-review/in-progress/backlog/todo ticket and recover them.
6. Comprehensive plan written down + executed.

## Current state (verified 2026-05-01 ~08:45 UTC)

**Hermes config**: 0 agents currently use `hermes_local`. The adapter is registered, container-runnable via the new `/usr/local/bin/hermes-py` wrapper, auth resolved.

**Ticket inventory**:

| Status | Count |
|---|---|
| done | 127 |
| cancelled | 109 |
| **blocked** | **20** |
| **in_review** | **15** |
| **backlog** | **8** |
| **in_progress** | **8** |
| **todo** | **2** |

**Top stuck patterns**:

1. **KOEA-41/42/43** — SEO HOT tickets, in_review with Executor as assignee, 16+ hrs stale. The Code Reviewer hand-off never fired. → Re-route.
2. **KOEA-46** — todo, no assignee, 17 hrs stale. → Triage + assign.
3. **KOEA-58/59/60/61** — Course outline G0 reviews stuck (15+ hrs). Half assigned to Course Author (in_review), half to Content Reviewer (blocked). → Trigger Content Reviewer.
4. **KOEA-63/10/64** — Blog G0 reviews stuck in_review (6-15 hrs). → Trigger Content Reviewer.
5. **KOEA-126/129/131/135** — Daily research tickets blocked (5+ hrs). Each researcher has TWO blocked entries for the same day. → Cancel duplicates.
6. **KOEA-215/216/217/218** — Researchers + Editor blocked again 4+ hrs ago. → Cancel duplicates.
7. **KOEA-220/221/222/264** — Chief recovery tickets blocked (recursive recovery noise). → Cancel.
8. **KOEA-255/257/266/269/270** — Content-author + reviewer chain stuck on Claude Security Beta blog. → Diagnose.
9. **KOEA-281/283/285** — current bug-fix chain. Properly cascading (Chief Eng + Code Reviewer + QA Verifier). LEAVE ALONE.

**Gate-skip leakage** (sample from last 24h, audit confirmed):

| Ticket | Title | CR | QA | Verdict |
|---|---|---|---|---|
| KOEA-23 | Stage 2: mobile responsiveness | 3 | **0** | QA SKIP |
| KOEA-275 | Fix D4+D5 BlogScrollLayer | **0** | 1 | CR SKIP |
| KOEA-277 | Fix D6+CLS rename References | **0** | **0** | NO REVIEW |
| KOEA-278 | Re-cert QA D6 + CLS | **0** | 1 | CR SKIP |
| KOEA-94 | GitHub-trigger publish path | **0** | **0** | NO REVIEW |

About **25%** of recently-shipped engineering tickets bypassed the cascade.

---

## Plan (5 phases, in priority order)

### Phase 1 — Lane rules (immediate, low-risk) — SOUL.md tightening

**Why**: Chief Engineering had multi-minute runs that look like analysis/work. Executor had tickets stuck in `in_review` because hand-off didn't fire — and could end up "reviewing" itself if not constrained.

**Action**:
- Add explicit lane-violations to `chief-engineering/SOUL.md` "What you never do":
  - Never write code yourself (not even "tiny fixes").
  - Never run `git commit`, `git push`, or any file-write/edit tool. If you find yourself wanting to, file a sub-ticket to Executor.
  - Never skip the Plan→Execute→Review→QA cascade — even for one-line fixes.
- Add explicit lane-violations to `executor/SOUL.md` "What you never do" (or create the file):
  - Never review your own work — that's Code Reviewer's job. Don't approve, decline, or comment on G_code reviews.
  - Never flip a ticket to `done` without a Code Reviewer and QA Verifier child ticket existing AND `done`.
  - Never write a PR description claiming "tests pass" without QA Verifier confirmation.

**Effort**: 15 min. Already in TaskCreate #99.

### Phase 2 — Stuck-ticket recovery sweep (immediate)

**Per-ticket actions**:

| Ticket | Action |
|---|---|
| KOEA-41/42/43 (SEO HOT, Executor in_review) | Re-assign to Code Reviewer + flip to `todo` so it picks up |
| KOEA-46 (FAQPage schema, no assignee) | Assign to SEO Optimizer |
| KOEA-58/59/60/61 (course outline G0) | Re-assign Content Reviewer + flip to `todo`; nudge heartbeat |
| KOEA-63/10/64 (blog G0) | Same as above |
| KOEA-126/129/131/135 + 215/216/217 (duplicate research blocks) | Cancel duplicates; keep one per researcher |
| KOEA-218 (Editor synthesis blocked) | Unblock once researcher dupes are cleared |
| KOEA-220/221/222/264 (recovery-loop noise) | Cancel |
| KOEA-255/257/266/269/270 (Security Beta chain) | Diagnose root cause; likely one root ticket needs unblocking |
| KOEA-72 (`__probe__`) | Cancel — orphaned probe |

**Effort**: 30 min (per-ticket UPDATE statements). Already in TaskCreate #100.

### Phase 3 — Hermes dashboard test (immediate, contained)

**Goal**: prove an agent configured with `hermes_local` + `claude-sonnet-4.6` + `command: hermes-py` can run a heartbeat successfully through Paperclip.

**Approach**: pick `vault-historian` (lowest-stakes agent — its job is reading + summarizing vault, no destructive output). Snapshot its current adapter_config, flip it to hermes_local for ONE heartbeat, verify success in `cost_events` + run logs, revert.

**Why vault-historian**: idle-only impact if it fails, no production downstream depending on its output for hours.

**Hermes default model**: `anthropic/claude-sonnet-4.6` (per `hermes-local/src/index.ts:DEFAULT_HERMES_LOCAL_MODEL`). Same provider/model as our subscription path — should auth via the existing claude_local credentials.

**Adapter-config snippet**:
```json
{
  "type": "hermes_local",
  "model": "anthropic/claude-sonnet-4.6",
  "command": "hermes-py",
  "yolo": true,
  "acceptHooks": true
}
```

**Effort**: 20 min. Already in TaskCreate #102.

### Phase 4 — Gate-enforcement guard (medium-risk, two-stage)

**Stage A (this session, fast ship — skill-level)**:
Add a "definition of done" check to chief-engineering's heartbeat skill:
> Before flipping any engineering ticket from `in_review` → `done`, query Paperclip API for child tickets. Confirm: (1) at least one `Code Reviewer` child ticket exists and is `done`, AND (2) at least one `QA Verifier` child ticket exists and is `done`. If either is missing, do NOT flip; instead, file the missing child ticket and flip parent to `blocked` with comment "awaiting <gate>".

This is enforced via the chief-engineering's `chief-engineering` skill prompt. Skill-bypassable but a strong nudge.

**Stage B (defer to next session — server-level)**:
Add a guard in the `paperclip-server`'s issue-status-flip endpoint: when an `engineering`-tag ticket flips to `done`, count `Code Reviewer` runs and `QA Verifier` runs against `context.issueId`. If either is 0, REJECT with HTTP 400 "gate-skip prevented".

**Why two-stage**: Stage A is a 30-min skill prompt edit + import. Stage B requires server source change + rebuild + careful unit tests. Both compound — Stage A prevents 80% of skips at the agent level, Stage B catches the remaining edge cases at the API layer.

**Effort**: Stage A ~30 min, Stage B ~2h. Already in TaskCreate #101.

### Phase 5 — Recovery loop & researcher block diagnosis (deferred)

**KOEA-220/221/222/264** are "Recover stalled issue X" tickets generated by the recovery service, which I dampened earlier this session (60-min lookback). But these old ones predate the dampening and accumulated. → Bulk-cancel + verify the dampening is preventing new ones.

**Researcher block pattern**: each of 4 researchers has 2 blocked tickets for the same day. The dampening should fix this going forward; pre-existing duplicates need cleanup.

**Effort**: 30 min. Will fold into Phase 2.

---

## Order of execution (this session)

1. ✅ Audit complete (this doc).
2. Phase 1 — SOUL tightening (chief-engineering + executor).
3. Phase 2 — Stuck-ticket recovery (per-ticket SQL UPDATEs).
4. Phase 3 — Hermes dashboard test (vault-historian one-shot).
5. Phase 4a — Gate-enforcement skill prompt (chief-engineering).
6. Hand off remaining items + Phase 4b to next session.

## Out of scope (per Vardaan's instruction)

- Plugging in local Qwen 3.6 / Gemma 27B / Gemma 4B 35B via Ollama — deferred. Hermes is wired but routed through Anthropic for now.
- New courses or content — staying focused on infra discipline this session.
