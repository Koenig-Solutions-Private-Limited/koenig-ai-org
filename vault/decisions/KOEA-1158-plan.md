---
ticket: KOEA-1158
planner: planner
date: 2026-05-12
estimated_complexity: small
estimated_token_cost: $0.35
status: ready-to-execute (pending worktree unblock — see Risk)
related: KOEA-265 (publish), KOEA-1161 (this planning task), G5 sidecar 2026-05-12-claude-security-beta-devsecops
---

# Plan: Bring `/blog/claude-security-beta-devsecops` under 80 KB HTML

## Goal

Live HTML response for `https://academy.kspl.tech/blog/claude-security-beta-devsecops` drops from **92,160 bytes → ≤ 81,920 bytes (≤ 80 KB)** so the G5 page-weight check flips from BLOCK to PASS. No other published blog regresses above its threshold. Same template fix should structurally bring most blog posts under target — not a one-off content edit.

## Context

- **Source repo (FE)**: `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` — branch `ci/koea-426-rebase-clean` @ `f94029aaca4d25d627dbffcd935fd77966b8cf96`. Owned `node:dialout`, writable.
- **Vault draft**: `vault/blogs/claude-security-beta-devsecops/draft.md` (9,190 bytes raw markdown) — **do not edit**; content already passed G0/G2/G3.
- **G5 sidecar**: `vault/marketing/publish-verify/2026-05-12-claude-security-beta-devsecops.md` — 7 checks pass, 2 block: Source URL (Business Standard 403) routes to content; page weight 92,160 B routes here.
- **Files to inspect / change**:
  - `learnova-academy/src/app/blog/[slug]/page.tsx` — server component, all inline styles + Flight payload origin
  - `learnova-academy/src/app/blog/[slug]/client-shell.tsx` — receives `body` + `markdownForToc` (duplicated)
  - `learnova-academy/src/components/_shared/tutor.tsx` — TutorRail prop surface (`body` consumer)
  - `learnova-academy/src/components/_shared/toc.tsx` — `extractHeadings` (already mirrored server-side as `extractHeadingsForScroll` in page.tsx)
  - `learnova-academy/src/lib/seo.ts` — JSON-LD generators (only 2,220 B on the wire; no change needed)
  - `learnova-academy/src/app/globals.css` — destination for extracted utility classes
- **Constraints**: don't restructure RSC/publishing pipeline; don't rewrite `prose` Tailwind classes; preserve all anchor IDs (TOC + JSON-LD reference them).

## Decomposition of the 92,160 bytes (measured 2026-05-12)

| Bucket | Bytes | Share | Lever? |
|---|---|---|---|
| RSC Flight chunks (`self.__next_f.push([1,"..."])`, 23 chunks) | 58,695 | 64% | YES — biggest lever |
| Inline `style="..."` attrs in HTML (128 attrs) | 8,726 | 10% | YES |
| JSON-LD (BlogPosting + BreadcrumbList + FAQPage) | 2,220 | 3% | no |
| Other markup (links, scripts, head, body chrome) | ~22,000 | 23% | partial |

Crucially, **inline styles appear twice** (once in HTML, once in the Flight payload), so a single style→class refactor compounds. The Flight payload also serialises the full markdown body passed as a prop to `BlogPageClient`, then a second time as `markdownForToc` — the same ~9 KB string twice.

## Approach (1 chosen, alternatives rejected)

**Chosen — Trim Flight payload + class-ify inline styles.** Two cuts:

1. **Stop passing body markdown to the client shell.** `BlogPageClient` currently receives `body` and `markdownForToc` (identical strings). Compute headings server-side (already done via `extractHeadingsForScroll`) and pass `Heading[]` only. `TutorRail`'s `body` prop becomes lazy — fetched on first chat open. Saves ≈9–11 KB from Flight chunks.
2. **Replace inline `style={{…}}` on layout containers with `className` references** in `globals.css`. Hot spots: hero wrapper, article wrapper, h1/h2/h3 inline styles, eyebrow div, learning-objectives box, references section. Save ≈6–8 KB across HTML + Flight.

Combined headroom: ≈15–19 KB on a 12 KB-over deficit. Comfortably under 80 KB with safety margin for future content growth.

**Rejected**:
- *Disable client hydration* (`export const dynamic = false`) — breaks TutorRail + CommandPalette + scroll-spy TOC. Too disruptive.
- *Shrink article body content* — content authority concern; routes to `@content-author`, not engineering. Out of scope per ticket.
- *Switch off RSC entirely / migrate to pages router* — multi-day rewrite, far over budget.
- *Compress JSON-LD or drop FAQPage* — only saves <1 KB and hurts GEO/AEO. Not worth it.

## Steps (Executor follows in order)

1. **Class-ify the heavy inline styles in `src/app/blog/[slug]/page.tsx`.** Replace `style={{…}}` props on these elements with `className` referencing new utility classes in `globals.css`:
   - Hero wrapper + `<Image>` container (lines ≈104–134)
   - `<main>` / `<article>` containers (lines ≈136–143)
   - Meta-chip row (lines ≈144–166)
   - `<h1 className="h1-article">` inline styles (≈168–179)
   - Author byline div (≈181–207)
   - Learning-objectives block (≈208–240)
   - `<References>` section (≈651–720)
   - Inside `renderBlock`: `<h2>` / `<h3>` / `<hr>` / `<p>` defaults (lines ≈320–453). Use `.prose-h2`, `.prose-h3`, `.prose-p`, `.prose-hr`.
   Keep `prose` Tailwind class on the body wrapper. Add ≈10 small utility classes in `globals.css` mirroring the current inline values exactly so visuals are byte-identical.
2. **Cut duplicated markdown from the client-shell props.** In `src/app/blog/[slug]/page.tsx`, change the `<BlogPageClient …/>` call to pass `headings={headings}` (the already-computed `Heading[]`) and drop `body` + `markdownForToc`.
3. **Update `src/app/blog/[slug]/client-shell.tsx`.** Replace `body` + `markdownForToc` in `BlogPageClientProps` with `headings: Heading[]`. Pass `headings` straight to `<Toc items={headings} />`. Drop the `useMemo` + `extractHeadings` call (server-side is authoritative now). Remove the `body` prop from `<TutorRail body={body} …/>`.
4. **Make TutorRail fetch body lazily** in `src/components/_shared/tutor.tsx`. On first chat-open, fetch the markdown via the existing vault read path (e.g. `GET /api/vault/blog/<slug>` if present, else add a thin route that re-uses `getBlog(slug).body`). Cache the result in component state. Until opened, no body is shipped.
5. **Build + measure locally**: `cd learnova-academy && pnpm build && pnpm start &` then `curl -s http://localhost:3000/blog/claude-security-beta-devsecops | wc -c` — expect ≤ 81,920. If above, halt before step 6 and re-decompose with the measurement script in the Verification section.
6. **Push to a Vercel preview**, then `curl -s <preview-url> | wc -c` to confirm ≤ 81,920 in production conditions BEFORE merging. Then PR → master and let auto-deploy run.

## Verification (QA Verifier + G5 re-run will check)

- [ ] `curl -s https://academy.kspl.tech/blog/claude-security-beta-devsecops | wc -c` returns **≤ 81,920**
- [ ] At least 2 other published blogs (e.g. `/blog/gpt-5-5-vs-claude-opus-4-7-agentic-coding`, `/blog/mcp-from-first-principles-to-production`) remain **≤ their threshold** after deploy
- [ ] Article body still renders end-to-end: h1, all h2/h3 anchors, prose paragraphs, Knowledge Check `<details>`, References section
- [ ] Floating TOC (bottom-left) still lists every heading and scroll-spy highlights the active section as the user scrolls
- [ ] Tutor FAB (bottom-right) opens; first message answers a question about the article (proves lazy body fetch lands successfully)
- [ ] JSON-LD still parses with required `@type`s: `BlogPosting` + `BreadcrumbList` (and `FAQPage` if currently wired). No console errors.
- [ ] Sitemap + llms.txt entries unchanged (no template path renaming)

Reproducible measurement script for the Executor to use after each step:

```bash
URL="https://academy.kspl.tech/blog/claude-security-beta-devsecops"
curl -s "$URL" -o /tmp/page.html && wc -c /tmp/page.html
python3 -c "
import re
h = open('/tmp/page.html').read()
ld = re.findall(r'<script type=\"application/ld\+json\"[^>]*>(.*?)</script>', h, re.DOTALL)
st = re.findall(r'style=\"[^\"]*\"', h)
nx = re.findall(r'self\.__next_f\.push\(\[1,\"(.*?)\"\]\)', h, re.DOTALL)
print(f'jsonld={sum(len(x) for x in ld)} inline_styles={len(st)}/{sum(len(x) for x in st)} flight={len(nx)}/{sum(len(x) for x in nx)}')
"
```

## Risk

- **Lazy tutor fetch may delay first chat open.** Mitigation: prefetch the markdown on FAB hover (`onMouseEnter` triggers fetch, response cached). If even step 1 + 2 alone (without lazy tutor) gets the page under 80 KB, skip step 4 to avoid the UX delta — measure after step 3.
- **CSS class collisions.** If a utility name in `globals.css` already exists with a different rule, namespace new ones under `.blog-` prefix.
- **Generated-style parity.** Class-ifying must produce byte-identical visuals (the same border, radius, padding). Visual diff at least the hero + h1 + references block before merging.

## Worktree / branch / SHA context (blocking note)

The ticket flags that the expected FE worktree at `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast-fe-agent` is **absent** because the parent `/Users/vardaankoenig/Documents/Paperclip/` is `root:root` and Chief Engineering could not `mkdir` there. **Confirmed at plan time** — directory still missing.

The existing `learnovaBeast` checkout at `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast` IS present (owner `node:dialout`, writable), currently on branch `ci/koea-426-rebase-clean` at `f94029aaca4d25d627dbffcd935fd77966b8cf96`. PR #14 (the parent of this commit) is squashed/merged.

**Executor cannot start until one of the following is true** (block-soft on planning, blocking on implementation):

1. **Preferred — create the dedicated worktree** (owner: human Vardaan or any chief with sudo):
   ```
   sudo chown -R vardaankoenig:staff /Users/vardaankoenig/Documents/Paperclip
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
   git fetch origin
   git worktree add -b fe/KOEA-1158-blog-weight ../learnovaBeast-fe-agent origin/master
   ```
2. **Fallback — reuse the existing checkout** (owner: Executor + coordination): branch off `origin/master` directly inside the existing `learnovaBeast` checkout, but ONLY if no other agent holds work on `ci/koea-426-rebase-clean`:
   ```
   cd /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
   git fetch origin
   git stash -u    # park any uncommitted state
   git checkout -b fe/KOEA-1158-blog-weight origin/master
   ```
   Risk: collides with any concurrent FE work on the same checkout.

**Recommended unblock**: open a brief comment on KOEA-1158 asking @ceo / @chief-engineering to take path (1) so the FE worktree separation that Chief Engineering already provisioned can be honored. If we have not heard back within one heartbeat, Executor may take path (2) at their discretion and note it in the PR.

## Out of scope

- Changes to article body content (route to `@content-author` if needed)
- JSON-LD schema restructure
- Hero image optimization (PNG dimensions already PASS in G5)
- Whole-template rewrite, RSC opt-out, or framework changes
- `/blog` index page, `/authors/*` pages, or other published surfaces
- Business Standard source-URL 403 (separate G5 block; routes to content)

## Notes for the board

If page-weight regressions become a pattern (this is the second observed: KOEA-1158 today, MCP-2026-roadmap previously hit 107 KB per `verify-publish/SKILL.md`), consider a follow-up ticket to add an automated page-weight CI check on each blog template change.
