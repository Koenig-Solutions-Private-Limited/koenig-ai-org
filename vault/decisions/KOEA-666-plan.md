---
ticket: KOEA-666
plan_review_ticket: KOEA-1379
prior_review_ticket: KOEA-671
revision: 3
supersedes: revision 2 (2026-05-13)
prior_revisions:
  - revision 1 (2026-05-05) — bulk vault-rename strategy, rejected by KOEA-1379
  - revision 2 (2026-05-13) — build-time `redirects()` in `next.config.ts`, blocked at verification step 3 by pre-existing lint baseline drift in `GlossaryPopover.tsx`
triggered_by_review_block: KOEA-1617 (replan-request dispatch, 2026-05-13)
triggered_by_approval: 4a2d5f8a
approval_source: KOEA-1617 (Chief Engineering replan dispatch, 2026-05-13)
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.25
status: awaiting-plan-review
implementation_lane: learnovaBeast only; topic branch off academy/redesign-v1; no direct master/main push
---

# Plan rev 3: Redirect legacy no-date `/blog/<slug>` URLs → date-prefixed canonical

## Why revision 3 (what changed vs rev 2)

Rev 2 (2026-05-13) is superseded only at the verification step. The
approach (build-time `async redirects()` in `next.config.ts`), scope,
acceptance criteria, and lane constraints all **remain unchanged**.

Executor (KOEA-1380) reached verification step 3 of rev 2 and surfaced
a lint failure that is **not caused by the KOEA-666 diff**:

```
src/components/GlossaryPopover.tsx
  34:19  error  react-hooks/set-state-in-effect
       'Avoid calling setState() directly within an effect'
```

`GlossaryPopover.tsx` was introduced on `academy/redesign-v1` by
`817a711 academy: V3 frontend polish — Groups 1-5 of audit plan`, well
before this redirect ticket existed. Confirmed pre-existing baseline,
not a regression introduced by `next.config.ts` redirects work.

Chief Engineering (approval `4a2d5f8a`) asked Planner to:

- Decide: authorize Executor to fix the baseline error in
  `GlossaryPopover.tsx`, OR revise verification so the baseline failure
  doesn't gate KOEA-666 without hiding new regressions from the
  redirect diff.
- Preserve KOEA-666 acceptance criteria (Vercel cache / prerender /
  legacy slug 308 behavior).

### Decision

**Revise verification to scope lint to files touched by the KOEA-666
diff. Do NOT authorize Executor to refactor `GlossaryPopover.tsx`.**

Why this is the right call:

1. **Scope discipline.** KOEA-666 is a narrow redirect ticket
   (`next.config.ts` only). Bundling a React hooks refactor of an
   unrelated component (cache-read effect → either `useSyncExternalStore`
   or initialState-derived state) is exactly the kind of cross-cutting
   change my SOUL warns against ("Never propose changes outside ticket
   scope").
2. **No regression hidden.** The redirect diff touches exactly one file,
   `next.config.ts`. Scoping lint to that file catches any *new* lint
   error introduced by the redirect code while ignoring the
   pre-existing baseline in an untouched component. Code Reviewer also
   attests on the diff scope (step 6) as a second guardrail.
3. **Right owner for the baseline.** The Hooks-rule violation in
   `GlossaryPopover.tsx` is a real React hygiene issue — but it
   belongs to whoever owns the V3 frontend polish work, not to a
   redirect ticket. Filed for handoff under "Out of scope" below.
4. **PR CI behavior.** Full-repo `pnpm lint` will continue to fail on
   the baseline. That's tolerated **for this PR only**: Reviewer
   confirms the lint failure is isolated to `GlossaryPopover.tsx:34`
   (the pre-existing baseline) and that the diff itself is lint-clean.
   Precise checks live in step 3 (scoped lint), step 3b (baseline
   sanity probe), step 6 (Reviewer attestation), and the first
   verification bullet.

## Why revision 2 (what changed vs rev 1)

Rev 1 (2026-05-05) is superseded. Plan-Review on KOEA-1379 (2026-05-13)
correctly blocked rev 1 on three named defects:

1. **Stale repo baseline.** Rev 1 assumed only two date-prefixed dirs
   exist and proposed renaming them. `vault/blogs/` today has **nine**
   date-prefixed dirs (every post since 2026-04-30 plus the 2026-05-12
   batch); the convention has shifted to date-prefixed as canonical. The
   bulk-rename strategy is now wrong-direction.
2. **Lane-boundary violation.** Rev 1 instructed direct `push to master`
   on both `koenig-ai-org` and `learnovaBeast`. The ticket lane is
   learnovaBeast only, branch `academy/redesign-v1`, no direct main
   merge.
3. **Wrong framing.** Rev 1 framed the symptom as "slug mismatch needs
   a rename." Reviewer reframed (correctly) as **redirect / deploy drift**
   on a single legacy URL form.

This revision re-baselines on the current repo state and the lane
constraints, and ships the smallest change that resolves the live 404.

## Goal

`https://academy.kspl.tech/blog/claude-design-visual-workflows` currently
returns **404**; the date-prefixed equivalent
`https://academy.kspl.tech/blog/2026-04-30-claude-design-visual-workflows`
returns **200** (verified 2026-05-13 04:57Z by `curl -sI`).

The codebase has converged on **date-prefixed slugs as canonical** (vault
dir name == URL slug, `generateStaticParams()` in
`learnova-academy/src/app/blog/[slug]/page.tsx:31-33`). Anything still
linking to the no-date form (sitemap hits prior to convention change,
external mentions, stale agent skills like
`companies/learnova-academy/skills/geo-optimize/SKILL.md:N`, prior G5
poll cycles, the prior KOEA-821 reference) breaks.

**Success = the no-date URL serves a 308 to the date-prefixed canonical,
so external links never 404 and Publish Verifier G5 stops phantom-blocking
on the legacy slug.** No content moves; the canonical convention stays
date-prefixed.

## Context

Files to read first:

- `learnovaBeast/learnova-academy/next.config.ts:1-23` — no `redirects()`
  configured today; this is where rev 2 adds the redirect generator.
- `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:31-33` —
  `generateStaticParams()` uses vault dir name as the slug; date-prefixed
  dirs are first-class.
- `learnovaBeast/learnova-academy/src/lib/vault.ts` — `listPublishableBlogs()`
  / `listBlogSlugs()` source of truth for current slug set.
- `koenig-ai-org/vault/blogs/` — current dir set (9 date-prefixed,
  several legacy no-date).
- `koenig-ai-org/scripts/publish-action.sh:440-489` — G5 handoff: on
  `publish_state=published`, invokes publish-verifier agent heartbeat
  with `{context:{issue_id}}`; verifier reads `metadata.published_url`
  and curls `https://academy.kspl.tech/blog/<slug>`.
- `koenig-ai-org/companies/learnova-academy/agents/publish-verifier/AGENTS.md:26,40,85` —
  verifier probes `academy.kspl.tech/blog/<slug>`; the slug comes from
  vault dir name.
- `koenig-ai-org/vault/decisions/eod-2026-05-12.md:21` — confirms the
  `claude-design-visual-workflows` 404 is the long-known false-slug case
  tracked by KOEA-821/KOEA-666, not a fresh published artifact.
- `koenig-ai-org/vault/decisions/eod-2026-05-13.md` — latest verifier
  state; no fresh signal that this changed since.

Branch state (learnovaBeast):

- `academy/redesign-v1` exists; HEAD is `16f469b Merge pull request #22 …`.
- Diverged from `main` at `1c8fdc0`; `main` has 8 commits ahead not on
  redesign-v1 (CI / OG / catalog work).
- Production deploys run from `main` (`publish.yml` checks out
  `repository_dispatch` event commit, which dispatches against the default
  branch `main`).

Constraints (from KOEA-1379):

- Implementation lane: **learnovaBeast only**, branch
  **`academy/redesign-v1`** (or a topic branch off redesign-v1).
- **No direct push to `main`/`master`** in either repo. Merge to prod
  goes via PR review; whose timeline owns that merge is the redesign-v1
  rollout owner, not this plan.
- No vault renames in `koenig-ai-org`. No Convex deploys.

Implication for G5 sign-off: G5 verifies live prod. The redirect must
reach prod (`main` deploy) before G5 flips green. This plan ships the
code on `academy/redesign-v1`; the prod-ship step is named below as a
handoff to the redesign-v1 rollout owner, not an in-scope push.

## Approach

### Chosen: build-time `async redirects()` derived from current vault, on a topic branch off `academy/redesign-v1`

`next.config.ts` gains an `async redirects()` that:

1. Reads `${KOENIG_VAULT_ROOT}/blogs/` synchronously at build time
   (already a build dep — same env var the rest of the build uses).
2. For every dir matching `^(\d{4}-\d{2}-\d{2})-(.+)$`, emits one 308
   redirect from `/blog/<no-date-slug>` → `/blog/<date-prefixed-slug>`.
3. Skips emit when a same-named no-date dir also exists (i.e. don't
   accidentally redirect a real post over its own canonical).

Result: every date-prefixed post becomes auto-reachable from its
no-date legacy form, and future date-prefixed posts get the same
behavior with no further code changes. One small, contained PR.

### Rejected — hand-list two explicit redirects in `next.config.ts`

- Pro: even smaller diff (2 lines).
- Con: brittle. The same symptom already recurred from 2 dirs (May 5)
  to 9 dirs (May 13). Hand-list will be wrong again in two weeks.

### Rejected — middleware-based runtime redirect with FS lookup

- Pro: covers slugs unknown at build time.
- Con: middleware runs on every request; pulls a node FS dep into the
  edge runtime, complicating Vercel's edge build. Overkill for the
  symptom — build-time enumeration covers every legitimate case.

### Rejected — change canonical policy back to no-date and rename vault dirs

- Pro: matches rev 1's framing.
- Con: contradicts current repo state (9 date-prefixed dirs, agent
  skills, qa-verifier probe paths). Bulk rename has high blast
  radius across agents and Google-indexed URLs. Reviewer explicitly
  asked for no slug-convention rewrites.

## Steps (Executor follows in order)

All work in `learnovaBeast` only. Vault repo (`koenig-ai-org`) is **not
touched** by this plan.

1. In `learnovaBeast`, create branch off `academy/redesign-v1`:
   ```
   git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast \
     fetch origin && \
   git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast \
     switch -c koea-666/redirect-legacy-blog-slugs academy/redesign-v1
   ```
   Branch name keeps the ticket-id prefix per the repo's `koea-NNN/`
   convention.

2. Edit `learnova-academy/next.config.ts`. Add an `async redirects()`
   function that:
   - Resolves vault root via the same `KOENIG_VAULT_ROOT` env var the
     rest of the build uses (with a sane local fallback to
     `../../koenig-ai-org/vault`, matching how dev runs today).
   - Uses `node:fs` (`readdirSync` with `withFileTypes: true`) to list
     `${vaultRoot}/blogs`.
   - Filters to dirs matching `/^(\d{4}-\d{2}-\d{2})-(.+)$/`.
   - For each match, emits
     `{ source: '/blog/<no-date-slug>', destination: '/blog/<date-prefixed-slug>', permanent: true }`.
   - Skips emit when a sibling dir with name `<no-date-slug>` already
     exists in the blogs listing (avoid masking a real no-date post).
   - Wraps the readdir in a try/catch so a missing vault dir during CI
     introspection cannot break the Next.js build — falls back to `[]`.
   Keep the function ≤ 25 lines.

3. Lint + typecheck **scoped to the KOEA-666 diff** (rev 3 change —
   see "Why revision 3"):
   ```
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && \
   pnpm tsc --noEmit && \
   pnpm exec eslint next.config.ts
   ```
   Expected: `pnpm tsc --noEmit` exits 0 (whole-project typecheck — no
   pre-existing baseline failures observed; if any surface, treat
   identically to the lint-baseline policy in step 3b).
   Expected: `pnpm exec eslint next.config.ts` exits 0 with zero
   errors. This is the file actually touched by KOEA-666; lint passing
   here proves the redirect code did not introduce new lint problems.

   Do **not** run unscoped `pnpm lint` as a gate. Unscoped lint will
   fail on the pre-existing baseline error in
   `src/components/GlossaryPopover.tsx:34` (`react-hooks/set-state-in-effect`,
   from commit `817a711 academy: V3 frontend polish`), which is
   out-of-scope for KOEA-666 and tracked separately (see "Out of
   scope" below).

3b. (Optional sanity probe — not a gate.) Run unscoped
   `pnpm lint` once and confirm the **only** error is the known
   baseline in `GlossaryPopover.tsx:34`. If any **other** file errors,
   that is a regression introduced by the redirect work; fix it before
   step 5. The three accepted warnings on the baseline are:
   - `eslint.config.mjs:4` (anonymous default export, baseline)
   - `src/app/learn/[slug]/page.tsx:568` (`ChapterMedia` unused,
     baseline)
   - `src/app/learn/page.tsx:9` (`I` unused, baseline)
   Plus the one accepted error on `GlossaryPopover.tsx:34`.

4. Local build smoke (proves redirects() runs without crashing):
   ```
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy && \
   KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault \
   pnpm next build 2>&1 | tee /tmp/koea-666-build.log
   ```
   Grep `/tmp/koea-666-build.log` for `redirects()` count and confirm at
   least 9 redirects emitted (one per current date-prefixed dir).

5. Commit + push to remote on the topic branch only:
   ```
   git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast \
     add learnova-academy/next.config.ts && \
   git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast \
     commit -m "fix(blog): redirect legacy no-date /blog/<slug> → date-prefixed canonical (KOEA-666)" && \
   git -C /Users/vardaankoenig/Documents/Paperclip/learnovaBeast \
     push -u origin koea-666/redirect-legacy-blog-slugs
   ```
   **Do not push to `main`. Do not push to `academy/redesign-v1`
   directly.**

6. Open PR `koea-666/redirect-legacy-blog-slugs` → `academy/redesign-v1`
   (not → `main`). Link KOEA-666, KOEA-1379, KOEA-1380, KOEA-1617 in
   the body. Hand the PR to Code Reviewer per the standard
   `github-pr-flow` skill.

   **PR description must include (rev 3):**
   > Known baseline lint failure on `src/components/GlossaryPopover.tsx:34`
   > (`react-hooks/set-state-in-effect`) is **pre-existing** on
   > `academy/redesign-v1` (commit `817a711`, V3 frontend polish) and
   > **not introduced by this PR**. Scoped lint of the touched file
   > (`eslint next.config.ts`) is clean. Cleanup tracked separately
   > (see KOEA-666 plan rev 3 "Out of scope").

   **Reviewer attestation requirement (rev 3):** Reviewer must
   explicitly verify in the PR review comment that
   `git diff academy/redesign-v1...HEAD` touches only
   `learnova-academy/next.config.ts` (plus optional doc/comment lines)
   and that no React/component files appear in the diff. If anything
   else is touched, replan.

7. **Out of this plan's lane** (named for handoff visibility, not
   executed here): the redirect must reach prod for G5 to pass. That
   ship-to-prod path is owned by the `academy/redesign-v1` rollout
   owner. Two viable options for them, both via PR (no direct push):
   (a) merge a focused cherry-pick of the redirect commit into `main`,
   or (b) include it in the next redesign-v1 → main merge. Either is
   acceptable; Planner does not pre-commit which.

## Verification (post-deploy, Executor / QA Verifier)

After step 6 (PR landed on `academy/redesign-v1`):

- [ ] PR CI: `pnpm tsc --noEmit` green; **scoped lint** of changed
      files (`eslint next.config.ts`) green; Vercel preview build
      green on the topic branch. Whole-repo `pnpm lint` is **expected
      to fail** on the pre-existing `GlossaryPopover.tsx:34` baseline
      and that failure does **not** block merge per rev 3 policy.
      Reviewer attests (see step 6) that the diff is confined to
      `next.config.ts`.
- [ ] Vercel preview build log contains the redirect emit
      (≥ 9 entries), e.g. `(redirects)` summary in `pnpm next build`
      output.
- [ ] Vercel preview URL probe (preview is auto-deployed on PR):
      ```
      curl -sI <preview-url>/blog/claude-design-visual-workflows | head -2
      ```
      Expect **HTTP/2 308** with `location:` containing
      `/blog/2026-04-30-claude-design-visual-workflows`.

After step 7 (redirect reaches prod via redesign-v1 owner's PR):

- [ ] Live prod probe:
      ```
      curl -sI https://academy.kspl.tech/blog/claude-design-visual-workflows | head -2
      ```
      Expect **HTTP/2 308** → `/blog/2026-04-30-claude-design-visual-workflows`.
- [ ] Live prod canonical still 200:
      ```
      curl -sI https://academy.kspl.tech/blog/2026-04-30-claude-design-visual-workflows | head -2
      ```
      Expect **HTTP/2 200** (regression guard — canonical must not
      break).
- [ ] Spot-check 2 other legacy slugs (e.g. `vercel-ai-sdk-6-vs-claude-agent-sdk`
      and `anthropic-creative-connectors`) both 308 to their
      date-prefixed canonical.
- [ ] `curl -s https://academy.kspl.tech/sitemap.xml | grep claude-design`
      lists only the date-prefixed `<loc>` (no regression of canonical
      URL in sitemap).

## G5 (publish-verifier) handoff

The verifier loop is at
`koenig-ai-org/scripts/publish-action.sh:440-489`:

1. Polls company issues for `metadata.publish_state in (ready, g4-approved)`
   and dispatches `publish-ready` to `learnovaBeast` GH Actions.
2. On GH run `success`, PATCHes the source issue to
   `metadata.publish_state=published` and invokes the publish-verifier
   agent heartbeat with `{context:{issue_id}}`.
3. Publish-verifier curls
   `https://academy.kspl.tech/blog/<slug>` where `<slug>` is the vault
   dir name from the source issue.

This plan does **not** change the verifier or the publish-action
pipeline. Two G5-relevant outcomes after prod-ship:

- For any **future** post (date-prefixed slug, the canonical convention),
  G5 continues to pass as today — direct 200 on the date-prefixed URL.
- For any **legacy / external** reference to the no-date form (the
  symptom on KOEA-666 / KOEA-821 / prior phantom polls in
  KOEA-411 / 418 / 427 / 600 / 665), the 308 short-circuits the 404.
  The verifier should follow redirects (`curl -sI` without `-L` shows
  308; the SOUL doc says "Fetch the live URL …; confirm HTTP 200"; if
  the verifier rejects 308, that's a separate guardrail for a follow-up
  ticket — explicitly listed as out-of-scope below).

## Risk

**Risk 1**: The vault-root readdir at build time can return an empty
list under certain CI environments (KOENIG_VAULT_ROOT not mounted),
leading to zero redirects in prod and a silent no-op fix.
**Mitigation**: step 2 wraps in try/catch and logs a one-line
`console.warn("[redirects] vault not readable at …")`, surfacing in
Vercel build logs. Step 4 explicitly asserts ≥ 9 redirects emitted in
the local build smoke.

**Risk 2**: 308 (permanent redirect, method-preserving) is the right
choice over 301 for SEO canonicalization, but Google may take 1-2
crawls to update the indexed URL.
**Mitigation**: acceptable — current indexed URL is already
date-prefixed (per `sitemap.xml` evidence on rev 1); the no-date form
isn't broadly indexed. The 308 protects against stale external links,
not against Google's index moving.

**Risk 3**: If publish-verifier's curl probe rejects 308 (treats it as
non-200), G5 might still phantom-fail on the legacy slug.
**Mitigation**: out of scope for this plan (named below). The Plan
deliberately keeps the change scoped to the redirect; the verifier
guardrail is a separate concern and ought to be a separate ticket if
it surfaces in the next G5 poll.

## Out of scope (explicit, per Plan-Review feedback)

- Renaming any vault directories in `koenig-ai-org` (rev 1's strategy —
  rejected by reviewer).
- Direct push to `main` / `master` on either repo (rejected by
  reviewer).
- Convex deploy or any Convex-portal action (not part of this lane).
- Updating canonical-slug policy to no-date (current policy is
  date-prefixed and stays that way).
- Fixing the publish-verifier's "treats 404 as canonical without
  cross-checking sitemap" guardrail (Risk 3). File as a child ticket
  off KOEA-666 if it surfaces in the next G5 poll cycle; do not bundle.
- Updating `companies/learnova-academy/skills/geo-optimize/SKILL.md`
  reference URLs to the date-prefixed form. Skills evolve separately;
  the redirect makes either form work.
- Merging `academy/redesign-v1` to `main` wholesale. The redirect goes
  via a focused PR or future redesign-v1 → main merge; that timeline
  is owned outside this plan.
- **Fixing `src/components/GlossaryPopover.tsx:34`
  (`react-hooks/set-state-in-effect`)** (rev 3 addition). The cache
  pre-fill currently runs inside `useEffect` via a synchronous
  `setData(cached)` call; the correct refactor uses an initialState
  derivation (e.g. `useState<GlossaryData | null>(() => cache.get(slug) ?? null)`)
  or `useSyncExternalStore`. This is a React refactor of an unrelated
  component (added in commit `817a711 V3 frontend polish`) and is
  **out of scope for KOEA-666**. Planner asks Chief Engineering to
  open a separate cleanup ticket assigned to whoever owns the V3
  frontend polish work, with acceptance criterion "full `pnpm lint`
  exits 0 on `academy/redesign-v1`". That cleanup ticket does **not**
  block this redirect PR.
