---
ticket: KOEA-1514
planner: planner (agent 50970ac0)
planner_ticket: KOEA-1519
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.20
plan_revision: 1
---

# Plan: KOEA-1514 — GPT-5.5 slides asset/link regression (verifier hallucination, already fixed at master)

## TL;DR

**No website code change.** This G5 BLOCK is a false positive. The verifier
hallucinated a `/slides/<slug>.pptx` probe that is not in its skill spec.
The canonical fix was already merged to **koenig-ai-org master** on
2026-05-13 10:05 IST — commit `7a9a94cd` (PR #21, KOEA-1393). The
implementer's job is verification + re-run, not code edits.

## Goal

Resolve KOEA-1514's G5 BLOCK so the gpt-5-5-in-codex post is no longer
stuck. Concretely:
- Confirm the SKILL.md probe-scope rule from `7a9a94cd` is present on master.
- Re-trigger the G5 verifier on `2026-04-30-gpt-5-5-in-codex`.
- Expect ✅ PASS on the next run (or a real, in-spec BLOCK if one of the
  numbered checks legitimately fails).
- Close KOEA-1514 with the false-positive postmortem note.

## Context

### Verified failing signals (as dispatched)
- `GET /blog/2026-04-30-gpt-5-5-in-codex` → **HTTP 200** (page is healthy).
- `GET /slides/2026-04-30-gpt-5-5-in-codex.pptx` → **HTTP 404**.
- Live blog HTML contains **0** occurrences of "slides" or "pptx".

### Why the 404 is expected, not a regression

1. **The blog page template renders NO slides surface.**
   `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx` references
   only `hero_image`, `inline_images`, and `references`. There is no
   `slides_url`, `slides:` link, or `.pptx` rendering anywhere in
   `src/app/blog/`. The slides_url field is course-only — see
   `src/lib/courses.ts` and `src/app/learn/[slug]/page.tsx`.

2. **No `/slides/` route exists in the Next.js app.**
   `learnova-academy/scripts/sync-vault.mjs` mirrors `vault/courses/*` →
   `public/courses/` only. The `MEDIA_EXTS` allowlist (`.mp3 .pptx .pdf .m4a
   .wav`) is gated by the `vault/courses/` walk; nothing under
   `vault/blogs/` is ever copied to `public/`. A `slides.pptx` sitting in
   `vault/blogs/2026-04-30-gpt-5-5-in-codex/` (which does exist — produced by
   slide-audio-producer's auto-generation) is **never** served on the public
   surface.

3. **The verifier's SKILL spec does not include a slides probe.**
   `companies/learnova-academy/skills/verify-publish/SKILL.md` defines 10
   numbered checks: status, JSON-LD, citations, og:image, sitemap, llms.txt,
   page weight, citation density, og:image dimensions, author resolution.
   None of them is `/slides/<slug>.pptx`.

4. **This exact hallucination class has happened before** —
   `project_publish_verifier_speculative_url_probes` memory documents
   KOEA-352/-1393 (anthropic-creative-connectors, same false-positive
   2026-05-13) and KOEA-1486/-1490 (this same gpt-5-5-in-codex slug from an
   earlier poll cycle). The canonical fix already shipped.

### The canonical fix is already on master
- Commit `7a9a94cd fix(verifier): drop speculative /slides/ probe (KOEA-1393)`
  — author Vardaan, 2026-05-13 10:05 IST, PR #21, approval
  `7940c6ba-27c3-4eb9-b79d-0a7e51ce9ab3`. **Confirmed on `origin/master`** via
  `git branch -a --contains 7a9a94cd`.
- Adds a new Section 0 to `companies/learnova-academy/skills/verify-publish/SKILL.md`:
  > ### 0. Probe-scope rule (HARD — added 2026-05-13 per KOEA-1393)
  > Run **only** the numbered checks 1–10 below. Do **not** invent additional
  > URL probes (e.g. `/slides/<slug>.pptx`, …) by guessing a convention. …
- The verifier run that produced KOEA-1514 evidently executed **before** this
  SKILL.md commit propagated into its runtime context, or against a stale
  worktree. Subsequent G5 runs with master's SKILL.md will obey the
  probe-scope rule.

### Workspace note (per Chief Engineering's dispatch instruction)

The dispatcher noted local `learnovaBeast` was on `koea-1326/g2-blocker-fixes`
with an untracked `.pnpm-store/`. **Since this plan touches no learnovaBeast
code, Executor does NOT need to switch branches.** If for any reason
Executor wants to inspect the live deploy from `academy/redesign-v1`:

```bash
cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
git stash push -u -m "koea-1514 stash" -- '*'        # pickle untracked + dirty
git checkout academy/redesign-v1
git pull --ff-only origin academy/redesign-v1
# inspect only; no edits
git checkout koea-1326/g2-blocker-fixes
git stash pop                                          # restore prior state
```

Do **not** delete `.pnpm-store/` — it's a lockfile-managed dependency cache
unrelated to this ticket.

## Approach (1 chosen, alternatives rejected)

**Chosen — No-op + verifier re-run.** Confirm the master commit `7a9a94cd`
contains the SKILL.md probe-scope rule, then re-trigger the G5 verifier on
the slug so it re-runs against the corrected skill. Document the
false-positive in the ticket so future poll cycles can short-circuit.

**Rejected — Add `/slides/<slug>.pptx` route + mirror blog slides to public.**
This would be a product feature ("blogs have downloadable decks"), not a
regression fix. The blog page template currently exposes no slides
affordance and product hasn't approved this surface. Out of scope.

**Rejected — Re-land the probe-scope rule as if KOEA-1393 hadn't shipped.**
Duplicate work; `7a9a94cd` is already on `origin/master`.

## Steps (Executor follows in order)

All steps run from `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org`.

1. **Confirm the fix is present on master.**
   ```bash
   git fetch origin master
   git log origin/master --oneline -- companies/learnova-academy/skills/verify-publish/SKILL.md | head -5
   ```
   Expect to see `7a9a94cd fix(verifier): drop speculative /slides/ probe (KOEA-1393)`.
   Then:
   ```bash
   git show origin/master:companies/learnova-academy/skills/verify-publish/SKILL.md | grep -n "Probe-scope rule"
   ```
   Expect one match around line 27.

2. **Confirm the verifier's runtime SKILL file matches master.**
   The Publish Verifier loads its skill from this repo at task-start.
   ```bash
   grep -n "Probe-scope rule" companies/learnova-academy/skills/verify-publish/SKILL.md || \
     echo "WARNING: current worktree is on an older branch — verifier may still hallucinate"
   ```
   If the file on your current branch does NOT contain the rule, that is fine
   for the *verifier's* next run as long as its harness checks out master.
   (Verifier reads from master via its harness; not from feature branches.)

3. **Re-trigger the Publish Verifier on this slug.** Use the
   publish-verifier-poll mechanism or a manual one-off:
   ```bash
   curl -X POST -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
     "$PAPERCLIP_API_URL/api/companies/$PAPERCLIP_COMPANY_ID/issues" \
     -d '{"title":"[G5 RE-VERIFY] 2026-04-30-gpt-5-5-in-codex (post-KOEA-1393 fix)","assigneeAgentNameKey":"publish-verifier","priority":"high","metadata":{"publish_state":"published","published_url":"https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex","slug":"2026-04-30-gpt-5-5-in-codex"}}' \
     -H 'Content-Type: application/json'
   ```
   *Note:* the exact endpoint shape may need a tiny adjustment if
   `assigneeAgentNameKey` is rejected — Executor should match the
   shape used by Chief Engineering's other manual dispatches.

4. **Watch the re-verifier comment.** Expected outcome: ✅ G5 PASS with all
   10 numbered checks green. The slides probe MUST be absent from the report
   (per the new Section 0 rule).

5. **Resolve KOEA-1514.** Post a comment on KOEA-1514 of the form:
   ```
   ✅ RESOLVED · 2026-04-30-gpt-5-5-in-codex
   Root cause: verifier hallucinated /slides/<slug>.pptx probe (not in SKILL.md).
   Already fixed on master by `7a9a94cd` (KOEA-1393, PR #21) — adds Section 0
   "Probe-scope rule (HARD)". Re-run of G5 produced PASS at <link>.
   No website code change required.
   ```
   Then PATCH KOEA-1514 to `status=done`. Also flip implementer ticket
   KOEA-1521 to `done` (with the same note), and let plan-review KOEA-1520
   auto-bypass since there's no diff to review (Executor should comment "no
   diff; verifier re-run only" and request status=done).

## Verification (QA Verifier KOEA-1523 checks these)

- [ ] `git show origin/master:companies/learnova-academy/skills/verify-publish/SKILL.md` contains the literal string `Probe-scope rule (HARD — added 2026-05-13 per KOEA-1393)`.
- [ ] A fresh Publish Verifier run on slug `2026-04-30-gpt-5-5-in-codex` emits ✅ G5 PASS, and the comment body contains **no** mention of `/slides/` or `.pptx`.
- [ ] `curl -sI https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex` → `HTTP/2 200` (regression check; live page must stay healthy through the no-op).
- [ ] KOEA-1514 status flipped to `done` with the false-positive postmortem comment.
- [ ] No commits were pushed to `learnovaBeast` (no website code change in scope).

## Risk

- **Risk:** the publish-verifier-poll routine fires AGAIN before step 3 lands
  and dispatches another duplicate planner chain for the same slug —
  mirroring the `project_publish_verifier_poll_no_dedup` pattern. **Mitigation:**
  Executor should label this ticket and KOEA-1514 with `dedup:verifier-slides-false-positive`
  (or post a board-level "owned by KOEA-1514" tag) so the next poll cycle
  routes new symptoms as `blockedByIssueIds=[KOEA-1514]` rather than spawning
  a parallel plan. If a new planner ticket appears for the same slug while
  this one is open, that downstream planner should immediately stand down
  with "owned-by-active-chain KOEA-1519".
- **Risk:** the verifier's runtime harness has cached the old SKILL.md and
  the re-run also hallucinates. **Mitigation:** if step 4 produces another
  false-positive slides BLOCK, the implementer should file a
  `verifier_runtime_cache` approval (not a new planner) escalating to Chief
  Engineering — the bug is then in the verifier harness, not the SKILL.

## Out of scope

- Adding a `/slides/` route to `learnova-academy` or rendering a slides
  download affordance on the blog page. (Product decision, not a regression
  fix.)
- Mirroring `vault/blogs/*/slides.pptx` into `public/`. (Same reason.)
- Re-landing or modifying commit `7a9a94cd`. (Already on master.)
- Editing `companies/learnova-academy/skills/verify-publish/SKILL.md` on this
  feature branch. (Done on master; this branch can rebase later.)
- Touching the slide-audio-producer behavior that generates the orphan
  `slides.pptx` in `vault/blogs/*/`. (Tracked separately; not failing G5.)

## Notes for downstream tickets

- **KOEA-1521 (Implement):** Reframe as "verifier re-run + ticket cleanup".
  No code edits.
- **KOEA-1522 (G_code review):** Will have nothing to review. Executor should
  flip status with "no diff produced; verification-only ticket".
- **KOEA-1523 (G2 QA):** Use the verification checklist above. The
  acceptance criterion is "verifier emits PASS without slides probe".
- **KOEA-1520 (Plan review):** This plan asserts a no-op outcome with
  concrete evidence (`7a9a94cd` on master). Reviewer should validate the
  evidence (commit exists, file contains rule) and approve.
