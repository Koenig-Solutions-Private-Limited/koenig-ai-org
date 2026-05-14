---
ticket: KOEA-1000
parent_ticket: KOEA-709
planner_ticket: KOEA-1001
revision_ticket: KOEA-1007
revision: 2
planner: planner
date: 2026-05-11
estimated_complexity: small (~20 LOC across 4 files + 1 Lighthouse re-run)
estimated_token_cost: $0.40
files_touched:
  - learnovaBeast/learnova-academy/src/components/GlossaryPopover.tsx
  - learnovaBeast/learnova-academy/eslint.config.mjs
  - learnovaBeast/learnova-academy/src/app/learn/[slug]/page.tsx
  - learnovaBeast/learnova-academy/src/app/learn/page.tsx
  - learnovaBeast/learnova-academy/src/app/layout.tsx
  - koenig-ai-org/vault/decisions/KOEA-1000-lcp-baseline.md (only if Path B chosen — see "Cross-repo scope exception" below)
target_branch: academy/redesign-v1
target_repo: learnovaBeast (Koenig-Solutions-Private-Limited/learnovaBeast)
worktree: /tmp/koea-1000-impl (new — see "Worktree" below)
tags: [planning, lint, lcp, performance, koea-709, koea-1000]
---

## Revision 2 (2026-05-11)

Addresses Code Reviewer feedback on KOEA-1002:
1. **Blocking** — scope contradiction: plan said "do not touch `vault/`" but Step 10 wrote to `vault/decisions/`. Resolved by adding the **Cross-repo scope exception** section below, plus updating Constraints and Step 10 to make the single allowed `vault/` write explicit.
2. **Non-blocking** — PR body expectations: `learnovaBeast` has no `.github/PULL_REQUEST_TEMPLATE.md`, so PR body was under-specified. Resolved by adding the **PR body format** subsection under Step 8.
3. **Non-blocking** — `GlossaryPopover` state correctness on slug change: the rewrite seeded `useState` from cache, but `useState` initializer only runs on mount, so a reused instance with a changed `slug` prop would retain stale data. Resolved by adding the **Slug-stability invariant** note + a derived-state reset pattern in Step 2.

# Plan: KOEA-1000 — Resolve G2 lint and LCP blockers for KOEA-709

## Goal

Unblock the post-deploy QA gate that failed on PR #22 (KOEA-986 G2 BLOCK, 2026-05-11). Two independent surface issues need to go to zero so QA can re-route KOEA-709:

1. `pnpm lint` exits non-zero because of one new React 19 lint rule firing on `GlossaryPopover.tsx:34` (`react-hooks/set-state-in-effect`). Three pre-existing warnings ride alongside.
2. Lighthouse mobile LCP on the two changed blog pages sits at 2.735s and 2.728s, ~0.2s above the 2.5s "Good" threshold.

Definition of done: `pnpm lint` exits 0 with zero errors and zero warnings; Lighthouse mobile LCP on both URLs reports below 2.5s after the next Vercel deploy. If LCP cannot be brought below 2.5s with cheap, scoped changes, ship a written baseline (Path B) that the QA Verifier can accept.

## Context

### Source of truth — G2 findings being repaired
- KOEA-986 G2 BLOCK comment (`838bbc91-b07e-4a04-ae45-2064d707436d`, 2026-05-11):
  - `pnpm lint`: 1 error + 3 warnings (full breakdown reproduced below)
  - Lighthouse LCP: `/blog/cloudflare-agents-week-2026-explained` 2.735s, `/blog/mcp-2026-roadmap-explained` 2.728s
- All other G2 checks (FAQPage JSON-LD, wikilink resolver, browser regressions, CLS 0.00, TBT 15.5ms / 3.5ms) already PASS.

### Repo + branch state (verified 2026-05-11 in plan mode)
- Target branch: `academy/redesign-v1` at `16f469b` (PR #22 merge commit `Merge pull request #22 from Koenig-Solutions-Private-Limited/koea-709/blog-faq-jsonld-and-wikilinks`).
- Live deployment: `dpl_HbRER4MemcQyYpBnQfRMSrM51W8m` (cached at Vercel CDN, `x-nextjs-prerender: 1`).
- Existing worktrees on this machine: `/tmp/learnova-pr22` (PR #22 base), `/tmp/learnova-redesign-g2` (`16f469b`, detached HEAD). Both are detached + safe to leave. **No active worktree lock prevents implementation.**

### Files to read first

- `learnova-academy/src/components/GlossaryPopover.tsx:24-54` — the offending effect
- `learnova-academy/eslint.config.mjs:1-9` — anonymous default export
- `learnova-academy/src/app/learn/[slug]/page.tsx:1-30, 568-585` — unused `ChapterMedia` (dead function, never referenced anywhere in the file)
- `learnova-academy/src/app/learn/page.tsx:5-12` — unused `import { I } …`
- `learnova-academy/src/app/layout.tsx:1-101` — third-party scripts inline in `<body>` (Microsoft Clarity inline `<script>`, `@vercel/analytics/next` `<Analytics>`); fonts loaded via `next/font/google` with `display: "optional"` (already render-blocking-safe)
- `learnova-academy/src/app/blog/[slug]/page.tsx:107-137` — hero image block, only rendered when `post.hero_image?.url` is truthy. Both target blogs use `hero_image: auto:flux` (a string, not an object), so this block does **not** render → LCP element on these pages is the `<h1 class="h1-article">` text.
- `learnova-academy/src/lib/vault.ts:33,108` — `hero_image?: { url, alt }` typed object, but `data.hero_image` from frontmatter is passed through verbatim; the "auto:flux" string never becomes an object → no hero image is materialized for these two posts.

### Exact lint findings (reproduced on `/tmp/learnova-redesign-g2/learnova-academy` 2026-05-11)

```
eslint.config.mjs
  4:1  warning  Assign array to a variable before exporting as module default  import/no-anonymous-default-export

src/app/learn/[slug]/page.tsx
  568:10  warning  'ChapterMedia' is defined but never used  @typescript-eslint/no-unused-vars

src/app/learn/page.tsx
  9:10  warning  'I' is defined but never used  @typescript-eslint/no-unused-vars

src/components/GlossaryPopover.tsx
  34:19  error  Calling setState synchronously within an effect can trigger cascading renders  react-hooks/set-state-in-effect

✖ 4 problems (1 error, 3 warnings)
```

### Constraints
- Plan-mode only; Executor implements. No production code edits in this heartbeat.
- Target branch is `academy/redesign-v1`. Do NOT push to `master`.
- **Code changes**: stay within `learnovaBeast/learnova-academy/`. Do not touch other `learnovaBeast/` sub-apps (`learnova-admin`, `learnova-sales`, `learnova-student`, `learnova-tc`), ops, or upstream Paperclip code.
- **Cross-repo `vault/` write**: exactly **one** file in `koenig-ai-org/vault/` is permitted by this plan — `koenig-ai-org/vault/decisions/KOEA-1000-lcp-baseline.md` — and only on the Path B fallback (Step 10). See the dedicated **Cross-repo scope exception** subsection for rationale and the exact path/rules.
- No dependency additions; no Next.js config swaps that aren't already there (`experimental.optimizeCss` was added in `76fbd20` — keep it).

### Cross-repo scope exception (Path B baseline doc)

This plan's primary code work lives entirely in `learnovaBeast/learnova-academy/`. The only authorised write outside that tree is the Path B fallback artifact:

- **File**: `koenig-ai-org/vault/decisions/KOEA-1000-lcp-baseline.md`
- **Repo**: `koenig-ai-org` (the same repo this plan document lives in)
- **Trigger**: only created if, after the Clarity defer is on Vercel preview, Lighthouse mobile LCP is still ≥2.5s on either target URL (see Step 9 measurement → Step 10 fallback).
- **Not created in `learnovaBeast`**: decision records (ADR-style baselines, waivers, planner notes) live in `koenig-ai-org/vault/decisions/`, alongside this plan. Putting the baseline in `learnovaBeast/` would split decision history across two repos and break Obsidian wikilink resolution; this is a deliberate carve-out of the otherwise-strict "code in learnovaBeast only" rule.
- **Atomicity**: this one file is the *entire* permitted scope of the `vault/` write. No edits to `MEMORY.md`, no edits to other decision docs, no edits to glossary, no edits to blogs.
- **Commit/PR**: if Path B fires, Executor commits the baseline doc to `koenig-ai-org` (on a short-lived branch like `koea-1000/lcp-baseline`) in a *separate* PR from the `learnovaBeast` code PR. The `learnovaBeast` PR description must reference the baseline doc URL once it's open.

## Approach (chosen + alternatives rejected)

**Chosen — A: Surgical lint fixes (always) + cheap LCP wins (try), then baseline if still >2.5s.**
- Lint: one targeted React fix in `GlossaryPopover.tsx`, plus three trivial cleanups for the warnings (named default export, drop dead `ChapterMedia` function, drop unused `I` import). Goes from `1 error + 3 warnings → 0 / 0`.
- LCP: defer the two third-party `<script>` tags in `app/layout.tsx` so they no longer compete with main-thread work on first paint:
  - Microsoft Clarity → migrate from the inline IIFE injected directly in `<body>` to `next/script` with `strategy="lazyOnload"`. The current inline `document.createElement('script')` injection runs synchronously after `<body>` parse and downloads/executes `clarity.ms/tag/...` on the critical path, which costs ~150-200ms on mobile-throttled Lighthouse.
  - `<Analytics />` (Vercel Analytics) → wrap in a small client island that only mounts after `requestIdleCallback` / `setTimeout(0)`, OR simpler: keep it (it already ships with `strategy: afterInteractive`) and only revisit if the Clarity defer alone doesn't close the 0.235s gap.
- If, after the Clarity defer ships to a Vercel preview deploy, LCP is still >2.5s on either URL, fall back to **Path B baseline**: write `koenig-ai-org/vault/decisions/KOEA-1000-lcp-baseline.md` (the one explicitly-authorised `vault/` write — see §"Cross-repo scope exception") documenting an accepted 3.0s "Needs Improvement" SLO for blog-post pages without rendered hero images, citing CLS 0.00 and TBT <20ms as offsetting evidence, then ask QA Verifier to apply that baseline going forward.

Why this ordering: the four lint edits are unconditionally safe and deterministic; they cost <10 LOC and remove the only hard `pnpm lint` failure. The LCP fix is a single-file change (`layout.tsx`) with a known mechanism (defer non-critical third-party scripts) and a measurable counterfactual on Vercel preview. The baseline is only used if measurement shows the cheap fix isn't enough — we don't pre-commit to it.

**Rejected — B: Baseline only (no code edit), accept LCP at 2.7s.**
Simplest, but leaves a known, mechanically-fixable optimization on the table and shifts the burden to every future blog page review.

**Rejected — C: Heavy LCP refactor (materialize real hero images, restructure article preamble DOM, swap CSS-in-JS for compiled CSS).**
Out of scope for KOEA-1000 — the issue is narrowly "unblock G2," not "redesign blog perf." Hero-image materialization for `auto:flux` is a separate product decision (image cost, alt text, prompt review). Flag as out-of-scope below.

## Steps (Executor follows in order)

1. **Branch off `academy/redesign-v1`.** From the learnovaBeast repo root: `git fetch origin && git worktree add /tmp/koea-1000-impl academy/redesign-v1 && cd /tmp/koea-1000-impl/learnova-academy && pnpm install`. The intended FE worktree is `/tmp/koea-1000-impl`. Create branch `koea-1000/lint-and-lcp-unblock` from `academy/redesign-v1`.

2. **Fix the lint error in `src/components/GlossaryPopover.tsx`.** Replace the effect at lines 31-54 with the form below. The change moves the cache read out of `useEffect` (read it during render, seed `useState` with it) so the effect no longer calls `setData` synchronously when the cache already has a hit — the path that the lint rule fires on. The fetch-then-`setData` branch stays; lint allows `setState` inside an async `.then` callback because the update is no longer synchronous-within-effect.

    Two pieces matter here:
    1. `useState` initializer runs **once**, on mount. If the component is reused with a different `slug`, the seeded state would be stale.
    2. The current call-sites (rendered from `[[glossary/<term>]]` wikilinks in MDX) produce one component per occurrence at distinct tree positions, so React reconciliation does not in practice swap one slug for another on the same instance. The fix below makes correctness explicit anyway, using the React-canonical "reset state on prop change during render" pattern (see Slug-stability invariant note below).

    ```tsx
    export function GlossaryPopover({ term, label }: GlossaryPopoverProps) {
      const slug = term.toLowerCase();
      const display = label ?? slug;
      const [open, setOpen] = useState(false);
      // Seed from cache so the effect never has to do a synchronous setState.
      const [data, setData] = useState<GlossaryData | null>(() => cache.get(slug) ?? null);
      // Track the slug we last seeded for, so a reused instance with a changed slug
      // resets its data without an effect (React docs: "Resetting state when a prop changes").
      const [seededSlug, setSeededSlug] = useState(slug);
      if (seededSlug !== slug) {
        setSeededSlug(slug);
        setData(cache.get(slug) ?? null);
      }
      const wrapRef = useRef<HTMLSpanElement | null>(null);

      useEffect(() => {
        if (!open || data || cache.has(slug)) return;
        let cancelled = false;
        fetch(`/api/glossary/${slug}`)
          .then((r) => {
            if (!r.ok) throw new Error(`HTTP ${r.status}`);
            return r.json();
          })
          .then((j: GlossaryData) => {
            if (cancelled) return;
            cache.set(slug, j);
            setData(j);
          })
          .catch(() => {
            cache.set(slug, null);
          });
        return () => {
          cancelled = true;
        };
      }, [open, slug, data]);

      return ( /* JSX unchanged — keep lines 56-127 verbatim */ );
    }
    ```

    **Slug-stability invariant (rationale for the reset block):**
    - *Invariant*: in production, each `[[glossary/<term>]]` wikilink in MDX produces a distinct `<GlossaryPopover term="...">` element at a distinct position in the React tree, so React's reconciler does not reuse one instance across two different slugs — slug per instance is stable in practice.
    - *But* we do not enforce this with a `key={slug}` at the call site (the wikilink resolver renders the components, and adding key plumbing there is out of scope for KOEA-1000). The Code Reviewer flagged that the seeded-from-cache pattern is incorrect *if* the invariant ever breaks (a parent re-renders with a different `term` at the same position).
    - *Defensive fix*: the `seededSlug` render-phase check above is the React-canonical reset pattern (React docs, "You Might Not Need an Effect → Resetting all state when a prop changes"). It runs during render, not in an effect, so it does not re-trigger the `react-hooks/set-state-in-effect` rule. If `slug` changes for a reused instance, `data` resets to the fresh cache lookup (or `null`), and the `useEffect` below will refetch.

    Notes for Executor:
    - Use `cache.has(slug)` for the "already-attempted" check; `null` is a sentinel for "fetch failed, don't retry."
    - Do NOT widen the props or add Suspense — out of scope.
    - Do NOT add a `key={slug}` at the wikilink-resolver call sites — out of scope for this ticket (the defensive in-component reset above is sufficient and self-contained).
    - Keep the existing JSX (lines 56-127) byte-for-byte; only the effect/state block changes.

3. **Fix warning in `eslint.config.mjs`.** Replace `export default [ … ]` with a named constant:

    ```mjs
    import nextConfig from "eslint-config-next/core-web-vitals";
    import tsConfig from "eslint-config-next/typescript";

    const config = [
      { ignores: [".next/**", ".vercel/**", "node_modules/**"] },
      ...nextConfig,
      ...tsConfig,
    ];

    export default config;
    ```

4. **Fix warning in `src/app/learn/[slug]/page.tsx`.** Remove the unused `ChapterMedia` function (lines 568 through the end of its definition — confirm `grep -n "ChapterMedia" src/app/learn/[slug]/page.tsx` returns only the declaration site after deletion). Pre-deletion sanity check: confirm zero references in `src/`, e.g. `rg -n "ChapterMedia" src/` should match only `learn/[slug]/page.tsx:568` before edit, and zero matches after.

5. **Fix warning in `src/app/learn/page.tsx`.** Remove the unused `import { I } from "@/components/_shared/icons";` at line 9. Confirm `rg -n "\\bI\\b" src/app/learn/page.tsx` returns no other usages.

6. **Cheap LCP win in `src/app/layout.tsx`.** Replace the inline Microsoft Clarity `<script>` block (lines ~86-97) with `next/script` lazy-loaded after first paint:

    ```tsx
    import Script from "next/script";
    // …elsewhere in <body>, near </body>:
    <Script id="ms-clarity" strategy="lazyOnload">
      {`(function(c,l,a,r,i,t,y){
        c[a]=c[a]||function(){(c[a].q=c[a].q||[]).push(arguments)};
        t=l.createElement(r);t.async=1;t.src="https://www.clarity.ms/tag/"+i;
        y=l.getElementsByTagName(r)[0];y.parentNode.insertBefore(t,y);
      })(window, document, "clarity", "script", "wjv5z43qr2");`}
    </Script>
    ```

    Notes for Executor:
    - `strategy="lazyOnload"` defers execution until after `window.load`, off the LCP critical path.
    - Keep `<Analytics />` (Vercel Analytics) as-is for this round; it already ships with `afterInteractive`, and the goal is the smallest cumulative change that closes the 0.235s gap.

7. **Local verification (pre-PR).** From `/tmp/koea-1000-impl/learnova-academy`:
    - `pnpm install`
    - `pnpm lint` → must exit 0 with "no errors, no warnings."
    - `pnpm exec tsc --noEmit` → must exit 0 (parity with prior G2 evidence).
    - `pnpm build` → must succeed (Next 16, `force-static` blog routes prerender).

8. **Open the PR.** `gh pr create -B academy/redesign-v1 -H koea-1000/lint-and-lcp-unblock -t "fix(academy): resolve G2 lint + LCP blockers (KOEA-1000)" -b "$(cat <<'EOF' …)"`. Route to Code Reviewer (G_code) via Paperclip per `github-pr-flow` skill.

    **PR body format** (use verbatim — `learnovaBeast` has no `.github/PULL_REQUEST_TEMPLATE.md`, so this plan defines the expected body):

    ```md
    ## Summary
    Unblocks KOEA-986 G2 for KOEA-709 / PR #22 by fixing the lone `pnpm lint` failure, clearing the three accompanying warnings, and deferring Microsoft Clarity off the LCP critical path on blog routes.

    Refs: KOEA-1000, KOEA-1003. Plan: `koenig-ai-org/vault/decisions/KOEA-1000-plan.md` (revision 2).

    ## Changes
    - `src/components/GlossaryPopover.tsx`: rewrite effect to seed `data` from cache during render + render-phase reset on `slug` change; fixes `react-hooks/set-state-in-effect`.
    - `eslint.config.mjs`: assign config array to a named constant before default export.
    - `src/app/learn/[slug]/page.tsx`: remove unused `ChapterMedia` function (dead code).
    - `src/app/learn/page.tsx`: remove unused `I` icon import.
    - `src/app/layout.tsx`: migrate Microsoft Clarity to `next/script` with `strategy="lazyOnload"`.

    ## Verification
    - `pnpm install && pnpm lint` exits 0 with no errors and no warnings.
    - `pnpm exec tsc --noEmit` exits 0.
    - `pnpm build` succeeds.
    - Lighthouse mobile LCP on `/blog/cloudflare-agents-week-2026-explained` and `/blog/mcp-2026-roadmap-explained` (Vercel preview).
    - DevTools Network: `clarity.ms/tag/wjv5z43qr2` request fires after `window.load`, not during initial parse.

    ## Risk and rollback
    - LCP gain depends on Vercel preview measurement; if still ≥2.5s, follow Path B baseline doc per plan §"Cross-repo scope exception" (do not merge before baseline is in `koenig-ai-org`).
    - Rollback: revert the merge commit on `academy/redesign-v1`; no DB migrations, no env changes.

    ## Out of scope
    - Hero-image materialization for `auto:flux` frontmatter (separate ticket if pursued).
    - Adding `key={slug}` at wikilink-resolver call sites (defensive in-component reset is sufficient).
    - Frontend test scaffolding.
    EOF
    ```

    Notes for Executor:
    - PR base must be `academy/redesign-v1`, **not** `master` or `main`.
    - PR title prefix is `fix(academy):` to match prior `koea-709/blog-faq-jsonld-and-wikilinks` convention on this branch.
    - Do **not** include `Co-Authored-By: Claude …` trailers in the PR body itself; they belong in commit messages, not the PR description.
    - If the Path B baseline doc exists, append a "## Path B baseline" section with a link to the `koenig-ai-org` baseline doc URL before merging.

9. **Post-deploy LCP measurement.** After Vercel preview build promotes to live (or once the merged build hits `academy.kspl.tech`), re-run Lighthouse mobile against the two URLs and capture LCP. This is the QA Verifier's responsibility (KOEA-1005), but Executor should run a quick check on the Vercel preview to confirm the trend before requesting merge.

10. **If LCP still ≥2.5s on either URL after Step 9 (Path B):** create the baseline doc, in the `koenig-ai-org` repo, exactly at `koenig-ai-org/vault/decisions/KOEA-1000-lcp-baseline.md` — this is the one explicitly-authorised `vault/` write (see §"Cross-repo scope exception" above). Template:

    ```md
    ---
    type: baseline
    ticket: KOEA-1000
    scope: blog-post pages without rendered hero image
    decided: 2026-05-11
    accepted_lcp_p75: 3.0s (Needs Improvement)
    ---
    ## LCP baseline for hero-less blog posts
    Measured (post-Clarity-defer): cloudflare … = X.XXXs, mcp-2026-roadmap … = X.XXXs.
    Offsetting metrics: CLS 0.00, TBT <20ms, INP not reported.
    Reasoning: H1 text LCP on Vercel-cached static HTML with `next/font` `display: optional`; no rendered `<img>` (frontmatter uses `auto:flux` which is not materialized — see KOEA-1000 plan §"Out of scope" for the hero-image follow-up).
    QA Verifier: treat blog-post pages without `<img>` hero as PASS when LCP ≤ 3.0s on Lighthouse mobile until KOEA-1000 hero-image follow-up ticket closes.
    ```

    Then add a row to `KOEA-1005` acceptance criteria pointing at this baseline file. **Do NOT merge the `learnovaBeast` PR before the baseline doc is committed to `koenig-ai-org` (in its own short-lived branch + PR, e.g. `koea-1000/lcp-baseline`)** — QA Verifier needs something concrete to gate against, and the two PRs are coordinated by referencing the baseline doc URL from the `learnovaBeast` PR description (per Step 8 "Path B baseline" addendum).

    Reminder: this is the **only** `koenig-ai-org/vault/` write authorised by this plan. Do not edit `MEMORY.md`, glossary entries, blogs, or other decision docs as part of KOEA-1000 implementation.

## Verification (QA Verifier — KOEA-1005 — checks these)

Run from a clean checkout of `academy/redesign-v1` (post-merge):

- [ ] `cd learnovaBeast/learnova-academy && pnpm install && pnpm lint` exits 0; output ends with "✖ 0 problems" or no problem summary.
- [ ] `pnpm exec tsc --noEmit` exits 0.
- [ ] `pnpm test` still passes (will print "No tests configured yet" — same as before; not a regression).
- [ ] `pnpm build` succeeds end-to-end.
- [ ] Lighthouse mobile against the live (or production-preview) URL `https://academy.kspl.tech/blog/cloudflare-agents-week-2026-explained` reports LCP **≤ 2.5s** — OR LCP between 2.5s and 3.0s with the Path B baseline doc in place and referenced.
- [ ] Same for `https://academy.kspl.tech/blog/mcp-2026-roadmap-explained`.
- [ ] All other prior-PASS checks still PASS: FAQPage JSON-LD present on both URLs with `mainEntity` length matching frontmatter; no `/learn/blog#...` or `/blog/blog/...` wikilink rendering on spot-checked pages; BlogPosting + BreadcrumbList still present.
- [ ] Microsoft Clarity still loads (open DevTools Network tab → confirm a request to `clarity.ms/tag/wjv5z43qr2` fires after window.load — not before).

## Acceptance criteria (from KOEA-1000 directly)

1. `pnpm lint` failure at `src/components/GlossaryPopover.tsx:34` is fixed (no `react-hooks/set-state-in-effect` error).
2. The three warnings from the same lint run are resolved (zero warnings on `pnpm lint`).
3. Lighthouse LCP below 2.5s on both `/blog/cloudflare-agents-week-2026-explained` and `/blog/mcp-2026-roadmap-explained` — OR an accepted baseline/waiver is documented (Path B).
4. KOEA-709 / PR #22 routed back through Code Reviewer and G2 once the fix or baseline is in place. (Routing is the next-stage agents' work; this plan ends at "PR merged + verifier signed off.")

## Risk

- **Lint error reappears in CI even after the fix.** Mitigation: the chosen rewrite removes the synchronous `setState` in the effect entirely, not the lint warning text; `react-hooks/set-state-in-effect` triggers on AST shape, and the new shape has no `setData()` call in the effect's synchronous body. Verified by reading the rule's error message and the React docs link in the lint output. Run `pnpm lint` locally before pushing.
- **LCP fix doesn't close the 0.235s gap.** Mitigation: Path B baseline is pre-authored above; Executor falls back without re-planning. Avoids a second planning round-trip.
- **Removing `ChapterMedia` breaks something.** Mitigation: full-repo grep is mandated in Step 4 before deletion. The function is a top-level `function` declaration in a single page file, declared but never invoked — safe to remove. If the grep surprises Executor with a hit, stop and re-route to Planner instead of deleting.
- **`auto:flux` hero image was intended to render but is wired up wrong.** Mitigation: out of scope (see below); Executor must NOT try to fix the hero-image pipeline as part of this ticket. If they're tempted, file a separate issue.

## Worktree / lock note

No active worktree lock on `learnovaBeast/learnova-academy` was detected at plan time (2026-05-11). `git worktree list` returns five entries, none of them on `academy/redesign-v1` head; the existing `/tmp/learnova-redesign-g2` is detached and safe to leave for QA reference. Executor should create a fresh worktree at `/tmp/koea-1000-impl` per Step 1 rather than re-using a detached one.

## Out of scope (note for Chief Engineering — file separately if pursued)

- Materialising real hero images for `auto:flux` frontmatter (would actually render an `<Image priority>` LCP element with explicit dimensions and likely improve LCP further, but it touches the content asset pipeline, not the academy renderer). Recommend a separate ticket if product wants it.
- Inline CSS-in-JS → compiled CSS migration on the blog template (potentially larger LCP win, but cross-page risk).
- Adding real assertion-bearing tests for the academy frontend (`pnpm test` still prints "No tests configured yet"). Out of scope; track separately.
- Adding `display: "swap"` (or removing `display: "optional"`) for the prose font. Current `optional` already avoids render-blocking and is the right pick for an LCP-first page; do not change without a separate measurement-backed decision.
