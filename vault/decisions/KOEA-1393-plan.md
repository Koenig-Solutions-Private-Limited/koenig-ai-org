---
ticket: KOEA-1393
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.30
---

# Plan: Fix live "slides 404" regression for `2026-04-30-anthropic-creative-connectors` by suppressing the verifier's speculative slides probe

## Goal

Stop the G5 Publish Verifier from emitting a "slides 404" BLOCK on the
`2026-04-30-anthropic-creative-connectors` blog (and any other blog) when no slides
affordance has shipped on the live academy site. Live blog stays HTTP 200 and the
G5 slides check no longer fires until a real `/slides/<slug>.pptx` feature exists.

Observable outcome: after the verifier skill update, a focused G5 recheck on the
same slug returns PASS on the slides dimension (or the slides line is absent from
the report). Live page is unchanged.

## Context

Investigation summary:

1. **No slides affordance is rendered on the live blog page.**
   `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx` (the only
   blog renderer) contains zero references to slides/pptx. Grep:
   `learnovaBeast/learnova-academy/src/app/blog/**` → `slides`/`pptx` → no matches.
2. **No `/slides/` route or static directory exists.**
   `learnovaBeast/learnova-academy/public/` contains only `courses/`. The
   build-time vault mirror `learnovaBeast/learnova-academy/scripts/sync-vault.mjs`
   only mirrors `vault/courses/*` media into `public/courses/`; it has no
   `vault/blogs/<slug>/slides.pptx` → `public/slides/<slug>.pptx` branch.
3. **The verifier invented the URL.**
   `companies/learnova-academy/skills/verify-publish/SKILL.md` defines exactly 10
   checks plus a citation-density floor. None of them probe `/slides/<slug>.pptx`.
   The G5 comment on KOEA-352 (id `b3395582-69f8-44ae-893e-5ccf69222661`,
   author Grok 4.3) added an out-of-scope check by guessing the URL convention.
4. **The .pptx artifact in the vault is NOT G0-approved.**
   `vault/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx` exists
   (37187 bytes) but [KOEA-1350](/KOEA/issues/KOEA-1350) BLOCKED it (slide 6
   needs ≥3 bullets) and the regen is `in_review` on
   [KOEA-1352](/KOEA/issues/KOEA-1352). Publishing it would violate the V7
   "every .pptx must pass G0" rule.
5. **Memory check (`project_publish_verifier_false_positive.md`) already records
   the verifier's habit of probing speculative paths** — this is the second
   incarnation of the same false-positive pattern. The first time it probed
   raw `vault/blogs/*` paths; this time it invented a `/slides/<slug>.pptx`
   convention.

Files Executor will read first:
- `companies/learnova-academy/skills/verify-publish/SKILL.md` (entire file — the
  skill defines the verifier's check surface; the patch is here).
- `companies/learnova-academy/agents/publish-verifier/SOUL.md` (one paragraph
  cross-reference, no edit required unless SOUL repeats the check list).

Constraints:
- Per-task cap $1; expected actual cost <$0.10 (one-file markdown edit).
- Must not touch upstream Paperclip code (`packages/`, `cli/`, `server/`, `ui/`).
- Must not regenerate/republish the .pptx — that work belongs to
  [KOEA-1352](/KOEA/issues/KOEA-1352).
- Deadline 2026-05-13 EOD UTC.

## Approach (1 chosen, alternatives rejected)

**Chosen — A: Patch the verifier skill to forbid speculative URL probes.**

Add a `### 0. Probe-scope rule (HARD)` section near the top of the `## Workflow`
in `verify-publish/SKILL.md` that says:

> "Run **only** the numbered checks below. Do NOT invent additional URL probes
> (e.g. `/slides/<slug>.pptx`, `/audio/<slug>.mp3`, `/transcripts/<slug>.txt`)
> based on guessed conventions. If a slides/audio link is not visible in the live
> HTML, the artifact is not part of the published surface and must not be
> probed. Re-enable check additions only via an explicit SKILL.md update when
> the feature ships."

Why this approach: the live page is already correct; there is no broken link to
fix. The "regression" is entirely a verifier hallucination, captured in our
existing `project_publish_verifier_false_positive` memory. Patching the skill is
a single-file, fully-reversible markdown edit that costs minutes and stops the
class of bug, not just this one slug.

**Rejected — B: Build blog-slides serving on the academy site.** Requires (a)
G0 re-approval of the .pptx (blocked on [KOEA-1352](/KOEA/issues/KOEA-1352)
re-review, (b) a sync-vault.mjs blog-media branch, (c) page-level rendering +
Office Online viewer, (d) a 13-deck backfill. That is a product feature
spanning multiple files, two repos, and at least one external dependency — not
a same-day regression fix. The parent goal "Audio + slides per blog/course"
already exists; this work belongs in its own ticket once [KOEA-1352](/KOEA/issues/KOEA-1352) lands.

**Rejected — C: Silence only `2026-04-30-anthropic-creative-connectors`.**
Per-slug allowlists rot fast and don't generalize. The verifier would still
emit phantom 404s for the other 12 slugs in [KOEA-1350](/KOEA/issues/KOEA-1350)'s
G6 list. Skill-level rule is the correct scope.

## Steps (Executor follows in order)

1. Branch: from `master` (or current `master`-tracking branch) cut
   `koea-1393/verifier-no-speculative-slides-probe` in `koenig-ai-org` repo.
   **Do not** touch `learnovaBeast` — no academy code change is part of this fix.
2. Edit `companies/learnova-academy/skills/verify-publish/SKILL.md`. Insert a
   new section between current line 26 (`## Workflow`) and line 28 (start of
   `### 1. HTTP status check`):

   ```markdown
   ### 0. Probe-scope rule (HARD — added 2026-05-13 per KOEA-1393)

   Run **only** the numbered checks 1–10 below. Do **not** invent additional
   URL probes (e.g. `/slides/<slug>.pptx`, `/audio/<slug>.mp3`,
   `/transcripts/<slug>.txt`) by guessing a convention. The academy site
   currently has no `/slides/` route — `learnova-academy/scripts/sync-vault.mjs`
   only mirrors `vault/courses/*` to `public/courses/`. If a slides or audio
   affordance is not present as a visible link in the fetched HTML, the
   artifact is **not** part of the published surface and probing it produces a
   false-positive 404. When the blog-slides feature ships, the team will add a
   new numbered check here; until then, leave slides/audio out of the report.
   ```

3. (Optional, only if SOUL.md repeats the check list verbatim) Cross-reference
   the new probe-scope rule in
   `companies/learnova-academy/agents/publish-verifier/SOUL.md`. A single line
   reference is enough — do not duplicate the rule body.
4. Commit with message:
   `fix(verifier): forbid speculative URL probes outside numbered checks (KOEA-1393)`.
   Body: one paragraph summary of the false-positive on KOEA-352 and the new
   rule. Co-author trailer.
5. Open PR against `master` with title
   `fix(verifier): drop speculative /slides/ probe (KOEA-1393)`. Body: link
   KOEA-1393, link the false-positive comment id
   `b3395582-69f8-44ae-893e-5ccf69222661` on KOEA-352 as the regression evidence,
   note Approach B (build the feature) is intentionally deferred.
6. Comment on KOEA-1393 with the PR URL + a request that Publish Verifier
   re-run a focused G5 pass for `2026-04-30-anthropic-creative-connectors`
   *after* merge. Do not auto-merge.

## Verification (QA Verifier checks these)

- [ ] PR diff touches exactly one file: `companies/learnova-academy/skills/verify-publish/SKILL.md` (or two if SOUL.md cross-reference is included). No `learnovaBeast` files. No upstream Paperclip files.
- [ ] After merge, dispatch a focused G5 recheck on
      `2026-04-30-anthropic-creative-connectors`. The recheck comment must
      either (a) PASS overall, or (b) BLOCK only on the unrelated L0/L3 items
      already routed by the CEO (vault `status: g0-passed`, meta description
      too short, FAQPage JSON-LD missing). It must **not** mention
      `/slides/<slug>.pptx` or any slides 404.
- [ ] `curl -sI https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors`
      still returns HTTP 200 (no academy deploy was triggered, but confirm).
- [ ] A second random slug from [KOEA-1350](/KOEA/issues/KOEA-1350)'s 13-deck
      list, when run through G5, also has no slides probe line in its report.

## Risk

- **Risk**: a future verifier model still ignores the rule and probes
  speculatively anyway (LLM rule-following is not perfect).
  **Mitigation**: the new section is placed before all numbered checks and uses
  the same `HARD` language already in checks 7 and 8; if drift continues,
  escalate by adding a deterministic probe-whitelist in a separate ticket
  (post-merge follow-up — not in scope here).
- **Rollback**: `git revert` the single SKILL.md commit. No production
  deploy/state to undo.

## Out of scope

- Building blog-slides serving (sync-vault.mjs branch, `/slides/` route, page
  UI, Office Online viewer). Belongs in a new ticket under goal
  `222a29ab` once [KOEA-1352](/KOEA/issues/KOEA-1352) re-approves the deck.
- Regenerating or G0-reviewing `vault/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx` — owned by [KOEA-1352](/KOEA/issues/KOEA-1352).
- The unrelated L0 (`status: g0-passed`) and L3 (meta description, FAQPage
  JSON-LD) BLOCKs on the same slug — already routed by the CEO triage to
  [KOEA-10](/KOEA/issues/KOEA-10), [KOEA-709](/KOEA/issues/KOEA-709), and the meta-description bug ticket.
- Any change to `learnovaBeast/learnova-academy` or its `public/` directory.
