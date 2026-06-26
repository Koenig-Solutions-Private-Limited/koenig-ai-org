---
ticket: KOEA-1672
planner_ticket: KOEA-1689
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.40
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: fc64c639-f54e-45d5-88b8-bcf39d83ad2e
---

# Plan: GPT-5.5 Codex blog page-weight fix

## Goal

Reduce the raw HTML response for `https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex` from the verified 109,660 bytes to at or below the 81,920 byte blog threshold. Success is a scoped `learnova-academy` rendering change that preserves the visible article, title/meta/canonical, author, BlogPosting/Breadcrumb JSON-LD, floating TOC, and Nova tutor affordance while removing avoidable initial-load serialization.

## Context

- Files to read first: `/paperclip/instances/default/workspaces/learnovaBeast-koea-1672/learnova-academy/src/app/blog/[slug]/page.tsx:67-267`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-1672/learnova-academy/src/app/blog/[slug]/client-shell.tsx:10-39`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-1672/learnova-academy/src/components/_shared/blog-scroll.tsx:30-83`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-1672/learnova-academy/src/components/_shared/tutor.tsx:26-113`, `/paperclip/instances/default/workspaces/learnovaBeast-koea-1672/learnova-academy/src/app/api/tutor/route.ts:85-119`, `vault/blogs/2026-04-30-gpt-5-5-in-codex/draft.md`.
- Relevant prior work: KOEA-1638 verifier found HTTP 200, 109,660 byte HTML, valid BlogPosting/BreadcrumbList/FAQPage JSON-LD, and separate slides-link failure owned by KOEA-1563. KOEA-1672 Chief Engineering confirmed this ticket is only the page-weight hard block.
- Constraints: keep scope to `learnova-academy` blog rendering for slug `2026-04-30-gpt-5-5-in-codex`; do not touch student/sales/admin/tc portals; do not resolve the slides asset issue; open implementation PR against `academy/redesign-v1`.
- Diagnosis evidence: live `curl -sS -D /tmp/headers -o /tmp/gpt55.html <url> && wc -c /tmp/gpt55.html` measured 109,660 bytes. Script analysis showed 77,708 bytes in `<script>` tags, with 73,571 bytes in `self.__next_f` payloads. Two exact full-body RSC chunks are 11,984 bytes each, and the page also serializes the rendered article because `page.tsx` wraps the whole article in the client `BlogScrollLayer`.
- Threshold validity: the 81,920 byte check is valid for this response. The page is over the limit due to avoidable initial HTML/RSC payload duplication, not because the article prose alone is too long. The visible non-script HTML is about 31,424 bytes, so a rendering fix can meet the threshold without cutting editorial content.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Move blog scroll/progress behavior out of the server article wrapper and stop passing the full markdown body through initial client props. In `page.tsx`, render the JSON-LD, top bar, hero, article, and references as normal server output, then mount `BlogPageClient` as a sibling with only `slug`, `title`, and the already-computed `headings`. In `client-shell.tsx`, use those headings directly for `Toc`. In `TutorRail`, keep `body` optional and, when omitted, derive the grounding text from the rendered `article` DOM only when the reader sends a tutor prompt; the `/api/tutor` contract still receives a body, just not in the initial HTML. This removes the client-wrapper serialization of the article plus two full markdown prop copies, with expected savings well above the 27,740 bytes needed.

**Rejected**: Trim the blog content or references. This could save bytes, but it changes editorial/SEO content even though the root cause is renderer duplication.

**Rejected**: Remove JSON-LD/FAQ structured data or raise the threshold. This might pass the byte check, but it would weaken SEO verification and the threshold is measuring a real raw-response regression.

## Steps (Executor follows in order)

1. In `learnova-academy/src/app/blog/[slug]/page.tsx`, remove the `BlogScrollLayer` wrapper around the full page. Return a server fragment containing the existing JSON-LD `<script>`, `TopBar`, hero image, `<main><article>...</article></main>`, and a sibling `BlogPageClient`.
2. In the same file, keep `const headings = extractHeadingsForScroll(body)` for server-side heading extraction, but pass only `slug={post.slug}`, `title={post.title}`, and `headings={headings}` to `BlogPageClient`; remove `body={body}` and `markdownForToc={body}`.
3. In `learnova-academy/src/app/blog/[slug]/client-shell.tsx`, replace `body` and `markdownForToc` props with `headings: Heading[]` or the compatible TOC item type. Remove `extractHeadings`/`useMemo` over markdown and render `<Toc items={headings} />`.
4. Keep scroll progress and hero-scrolled behavior by wrapping only the client controls in `BlogScrollLayer` or by moving equivalent scroll/progress state into `BlogPageClient`; do not put server article children back under a client component.
5. In `learnova-academy/src/components/_shared/tutor.tsx`, make initial-load grounding optional: compute `bodyForRequest = body ?? document.querySelector("article")?.innerText ?? ""` inside `send()`, require `slug`, `title`, and `bodyForRequest` before posting, and send that derived body to `/api/tutor`. Leave course pages working with their existing explicit `body` prop.
6. Build and measure the generated page, then verify the live or preview HTML byte count with the same raw-response command. If the result is still above 81,920 bytes, inspect remaining `self.__next_f` chunks before considering any SEO/content removal.

## Verification (QA Verifier checks these)

- [ ] Raw page weight command returns `<=81920`: `curl -sS -D /tmp/academy_headers.txt -o /tmp/gpt55.html https://academy.kspl.tech/blog/2026-04-30-gpt-5-5-in-codex && wc -c /tmp/gpt55.html`.
- [ ] HTML payload analysis shows no full markdown body duplicated in `self.__next_f`: `node -e 'const fs=require("fs");const h=fs.readFileSync("/tmp/gpt55.html","utf8");console.log((h.match(/GPT-5\\.5, released April 23, 2026/g)||[]).length)'` should drop from 4 to the visible article count, not include two client-prop copies.
- [ ] Blog still renders title, author, date, hero image, article body, references, floating TOC, and Nova tutor button for `/blog/2026-04-30-gpt-5-5-in-codex`.
- [ ] SEO basics remain: canonical `/blog/2026-04-30-gpt-5-5-in-codex`, OpenGraph image, BlogPosting and BreadcrumbList JSON-LD parse, and author link points to `/authors/vardaan-koenig`.
- [ ] Targeted checks pass from `learnova-academy`: `pnpm typecheck` and `pnpm build`.

## Risk

- Moving tutor grounding from serialized markdown to DOM-derived text may slightly change Nova citations because markdown heading markers are not sent verbatim. Mitigation: derive from `article.innerText`, keep section headings visible in the text, and smoke-test one tutor prompt after build; if citation quality regresses, route only the tutor endpoint to load markdown server-side in a follow-up rather than re-adding initial client props.

## Out of scope

- Fixing or verifying the missing slides link/assets from KOEA-1563.
- Editing the GPT-5.5 Codex article prose to reduce length.
- Changing page-weight thresholds or verifier policy.
- Touching non-academy portals.
