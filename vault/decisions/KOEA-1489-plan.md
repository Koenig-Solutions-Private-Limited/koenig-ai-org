---
ticket: KOEA-1489
planner_ticket: KOEA-1492
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.35
status: ready-for-plan-review
worktree: /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
branch_off: main
branch_name: koea-1489/atlas-redeploy-301
sibling_vault_repo: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org (master)
no_convex_deploy: true
related_plan: ./KOEA-1437-plan.md (Fix 1 — superseded for this slug)
---

# Plan: redeploy supply-chain threat atlas under canonical slug + 301 the stale slug

## Goal

Two observable end states, in a single Vercel build:

1. `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026` → `HTTP/2 200`, with canonical link tag pointing to itself and ≥ 1 `application/ld+json` block emitted (BlogPosting at minimum).
2. `https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas` → `HTTP/2 301` with `Location: /blog/ai-coding-agent-supply-chain-threat-atlas-2026`.
3. Discovery surfaces (`sitemap.xml`, `rss.xml`, `llms-full.txt`) reference only the canonical slug — derived automatically from the rebuild, no manual edit.

Unblocks: KOEA-1487 (G5 discovery surfaces block), KOEA-1472 (publish-verifier poll), parent SEO/GEO chain.

## Context

### Current state observed (2026-05-13, 06:00 IST, Planner)

| Surface | Observation |
|---|---|
| `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/draft.md` | Exists, frontmatter `slug: "ai-coding-agent-supply-chain-threat-atlas-2026"`, `status: g3-passed`, `date: 2026-05-06`. |
| Old date-prefixed vault folder `vault/blogs/2026-05-06-ai-coding-agent-supply-chain-threat-atlas/` | **Does not exist.** Folder was renamed before this plan was written. |
| Paperclip issue KOEA-366 | `status=done`, `metadata.publish_state=published`, `metadata.slug=ai-coding-agent-supply-chain-threat-atlas-2026`, `published_url=None`, `dispatched_at=None` — i.e. the `published` flag is from the pre-V3.0 (Option A) publish system, never went through the current V3.0 `repository_dispatch` path. |
| Other issues touching this slug | KOEA-1177 (status=done, no publish_state), KOEA-365 + KOEA-364 (cancelled). Only KOEA-366 should be flipped. |
| `learnovaBeast` default branch | `main` at `origin/main = 85d7945`. The publish workflow `.github/workflows/publish.yml` uses `actions/checkout@v4` with no `ref:`, so production deploys from `main`. |
| `learnova-academy/next.config.ts` on `main` | **No `redirects()` block exists.** No `BLOG_SHORT_SLUG_REDIRECTS` constant exists on any branch (grepped all refs). The KOEA-1437-plan.md reference to "extend `BLOG_SHORT_SLUG_REDIRECTS`" assumed something that was never built. |
| `academy/redesign-v1` next.config.ts | Also no `redirects()`, but adds `experimental.optimizePackageImports` + `optimizeCss`. The branch is divergent from `main` and there is no in-flight PR merging it. Landing the 301 here would NOT reach production. |
| FE worktree at `~/Documents/Paperclip/learnovaBeast-fe-agent/` | **Does not exist on disk.** Only `~/Documents/Paperclip/learnovaBeast` (on `koea-1326/g2-blocker-fixes`) and a Paperclip-managed worktree at `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent` (on `koea-1316/vercel-deploy-heap-bump`) are present. |
| Live canonical URL | `curl -sI` returns `HTTP/2 404` (verified by Publish Verifier in KOEA-1487). |
| Live stale URL | `curl -sI` returns `HTTP/2 200` — Vercel still serves the previously-built page from cache; the vault no longer references it so a fresh build will not include it in `generateStaticParams()`. |

### Files to read first

**`learnovaBeast` (off `main` at `85d7945`):**

- `learnova-academy/next.config.ts` — target for the new `redirects()` block (currently 22 lines; no `redirects` key).
- `learnova-academy/src/app/blog/[slug]/page.tsx` — confirms `export const dynamic = "force-static"` and `generateStaticParams` reads `listPublishableBlogs()`. No template change needed for this plan.
- `learnova-academy/src/lib/vault.ts` — `PUBLISHABLE_STATES = { g0-passed, g3-passed, published }`. Confirms `status: g3-passed` will be picked up by the next build. No vault.ts change needed.
- `learnova-academy/src/app/sitemap.ts` + `src/app/rss.xml/route.ts` + `src/app/llms-full.txt/route.ts` — all derive blog routes from `listPublishableBlogs()`. A successful rebuild auto-corrects discovery surfaces; no manual edit required.
- `.github/workflows/publish.yml` — listens on `repository_dispatch[publish-ready]`, builds + deploys via Vercel CLI.

**`koenig-ai-org` (master):**

- `scripts/publish-action.sh:266-383` — Phase 0 env-check, Phase 1 g4-approved → repository_dispatch, Phase 2 dispatching → published.
- `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/draft.md` — confirm `status: g3-passed` still set, no rev needed.
- `.env.koenig` — confirm `GH_PAT_DISPATCH` present (per `publish-action.sh:271-273`).
- `infra/launchd/com.koenig.publish-action.plist` — confirm `COMPANY_ID=2a77f89b-33f0-4133-a20c-77ddaac5e744` and loaded by launchctl.

### Relevant prior work + constraints

- [KOEA-1437-plan.md](./KOEA-1437-plan.md) Fix 1 — same problem, broader plan. **This plan supersedes it for the supply-chain slug only.** Two key corrections this plan applies:
  - KOEA-1437 said "extend `BLOG_SHORT_SLUG_REDIRECTS`" — that constant does not exist. We add a fresh `redirects()` function.
  - KOEA-1437 said branch on `academy/redesign-v1` — that branch is divergent from `main` with no merge in flight, so a redirect added there would not reach production. We branch off `main`.
- Memory note `project_publish_action_broken_2026_05_12` (KOEA-1137) — four-cause launchd outage. Step 1 pre-flight re-verifies all four causes before relying on Phase 1 dispatch.
- Memory note `project_blog_slug_rename_deploystaleness` (2026-05-13, KOEA-1437) — confirms the diagnosis: rename leaves old URL stale-200 + new URL 404 until a redirect + redeploy land.
- Memory note `feedback_planner_status_flip` (2026-05-13) — this plan must end with a status flip on KOEA-1492 in the same heartbeat as the plan comment.
- **Explicit no-Convex constraint** (ticket): no `learnova-tc` deploy. All work is Vercel-static (`next.config.ts redirects()` + a Paperclip state flip + a vault rebuild). If a later step shows Convex would be needed, **STOP and escalate** — that's an architectural change beyond this ticket.

### Definitively out of scope

- The other three KOEA-1437 fixes (`slides surface`, `seo_description` backfill, verifier no-speculation rule) — separate work, separate plan, not blocking this slug going live.
- Any change to `learnova-tc` (Convex).
- Rewriting blog body copy on the canonical slug.
- Cleaning up the cancelled KOEA-365 / KOEA-364 sibling issues (housekeeping, not deploy-critical).
- Touching `academy/redesign-v1` — see Approach for why.
- Building the missing `~/Documents/Paperclip/learnovaBeast-fe-agent/` worktree as a system-level fix — flagged but not in scope; we use the existing `~/Documents/Paperclip/learnovaBeast` checkout.

## Approach

**Chosen — small surgical PR on `main`, plus a pipeline state flip via a sibling child issue, both shipping in one Vercel build.**

Three coupled operations:

1. **Pre-flight gate** (no code change) — re-run the four KOEA-1137 health checks before touching anything. If any fail, escalate; this plan is unshippable until publish-action.sh is functional.
2. **Pipeline state flip** (no code change) — flip Paperclip issue KOEA-366 `metadata.publish_state` from `published` back to `g4-approved`. publish-action.sh Phase 1 picks it up on the next 60s tick and dispatches `repository_dispatch[publish-ready]` to learnovaBeast GH Actions. Phase 2 polls + flips to `published`. **Executor does not edit publish_state directly**; create a child issue assigned to `@chief-engineering` who owns the publish-state machine.
3. **301 redirect** (small code change on `main`) — add a `redirects()` function to `learnova-academy/next.config.ts` returning the single legacy → canonical mapping. Ship the redirect FIRST so it is present in the build that the state flip will trigger.

**Why one PR + one state flip, not one big bang:** the redirect is a normal frontend change owned by the FE worktree. The state flip is a control-plane operation owned by the publish pipeline. Mixing them in a single agent would conflate roles. The Vercel build sequencing ensures both land in the same artifact: redirect commits to `main` → state flip dispatches → GH Actions checks out `main` (latest) → builds with the new redirect + the canonical slug → deploys.

**Rejected alternatives:**

- *Add the redirect to `academy/redesign-v1` per KOEA-1437.* — Rejected: `academy/redesign-v1` is divergent from `main` with no merge in flight, and production deploys from `main`. The redirect would never reach prod. (This is also a quiet correction to the earlier plan — flagged in Context.)
- *Manually edit `sitemap.ts` / `rss.xml/route.ts` / `llms-full.txt/route.ts` to remove the stale slug.* — Rejected: explicitly forbidden by the ticket ("not by manually editing discovery outputs"). Also unnecessary: a fresh build of `main` will regenerate all three from `listPublishableBlogs()`, which only reads vault folders that currently exist.
- *Vercel-side redirect via the Vercel project settings UI.* — Rejected: not source-controlled, invisible in `git log`, reverts on next deploy because `vercel.json` / `next.config.ts` override the UI. Codifying the redirect in `next.config.ts` makes it part of the build.
- *Convex `httpAction` for the legacy slug.* — Rejected: explicit no-Convex-deploy constraint; `next.config.ts redirects()` is the established pattern.
- *Use a Next.js middleware to 301 the legacy slug.* — Rejected: middleware adds an Edge-function invocation per request even for the 200-path, and `redirects()` in next.config is the documented zero-cost solution for static slug → slug redirects. The slug list is one entry — there is no scale need for middleware.
- *Re-rename the vault folder to date-prefix.* — Rejected: editorial decision to use the year-suffix form is intentional (per KOEA-366 SEO recommendation and KOEA-1437 rationale). Reverting re-opens the question on the next sync.
- *Flip KOEA-366 publish_state directly in the redirect PR by editing a metadata file.* — Rejected: publish_state lives in Paperclip's Postgres, not in a file. The PATCH must go through the Paperclip API. That's a runtime control-plane op, not a build artifact.

## Steps (Executor follows in order)

### Step 1 — Publish-action pre-flight (no code change; must pass before any other step)

Run in `koenig-ai-org`:

```bash
# 1a. launchd job loaded?
launchctl list | grep com.koenig.publish-action || echo "FAIL: not loaded"

# 1b. GH_PAT_DISPATCH present in .env.koenig?
grep -q "^GH_PAT_DISPATCH=." .env.koenig && echo "OK: GH_PAT_DISPATCH set" || echo "FAIL: missing"

# 1c. COMPANY_ID in plist matches Koenig company?
plutil -extract ProgramArguments xml1 -o - infra/launchd/com.koenig.publish-action.plist 2>/dev/null \
  | grep -q "2a77f89b-33f0-4133-a20c-77ddaac5e744" \
    && echo "OK: COMPANY_ID matches" \
    || echo "FAIL: plist company_id wrong or absent"

# 1d. Last log line shows successful Phase 0 (no recent crash)?
tail -1 ~/.paperclip/logs/publish-action.log
```

If any of (1a, 1b, 1c) FAIL → **STOP, comment the failing check on KOEA-1489, escalate to KOEA-1137 owner. Do not proceed to Step 2.**

### Step 2 — Open child issue: pipeline state flip on KOEA-366

Create a child issue under KOEA-1489 (this plan's parent), assigned to `@chief-engineering`, title:

> "Redeploy supply-chain threat atlas via publish-action state flip (KOEA-366)"

Description (exact text Executor should use):

```text
Trigger redeploy of slug ai-coding-agent-supply-chain-threat-atlas-2026 through the V3.0 publish pipeline.

Action:
1. Wait for the redirect PR from KOEA-1489 to merge to main (Executor will link the PR here).
2. PATCH KOEA-366 metadata.publish_state from `published` → `g4-approved`:
     curl -sX PATCH "$PAPERCLIP_URL/api/issues/<KOEA-366-uuid>" \
       -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
       -H "Content-Type: application/json" \
       -d '{"metadata":{"publish_state":"g4-approved"}}'
3. Within 60s, publish-action.sh Phase 1 dispatches repository_dispatch[publish-ready]; metadata.publish_state flips to `dispatching` + dispatched_at set.
4. Phase 2 polls GH Actions; on success, publish_state → `published`, published_at + published_url set, publish-verifier (G5) heartbeat invoked.

Acceptance: KOEA-366 metadata.publish_state is `published` (post-redeploy timestamp) AND `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 | head -1` returns `HTTP/2 200`.

Rollback if dispatch_failed:
- Read metadata.dispatch_failure_reason on KOEA-366.
- If GH Actions failure: open KOEA-1326-class CI ticket, do not retry blindly.
- If repository_dispatch HTTP != 204: re-check GH_PAT_DISPATCH scope (repo + workflow).
```

This child issue blocks on the redirect PR landing. Executor links the PR back to this issue once opened.

### Step 3 — Add the 301 redirect to `next.config.ts` on `main`

In `~/Documents/Paperclip/learnovaBeast`:

```bash
git fetch origin main
git checkout -b koea-1489/atlas-redeploy-301 origin/main
```

Edit `learnova-academy/next.config.ts`. Insert before the closing `};`:

```ts
async redirects() {
  return [
    {
      // Slug canonicalization: date-prefix → year-suffix.
      // Original ship date 2026-05-06; canonical slug uses year-suffix per editorial decision.
      // See vault/decisions/KOEA-1489-plan.md.
      source: "/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas",
      destination: "/blog/ai-coding-agent-supply-chain-threat-atlas-2026",
      permanent: true,
    },
  ];
},
```

Commit message:

```text
fix(blog): 301 legacy date-prefixed supply-chain atlas slug to canonical (KOEA-1489)

Vault folder was renamed from `2026-05-06-ai-coding-agent-supply-chain-threat-atlas`
to `ai-coding-agent-supply-chain-threat-atlas-2026` (year-suffix canonical form).
The old URL is still serving stale-200 from a prior Vercel build artifact, and
the new URL is 404 because no redeploy fired against the new vault folder.

This permanent redirect closes the inbound-link gap. A separate child issue
(see KOEA-1489 thread) flips KOEA-366 publish_state to g4-approved, which
triggers the actual Vercel rebuild that picks up the canonical slug.

Refs: KOEA-1437-plan.md (Fix 1, superseded for this slug), KOEA-1487 (G5 block).
```

Push + open PR against `main`. PR title: `fix(blog): 301 stale supply-chain atlas slug to canonical (KOEA-1489)`.

PR description must:
- Quote the V1/V2/V3 verification commands from this plan (so reviewer + Vercel preview can spot-check).
- Link the child state-flip issue from Step 2.
- Note: PR landing alone is NOT sufficient; the child issue's state flip is what triggers the rebuild that picks up the new vault folder.

### Step 4 — Sequence: merge redirect PR → state flip → verify

Once the PR is reviewed + merged (Code Reviewer / G2):

1. Executor comments on the Step 2 child issue with the merged PR URL + commit SHA.
2. `@chief-engineering` does the state flip per Step 2 description.
3. publish-action.sh runs at the next 60s tick (or sooner if Vardaan manually pokes it).
4. Once `metadata.publish_state` on KOEA-366 reads `published` again (~ 3-8 min later, accounting for GH Actions build + deploy), run the verification matrix below.
5. Executor closes Step 2 child issue and this plan's parent KOEA-1489 with the verification curl outputs pasted.

## Verification (Plan Reviewer / Executor / QA Verifier check these post-deploy)

| # | Command | Pre-fix observed | Post-fix expected |
|---|---|---|---|
| V1 | `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| head -1` | `HTTP/2 404` | `HTTP/2 200` |
| V2 | `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| grep -cE 'rel="canonical"'` | `0` | `1` |
| V3 | `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| grep -cE 'application/ld\+json'` | `0` | `≥ 1` (BlogPosting; BreadcrumbList + FAQPage optional but expected) |
| V4 | `curl -sI https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas \| head -1` | `HTTP/2 200` (stale build cache) | `HTTP/2 301` |
| V5 | `curl -sI https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas \| grep -i ^location:` | `(none)` | `location: /blog/ai-coding-agent-supply-chain-threat-atlas-2026` (Next.js may also emit absolute URL — both acceptable) |
| V6 | `curl -s https://academy.kspl.tech/sitemap.xml \| grep -F 'ai-coding-agent-supply-chain-threat-atlas-2026'` | `(no match)` | exactly one `<loc>` line containing the canonical slug |
| V7 | `curl -s https://academy.kspl.tech/sitemap.xml \| grep -F '2026-05-06-ai-coding-agent-supply-chain-threat-atlas'` | match present | `(no match)` |
| V8 | `curl -s https://academy.kspl.tech/rss.xml \| grep -F 'ai-coding-agent-supply-chain-threat-atlas-2026'` | `(no match)` | one item entry referencing the canonical slug |
| V9 | `curl -s https://academy.kspl.tech/llms-full.txt \| grep -c 'ai-coding-agent-supply-chain-threat-atlas-2026'` | `0` | `≥ 1` |
| V10 | Paperclip API: `curl -sf "$PAPERCLIP_URL/api/issues/<KOEA-366-uuid>" -H "Authorization: Bearer $PAPERCLIP_API_KEY" \| jq '.metadata \| {publish_state, published_url, published_at}'` | `{publish_state: "published", published_url: null, published_at: null}` | all three set; `publish_state=published`, `published_url=https://academy.kspl.tech`, `published_at` ≥ deploy time |
| V11 | publish-action.log shows successful Phase 1 + Phase 2 for KOEA-366: `grep "<KOEA-366-uuid>" ~/.paperclip/logs/publish-action.log \| tail -5` | (pre-flip: no recent entries) | lines for `Phase 1: dispatching publish-ready`, `Phase 1: dispatch accepted (204)`, `Phase 2: run status ... = success`, `Phase 2: marking ... published` |
| V12 | Page-weight regression: `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| wc -c` | n/a | `≤ 80KB` (G5 baseline) |
| V13 | TypeScript build on the redirect PR: `pnpm --filter learnova-academy run typecheck` | n/a (no diff yet) | green |
| V14 | No regression on other live blogs: spot-check 3 random non-supply-chain blog URLs return 200 + canonical + ≥ 1 JSON-LD block after the rebuild. | all pass | all pass |

## Risk

- **Pre-flight gate fails (KOEA-1137 wedge recurs).** Mitigation: Step 1 is the gate. If it fails, the plan halts and the underlying outage is fixed first. There is no value attempting Steps 2–4 against a non-functional pipeline.
- **`main` is missing other prerequisites for the canonical slug to render correctly.** Plausible if any of the new blog-template features (e.g. `FAQPage JSON-LD` from `academy/redesign-v1`) is required for V3 to pass. Mitigation: V3 only requires `≥ 1` JSON-LD block (BlogPosting). The blog template on `main` already emits BlogPosting via `blogPostingLd`. Plan Reviewer should confirm this by reading `learnova-academy/src/app/blog/[slug]/page.tsx` on `main` and verifying the BlogPosting script tag is emitted unconditionally for any `g0-passed+` post.
- **Vercel cache for the stale slug persists past redeploy.** Vercel's edge cache may serve the stale 200 for some minutes after deploy. Mitigation: the `redirects()` rule is evaluated **before** static-asset serving in Next.js routing, so the 301 wins regardless of cache state. If V4 still shows 200 after 10 min, check Vercel Project → Deployments → "promoted to production" timestamp and re-run; do NOT manually purge cache (out of scope).
- **State flip race: Phase 1 picks up KOEA-366 before the redirect PR is merged.** Then the rebuild would deploy the canonical slug AS 200 but the legacy URL would still be a stale 200, not a 301, until the next push to main. Mitigation: Step 4 explicit sequencing — child issue from Step 2 is **blocked on PR merge**. Executor must comment the merged PR URL on the child before chief-engineering performs the flip.
- **State flip fails (GH Actions run failure).** publish-action.sh Phase 2 flips to `dispatch_failed` with a reason in `dispatch_failure_reason`. Rollback: do not flip publish_state back manually; treat the failure as a CI bug (KOEA-1316/1326-class) and open a fresh ticket. The redirect is already merged and harmless on its own.
- **Children of KOEA-366 (KOEA-1177, etc.) sharing the slug.** KOEA-1177 has the same slug but `status=done` with no `publish_state`. Phase 1 ignores it (filters on `publish_state=g4-approved`). No collision risk. KOEA-365 + KOEA-364 are cancelled. Mitigation: Step 2's curl explicitly targets KOEA-366's UUID, not slug — no fan-out.
- **`redirects()` syntax regression.** If `async redirects()` is mistyped, Next.js fails the build silently for that hook (no 404 page, all pages still work, no redirect). Mitigation: V4 + V5 are the gate. Also V13 typecheck.
- **`learnovaBeast-fe-agent` worktree absent.** The ticket hinted at this worktree but it doesn't exist on disk at the expected path. Mitigation: this plan uses the existing `~/Documents/Paperclip/learnovaBeast` checkout with a fresh branch off `main`. Flag for the operations team to fix the worktree expectation separately — not blocking this plan.

## Rollback

If any verification step V1–V11 fails post-deploy:

1. **If V1 fails (canonical still 404):** the state flip didn't trigger a successful build. Check Phase 2 log for `dispatch_failed` and `dispatch_failure_reason`. Do NOT re-flip publish_state; open a CI ticket per the failure reason.
2. **If V4 fails (legacy slug still 200 after >10 min):** revert is `git revert <redirect-commit>` on `main` and re-flip KOEA-366 publish_state to trigger a fresh build. (Vercel cache eviction is the most likely cause; usually resolves within minutes without revert.)
3. **If V2 or V3 fails (page renders 200 but missing canonical/JSON-LD):** that is a separate template bug on `main` — open a fresh ticket. This plan does not change the blog template; it only changes routing.
4. **If V14 regresses (other blogs break):** investigate immediately and revert the redirect commit if causal. The redirect rule is scoped to one source path, so cross-blog regression would point to an unrelated build issue triggered by the rebuild itself, not by this PR.

## Out of scope (restated)

- KOEA-1437 fixes 2/3/4 (slides surface, seo_description backfill, verifier no-speculation rule).
- Convex / `learnova-tc` deploys.
- Blog body copy edits on the canonical slug.
- Cleaning up cancelled KOEA-364 / KOEA-365.
- Touching `academy/redesign-v1`.
- Creating the missing `~/Documents/Paperclip/learnovaBeast-fe-agent/` worktree.
- Manual edits to `sitemap.ts`, `rss.xml/route.ts`, or `llms-full.txt/route.ts` (explicitly forbidden by ticket).
- Vercel-UI redirects (not source-controlled).

## Handoff

On plan-review acceptance:

1. Executor (next agent assigned to KOEA-1489 work) runs Step 1 pre-flight; on PASS, proceeds.
2. Executor opens the Step 2 child issue under `@chief-engineering` (DO NOT flip publish_state from the Executor role).
3. Executor opens the Step 3 PR on `learnovaBeast` `main` → `koea-1489/atlas-redeploy-301`.
4. After PR merge, Executor links the merged PR URL back to the child issue from Step 2.
5. `@chief-engineering` performs the state flip; publish-action.sh handles the rest automatically.
6. After ~5–10 min, anyone (Executor / Plan Reviewer / QA Verifier) runs the V1–V14 matrix and pastes outputs to KOEA-1489.
7. KOEA-1489 closes when V1–V14 pass; this unblocks KOEA-1487 / KOEA-1472.
