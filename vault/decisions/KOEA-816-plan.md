---
ticket: KOEA-816
parent: KOEA-813
planner: planner
date: 2026-05-06
estimated_complexity: small
estimated_token_cost: $0.20
tags: [decision, blog, publish-gate, misdiagnosis]
---

# Plan: KOEA-813 is a misdiagnosis — no `/blog/[slug]` deploy artifact gap exists

## Goal

Reframe KOEA-813. Probe data shows the deploy artifact pipeline is working correctly for blog slugs. The single 404 the Publish Verifier flagged is the publish-gate working as designed (a `g0-blocked` draft is intentionally not rendered). Recommend cancelling the implementation/review chain (KOEA-817/818/819) and instead fixing the **Publish Verifier's URL list** so it doesn't probe blocked drafts.

## Context

Files inspected:
- `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:25,31-33` — `generateStaticParams()` enumerates from `listPublishableBlogs()`, with `export const dynamic = "force-static"`.
- `learnovaBeast/learnova-academy/src/lib/vault.ts:42-46,64,117-141` — `PUBLISHABLE_STATES = {g0-passed, g3-passed, published}`. Drafts with any other status (including `g0-blocked`) are filtered out and never reach `generateStaticParams`.
- `learnovaBeast/learnova-academy/scripts/sync-vault.mjs:40-66,112` — Vercel-side prebuild git-clones the vault to `/tmp/koenig-vault/vault` so `lib/vault.ts` can read it. This is working: 13/14 published slugs return 200 and appear in the deployed sitemap.
- `learnovaBeast/learnova-academy/src/app/blog/page.tsx`, `src/app/sitemap.ts:30-35` — both consume the same `listPublishableBlogs()`, so the index and sitemap are also correctly excluding the blocked draft.
- `koenig-ai-org/vault/blogs/gpt-5-5-vs-claude-opus-4-7-agentic-coding/draft.md:6` — `status: g0-blocked` (the only slug currently 404ing).

### Probe results (live, 2026-05-06)

I ran `curl -sL -o /dev/null -w "%{http_code}"` against every slug present in `koenig-ai-org/vault/blogs/`:

| Status | Count | Slugs |
|---|---|---|
| 200 | 13 | all `2026-04-30-*`, `claude-security-beta-devsecops`, `cloudflare-agents-week-2026-explained`, `cursor-3-2-vs-claude-code-workflow`, `gemma-4-vs-llama-4-vs-qwen-3-5`, `mcp-2026-roadmap-explained`, `notebooklm-as-a-learning-system` |
| 404 | 1 | `gpt-5-5-vs-claude-opus-4-7-agentic-coding` |

The 404 slug is **also absent from the deployed `/sitemap.xml`** — i.e., the system is internally consistent. It is not "missing in deploy"; it is "intentionally not published."

### Why the verifier flagged it

The Publish Verifier (KOEA-812) appears to be probing slugs from a list that does not honour `PUBLISHABLE_STATES`. Likely sources of the stale list:
- Vault directory listing of `vault/blogs/*` (which includes `g0-blocked` drafts).
- A historical record from before the draft was downgraded from `g0-passed` → `g0-blocked`.

Either way, the verifier is asserting an SLA that the publish gate explicitly does not promise.

## Approach (1 chosen, alternatives rejected)

**Chosen — Reframe + redirect**: Close KOEA-816 as `not_planned` (this plan is the deliverable), and request that KOEA-817/818/819 be cancelled. Open a new bug on the Publish Verifier asking it to source its probe list from either (a) the deployed sitemap, or (b) the same `listPublishableBlogs()` filter that the renderer uses. Optionally, the content team can either revive the draft to `g0-passed` or delete the directory if it should not exist.

**Rejected — Add `g0-blocked` to `PUBLISHABLE_STATES`**: would force-publish a draft that the G0 reviewer explicitly blocked. Defeats the publish gate. Hard reject.

**Rejected — Make `[slug]/page.tsx` render `g0-blocked` drafts with a "blocked" placeholder**: leaks editorial state to the public web and creates a thin/duplicate page that hurts SEO. No upside vs. a 404.

## Steps (Executor / Chief Engineering — gated on confirmation)

1. **Do not** merge any code change against `learnovaBeast/learnova-academy` for this issue.
2. Cancel KOEA-817 (Implement), KOEA-818 (G_code review), KOEA-819 (G2 QA verify) with reason "misdiagnosis — no deploy gap; see KOEA-816 plan."
3. Close KOEA-813 (`not_planned`) with a comment linking this plan.
4. Open a new issue on the Publish Verifier owner: **"verifier should not probe non-publishable slugs."** The verifier's URL list must come from `https://academy.kspl.tech/sitemap.xml` (authoritative) or a query of `listPublishableBlogs()`-equivalent state — not from the raw `vault/blogs/` directory listing.
5. (Optional, content-team call) Decide what to do with `koenig-ai-org/vault/blogs/gpt-5-5-vs-claude-opus-4-7-agentic-coding/`: revive to `g0-passed` after addressing reviewer feedback, or delete the directory. This is editorial, not engineering.

## Verification (QA Verifier checks these)

- [ ] No code merged into `learnova-academy` under KOEA-813.
- [ ] KOEA-817 / KOEA-818 / KOEA-819 are cancelled or closed with reason linking this plan.
- [ ] A new ticket against the Publish Verifier exists, scoped to "source URL list from sitemap, not vault directory."
- [ ] On the next Publish Verifier poll after that ticket lands, no false-positive 404 is emitted for `g0-blocked` drafts.

## Risk

- **Risk**: A reviewer rubber-stamps KOEA-817 and Executor force-publishes the blocked draft to "make the verifier green." Mitigation: this plan + the comment on KOEA-816 must land before KOEA-817 is woken; mark KOEA-817 blocked on KOEA-816 confirmation.
- **Risk**: The verifier has additional 404s I didn't sample. Mitigation: I probed every slug currently in `vault/blogs/`. If the verifier's list contains slugs not on disk, that's further evidence its source is stale (and reinforces the recommendation).

## Out of scope

- Content-team decision on whether to revive or delete the `gpt-5-5-vs-claude-opus-4-7-agentic-coding` draft.
- Any change to `PUBLISHABLE_STATES`, the publish-gate semantics, or the G0 reviewer flow.
- Any change to `sync-vault.mjs` or Vercel deploy config — they are working correctly.

## Evidence appendix

- Probe command (reproducible): `for slug in $(ls koenig-ai-org/vault/blogs/); do curl -sL -o /dev/null -w "%{http_code}  $slug\n" "https://academy.kspl.tech/blog/$slug"; done`
- Sitemap probe: `curl -s https://academy.kspl.tech/sitemap.xml | grep -oE 'https://academy.kspl.tech/blog/[^<]+' | sort -u` → 13 entries, matching the 200 set above.
- Frontmatter evidence: `head -10 koenig-ai-org/vault/blogs/gpt-5-5-vs-claude-opus-4-7-agentic-coding/draft.md` shows `status: g0-blocked`.
