---
title: KOEA-1185 plan — academy.kspl.tech 404 for AI supply-chain blog
date: 2026-05-12
author: planner
ticket: KOEA-1185
parent: KOEA-1185
planner_ticket: KOEA-1188
tags: [plan, academy, blog, slug, publish-pipeline, koea-1185]
estimated_complexity: small
estimated_token_cost: $0.30
files_touched:
  - vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/  (rename → ai-coding-agent-supply-chain-threat-atlas-2026/)
  - Paperclip issue KOEA-1047 metadata.slug
  - Paperclip issue KOEA-366  metadata.slug (sibling Publish/source ticket)
status: ready-for-review
revision: 2
revisions:
  - {n: 1, at: 2026-05-12T10:26Z, by: planner, note: "initial plan"}
  - {n: 2, at: 2026-05-12T12:05Z, by: planner, note: "address Code Reviewer + Chief Eng feedback: (a) Step 2 + 4 use standard PAPERCLIP_API_URL/PAPERCLIP_API_KEY env + executable lookup-via-related-work and fetch-merge-PATCH sequence; (b) add explicit Step 8 = re-wake KOEA-1181 with prepared comment payload and resume:true once live URL passes"}
---

# Plan: fix the 404 for `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`

## Goal

Make `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026`
return HTTP 200 with the rendered post once the publish pipeline (KOEA-1137)
is unblocked. Restore alignment between the canonical slug used by agents
(`ai-coding-agent-supply-chain-threat-atlas-2026`) and the vault folder name
that drives `generateStaticParams` on `academy/redesign-v1`.

## Root-cause hypothesis

Two compounding causes:

1. **Slug mismatch (this ticket's primary cause).**
   - `learnova-academy/src/lib/vault.ts` derives the public slug
     **verbatim from the vault folder name** (`listBlogSlugs() →
     readdirSync(blogs)`). There is no `slug:` frontmatter override.
   - The folder is `vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/`,
     so even a successful build would expose the post at
     `/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas`, not at
     `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`.
   - The canonical slug recorded in `companies/.../agents/ceo/SOUL.md` and
     `agents/chief-content/SOUL.md` is the "topic-year" form
     (`...-threat-atlas-2026`). The mismatch is silent today because the
     post never deployed (cause #2), so no one noticed the URL skew until G5
     probed it.

2. **Publish pipeline is broken (already diagnosed in
   `vault/decisions/KOEA-1137-plan.md`).** Four stacked failures (launchd
   unloaded, missing `GH_PAT_DISPATCH`, no Paperclip API auth header in
   `scripts/publish-action.sh`, wrong hardcoded `COMPANY_ID`) mean
   `2026-05-06-ai-coding-agent-supply-chain-threat-atlas` (status
   `g3-passed`) has never been picked up by `repository_dispatch`. The G3
   draft has been sitting in the vault since 2026-05-06; today is
   2026-05-12.

   Confirmation that no build has been re-run since the draft landed:
   `learnovaBeast academy/redesign-v1` HEAD is `76fbd20 feat(css): add
   critters + enable experimental.optimizeCss (KOEA-719)` from before
   2026-05-06; no commit references the supply-chain draft.

This plan addresses cause #1. Cause #2 is tracked under KOEA-1137; this
ticket is **blocked on KOEA-1137** for the live-URL flip but the slug fix
is the prerequisite that makes any future dispatch land on the right URL.

## Context

### Exact files / routes / registry to inspect (read-only first)

- `learnovaBeast/learnova-academy/src/lib/vault.ts` — `readBlogFile()`,
  `listBlogSlugs()`, `listPublishableBlogs()`. Confirms slug = folder name,
  no frontmatter override. `PUBLISHABLE_STATES` already accepts `g3-passed`.
- `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx` —
  `generateStaticParams()` consumes the vault slug list verbatim. No slug
  rewriting layer.
- `learnovaBeast/learnova-academy/next.config.ts` (on `academy/redesign-v1`) —
  no `redirects()` block on that branch. The `ci/koea-426-rebase-clean`
  branch added `BLOG_SHORT_SLUG_REDIRECTS` for three older posts; that
  pattern is the precedent if a redirect is required, but on this branch
  there is no inbound link to preserve so no redirect is needed.
- `scripts/publish-action.sh` lines 41-83 — Phase 1 uses
  `metadata.slug` from the Paperclip issue as the `client_payload.slug`
  dispatched to GH Actions. Whatever slug the issue carries is what
  GH Actions will build the URL from.
- `companies/learnova-academy/agents/ceo/SOUL.md` (line ~94) and
  `companies/learnova-academy/agents/chief-content/SOUL.md` (line ~105) —
  both reference `metadata.slug == "ai-coding-agent-supply-chain-threat-atlas-2026"`.
  This is the canonical slug per the agent contract.
- Paperclip issue `KOEA-1047` (referenced in
  `vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/draft.md`
  frontmatter as `ticket: KOEA-1047`) — read its
  `metadata.slug` field. Also search for any sibling **Publish** ticket
  (title pattern `Publish blog: AI Coding Agent Supply Chain ...`)
  carrying `metadata.publish_state`.
- No content registry in this repo beyond the vault — there is no
  `posts.json` / `manifest.ts` to update.

### Relevant prior work

- `vault/decisions/KOEA-1137-plan.md` (2026-05-12) — full publish-pipeline
  diagnosis. KOEA-1185 is the **content-side** companion to KOEA-1137's
  **pipeline-side** fix.
- Commit `f94029a` on `ci/koea-426-rebase-clean` — precedent for the
  `BLOG_SHORT_SLUG_REDIRECTS` pattern in `next.config.ts` if any alias is
  needed later.
- `vault/decisions/KOEA-426-*` — earlier short-slug → long-slug 301
  decision; we are intentionally going the **opposite** direction here
  (canonical slug has no date prefix, year is part of the topic name).
- Memory entry "Publish-action pipeline broken 2026-05-12" → KOEA-1137 is
  the unblocker.

### Constraints

- **Plan-mode only this heartbeat.** No code edits, no folder renames,
  no metadata PATCHes by Planner. Executor implements.
- **Convex master rule.** No Convex deploy required — the post is a
  static Next.js build on Vercel. Deploys originate from `learnova-tc`
  only if Convex is touched; nothing here requires that.
- **Branch of record**: `learnovaBeast academy/redesign-v1`. The
  `ci/koea-426-rebase-clean` branch is unrelated to this fix.
- **No other portals touched**: `learnova-careers`, `learnova-admin`,
  `learnova-sales`, `learnova-student`, `learnova-tc` are out of scope.
- **No vault mutation outside the one folder**: do not rename or
  re-frontmatter any other `vault/blogs/*` entry; the date-prefixed
  shape stays for those posts (intentional convention per KOEA-426).

## Approach (chosen)

**Rename the vault folder to match the canonical slug** the agents and
the issue already use.

`vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/` →
`vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/`

`vault.ts` re-reads the directory at build time, so the rename alone
flips `generateStaticParams` to emit `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`.
The post's publication date (`date: 2026-05-06`) is already in the
draft's YAML frontmatter and surfaces in the rendered page, so no
information is lost by dropping the date from the folder name. The
agent SOULs and the canonical slug recorded in their metadata
queries match the post-rename folder name. No code change is
required in `learnovaBeast`. No redirect is needed because the
date-prefixed alias has never been deployed and has no inbound links.

Once KOEA-1137 lands and the publish-action launchd job dispatches,
GH Actions will build with the new folder name, the live URL will be
`/blog/ai-coding-agent-supply-chain-threat-atlas-2026`, and G5 will
PASS.

## Approaches rejected

- **Add a `slug:` frontmatter field + honor it in `vault.ts`.** Would
  preserve the date-prefixed folder shape and add flexibility, but
  costs a code change in `learnovaBeast`, a new test, and a schema
  field that introduces drift between folder name and live slug for
  every future post. The vault has been folder-driven for every prior
  post; adding a override for one post is not worth the surface area.
- **Update the Paperclip `metadata.slug` to
  `2026-05-06-ai-coding-agent-supply-chain-threat-atlas` and rewrite
  the canonical-slug references in `agents/ceo/SOUL.md` +
  `agents/chief-content/SOUL.md`.** Inverts the canonical slug the org
  has already aligned on, churns two SOUL files, and produces an
  inconsistent URL convention vs. how 2026-04-30 posts ended up
  (those were renamed *to* date-prefix as canonical via the
  `BLOG_SHORT_SLUG_REDIRECTS` pattern, but that was a different
  decision driven by inbound-link preservation that does not apply
  here). Reject.

## Steps (Executor follows in order)

1. **Probe live state** (read-only, both candidate URLs and the
   `/blog` index) to confirm the 404 and that no version of this
   post is yet deployed:
   ```bash
   for SLUG in \
     ai-coding-agent-supply-chain-threat-atlas-2026 \
     2026-05-06-ai-coding-agent-supply-chain-threat-atlas; do
     curl -sI -o /dev/null -w "%{http_code}  /blog/$SLUG\n" \
       "https://academy.kspl.tech/blog/$SLUG"
   done
   curl -s "https://academy.kspl.tech/blog" | grep -c "supply-chain" || true
   curl -s "https://academy.kspl.tech/sitemap.xml" | grep -c "supply-chain" || true
   ```
   Expected: both URLs 404, zero hits in `/blog` index, zero hits in
   sitemap. If any returns 200, stop and re-plan (the slug is already
   deployed somewhere unexpected).

2. **Look up the slug source of truth.** Use the standard runtime env
   (`PAPERCLIP_API_URL`, `PAPERCLIP_API_KEY`) that every Paperclip agent
   shell already has bound — do **not** invent new vars. The
   `/api/issues/{identifier}` endpoint returns `companyId`, `metadata`,
   and a `relatedWork` fan-out, which is enough to find any sibling
   Publish ticket without a separate list query.

   ```bash
   # 2a. Author ticket: capture metadata.slug + companyId + related-work edges.
   curl -fsS -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
     "$PAPERCLIP_API_URL/api/issues/KOEA-1047" \
     | tee /tmp/koea-1047.json \
     | jq '{identifier, status, companyId, metadata,
            related_in:  [.relatedWork.inbound[]?  | {id: .issue.identifier, title: .issue.title, status: .issue.status}],
            related_out: [.relatedWork.outbound[]? | {id: .issue.identifier, title: .issue.title, status: .issue.status}]}'

   # 2b. KOEA-366 is the canonical Publish/parent for this blog
   #     (referenced in KOEA-1181's description as the upstream ticket).
   #     Fetch it directly and record metadata.slug / publish_state.
   curl -fsS -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
     "$PAPERCLIP_API_URL/api/issues/KOEA-366" \
     | jq '{identifier, status, metadata}'

   # 2c. From the 2a related-work output, also fetch any other ticket whose
   #     title contains "Publish" or "supply-chain", e.g.:
   #     for ID in $(jq -r '.related_in[].id, .related_out[].id' < /tmp/koea-1047.json | grep -i -E "publish|supply|atlas" | sort -u); do
   #       curl -fsS -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
   #         "$PAPERCLIP_API_URL/api/issues/$ID" | jq '{identifier, status, metadata}'
   #     done
   ```

   Record the issue IDs (KOEA-1047, KOEA-366, and any extra match from 2c)
   and their current `metadata.slug` / `metadata.publish_state` values
   for steps 4 + 5. If `metadata.slug` is absent on KOEA-1047 / KOEA-366,
   treat that as "needs setting" rather than "needs changing" — same
   PATCH either way.

3. **Rename the vault folder** to align with the canonical slug:
   ```bash
   cd /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org
   git mv \
     vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas \
     vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026
   ```
   No file content edits inside `draft.md` / `images/`. Commit on a
   feature branch `koea-1185/rename-supply-chain-slug` (see
   "Worktree / lock expectations" below).

4. **Reconcile Paperclip issue metadata.** For KOEA-1047 and KOEA-366
   (plus any extra ticket discovered in step 2c), ensure
   `metadata.slug == "ai-coding-agent-supply-chain-threat-atlas-2026"`.
   PATCH only if it is missing or wrong; do **not** touch
   `publish_state` (KOEA-1137 owns that).

   `PATCH /api/issues/{identifier}` accepts a partial body but replaces
   the entire `metadata` object — so fetch first, merge, then PATCH:

   ```bash
   for ID in KOEA-1047 KOEA-366; do
     CURRENT=$(curl -fsS -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
       "$PAPERCLIP_API_URL/api/issues/$ID" | jq '.metadata // {}')
     SLUG=$(echo "$CURRENT" | jq -r '.slug // ""')
     if [ "$SLUG" = "ai-coding-agent-supply-chain-threat-atlas-2026" ]; then
       echo "$ID slug already canonical — skip"
       continue
     fi
     MERGED=$(echo "$CURRENT" | jq '. + {slug: "ai-coding-agent-supply-chain-threat-atlas-2026"}')
     curl -fsS -X PATCH \
       -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
       -H "Content-Type: application/json" \
       -d "$(jq -n --argjson m "$MERGED" '{metadata: $m}')" \
       "$PAPERCLIP_API_URL/api/issues/$ID" | jq '{identifier, metadata}'
   done
   ```

   Verify each PATCH response shows `metadata.slug` matches and that no
   other field (e.g. `publish_state`, `hero_image`) was dropped.

5. **Local build smoke check** (no deploy):
   ```bash
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy
   git checkout academy/redesign-v1
   pnpm install
   KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault \
     pnpm exec next build 2>&1 | tee /tmp/koea-1185-build.log
   ```
   Verify `/tmp/koea-1185-build.log` shows
   `/blog/ai-coding-agent-supply-chain-threat-atlas-2026` in the static
   route table and **not**
   `/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas`.

6. **Open PR against `master`** for the vault rename (commit message
   `vault(blogs): rename supply-chain draft folder to canonical slug
   (KOEA-1185)`). Tag KOEA-1137 in the PR description so the publish
   pipeline owner knows this slug is the one that will dispatch once
   KOEA-1137 lands.

7. **Mark KOEA-1185 blocked-on KOEA-1137** in Paperclip and do not
   close until KOEA-1137 dispatches the post and KOEA-1185's
   verification checklist passes against live academy.kspl.tech.

8. **Re-wake KOEA-1181 (SEO post-publish validation) after the live URL
   passes the verification checklist.** KOEA-1181 spawned KOEA-1185 in
   the first place, owns the 6-check SEO/GEO acceptance, and will not
   re-run on its own. Post the comment below to KOEA-1181 once *all*
   four live URLs in the post-deploy checklist (canonical, `/blog`,
   `/sitemap.xml`, `/llms.txt`) return the expected content. Use the
   exact payload — the wording is what KOEA-1181's acceptance checks
   look for, and `resume: true` is required by the execution contract
   to re-arm a previously-completed issue.

   ```bash
   COMMENT_BODY=$(cat <<'EOF'
Resume: live URL flipped to 200 after KOEA-1185 + KOEA-1137 landed.

- Canonical: `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026` → HTTP 200
- `/blog` index: lists the post (sorted on `date: 2026-05-06`)
- `/sitemap.xml`: contains `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`
- `/llms.txt`: contains the same URL
- `og:image`: 200, 1200×630
- robots.txt AI-bot allowlist: PASS (unchanged pre-deploy)

Re-run the 6-check acceptance (canonical, JSON-LD Article + FAQPage,
og:image, robots.txt, llms.txt, Search Console submission) and PASS or
BLOCK with specific failures.
EOF
)
   jq -n --arg body "$COMMENT_BODY" '{body: $body, resume: true}' \
     | curl -fsS -X POST \
         -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
         -H "Content-Type: application/json" \
         --data-binary @- \
         "$PAPERCLIP_API_URL/api/issues/KOEA-1181/comments" \
     | jq '{id, createdAt}'
   ```

   After this comment lands, KOEA-1181 owns the close (PASS or BLOCK
   with named failures). KOEA-1185 may close once KOEA-1181 PASSes; if
   KOEA-1181 BLOCKs, file the named failure as a follow-up ticket and
   keep KOEA-1185 open until the live URL satisfies the full 6-check
   set.

## Verification (QA Verifier / G5 checks)

### Pre-deploy (post-rename, on local build)

- [ ] `curl -s "https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026"`
      currently 404 (will flip after KOEA-1137 lands).
- [ ] `pnpm exec next build` emits exactly one route for the new slug
      and no route for the old date-prefixed slug.
- [ ] `git status` after the rename shows only the folder rename
      (`R  vault/blogs/.../draft.md` etc.) — no other vault paths
      touched.
- [ ] `grep -R "2026-05-06-ai-coding-agent-supply-chain-threat-atlas"
      .` in the koenig-ai-org repo returns zero matches after the
      rename + any stale wikilink fixups.

### Post-deploy (after KOEA-1137 dispatches the post)

- [ ] `curl -sI .../blog/ai-coding-agent-supply-chain-threat-atlas-2026` → `200`
- [ ] Body contains `<h1>` matching the draft's H1
      (`Treat AI coding agents as software supply chains with keyboards`)
- [ ] JSON-LD: at least `BlogPosting` + `BreadcrumbList` parse
      cleanly (no `2026-05-06-...` slugs in any `@id` field).
- [ ] `/sitemap.xml` lists `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`.
- [ ] `/llms.txt` (and `/llms-full.txt` if blog-included on
      `academy/redesign-v1`) lists the new URL.
- [ ] `og:image` returns 200 + 1200×630.
- [ ] G5 verifier emits `✅ G5 PUBLISH VERIFIED` on the matched issue.
- [ ] Step 8 executed: comment posted on KOEA-1181 with `resume: true`
      and the four-URL summary. Confirm a new comment id appears in
      `GET /api/issues/KOEA-1181/comments`.
- [ ] KOEA-1181 re-runs its 6-check acceptance and PASSes (or BLOCKs
      with a specific named failure, in which case file follow-up).

### Live-site validation checklist (Vardaan smoke)

- [ ] Visit `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026`
      in browser. Hero loads, TOC scrolls, in-page links resolve.
- [ ] Old date-prefixed URL is `404` (acceptable — never had inbound links).
- [ ] Blog index `/blog` shows the new post in date-sorted order
      (sorted on `date: 2026-05-06`, so it should be the most recent).

## Risk

- **Risk**: an external link or LLM citation already references the
  date-prefixed URL `/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas`
  (e.g., somebody hand-shared the path while reviewing the draft).
  - **Mitigation**: low probability (post never deployed; only place
    the date-prefixed shape exists is the local vault folder name).
    If discovered post-rename, add a single entry to
    `BLOG_SHORT_SLUG_REDIRECTS` in `next.config.ts` on
    `academy/redesign-v1` (mirroring `ci/koea-426-rebase-clean`
    precedent), source
    `/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas` →
    destination `/blog/ai-coding-agent-supply-chain-threat-atlas-2026`,
    `permanent: true`. File as a follow-up KOEA-118x.

## Worktree / lock expectations

- **Worktree**: use a fresh feature worktree
  `koenig-ai-org/.claude/worktrees/koea-1185-rename` so the existing
  `koea-862/bwrap-docker-fix` working tree isn't disturbed. The vault
  has uncommitted churn on the current branch — do not co-mingle.
- **Branch**: `koea-1185/rename-supply-chain-slug` off `master`.
- **Lock**: vault writes are serialised by convention but there's no
  enforced lock on `vault/blogs/`. Coordinate by Paperclip
  comment if the Content Author has a parallel edit in flight (none
  expected — status is `g3-passed`, draft frozen).
- **No concurrent merges with KOEA-1137**: both touch publish-flow
  state but on different surfaces (KOEA-1137 = scripts + env,
  KOEA-1185 = vault folder name). Land KOEA-1185 first so when
  KOEA-1137's dispatcher boots, it dispatches the correct slug.

## Out of scope

- Fixing `publish-action.sh` / launchd / `GH_PAT_DISPATCH` /
  `COMPANY_ID` — owned by KOEA-1137.
- Adding a `slug:` frontmatter field or a folder-→-slug normaliser to
  `vault.ts` — not needed for one post; revisit only if a third
  collision shows up.
- Renaming or retro-fitting any other `vault/blogs/*` folder (the
  date-prefixed 2026-04-30 posts intentionally keep date prefixes per
  KOEA-426's 301-redirect decision).
- Convex schema or function changes (no Convex surface involved).
- Changes to any sibling portal (`learnova-careers` etc.).

## Suggested executor handoff

Create one implementation subtask under KOEA-1185:

- **KOEA-1185a — eng**: rename
  `vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/`
  → `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/`,
  reconcile `metadata.slug` on KOEA-1047 + KOEA-366 (and any extra
  ticket surfaced via the step-2c related-work scan), run local
  `pnpm exec next build` smoke, open PR. Mark KOEA-1185
  `blocked-on KOEA-1137` after PR merges. Once KOEA-1137 dispatches
  and live URL flips, **execute step 8**: post the prepared comment
  to KOEA-1181 with `resume: true` so SEO/GEO validation re-runs.
  Close KOEA-1185 only after KOEA-1181 PASSes (or after triaging any
  BLOCK that KOEA-1181 returns).

## Open questions for plan-audit

1. KOEA-366 is the canonical Publish ticket for this blog (referenced
   from KOEA-1181's description). Step 2b fetches it explicitly; step
   2c handles any further unforeseen sibling via the related-work
   scan; step 4 patches metadata on whatever step 2 surfaces.
2. Once both KOEA-1137 and KOEA-1185 are green, should `vault.ts`
   grow a defensive assertion that the folder name equals
   `slugify(title)` (or a frontmatter `canonical_slug`) so a future
   author-ticket → vault-folder mismatch fails the build instead of
   404ing live? File as KOEA-118x follow-up if so — not required for
   this fix.
