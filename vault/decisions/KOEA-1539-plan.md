---
ticket: KOEA-1539
planner_ticket: KOEA-1541
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.15
status: ready-for-plan-review
worktree: /paperclip/instances/default/workspaces/learnovaBeast-fe-agent
target_branch: academy/redesign-v1
sibling_vault_repo: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org (master)
no_convex_deploy: true
related_plan: ./KOEA-1437-plan.md (fix-1b carve-out)
---

# Plan: 301 redirect for stale supply-chain threat atlas slug (KOEA-1539)

## Goal

After this lands, `https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas`
returns **HTTP 308** (Next.js default for permanent redirects; or 301 if `statusCode` is set)
with `Location: /blog/ai-coding-agent-supply-chain-threat-atlas-2026`. The new URL
already serves 200 today; only the legacy-slug → new-slug hop is missing.

## Context

### Live state (verified 2026-05-13)

| URL | Current | Target |
|---|---|---|
| `/blog/ai-coding-agent-supply-chain-threat-atlas-2026` (new, canonical) | **HTTP 200** ✅ | unchanged |
| `/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas` (legacy slug) | **HTTP 404** ❌ | **HTTP 308** → new slug |

The new-slug deploy already shipped (the supply-chain redeploy from KOEA-1437 fix-1a
landed sometime between the KOEA-1437 plan being written and this verification).
What's missing is the legacy-slug 301 — inbound links from search engines,
Slack history, prior blog references all currently hit a 404 cold.

### Files to read first

**FE repo `learnovaBeast` (target branch `academy/redesign-v1`):**

- `learnova-academy/next.config.ts` — current 22 lines, **no `redirects()` function yet**.
  The whole config object is:
  ```ts
  const nextConfig: NextConfig = {
    reactStrictMode: true,
    experimental: { optimizePackageImports: [...], optimizeCss: true },
    images: { remotePatterns: [...] },
  };
  ```
  Executor must add an `async redirects()` field. There is no existing
  `BLOG_SHORT_SLUG_REDIRECTS` array to extend — the KOEA-1437 plan's read of the file
  was inaccurate (referenced lines 5–19 of that name, but those lines don't exist
  in `origin/academy/redesign-v1` as of commit `8a71437` on 2026-05-13).

- `learnova-academy/src/app/blog/[slug]/page.tsx` — read only to confirm the new slug
  is the canonical form emitted by `generateMetadata` (it is — page is live at the
  new URL).

**Vault repo `koenig-ai-org` (master), read-only:**

- `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/draft.md` — confirms
  the new slug is the editorially-chosen canonical form. No content change needed.

### Relevant prior work / overlap

- **KOEA-1437 fix-1b** ([./KOEA-1437-plan.md](./KOEA-1437-plan.md) step 10) prescribed
  the same redirect inside a larger four-fix bundle. **KOEA-1437 was cancelled
  before any of its fixes shipped** — except that the supply-chain blog redeploy
  (fix-1a) appears to have happened through a separate path, since the new URL
  is now HTTP 200. The redirect (fix-1b) was never executed. This ticket is the
  clean, isolated execution of that one missing piece. No coordination needed
  with the KOEA-1437 chain because that chain is closed; the other fixes
  (slides surface, meta-description fallback, verifier speculation prohibition)
  would need separate tickets if still needed.
- Memory `project_blog_slug_rename_deploystaleness` (2026-05-13) — root cause family:
  vault folder rename after publish leaves old URL stale. Standard fix is the
  301 plus a redeploy. The redeploy already happened; this plan handles the 301.
- Memory `project_publish_verifier_poll_no_dedup` (2026-05-13) — same-symptom G5
  BLOCK tickets get re-dispatched into parallel chains. KOEA-1539 is a focused
  re-dispatch after KOEA-1437 was cancelled; the narrow scope (one redirect)
  makes it independently shippable and is the right path.

### Constraints (from ticket)

- Plan mode only — no code edits in this heartbeat.
- Do not modify other portals (Academy `learnova-academy` only).
- Do not deploy Convex (`learnova-tc` untouched — Next.js static redirect).
- FE worktree `~/Documents/Paperclip/learnovaBeast-fe-agent/` was prescribed by the
  ticket but does NOT exist on disk; the actual FE worktree is at
  `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent` and is currently
  on branch `koea-1316/vercel-deploy-heap-bump`. Executor pre-flight must switch
  that worktree to `academy/redesign-v1` (or create a new worktree) before editing.
- `.claude/agent-lock` was prescribed; no such file exists at either worktree path
  today. Executor should respect any lock present at edit time, but absence is
  fine — note this as a worktree-state observation, not a blocker.

## Approach

**Chosen — single-edit `redirects()` function in `next.config.ts`, one entry, permanent.**

Add an `async redirects()` async method to the `NextConfig` object returning one
redirect entry. Use `permanent: true` (Next.js emits HTTP 308 by default for permanent;
search engines treat 308 as 301-equivalent for ranking purposes — both signal
"this URL is gone, follow the new one"). The implementation is ~6 lines including
the function wrapper.

**Why this shape:**
- No array constant or helper module — premature abstraction for a single entry.
  If a second redirect lands later, the same shape extends to an array literal in
  the same place.
- `async` (not sync) — Next.js docs treat `redirects()` as async; staying consistent
  with the framework signature avoids friction if we later want filesystem reads
  to populate it.
- Inline strings, no consts — three identifiers (`source`, `destination`,
  `permanent`) read fine inline; extracting to constants would obscure the only
  thing a reviewer needs to see.

**Rejected alternatives:**

- *Add `BLOG_SHORT_SLUG_REDIRECTS` array + map helper now.* Rejected — KOEA-1437
  plan prescribes this shape for an eventual multi-entry future, but with only
  one entry today the array+map adds five lines of structure around one tuple.
  Defer the shape to when there are ≥3 entries; for one entry, just inline.
- *Use a Convex http action / middleware-level redirect.* Rejected — explicit
  no-Convex-deploy constraint, plus `redirects()` is the well-trodden Next.js
  primitive for exactly this case.
- *Server-side rewrite (rewrite, not redirect).* Rejected — would serve the new
  content under the old URL with HTTP 200, hiding the canonicalization from SEO
  and bookmarks. We want the URL to actually change in the browser bar.
- *Generate the redirect from vault frontmatter (e.g. a `redirects_from:` field).*
  Rejected as in-scope — that's a build-time codegen system worth designing
  separately when we have ≥5 such rename events. For now, one tuple in
  `next.config.ts` is faster and clearer.
- *Wait for KOEA-1437 to ship its bundle.* Rejected — KOEA-1437 is `cancelled`;
  no bundle is coming. Legacy URL is 404 today for inbound traffic. This redirect
  is six lines of net code and ships in one Vercel build cycle (~3 min).

## Steps (Executor follows in order)

1. **Pre-flight: align worktree.** In `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent`,
   stash or commit any in-flight work on `koea-1316/vercel-deploy-heap-bump`, then
   `git fetch origin && git checkout academy/redesign-v1 && git pull --ff-only origin academy/redesign-v1`.
   If the worktree cannot be repointed safely (uncommitted work on the heap-bump
   branch), create a fresh worktree:
   `git worktree add /paperclip/instances/default/workspaces/learnovaBeast-fe-1539 academy/redesign-v1`
   and work there. Confirm `HEAD = 8a71437` (or later) before editing.

2. **Create feature branch:** `git checkout -b koea-1539/supply-chain-slug-301` off
   `academy/redesign-v1`.

3. **Edit `learnova-academy/next.config.ts`.** Insert one async method into the
   `nextConfig` object, after the `images` field and before the closing brace.
   Final shape:
   ```ts
   const nextConfig: NextConfig = {
     reactStrictMode: true,
     experimental: { optimizePackageImports: [...], optimizeCss: true },
     images: { remotePatterns: [...] },
     async redirects() {
       return [
         {
           source: "/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas",
           destination: "/blog/ai-coding-agent-supply-chain-threat-atlas-2026",
           permanent: true,
         },
       ];
     },
   };
   ```
   No comment needed — the slug pair is self-explanatory. Do NOT add helper
   modules, constants, or other redirects in this PR.

4. **Local verify:**
   - `pnpm --filter learnova-academy run typecheck` → green.
   - `pnpm --filter learnova-academy build` → succeeds, no warnings about the
     new field.
   - (Optional, if Executor has a local dev server up:) `curl -sI
     http://localhost:3000/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas`
     → `HTTP/1.1 308` with the expected `Location` header.

5. **Open PR against `academy/redesign-v1`.** Title: `fix(blog): 301 legacy
   supply-chain-threat-atlas slug to canonical (KOEA-1539)`. PR description must
   include: link to this plan; the verified pre/post URL states (V1–V3 below);
   note that this carves out KOEA-1437 fix-1b and that KOEA-1437 Executor should
   drop step 10 from its eventual bundle.

6. **Deploy.** Merge to `academy/redesign-v1` triggers Vercel build via existing
   GitHub Actions; no extra dispatch needed.

7. **Post-deploy verify** (Executor runs in same heartbeat as merge):
   - V1 below must flip from 404 → 308 with the right Location header.
   - V2 (new URL still 200) must remain unchanged.

## Verification (QA Verifier / Plan Reviewer checks these)

| # | Check | Pre-fix | Post-fix |
|---|---|---|---|
| V1 | `curl -sI https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas \| head -3` | `HTTP/2 404` | `HTTP/2 308` with `location: /blog/ai-coding-agent-supply-chain-threat-atlas-2026` |
| V2 | `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| head -1` | `HTTP/2 200` | `HTTP/2 200` (unchanged) |
| V3 | `curl -sL -o /dev/null -w '%{url_effective}\n' https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas` | (empty, 404) | `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026` (follows the redirect to 200) |
| V4 | TypeScript build green: `pnpm --filter learnova-academy run typecheck` | — | exit 0 |
| V5 | No regression on any other blog slug: spot-check 3 unrelated blog URLs return their existing status codes after the deploy. | (status quo) | unchanged |

## Risk

- **308 vs 301 status code.** Next.js `permanent: true` emits HTTP 308 by default,
  not 301. Both signal "moved permanently" to crawlers and modern browsers, but
  some legacy clients (very old curl, some bots) only special-case 301. If a
  reviewer flags this, the fix is `statusCode: 301` instead of `permanent: true`
  — same semantics, explicit status. Default to `permanent: true` first; only
  switch if SEO ops asks.

- **Worktree-state divergence.** The FE worktree is on a different branch
  (`koea-1316/vercel-deploy-heap-bump`). Step 1 handles this, but Executor must
  not silently stash someone else's WIP. If the heap-bump branch has uncommitted
  work, create a separate worktree rather than disturbing the existing one.

- **KOEA-1437 collision.** Eliminated — KOEA-1437 is `cancelled` so no parallel
  PR will add a competing `redirects()` block.

- **Build cache.** Vercel caches `next.config.ts` parses. New deploy will always
  bust because the file content changed; no manual invalidation needed.

## Out of scope (explicit)

- The supply-chain blog redeploy itself — already shipped (new URL = 200 today).
- Any other blog slug rename / redirect — single-entry plan, single ticket.
- A general `BLOG_SHORT_SLUG_REDIRECTS` registry, vault-driven redirects, or
  helper module — defer until ≥3 entries.
- Convex (`learnova-tc`) changes — explicitly forbidden by ticket.
- KOEA-1437's other fixes (slides surface, meta-description fallback, verifier
  speculation prohibition) — those remain owned by KOEA-1437.
- Updating Publish Verifier skill or SOUL — no skill change required for this
  redirect.
- Sitemap / RSS feed updates — Next.js redirects are transparent to sitemap
  generation; the canonical slug is already in the sitemap because the new URL
  is live.

## Handoff

- Plan ready for plan-review (Code Reviewer).
- On plan-review acceptance: Executor opens PR per Steps 1–6.
- After merge + V1/V2/V3 green: Executor comments on parent KOEA-1539 with the
  three curl outputs and PATCHes status=done.
- No KOEA-1437 coordination needed — that ticket is `cancelled`. This plan is
  the sole live path for the redirect.
