---
ticket: KOEA-1233 (plan for parent 60e4d6ea-e6f2-48fc-9f62-6f4ee88dd3c9)
planner: planner
date: 2026-05-12
estimated_complexity: small
estimated_token_cost: $0.40
status: ready-to-execute
related:
  - parent bug 60e4d6ea-e6f2-48fc-9f62-6f4ee88dd3c9 ([BUG] Slide .pptx files in vault never copied to learnovaBeast public/slides/ — links 404)
  - KOEA-1158 (same FE worktree convention)
---

# Plan: Mirror vault blog slides → `public/slides/<slug>.pptx`, footer link, sitemap entries

## Goal

Every published blog post whose `vault/blogs/<slug>/slides.pptx` exists gets a working `https://academy.kspl.tech/slides/<slug>.pptx` URL after the next deploy. Specifically:

1. **Asset mirror**: `vault/blogs/<slug>/slides.pptx` → `learnova-academy/public/slides/<slug>.pptx` during `prebuild`/`predev` (13 files at plan time).
2. **Footer link**: a "Download slides" link appears at the bottom of `/blog/<slug>` when (and only when) that blog has slides.
3. **Sitemap**: `https://academy.kspl.tech/slides/<slug>.pptx` is listed once per publishable blog that has slides.

Observable check: `curl -I https://academy.kspl.tech/slides/2026-04-30-claude-design-visual-workflows.pptx` returns `200` after deploy; same probe on a blog **without** slides returns `404`. G5 page-weight remains unchanged (PPTX is downloaded, not embedded).

## Context

- **Implementation repo**: `learnovaBeast` (sibling of `koenig-ai-org`), branch **`academy/redesign-v1`** @ `76fbd20 feat(css): add critters + enable experimental.optimizeCss (KOEA-719)`.
- **Implementation root inside that repo**: `learnova-academy/` (NOT `apps/learnova-academy/` — the parent issue text uses the wrong prefix; the actual layout is flat `learnova-academy/`). Do not touch `learnova-tc`, `learnova-admin`, `learnova-sales`, `learnova-student`.
- **Files to read first**:
  - `learnova-academy/scripts/sync-vault.mjs` (current course-media mirror; lines 68–110 are the template to copy)
  - `learnova-academy/src/lib/vault.ts:117-145` (`listBlogSlugs`, `listPublishableBlogs`, `getBlog`)
  - `learnova-academy/src/app/blog/[slug]/page.tsx:67-268` (server component, References section ends ~line 257 — insert link there)
  - `learnova-academy/src/app/sitemap.ts:30-35` (`blogRoutes` block — extend it)
  - `learnova-academy/src/app/learn/[slug]/page.tsx:316-330,588-690` (existing course slides UX — mirror the **download** affordance only; do **not** embed Office Online for blogs)
- **Source-of-truth count** (verified on master 2026-05-12):
  ```
  vault/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx
  vault/blogs/2026-04-30-claude-design-visual-workflows/slides.pptx
  vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx
  vault/blogs/2026-04-30-openai-on-aws-bedrock-the-real-tradeoffs/slides.pptx
  vault/blogs/2026-04-30-opus-4-7-long-running-coding-benchmark/slides.pptx
  vault/blogs/2026-04-30-vercel-ai-sdk-6-vs-claude-agent-sdk/slides.pptx
  vault/blogs/2026-04-30-voice-agents-2026-tts-latency-benchmark/slides.pptx
  vault/blogs/claude-security-beta-devsecops/slides.pptx
  vault/blogs/cloudflare-agents-week-2026-explained/slides.pptx
  vault/blogs/cursor-3-2-vs-claude-code-workflow/slides.pptx
  vault/blogs/gemma-4-vs-llama-4-vs-qwen-3-5/slides.pptx
  vault/blogs/mcp-2026-roadmap-explained/slides.pptx
  vault/blogs/notebooklm-as-a-learning-system/slides.pptx
  ```
  **13 files**. Total ≈ 30–70 MB once mirrored (per-file ≈ 2–5 MB). Acceptable for Vercel's 1 GB asset limit, but flagged under Risk.
- **Constraints**:
  - Do **not** deploy Convex (Chief Engineering rule — Convex deploys only from `learnova-tc`).
  - Do **not** touch other portals (`learnova-tc`, `learnova-admin`, `learnova-sales`, `learnova-student`).
  - Preserve `prebuild` + `predev` behaviour for `vault/courses/<slug>/*.{mp3,pptx,…}` — extend, don't replace.
  - Keep page weight under the existing G5 threshold (no embed; download link only — `~120 bytes` overhead per blog page).

## Approach (1 chosen, alternatives rejected)

**Chosen — Build-time mirror + static link/sitemap entries.** Three small, additive cuts:

1. **Extend `sync-vault.mjs`** with a `mirrorBlogSlides()` function modelled on the existing `mirrorCourseMedia()`. Scans `vault/blogs/*/slides.pptx`, copies each to `public/slides/<slug>.pptx`. Same mtime+size idempotency check the course mirror already uses.
2. **Add `hasBlogSlides(slug)` to `lib/vault.ts`** — a `statSync` on `<VAULT_ROOT>/blogs/<slug>/slides.pptx`. Used by both the blog page and the sitemap so the predicate is one place.
3. **Conditionally render the download link** in `app/blog/[slug]/page.tsx` (after `<References>`) and add `/slides/<slug>.pptx` rows to `sitemap.ts` for every publishable blog whose `hasBlogSlides(slug)` returns true.

This matches the established course-media pipeline 1-for-1, so reviewers can verify by diffing against `mirrorCourseMedia()` + the existing course slides UX.

**Rejected**:
- *R2 / Cloudflare-served binaries* — would require a new bucket + upload step + CORS config. Course slides already ship from `public/`; consistency wins. Revisit if total `public/` size crosses 500 MB.
- *Office Online embed on blog pages* (mirror of course `ChapterBottomDeck`) — blog post weight is already a recurring problem (KOEA-1158). A 30 KB `<iframe>` to `view.officeapps.live.com` per blog regresses page weight. Download-only is the right minimum.
- *Read source `vault/blogs/<slug>/slides.pptx` at request time via a Next route handler* — `force-static` blog pages can't, and a dynamic route adds runtime vault dependency. Build-time mirror keeps the existing static-export model.
- *Frontmatter `slides_url` field* (mirror of course `chapter.slides_url`) — adds an authoring burden across 13 existing posts and any future post. Convention-over-config (just drop `slides.pptx` in the blog dir) matches the rest of the asset pipeline.

## Steps (Executor follows in order)

1. **Worktree setup**. Plan-time scratch worktree `/tmp/learnova-plan-1233` exists; delete it after reading (`cd learnovaBeast && git worktree remove /tmp/learnova-plan-1233 --force`). Then create the executor worktree:
   ```bash
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
   git fetch origin
   git worktree add -b fe/KOEA-1233-blog-slides ../learnovaBeast-fe-agent origin/academy/redesign-v1
   cd ../learnovaBeast-fe-agent/learnova-academy && pnpm install
   ```
   If `/Users/vardaankoenig/Documents/Paperclip/` is still `root:root` (KOEA-1158 unblock pending), fall back to a `/tmp/learnovaBeast-1233` worktree on the same branch and note it in the PR.
2. **Extend `learnova-academy/scripts/sync-vault.mjs`**. Add a `mirrorBlogSlides()` function right after `mirrorCourseMedia()` (paste pattern, swap paths):
   - source: `join(VAULT_ROOT, "blogs", slug, "slides.pptx")`
   - destination: `join(PROJECT_ROOT, "public", "slides", slug + ".pptx")` (note: **flat naming** — `<slug>.pptx`, not `<slug>/slides.pptx`)
   - skip slugs starting with `.`; skip when `slides.pptx` is missing; preserve the mtime+size short-circuit
   - log `[sync-vault] mirrored N blog slide deck(s) to public/slides/`
   - call it from the bottom of the module (line 113 area) right after `mirrorCourseMedia()`.
3. **Add `hasBlogSlides(slug)` to `learnova-academy/src/lib/vault.ts`**. Single-line `statSync` on `join(VAULT_ROOT, "blogs", slug, "slides.pptx")` wrapped in try/catch → `boolean`. Export it. Do NOT change `BlogPost` interface (slides existence is derived, not authored).
4. **Wire the download link in `learnova-academy/src/app/blog/[slug]/page.tsx`**. Inside the `<article>` (after `<References post={post} />`, before closing `</article>` ~line 257), render:
   ```tsx
   {hasBlogSlides(post.slug) && (
     <div style={{ marginTop: 32, paddingTop: 24, borderTop: "1px solid var(--rule)" }}>
       <a
         href={`/slides/${post.slug}.pptx`}
         download
         style={{ display: "inline-flex", alignItems: "center", gap: 8, fontSize: 14, color: "var(--cyan-600)", textDecoration: "underline" }}
       >
         <I.cards size={14} /> Download slides (.pptx)
       </a>
     </div>
   )}
   ```
   Import `hasBlogSlides` from `@/lib/vault`. Use the existing `I.cards` icon already imported. Do **not** embed Office Online (intentional — see Approach).
5. **Extend `learnova-academy/src/app/sitemap.ts`**. After `blogRoutes` (line 35), add:
   ```ts
   const blogSlideRoutes: MetadataRoute.Sitemap = listPublishableBlogs()
     .filter((b) => hasBlogSlides(b.slug))
     .map((b) => ({
       url: `${BASE}/slides/${b.slug}.pptx`,
       lastModified: new Date(b.date + "T00:00:00Z"),
       changeFrequency: "yearly",
       priority: 0.4,
     }));
   ```
   Import `hasBlogSlides`. Add `...blogSlideRoutes` to the final spread on line 65.
6. **Verify locally (see Verification block for exact commands)**, push the branch, open PR titled `feat(blog): mirror slides.pptx to public/slides + footer link + sitemap (KOEA-1233)` against `academy/redesign-v1`. PR body must include the `wc -l` count and the curl probe output.

## Verification (QA Verifier checks these)

Run from `learnovaBeast-fe-agent/learnova-academy/`:

```bash
# 1. Mirror runs and copies 13 files
rm -rf public/slides
node ./scripts/sync-vault.mjs 2>&1 | grep "blog slide"
ls public/slides/*.pptx | wc -l
# Expected: "[sync-vault] mirrored 13 blog slide deck(s) to public/slides/"
# Expected: 13

# 2. Idempotent re-run copies 0
node ./scripts/sync-vault.mjs 2>&1 | grep "mirrored 0 blog"
# Expected: line matches (mtime+size short-circuit working)

# 3. Build succeeds, sitemap contains the new URLs
pnpm build 2>&1 | tail -20
curl -s http://localhost:3010/sitemap.xml > /tmp/sm.xml &  # after `pnpm start &`
grep -c "/slides/.*\.pptx" /tmp/sm.xml
# Expected: 13 (or however many of the 13 are in publishable state; min 1)

# 4. Blog page renders the link for a blog WITH slides
curl -s http://localhost:3010/blog/2026-04-30-claude-design-visual-workflows | grep -o 'href="/slides/[^"]*"'
# Expected: href="/slides/2026-04-30-claude-design-visual-workflows.pptx"

# 5. Blog page does NOT render the link for a blog without slides
#    (pick any publishable blog NOT in the 13-file list — confirm absence at PR time)
curl -s http://localhost:3010/blog/<no-slides-blog> | grep -c 'href="/slides/'
# Expected: 0

# 6. Direct asset fetch works locally
curl -sI http://localhost:3010/slides/2026-04-30-claude-design-visual-workflows.pptx | head -1
# Expected: HTTP/1.1 200 OK
```

Reviewer checklist:

- [ ] `pnpm typecheck` (or `next build`) passes — no TS errors from the new `hasBlogSlides` export
- [ ] Course slides at `/courses/<slug>/<file>.pptx` still resolve — `curl -I https://<vercel-preview>/courses/.../*.pptx` returns 200 (regression check; the `mirrorCourseMedia` block must remain unchanged)
- [ ] Blog page weight check on `/blog/claude-security-beta-devsecops` stays ≤ 81,920 B (KOEA-1158 threshold) — the download `<a>` adds ≈ 220 B
- [ ] `/sitemap.xml` is well-formed XML (no orphaned tags around the new entries)
- [ ] On a blog **without** `slides.pptx` (e.g. any post under `vault/blogs/` that isn't in the 13-file list), the "Download slides" link is absent from rendered HTML
- [ ] No Convex deploy triggered (`learnova-tc` untouched in the diff)
- [ ] PR commit message references KOEA-1233 and the parent bug GUID

## Risk

- **Vercel build asset size.** 13 × ~3 MB ≈ 40 MB added to the deploy artifact. Vercel's free-tier hard limit is 1 GB per deployment — we are nowhere near, but **if `public/` total exceeds 500 MB** in a future audit, migrate slides to R2 (mirrors the cardinal "inexpensive not cheap" rule by deferring the SaaS cost until needed). Mitigation today: noop; track via `du -sh public/` in PR description.
- **`sync-vault.mjs` runs on every `pnpm dev` start** — adds ~1 s of `copyFileSync` on cold start. The mtime+size short-circuit makes subsequent dev starts free.
- **Blog page weight regression for the 13 slide-bearing blogs.** Adding `<I.cards>` + an `<a>` ≈ 220 B in HTML + Flight payload. Acceptable; verify on `claude-security-beta-devsecops` (the post closest to the 80 KB cap) before merging.
- **Slug case collisions.** Vault directory names are lowercase kebab-case (verified across 13 files). If a future blog uses a slug with non-URL-safe characters, the mirror will fail silently with a copy error. Mitigation: `mirrorBlogSlides()` logs `failed to copy` warnings, same as `mirrorCourseMedia()`.
- **Lock handling**: `sync-vault.mjs` has no file lock today. Two concurrent `pnpm dev` invocations could race the `copyFileSync` — not a real concern (last writer wins, idempotent). No change needed here; an explicit lock is out of scope and over-engineering for this fix.

## Worktree / branch / SHA context

- Target branch: `academy/redesign-v1` @ `76fbd20` (last verified 2026-05-12).
- Recommended worktree path: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-fe-agent` (mirrors KOEA-1158 convention). If parent dir is still `root:root` (KOEA-1158 unblock pending), the executor may use `/tmp/learnovaBeast-1233` and note the deviation in the PR body.
- Cleanup at plan exit: the planner's scratch worktree at `/tmp/learnova-plan-1233` should be pruned by the executor's Step 1 (`git worktree remove --force`).

## Out of scope

- Adding an Office Online embed to blog pages (page-weight risk; see Approach).
- Frontmatter `slides_url` field on blog drafts (convention-over-config wins).
- Migrating any slides to R2 / Cloudflare object storage (deferred until `public/` size demands it).
- Updating courses, glossary, capabilities, or any portal other than `learnova-academy`.
- Backfilling slides for blogs that don't yet have a `slides.pptx` (separate content-author task).
- G5 verifier or publish-pipeline changes (the new `/slides/<slug>.pptx` URLs being added to the sitemap is sufficient to surface them; G5 picks them up automatically if it probes sitemap entries — confirm with @publish-verifier after deploy).
- llms.txt / llms-full.txt updates (slides aren't text content; no LLM benefit from listing them).

## Notes for the board

- This bug pattern (vault-side asset → never mirrored to FE `public/`) is the same shape as the original course-media bug fixed in `0550823 fix(build): clone koenig-ai-org vault during Vercel prebuild` and the course pptx work in `a07900d feat(blog,course): hero/inline images, references, audio+pptx embed, full-width`. Consider one consolidated `mirrorVaultAssets()` pass in `sync-vault.mjs` as a follow-up (out of scope here) so courses, blogs, and any future content type share a single config-driven mirror loop.
- Future blogs will need `slides.pptx` authored under `vault/blogs/<slug>/`. The Content Author skill should be updated to make slide-deck generation a default deliverable for new blog posts — file a separate ticket against `@content-author` if the academy product values slides as standard.
