---
ticket: KOEA-1563
planner_ticket: KOEA-1565
plan_review_ticket: KOEA-1566
revision_ticket: KOEA-1608
planner: planner (agent 50970ac0)
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.45
plan_revision: 2
triggered_by_approval: 15a92113
no_convex_deploy: true
chain_depth_alert_approval_id: c15bd74e-3129-45d7-b8e7-3ef0859e3872
---

## Revision 2 (2026-05-13) — verification command drift

**Trigger:** approved board action `15a92113` (raised by Executor on KOEA-1585):
plan revision 1 step 6 prescribed `pnpm --filter learnova-academy run typecheck`,
but `learnova-academy/package.json` defines no `typecheck` script. Only scripts
present: `predev`, `dev`, `prebuild`, `build`, `start`, `lint`, `test`.

**Resolution chosen — direct compiler invocation, no `package.json` change.**

The smallest valid verification is `pnpm --filter learnova-academy exec tsc --noEmit`.
This works without authoring a new script because:

1. `typescript` is already a devDependency of `learnova-academy`.
2. `learnova-academy/tsconfig.json` already sets `noEmit: true` and `strict: true`,
   so `tsc` invoked against the package's tsconfig performs a full strict
   typecheck without artifact emission.
3. `pnpm --filter <pkg> exec <bin>` is the standard pnpm pattern for running
   a binary in a workspace package — same surface Executor already uses for
   `pnpm --filter learnova-academy run <script>`.
4. Avoids touching `package.json` in this PR, keeping the diff focused on the
   feature (mirror + page link). A future ticket may add a `typecheck` script
   alias for ergonomics; out of scope here.

**Rejected alternative — add a `typecheck` script to `package.json`.** Would
expand the FE PR scope to `package.json` and require coordinating with whoever
owns the FE script conventions. The board-approved drift report explicitly
permits authorizing this as an option, but the smaller path (no script
addition) is sufficient and reverts more cleanly.

**Rejected alternative — use `pnpm --filter learnova-academy run build` as
the typecheck proxy.** Next 16's `next build` does run typechecking, but it
also runs the `prebuild` hook (`node ./scripts/sync-vault.mjs`) which mutates
`public/` and is heavier than required. Keep step 6 cheap; step 6 already
runs `node scripts/sync-vault.mjs` explicitly as the next sub-step.

**Acceptance criteria preserved (unchanged):**
- live blog page links `/slides/<slug>.pptx`
- `/slides/<slug>.pptx` returns HTTP 200
- positive case (blog with slides.pptx) — pill renders, asset 200
- negative case (blog without slides.pptx) — no pill, no probe
- no speculative-probe regression (check 11 gates on vault existence)

**Files edited in this revision:** only `vault/decisions/KOEA-1563-plan.md`
(this file). Steps 6 and verification row V8 carry the new command. All other
steps and verification rows are byte-identical to revision 1.

# Plan: KOEA-1563 — ship blog slides surface (`/slides/<slug>.pptx`)

## TL;DR

Mirror every `vault/blogs/<slug>/slides.pptx` → `public/slides/<slug>.pptx`, add
a `slides_url` field on `BlogPost`, render a "Download slides" pill on the blog
template, and add **G5 check 11** to `verify-publish/SKILL.md` that asserts the
new contract. This **completes the path KOEA-1393's Section 0 explicitly
deferred** ("When the blog-slides feature ships, the team will add a new
numbered check here") — it is the feature-ship moment, not a policy reversal.

## Chain context (read before reviewing)

This is the **fifth dispatched ticket** addressing the same gpt-5-5-in-codex
slides symptom:

| Ticket | Verdict | Status |
|---|---|---|
| KOEA-1437 | Bundled fix (Fix 1/3/4); plan written | cancelled |
| KOEA-1486 | Routed duplicate of KOEA-1437 | cancelled |
| KOEA-1514 | Declared false-positive; closed via KOEA-1393 | blocked |
| KOEA-1518 | Routed under KOEA-1437 chain | cancelled |
| **KOEA-1563** | Chief Engineering reopens with feature-ship mandate | in_progress |

A `planner_chain_alert` is filed on this heartbeat (filed as
`request_board_approval` per `project_approvals_enum_planner_chain_alert_missing`
memory) so CEO/board sees the dispatch-deduplication pattern. Approval id is
recorded in the Handoff section once filed.

## Goal

After this lands, against `2026-04-30-gpt-5-5-in-codex` AND every other blog
whose `vault/blogs/<slug>/slides.pptx` exists today (13 slugs — see Risk):

- `curl -sI https://academy.kspl.tech/slides/<slug>.pptx` → `HTTP/2 200`.
- `curl -s /blog/<slug>` contains `<a … href="/slides/<slug>.pptx" download>`.
- G5 verifier check 11 PASSES (positive contract, gated on vault existence).
- KOEA-1562 re-verify → PASS.

## Context

### Live state verified 2026-05-13T06:30Z

- `vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx` exists (37,240 bytes).
- `/blog/2026-04-30-gpt-5-5-in-codex` → HTTP 200, **0** mentions of
  `slides`/`pptx` in the page body.
- `/slides/2026-04-30-gpt-5-5-in-codex.pptx` → HTTP 404.
- `/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx` → HTTP 404 (alternate shape
  KOEA-1437 Fix 3 had proposed; also unserved).
- KOEA-1437/1442/1486/1518 all `cancelled` in API — no slides surface ever
  shipped.
- KOEA-1393 commit `7a9a94cd` on `origin/master` adds Section 0 to SKILL.md.
  Section 0 line 36 explicitly anticipates this work: *"When the blog-slides
  feature ships, the team will add a new numbered check here; until then,
  leave slides/audio out of the report."*

### Why the URL shape is `/slides/<slug>.pptx`, not `/blogs/<slug>/slides.pptx`

KOEA-1437 plan chose the nested `/blogs/<slug>/slides.pptx` shape because it
mirrored vault structure. KOEA-1563 explicitly mandates `/slides/<slug>.pptx`
(top-level flat namespace). Two reasons to honor that:

1. **Chief Engineering authoritative ask.** KOEA-1563 body: "the live blog page
   must link `/slides/<slug>.pptx` and that URL must return HTTP 200".
2. **Symmetry with `/courses/`.** Courses already serve assets under
   `/courses/...`. A top-level `/slides/` namespace fits the same pattern, and
   keeps the URL stable if a slug ever rotates between blog and course.

### Files to read first

**`learnovaBeast` (branch `academy/redesign-v1`, FE worktree
`/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-fe-agent`, port 3001
on Vardaan's Mac):**
- `learnova-academy/src/lib/vault.ts` — `BlogPost` interface + `readBlogFile`
  (target of step 5).
- `learnova-academy/scripts/sync-vault.mjs` — `MEDIA_EXTS` + `mirrorCourseMedia`
  (model the new mirror after this — step 4).
- `learnova-academy/src/app/blog/[slug]/page.tsx` — render the download pill
  (step 6); locate the closing `</article>` and insert above the references
  block.
- `learnova-academy/src/app/learn/[slug]/page.tsx` or any chapter "bottom deck"
  component — reference styling pattern; do NOT import (different surface).
- `learnova-academy/_shared/icons/` — pick an existing download icon for the
  pill; do not add a new asset.

**`koenig-ai-org` (master):**
- `companies/learnova-academy/skills/verify-publish/SKILL.md` lines 27–37
  (Section 0 deferral text — updated by step 9) and the numbered-checks block
  (insert check 11 at end of step 10).
- `companies/learnova-academy/agents/publish-verifier/SOUL.md` — confirm any
  prose mirror of the no-speculation rule is updated to the positive contract.

### FE worktree availability

The dispatcher specified `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-fe-agent`
on port 3001. On the planner container that path resolves to
`/paperclip/instances/default/workspaces/learnovaBeast-fe-agent`. On Vardaan's
Mac the same volume mounts at the dispatcher-specified path. Pre-flight (step
1) forces Executor to verify worktree presence and `pnpm install` before any
edits.

### Constraints honored

- **No Convex deploy** — pure FE template + static mirror + skill markdown.
- **No publish-action.sh dispatch** — slugs already published; only template
  rebuild is needed.
- **Per-task cap $1** — planning ~$0.40; execution estimated ~$0.50 once
  audited.
- **Branch policy** — FE on `academy/redesign-v1`; koenig-ai-org on fresh
  feature branch off `master`.

## Approach (1 chosen, 4 rejected)

**Chosen — Build-time static mirror + page link + skill check 11.**

The smallest end-to-end fix. Mirror is build-time and identical in shape to
`mirrorCourseMedia()`; page link is one `<aside>` block guarded by
`post.slides_url`; verifier check 11 is a numbered addition. All three pieces
revert independently.

**Rejected — Dynamic Next.js route handler at `/slides/[slug].pptx`.**
Adds runtime cost for a static binary; offers nothing the mirror doesn't.

**Rejected — Reuse KOEA-1437's `/blogs/<slug>/slides.pptx` shape + 301 from
`/slides/<slug>.pptx`.** Adds redirect complexity, contradicts KOEA-1563's
explicit URL ask, and re-opens a settled namespace question.

**Rejected — Per-slug allowlist for only `2026-04-30-gpt-5-5-in-codex`.**
Would need re-deciding for every future slug; doesn't honor "if vault has
asset, page surfaces it" intent in KOEA-1563.

**Rejected — Ship FE-only, defer the skill update to a follow-up.** Leaves
the verifier without a check, so KOEA-1562 re-verify could still mis-route
on the next sweep. Bundle the skill update — it's two paragraphs.

## Steps (Executor follows in order)

### Pre-flight (Executor MUST run before editing)

1. **Worktree verify.** From `/Users/vardaankoenig/Documents/Paperclip`:
   ```bash
   git -C learnovaBeast worktree list | grep learnovaBeast-fe-agent || \
     git -C learnovaBeast worktree add learnovaBeast-fe-agent academy/redesign-v1
   cd learnovaBeast-fe-agent
   git status                                  # expect clean
   git log -1 --oneline                        # expect a recent academy/redesign-v1 head
   pnpm install                                # ensures lockfile is in sync
   ```

2. **Blast-radius audit.** From `koenig-ai-org` master:
   ```bash
   ls -1 vault/blogs/*/slides.pptx | wc -l     # currently 13
   ls -1 vault/blogs/*/slides.pptx
   ```
   If the count exceeds 13 by the time Executor runs (new slides have been
   added in the meantime), comment the list on KOEA-1563 and proceed unless
   chief-engineering objects within one heartbeat.

### learnovaBeast — `koea-1563/blog-slides-surface` (off `academy/redesign-v1`)

3. **`scripts/sync-vault.mjs` — add `mirrorBlogSlides()`** modeled on
   `mirrorCourseMedia()`:
   - Walk `${VAULT_ROOT}/blogs/` directory entries.
   - For each `<slug>/slides.pptx`, mirror to `public/slides/<slug>.pptx`.
   - Skip if `public/slides/<slug>.pptx` already exists with matching mtime
     and size (same skip-if-fresh logic).
   - `mkdir -p public/slides` once at function start.
   - Add a `console.warn` if `public/slides/<slug>.pptx` exists with non-mirror
     content (size mismatch on an existing file with a different mtime origin).
   - Call `mirrorBlogSlides()` in the script's main invocation block alongside
     existing mirror calls.
   - **Do not extend the mirror to other extensions** (audio, PDFs). KOEA-1563
     is `.pptx` only; other media belongs to follow-up tickets.

4. **`src/lib/vault.ts`** — extend `BlogPost`:
   - Add `slides_url?: string` to the `BlogPost` interface near other optional
     URL fields.
   - In `readBlogFile`, after frontmatter parsing and before `return`:
     ```ts
     const slidesAbs = join(VAULT_ROOT, "blogs", slug, "slides.pptx");
     const slides_url = existsSync(slidesAbs) ? `/slides/${slug}.pptx` : undefined;
     ```
   - Ensure `existsSync` is imported from `node:fs` (most likely already is).
   - Pass `slides_url` into the returned object.

5. **`src/app/blog/[slug]/page.tsx`** — render the download pill:
   - Find the closing `</article>` (or equivalent) before the references
     footer. Insert above it:
     ```tsx
     {post.slides_url && (
       <aside className="blog-slides-pill" /* match _shared/blog.module.css naming */>
         <a href={post.slides_url} download>
           <I name="download" /> Download slides (.pptx)
         </a>
       </aside>
     )}
     ```
   - If the existing icon registry has no usable `download`, ship text-only
     (`"Download slides (.pptx) ↓"`). Do NOT add a new icon asset.
   - Reuse existing CSS module / design tokens; do not introduce new colors.

6. **Type + smoke test:**
   ```bash
   pnpm --filter learnova-academy exec tsc --noEmit   # MUST be green (see revision 2 note)
   node scripts/sync-vault.mjs                         # check public/slides/<slug>.pptx written
   ls -la public/slides/ | head -20
   pnpm --filter learnova-academy run dev -p 3001      # background; visit /blog/2026-04-30-gpt-5-5-in-codex
   curl -s http://localhost:3001/blog/2026-04-30-gpt-5-5-in-codex | grep -F '/slides/2026-04-30-gpt-5-5-in-codex.pptx'
   ```
   The local curl must show the `<a … download>` substring.

   Why `exec tsc --noEmit` instead of `run typecheck`: `learnova-academy`
   has no `typecheck` script (see revision 2 note). `tsc` is a devDependency
   and the package's `tsconfig.json` already sets `noEmit: true` + `strict: true`,
   so this command performs a full strict typecheck without authoring a new
   `package.json` script. If `next-env.d.ts` is missing on a fresh checkout,
   run `pnpm --filter learnova-academy exec next telemetry status` first to
   trigger Next's type-generation side effect, then re-run `tsc --noEmit`.

7. **Commit + push** to `koea-1563/blog-slides-surface`, open PR against
   `academy/redesign-v1`. PR title: `feat(blog): serve /slides/<slug>.pptx and link from blog pages (KOEA-1563)`.

### koenig-ai-org — `koea-1563/skill-check-11` (off `master`)

8. **`companies/learnova-academy/skills/verify-publish/SKILL.md` — update
   Section 0 deferral text** (currently lines ~27–37): replace the
   "When the blog-slides feature ships…" closing sentence with a
   one-line pointer: *"Slides surface shipped per KOEA-1563 — see check 11
   below. Continue to refuse speculative probes for any URL shape not in
   checks 1–11."*

9. **Add check 11** to the same SKILL.md, after the existing last numbered
   check and before any "Decide" / routing block. Wording:

   ```markdown
   ### 11. Slides surface integrity (blogs only)

   Skip this check entirely if `vault/blogs/<slug>/slides.pptx` does NOT
   exist in the source vault.

   When the vault file exists:

   ```bash
   curl -sI -o /dev/null -w "%{http_code}\n" "https://academy.kspl.tech/slides/${slug}.pptx"
   ```

   Expected: 200, content-type containing `presentation` or `octet-stream`.

   Then fetch the page HTML and assert the link is present:

   ```bash
   curl -s "$URL" | grep -F "/slides/${slug}.pptx"
   ```

   Expected: at least one `<a … download href="/slides/${slug}.pptx" …>` match.

   Failure of either → BLOCK to chief-engineering with the vault path AND
   the missing-side (`asset` vs `link`). Do NOT invent alternative URL
   shapes for the asset.
   ```

10. **`companies/learnova-academy/agents/publish-verifier/SOUL.md`** — if a
    "Never invent asset URLs" line exists, edit to: *"Never invent asset URLs.
    Probe only URLs in checks 1–11 of `skills/verify-publish/SKILL.md`. For
    slides specifically, probe `/slides/<slug>.pptx` IFF
    `vault/blogs/<slug>/slides.pptx` exists; never otherwise."*

11. **Commit + push** to `koea-1563/skill-check-11`, open PR against `master`.
    PR title: `chore(skill): add check 11 for blog slides surface (KOEA-1563)`.

### Deploy

12. **No publish-action.sh dispatch needed.** Once both PRs merge:
    - `academy/redesign-v1` rebuilds on Vercel → mirror runs → public/slides/
      populated → 13 URLs go live; pill renders on 13 blog pages.
    - `master` merge updates the skill that the verifier loads at task-start
      → next G5 sweep runs check 11.

    If Vercel auto-build doesn't trigger, nudge a redeploy of `academy/redesign-v1`
    from the Vercel UI.

## Verification (QA Verifier checks these — focus slug + sanity slugs)

| # | Check | Pre-fix | Post-fix |
|---|---|---|---|
| V1 | `curl -sI https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx \| head -1` | `HTTP/2 404` | `HTTP/2 200` |
| V2 | `curl -s https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex \| grep -F '/slides/2026-04-30-gpt-5-5-in-codex.pptx'` | empty | ≥1 match incl. `download` attribute |
| V3 | `curl -s https://academy.kspl.tech/slides/2026-04-30-gpt-5-5-in-codex.pptx \| wc -c` | `0` | ≥ 30000 (vault is 37240) |
| V4 | Same V1/V2 against `2026-04-30-anthropic-creative-connectors` (sanity — different slug) | both fail | both pass |
| V5 | Same V1/V2 against `claude-security-beta-devsecops` (sanity — non-date slug) | both fail | both pass |
| V6 | `curl -s https://academy.kspl.tech/blog/<a blog WITHOUT slides.pptx, e.g. pick after audit step 2> \| grep -F '/slides/'` | empty | empty (negative: no pill where no vault asset) |
| V7 | `curl -sI https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex \| head -1` | 200 | 200 (no regression) |
| V8 | `pnpm --filter learnova-academy exec tsc --noEmit` (see revision 2 — no `typecheck` script exists; this is the smallest valid typecheck path) | — | green |
| V9 | G5 verifier re-run on KOEA-1562 slug — comment body must include "check 11 PASS" and contain no "speculative" or "unknown probe" wording. | BLOCK | PASS |
| V10 | Re-run the same G5 verifier against a non-vault-asset slug (e.g. a course chapter); the verifier must NOT probe `/slides/<slug>.pptx` (check 11 skips). | n/a | check 11 skipped |
| V11 | Page weight regression: `curl -s /blog/2026-04-30-gpt-5-5-in-codex \| wc -c` — must remain `≤ 80KB`. Pill is ~200 bytes. | — | under threshold |

## Risk

- **Blast radius — 13 blogs gain a pill.** Pre-flight step 2 audits this.
  All 13 are content-ready (slides.pptx in vault means slide-audio-producer
  already generated decks). No CEO sign-off is required to surface them
  collectively because the implicit policy is "if vault has it, page surfaces
  it" (KOEA-1563 affirms this). Executor MUST list the 13 slugs on the
  KOEA-1563 thread before merging the FE PR so chief-engineering can
  fast-block if any deck is not actually shippable.
- **Verifier check 11 fires immediately on next sweep.** Once the skill PR
  merges to master, the next verifier heartbeat runs check 11 against EVERY
  blog G5 ticket. The 13 with vault slides will pass; the rest skip cleanly
  (vault check guards). No false-positive class is reintroduced as long as
  the vault-existence gate is correct — Executor should hand-verify the
  guard with one positive and one negative case during PR review.
- **Stale verifier runtime cache.** Verifier may pick up the new SKILL.md
  on its next task-start; in-flight task started before the merge will run
  the old skill and may emit one last "missing slides" BLOCK with the old
  Section 0 wording. Acceptable; re-route as duplicate of this work.
- **`pptx` content-type inconsistency.** Vercel may serve `.pptx` as
  `application/octet-stream` rather than the canonical
  `application/vnd.openxmlformats-officedocument.presentationml.presentation`.
  Check 11 wording accepts either.
- **Slug → static-file collision.** A theoretical slug named `index` would
  collide with Next.js routing. None of today's 13 collide. The mirror
  function's `console.warn` (step 3) catches an unexpected overwrite.
- **Worktree drift on Mac host.** If `learnovaBeast-fe-agent` worktree is
  not on `academy/redesign-v1` HEAD, pnpm-install may leave a divergent
  lockfile. Pre-flight step 1 catches this.
- **Rollback.** Revert both PRs; on the next Vercel build:
  - `public/slides/*.pptx` files persist until next clean build, but the
    page no longer renders the pill (page revert is immediate).
  - Verifier check 11 reverts to the deferred wording on next master sweep.
  - 13 URLs that were 200 will remain 200 in cache for `max-age` window,
    then drop to 404.
- **Policy-reversal contention.** Minimal. KOEA-1393 itself flagged this
  as the intended path (line 36 of SKILL.md). `planner_chain_alert` filed
  on this heartbeat for CEO visibility on the dispatch-deduplication
  pattern, not on the policy itself.

## Out of scope

- Audio podcast (.mp3) surfaces on blogs — separate ticket if/when needed.
- PDF (.pdf) surfaces on blogs — same.
- Course slides — already work.
- Other extensions in the mirror — keep limited to `.pptx`.
- Convex / `learnova-tc` — explicit no-Convex-deploy constraint.
- 13-blog SEO-description backfill — KOEA-1247 chain.
- Retiring the (cancelled) KOEA-1437 `/blogs/<slug>/slides.pptx` shape — was
  never shipped; nothing to retire.
- New icon assets in `_shared/icons/`.

## Handoff

1. **`planner_chain_alert` approval filed** on this heartbeat as
   `request_board_approval` (per memory note
   `project_approvals_enum_planner_chain_alert_missing`). Subject prefixed
   `[planner_chain_alert]`. Payload includes `rootIssueId=KOEA-1437`,
   `chainIds=[KOEA-1437, KOEA-1486, KOEA-1514, KOEA-1518, KOEA-1563]`,
   `depth=5`. Approval id written back into this file's frontmatter once
   the POST returns.
2. **Comment posted on KOEA-1565** with this plan path + a one-line
   summary and request to flip KOEA-1565 → `done`.
3. **KOEA-1566 (Plan Review)** is the next gate. Code-Reviewer picks it up
   on next heartbeat. Plan reviewer's primary job is to validate (a) the
   URL-shape choice and (b) the blast-radius audit step.
4. **Executor lane** opens after Plan Review acceptance: two PRs as
   described, no child issues required (no content / no engineering deploy
   handoff).
5. **Closure path:** KOEA-1562 G5 re-verify PASS closes KOEA-1563 and
   transitively KOEA-1562, KOEA-1514, KOEA-1518.
