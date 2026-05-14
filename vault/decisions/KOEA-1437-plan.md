---
ticket: KOEA-1437
planner_ticket: KOEA-1440
planner: planner
date: 2026-05-13
estimated_complexity: medium
estimated_token_cost: $0.55
status: ready-for-plan-review
worktree: /Users/vardaankoenig/Documents/Paperclip/learnovaBeast
branch: academy/redesign-v1
sibling_vault_repo: /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org (master)
no_convex_deploy: true
---

# Plan: repair blog deploy/template SEO failures (G5 BLOCK KOEA-1437)

## Goal

Close every failing G5 check from KOEA-1435 / KOEA-1437 by treating each as a separate
root cause, not one omnibus "SEO" bug. After this lands:

- `https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026` → HTTP 200, with canonical + JSON-LD blocks (`BlogPosting` + `BreadcrumbList`).
- `https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors` → live meta description ≥ 80 chars, no internal rev-note text, slides download link present + the `.pptx` resolves 200.
- `https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex` → slides download link present + the `.pptx` resolves 200.
- Publish Verifier stops speculating asset URLs that aren't part of the skill spec.

## Context

### Symptom → root-cause matrix

| # | Symptom (from KOEA-1435 verifier output) | True root cause | Fix surface |
|---|---|---|---|
| 1 | `/blog/ai-coding-agent-supply-chain-threat-atlas-2026` returns HTTP 404; no canonical; 0 JSON-LD blocks | Vault folder was renamed (date-prefixed → year-suffixed) **after** KOEA-366 originally published. Paperclip metadata still reads `publish_state=published` on KOEA-366 with slug `ai-coding-agent-supply-chain-threat-atlas-2026`, but no redeploy fired against the new slug. Vercel still serves the old slug `2026-05-06-ai-coding-agent-supply-chain-threat-atlas` (HTTP 200, valid title + description) from the previous build artifact. | Trigger fresh deploy + 301 from old slug. **No code change to template/JSON-LD needed — `generateMetadata` + `blogPostingLd` already emit canonical + JSON-LD for any g3+ draft. The page emits *nothing* only because it 404s today.** |
| 2 | Missing canonical + 0 JSON-LD blocks on supply-chain blog | Direct consequence of #1 — Next.js `notFound()` short-circuits `generateMetadata`. | Same as #1; no separate fix. |
| 3 | `2026-04-30-anthropic-creative-connectors` and `2026-04-30-gpt-5-5-in-codex` — vault `slides.pptx` not linked on page; `/slides/<slug>.pptx` returns 404 | Two layers: (a) the `BlogPost` schema in `lib/vault.ts` has no `slides_url` field — there is no surface in `page.tsx` that links slides for blogs; (b) `scripts/sync-vault.mjs` only mirrors `vault/courses/**` to `public/courses/`, never `vault/blogs/<slug>/slides.pptx` — so even a hand-crafted `/slides/<slug>.pptx` URL would 404 because nothing serves the bytes; (c) the `/slides/<slug>.pptx` URL pattern the verifier probed is **not in `verify-publish/SKILL.md`** — Grok 4.3 invented it (matches the speculative-URL-probe pattern first hit at KOEA-352 → KOEA-1393). | Build a real slides surface end-to-end (mirror + schema + template), and pin the verifier so it reads `slides_url` from page output instead of guessing a URL shape. |
| 4 | `2026-04-30-anthropic-creative-connectors` live meta description is 54 chars: `"Updated Resolume and Blender descriptions for accuracy"` | Draft frontmatter has no `seo_description`. `lib/vault.ts` only reads `seo_description`; the draft has a 177-char `description:` field that vault.ts ignores. `page.tsx` `generateMetadata` falls back through `seo_description ?? whats_new[0] ?? <reading-time>` — `whats_new[0]` is the internal rev note. | Surgical fix at two layers: (a) **vault entry backfill** of `seo_description` for this one slug (this ticket only — the systemic backfill + G0/G5/commit-hook enforcement is already owned by [KOEA-1247 plan f478f11b](./f478f11b-8082-452a-afb8-23dfb0498514-plan.md), do not duplicate); (b) **template fallback tightening** in `page.tsx`: insert `post.description` before `post.whats_new?.[0]` in the chain so any vault entry that uses `description:` (legacy frontmatter shape) no longer leaks internal rev notes — closes the leak even before KOEA-1247's policy gates roll out. |

### Files to read first

**`learnovaBeast` (branch `academy/redesign-v1`):**
- `learnova-academy/src/app/blog/[slug]/page.tsx:36-66` — `generateMetadata` fallback chain (target of fix-4b)
- `learnova-academy/src/app/blog/[slug]/page.tsx:79-99` — `blogPostingLd` description chain (same fix-4b)
- `learnova-academy/src/lib/vault.ts:21-114` — `BlogPost` interface + `readBlogFile` (target of fix-3a: add `slides_url`)
- `learnova-academy/scripts/sync-vault.mjs:38` — `MEDIA_EXTS` mirror loop (target of fix-3b: add blog-slides mirror)
- `learnova-academy/src/app/learn/[slug]/page.tsx` — `ChapterBottomDeck` slides pill (reference pattern from commit c2ee4dc — mimic shape, do not import — different surface)
- `learnova-academy/next.config.ts:5-19` — `BLOG_SHORT_SLUG_REDIRECTS` (target of fix-1b: add legacy-slug 301)

**`koenig-ai-org` (master):**
- `vault/blogs/2026-04-30-anthropic-creative-connectors/draft.md` — backfill `seo_description` (fix-4a)
- `vault/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx` — already present, will be mirrored
- `vault/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx` — already present, will be mirrored
- `vault/blogs/ai-coding-agent-supply-chain-threat-atlas-2026/draft.md` — status currently `g3-passed`, slug is canonical (year-suffix is intentional; year-prefix `2026-05-06-` was wrong because of the original ship date drift); we redeploy this version
- `companies/learnova-academy/skills/verify-publish/SKILL.md:103-110` — slot for new slides-link check (fix-3d)
- `companies/learnova-academy/skills/verify-publish/SKILL.md:147-160` — "Pre-flight gate" — append a **no-speculation rule** (fix-3d)
- `companies/learnova-academy/agents/publish-verifier/SOUL.md` — append speculative-probe prohibition (fix-3d, identity-level)
- `scripts/publish-action.sh:339-385` — Phase 1 dispatch (verify: re-dispatch is one slug-touch, not a full restart)

### Relevant prior work / constraints

- [KOEA-1247 plan f478f11b](./f478f11b-8082-452a-afb8-23dfb0498514-plan.md) — systemic `seo_description` enforcement (Content Reviewer G0 rule + G5 check 11 + commit-msg hook + 13 backfill child tickets). **This plan does NOT duplicate that work** — for fix-4 we add only (a) the single-slug backfill that this ticket explicitly names and (b) a one-line `page.tsx` fallback hardening that closes the most common leak shape immediately.
- Memory note `project_publish_verifier_speculative_url_probes` (2026-05-13) — Grok 4.3 invents asset URLs. This plan adds the explicit prohibition in SOUL.md and the structural pin in `verify-publish/SKILL.md`.
- Memory note `project_publish_verifier_false_positive` (2026-05-06 KOEA-812 / KOEA-813) — verifier probes `vault/blogs/*` directly, conflating g0-blocked drafts with published. This plan does NOT touch that bug class because the supply-chain draft IS `g3-passed` (auto-publishes per blog policy) and HAS an existing `publish_state=published` on KOEA-366 — it's a true deploy-staleness bug, not a false positive.
- Memory note `project_publish_action_broken_2026_05_12` (KOEA-1137) — four-cause launchd outage. **Verify before relying on dispatch:** confirm `com.koenig.publish-action.plist` is loaded and `GH_PAT_DISPATCH` is set in `.env.koenig` before assuming fix-1 will deploy on its own. If publish-action is still wedged, this plan's fix-1 cannot proceed and must escalate to KOEA-1137 owner.
- `learnova-tc` is the Convex backend repo. **NO change here requires a Convex deploy.** All work is Vercel-static (Next.js redirects + public/ mirror + JSON-LD). If a fix is later judged to need Convex (e.g. issuing a runtime redirect via a Convex http action), STOP and escalate — that's an architectural change beyond this ticket.

### Definitively out of scope

- The 13-blog `seo_description` backfill stream — owned by KOEA-1247.
- Rewriting G0 Content Reviewer policy to require `seo_description` — also KOEA-1247.
- The commit-msg blog-SEO hook — KOEA-1247 step 5.
- Course / lesson / glossary meta descriptions — separate audit.
- Any change to `learnova-tc` (Convex) — explicit no-Convex-deploy constraint from ticket.
- Audio podcast surfaces on blog pages — the Audio + slides goal is a separate stream (KOEA-1352 etc.).
- Rerouting `2026-05-06-ai-coding-agent-supply-chain-threat-atlas` traffic to a *content rewrite* — slug rename only; the body is unchanged.

## Approach

**Chosen — four small, independently-shippable fixes in one PR.**

The four bugs are causally independent (separate files, separate failure modes) but small enough that a single PR is the right unit — splitting would add review overhead with no isolation win. The PR is structured so each fix can be reverted independently if it regresses.

Verification ordering matters: Fix-3 (slides) and Fix-4 (meta-description) MUST be live before Fix-1 (supply-chain redeploy) finishes, because the supply-chain redeploy is the one that re-renders the FE and embeds the new template logic.

**Rejected alternatives:**

- *Split into four separate PRs.* — Rejected: four PRs × G_code × G2 × CEO G3 = 12 review touchpoints for ~120 LOC total. Bundled is cheaper and reverts are still atomic (one revert commit per concern).
- *Add a "blog slides URL contract" to `verify-publish` without actually serving slides.* — Rejected: that just papers over the speculation by codifying a URL that 404s for every other blog. Either we serve blog slides or the verifier should not check for them. We're choosing to serve them.
- *Use a Convex http action to 301 the legacy supply-chain slug.* — Rejected: explicit no-Convex-deploy constraint; Next.js `redirects()` is the existing pattern and works.
- *Drop the new slug, rename the vault folder back to `2026-05-06-ai-coding-agent-supply-chain-threat-atlas`.* — Rejected: the new slug `ai-coding-agent-supply-chain-threat-atlas-2026` is the editorially-chosen canonical form (year-suffix, no leading date) per the auto vault-sync at 2026-05-13T03:59 and the SEO recommendation in the original publish ticket KOEA-366. Reverting would lose that intent and re-open the question on the next sync.
- *Keep the existing template behavior and only backfill the one missing `seo_description`.* — Rejected for fix-4: the same vault-frontmatter shape (`description:` set, `seo_description:` missing) will leak again the next time it ships. The `page.tsx` one-line fallback insertion is a 30-second defense-in-depth that costs nothing.

## Steps (Executor follows in order)

### Fix 4 — meta description on `anthropic-creative-connectors` (smallest, ship first; learnovaBeast + koenig-ai-org)

1. **In `koenig-ai-org` (branch off `master`, single commit on a feature branch `koea-1437/seo-description-anthropic-connectors`):** edit `vault/blogs/2026-04-30-anthropic-creative-connectors/draft.md` frontmatter to insert a hand-written `seo_description` (120–160 chars, answer-first, mirrors the H1 promise). **Executor does NOT author this string** — open a child issue under `@content-author` for the actual text and block the PR on it. Suggested seed for the Author: *"Claude can now drive Blender, Adobe Creative Cloud, Ableton Live, and Resolume via 9 new MCP connectors — see exactly what each one does and how to wire them into a workflow."* (148 chars). Author should treat this as a starting point, not a final.
2. **In `learnovaBeast` (branch `academy/redesign-v1`):** in `learnova-academy/src/app/blog/[slug]/page.tsx`:
   - At `generateMetadata` line ~40, change the fallback chain from `post.seo_description ?? post.whats_new?.[0] ?? \`${...}\`` to `post.seo_description ?? (post as { description?: string }).description ?? \`${post.reading_time_min} min read on ${post.vendor_tag}\`` — drop `whats_new[0]` from the chain entirely; the `description` field is the legacy alias.
   - Mirror the same edit in the `blogPostingLd` chain at line ~84.
   - **Do NOT add `description` to `lib/vault.ts` `BlogPost` interface** — the `as { description?: string }` cast keeps the type surface tight and signals this is a transitional alias. KOEA-1247 will retire it.

### Fix 3 — blog slides surface (learnovaBeast)

3. **`learnova-academy/src/lib/vault.ts`:** add `slides_url?: string` to the `BlogPost` interface (~line 36). In `readBlogFile`, after the existing field assignments and BEFORE the `return`, derive:
   ```ts
   import { existsSync } from "node:fs"; // already imported above? confirm
   const slidesPath = join(VAULT_ROOT, "blogs", slug, "slides.pptx");
   const slides_url = existsSync(slidesPath) ? `/blogs/${slug}/slides.pptx` : undefined;
   ```
   Pass `slides_url` into the returned object.
4. **`learnova-academy/scripts/sync-vault.mjs`:** add a `mirrorBlogMedia()` function modeled on `mirrorCourseMedia()` (line ~70):
   - Walk `vault/blogs/<slug>/` for each directory entry.
   - Mirror files whose extension is in `MEDIA_EXTS` (`.pptx`, `.pdf`, `.mp3`, `.m4a`, `.wav`) into `public/blogs/<slug>/<basename>`.
   - Same mtime/size skip-if-fresh logic as `mirrorCourseMedia()`.
   - Call `mirrorBlogMedia()` at the bottom of the file alongside `mirrorCourseMedia()`.
5. **`learnova-academy/src/app/blog/[slug]/page.tsx`:** after the article body and before the references footer (Executor: find the closing `</article>` and insert above), add a slides-pill block guarded by `post.slides_url`:
   ```tsx
   {post.slides_url && (
     <aside style={{ maxWidth: 1080, margin: "24px auto", padding: "0 16px" }}>
       <a
         href={post.slides_url}
         download
         style={{
           display: "inline-flex", alignItems: "center", gap: 8,
           padding: "10px 16px", borderRadius: 999,
           background: "var(--surface-2)", color: "var(--text-1)",
           textDecoration: "none", fontWeight: 500, fontSize: 14,
         }}
       >
         <I name="download" /> Download slides (.pptx)
       </a>
     </aside>
   )}
   ```
   Use whatever icon name the existing `I` registry already exposes for download (Executor: grep `_shared/icons` and pick the closest match, do NOT add a new icon).
6. **`koenig-ai-org` → `companies/learnova-academy/skills/verify-publish/SKILL.md`:**
   - Add the no-speculation rule to the Pre-flight gate (around line 151), as a bullet: *"NEVER probe asset URLs whose shape is not defined in this skill or in the live page's emitted HTML. If you suspect a missing asset, BLOCK with the URL you saw on the page or the path from the vault file — do not invent URL shapes like `/slides/<slug>.pptx` or `/audio/<slug>.mp3`. Speculative probes mis-route engineering attention; ground every URL in an HTML reference or a vault path."*
   - Add a new check 11 between current check 10 (author resolution) and the Decide block: **"Blog asset link integrity"** — scrape the page HTML for `<a download href="/blogs/<slug>/...">`; for each, `curl -sI` and assert 200. If `vault/blogs/<slug>/slides.pptx` exists but no `<a download>` references it on the page, BLOCK to chief-engineering with the vault path. Add the regression fixture: `https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors` BEFORE this PR ships MUST show "no slides link" (the bug); AFTER, MUST show "slides link → /blogs/2026-04-30-anthropic-creative-connectors/slides.pptx → 200".
7. **`koenig-ai-org` → `companies/learnova-academy/agents/publish-verifier/SOUL.md`:** append a one-paragraph **"What you never do"** bullet: *"Never invent asset URLs. Probe only URLs that appear in the page HTML or are explicitly defined in `skills/verify-publish/SKILL.md`. If a vault file has an asset that isn't surfaced, that's a chief-engineering BLOCK with the vault path — not a probe."*

### Fix 1 — supply-chain blog redeploy + legacy-slug 301

8. **Pre-flight check (Executor before doing anything):** run `bash scripts/publish-action.sh --dry-run` (or equivalent) and confirm:
   - launchd job `com.koenig.publish-action.plist` is loaded (`launchctl list | grep publish-action`).
   - `GH_PAT_DISPATCH` is set in `.env.koenig`.
   - `COMPANY_ID` env in the plist matches `2a77f89b-33f0-4133-a20c-77ddaac5e744`.
   If any of these are off → **STOP**, escalate to KOEA-1137 owner; this plan's fix-1 cannot land until publish-action.sh is functional. Comment the blockage on KOEA-1442 with the failing check.
9. **Trigger a redeploy of `ai-coding-agent-supply-chain-threat-atlas-2026`:**
   - The draft is `status: g3-passed` and KOEA-366 has `metadata.publish_state=published` — `publish-action.sh` Phase 1 only dispatches `publish_state=g4-approved`, so the natural path is: flip KOEA-366 `metadata.publish_state=g4-approved` → publish-action picks it up on the next 60s tick → dispatches `repository_dispatch` → Vercel builds + deploys. **Executor: do not flip the publish_state directly in this PR** — instead create a child issue under `@chief-engineering` titled "Redeploy supply-chain threat atlas blog under canonical slug" with the explicit instruction to flip `publish_state` and confirm a successful run via `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 → 200`. Link from this plan.
   - Reason for the indirection: a Planner / Executor PR should not perform state-machine flips against live data; the deploy belongs to the agent who owns the pipeline.
10. **`learnova-academy/next.config.ts`:** extend `BLOG_SHORT_SLUG_REDIRECTS` with `["2026-05-06-ai-coding-agent-supply-chain-threat-atlas", "ai-coding-agent-supply-chain-threat-atlas-2026"]`. Permanent (301). Add a brief comment explaining the rename was a slug canonicalization (year-suffix replaces date-prefix). This redirect goes out in the **same Vercel build** as the supply-chain redeploy, so old inbound links resolve cleanly to the new URL.

### Final PR shape

- Branch: `academy/redesign-v1` on `learnovaBeast` (frontend changes).
- Branch: `koea-1437/blog-template-and-verifier` on `koenig-ai-org` (vault frontmatter backfill + skill updates).
- Both branches push together; PR descriptions cross-link.
- PR title: `fix(blog): supply-chain redeploy 301 + slides surface + meta-fallback hardening (KOEA-1437)`.

## Verification (QA Verifier / Plan Reviewer checks these)

A "before" snapshot MUST be captured in the PR description for each row.

| # | Check | Pre-fix expected | Post-fix expected |
|---|---|---|---|
| V1 | `curl -sI https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| head -1` | `HTTP/2 404` | `HTTP/2 200` |
| V2 | `curl -s https://academy.kspl.tech/blog/ai-coding-agent-supply-chain-threat-atlas-2026 \| grep -E 'rel="canonical"\|application/ld\+json' \| wc -l` | `0` | `≥ 2` (one canonical + ≥1 JSON-LD script tag) |
| V3 | `curl -sI https://academy.kspl.tech/blog/2026-05-06-ai-coding-agent-supply-chain-threat-atlas \| head -1` | `HTTP/2 200` (stale cache) | `HTTP/2 301` with `Location: /blog/ai-coding-agent-supply-chain-threat-atlas-2026` |
| V4 | `curl -s https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors \| grep -oE 'name="description" content="[^"]+"' \| awk -F'"' '{print length($4)}'` | `54` | `≥ 80` (and ≤ 160; Content Author target 120–160) |
| V5 | `curl -s https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors \| grep -oE 'name="description" content="[^"]+"'` | `"Updated Resolume and Blender descriptions for accuracy"` | Hand-written `seo_description` (or `description` until KOEA-1247 retires it) — must NOT match `^(Updated\|Fixed\|Rev \\d+\|Standardized)\\b` (the commit-message-opener regex from KOEA-1247) |
| V6 | `curl -s https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors \| grep -F 'download'` | `(no match — no slides pill)` | Match: `<a … download href="/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx" …>` |
| V7 | `curl -sI https://academy.kspl.tech/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx \| head -1` | `HTTP/2 404` | `HTTP/2 200` with `content-type` containing `presentation` or `octet-stream` |
| V8 | `curl -s https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex \| grep -F 'download'` | `(no match)` | Match: `<a … download href="/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx" …>` |
| V9 | `curl -sI https://academy.kspl.tech/blogs/2026-04-30-gpt-5-5-in-codex/slides.pptx \| head -1` | `HTTP/2 404` | `HTTP/2 200` |
| V10 | `curl -s https://academy.kspl.tech/blog/2026-04-30-anthropic-creative-connectors \| python3 -c "import re,json,sys; html=sys.stdin.read(); m=re.search(r'<script type=\"application/ld\\+json\">(.*?)</script>',html,re.S); print(json.loads(m.group(1)).get('description',''))"` | Internal rev note (54 chars) | Hand-written `seo_description` matching V5 (JSON-LD description MUST equal HTML meta description) |
| V11 | Spot-check 3 other live blogs after Fix-3 ships — each should still pass G5 checks 1-10 (no regression) | All pass | All pass |
| V12 | Verify-publish skill self-test: against a synthetic vault entry where `slides.pptx` exists but no `<a download>` link is in HTML, the check 11 implementation must BLOCK with the vault path; against the same vault entry but with the link present and the .pptx 200, must PASS. Document both runs in the PR. | — | both states captured |
| V13 | `learnova-academy/scripts/sync-vault.mjs` smoke: run locally with `VAULT_ROOT` pointed at the vault; confirm `public/blogs/2026-04-30-anthropic-creative-connectors/slides.pptx` is created with same size as source. | — | file mirrored, size matches |
| V14 | TypeScript build: `pnpm --filter learnova-academy run typecheck` succeeds. | — | green |
| V15 | Page-weight regression: `wc -c` on `/blog/2026-04-30-anthropic-creative-connectors` body — must remain `≤ 80KB` (G5 check 7). The slides pill is ~200 bytes. | — | under threshold |

## Risk

- **publish-action.sh wedge.** If launchd / `GH_PAT_DISPATCH` / company-id is still broken from KOEA-1137, fix-1 cannot deploy. Mitigation: Step 8 pre-flight gate; if blocked, ship fixes 3 + 4 as an interim PR and unblock fix-1 separately once KOEA-1137 lands. **The remaining three fixes deliver real user value on their own and don't depend on fix-1 deploying.**
- **Slug-rename traffic gap.** Between the redeploy (new URL goes live) and the redirect deploy (old URL starts 301-ing), there could be a window where the OLD URL 404s. Mitigation: both fix-1 and fix-1b ship in the SAME Vercel build (step 10 edits next.config.ts in the same `academy/redesign-v1` PR that triggers the build) — there is no temporal split.
- **`description` alias temporary.** Fix-4b adds a transitional `description` fallback to keep the template defensive even while KOEA-1247 is in flight. Risk: the alias outlives its purpose. Mitigation: comment in `page.tsx` cites KOEA-1247 as the retire-this-line tracker; the cast `as { description?: string }` keeps it from "looking" like a first-class field.
- **`I name="download"` icon may not exist.** Mitigation: Executor greps `_shared/icons` first, picks closest existing icon, does NOT add a new asset (out of scope for this ticket). If no suitable icon exists, ship the pill text-only (`"Download slides (.pptx) →"`) — same accessibility win.
- **public/blogs/ public-asset collision.** If a blog slug ever collides with a Next.js route (e.g. `slug: "page"`), mirroring would clash with build output. Mitigation: extremely unlikely given our slug shape (always date-prefixed or topic-keyword); add a `console.warn` in `mirrorBlogMedia()` if `out` already exists with non-mirrored files, and never overwrite non-`.pptx` files.
- **Verifier skill change is read-only for active polls.** Verifier reads SKILL.md on the next heartbeat; the new check 11 will fire against ALL live blogs on the next sweep. There are 13 live blogs without slides.pptx — they all pass V11's "no vault slides → no link expected" branch; the check only fires when `vault/blogs/<slug>/slides.pptx` exists. Risk: a vault entry that *should* have slides but doesn't get a false negative. Acceptable — that's not the bug class this fixes.

## Out of scope (restated)

- 13-blog `seo_description` backfill stream → KOEA-1247.
- G0 Content Reviewer enforcement → KOEA-1247.
- Commit-msg blog-SEO hook → KOEA-1247.
- Course / lesson meta descriptions.
- Audio podcast surfaces on blog pages (separate goal).
- Convex (`learnova-tc`) deploys — explicitly forbidden by ticket.
- Adding new icons to `_shared/icons`.
- Rewriting any blog body copy.

## Handoff

Plan ready for review at KOEA-1441 (Code Reviewer plan-review). On plan-review acceptance:

1. Executor (KOEA-1442) opens the two-branch PR per "Final PR shape" above.
2. Executor opens **two child issues** before starting:
   - `@content-author` (via `@chief-content`): hand-write `seo_description` for `2026-04-30-anthropic-creative-connectors` per fix-4a.
   - `@chief-engineering`: flip KOEA-366 `metadata.publish_state=g4-approved` and confirm publish-action.sh successful dispatch per fix-1 step 9.
3. Executor's PR can land without waiting on those children (typecheck and template logic ship green), but the verification matrix V1-V11 cannot fully PASS until both children close. PR description must call this out and link the children.
4. After PR merge + both children resolve, Publish Verifier re-runs against all four URLs and produces an updated G5 report. That report is what closes KOEA-1437.
