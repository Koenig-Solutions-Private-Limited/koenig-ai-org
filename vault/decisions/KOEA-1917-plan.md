---
ticket: KOEA-1917
planning_issue: KOEA-1939
planner: planner
date: 2026-05-14
estimated_complexity: small
estimated_token_cost: $0.30
base_branch: academy/redesign-v1
basebranch_verified: true
chain_alert_approval: 11502275-a5fd-41d9-8e12-9a14e0e01dfb
type: decision
tags:
  - decision
  - engineering
  - seo
---

# Plan: remove dead Academy course URLs from crawler surfaces

## Goal
Stop advertising course URLs that the Academy site does not serve. Success means `sitemap.xml`, `/llms.txt`, and `/llms-full.txt` expose the same publishable course corpus, and the 12-course production probe no longer finds sitemap-listed `/learn/*` URLs that return 404.

## Context
- Files to read first: `learnova-academy/src/app/sitemap.ts:1-65`, `learnova-academy/src/app/llms.txt/route.ts:1-90`, `learnova-academy/src/app/llms-full.txt/route.ts:1-101`, `learnova-academy/src/lib/courses.ts:10-260`, `learnova-academy/src/app/learn/[slug]/page.tsx:42-86`.
- Relevant prior work: `vault/decisions/KOEA-1030-plan.md` correctly identified the fixture-vs-vault source mismatch, but it is stale on base branch details and current file state.
- Current state: `llms.txt` and `llms-full.txt` already use `listPublishableCourses()`. `sitemap.ts` still imports `courses` from `@/lib/fixtures` and emits all 12 fixture slugs.
- Live evidence from 2026-05-14: production `sitemap.xml` lists 12 `/learn/*` URLs; only `claude-tool-use-from-zero` and `mcp-from-first-principles-to-production` return 200. The other 10 return 404.
- Publishable source of truth: `listPublishableCourses()` filters vault course outlines to `g0-passed`, `g3-passed`, or `published`; current vault state has 2 publishable courses.
- Constraints: base branch is `academy/redesign-v1` in `learnovaBeast`; do not change schema, live-page markup, or course publishing states; keep the implementation in Academy crawler-surface code only.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Make the sitemap use the same vault-backed publishable-course source as the llms routes. This is the smallest current-state fix: replace the sitemap fixture import with `listPublishableCourses()` and build course routes from that list. The llms files should remain code-unchanged unless Executor finds a parity bug during verification; the plan explicitly verifies them because they are part of the crawler corpus contract.

**Rejected**: Publish the 10 missing courses — this is content production, not an SEO surface fix; manually blacklist the 10 dead slugs in `sitemap.ts` — this creates another stale list; broaden the ticket to catalog/home/tutor links — useful follow-up, but outside the crawler-surface acceptance criteria.

## Steps (Executor follows in order)
1. In `learnovaBeast`, create or reuse a clean FE worktree from `academy/redesign-v1`; if using `/paperclip/instances/default/workspaces/learnovaBeast-fe-agent`, first confirm `.claude/agent-lock` is absent and do not overwrite unrelated branch changes.
2. Edit `learnova-academy/src/app/sitemap.ts`: replace `import { courses } from "@/lib/fixtures"` with `import { listPublishableCourses } from "@/lib/courses"`.
3. Edit `learnova-academy/src/app/sitemap.ts`: change `courseRoutes` to iterate `listPublishableCourses()` and emit `BASE + "/learn/" + c.slug`, leaving static, blog, author, glossary, vendor, and capability routes unchanged.
4. Inspect `learnova-academy/src/app/llms.txt/route.ts` and `learnova-academy/src/app/llms-full.txt/route.ts`; do not rewrite them unless they no longer use `listPublishableCourses()` or fail the parity checks below.
5. Run `pnpm --filter learnova-academy build` from the repo root. If local package filtering is unreliable, run `pnpm build` inside `learnova-academy`.
6. Start the built Academy app on port `3010` with `pnpm --filter learnova-academy start` or `pnpm start` inside `learnova-academy`; if port `3010` is occupied, use `PORT=3011` only if Next honors it for this package, otherwise stop the stale process before retrying.
7. Open a draft PR against `academy/redesign-v1` with the repository PR template filled in; rollback is a one-commit revert of the sitemap import/loop change.

## Verification (QA Verifier checks these)
- [ ] Build passes: `pnpm --filter learnova-academy build`.
- [ ] Local sitemap course URLs equal the publishable vault course slugs:
  ```bash
  curl -s http://localhost:3010/sitemap.xml \
    | rg -o 'https://academy\.kspl\.tech/learn/[a-z0-9-]+' \
    | sort -u > /tmp/sitemap-courses.txt

  rg -l '^status: (g0-passed|g3-passed|published)$' \
    /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault/courses/*/outline.md \
    | sed -E 's#.*/courses/([^/]+)/outline.md#https://academy.kspl.tech/learn/\1#' \
    | sort -u > /tmp/publishable-courses.txt

  diff -u /tmp/publishable-courses.txt /tmp/sitemap-courses.txt
  ```
- [ ] The 12-course probe shows only publishable courses are sitemap-listed:
  ```bash
  for slug in \
    claude-tool-use-from-zero \
    gpt-voice-realtime-handbook \
    gemini-2m-context-deep-dive \
    mcp-from-first-principles-to-production \
    prompt-engineering-without-tears \
    building-evals-101 \
    rag-in-2026-still-worth-it \
    agents-from-prompt-to-production \
    fine-tuning-when-and-when-not \
    shipping-safe-llm-features \
    embeddings-the-quiet-workhorse \
    your-first-prompt-in-five-minutes; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:3010/learn/$slug")
    in_sitemap=$(rg -c "/learn/$slug$" /tmp/sitemap-courses.txt || true)
    printf "%-48s HTTP %s | in_sitemap=%s\n" "$slug" "$code" "$in_sitemap"
  done
  ```
- [ ] `/llms.txt` uses the same course URL set as the sitemap:
  ```bash
  curl -s http://localhost:3010/llms.txt \
    | rg -o 'https://academy\.kspl\.tech/learn/[a-z0-9-]+' \
    | sort -u > /tmp/llms-courses.txt
  diff -u /tmp/sitemap-courses.txt /tmp/llms-courses.txt
  ```
- [ ] `/llms-full.txt` course entry URLs use the same course URL set as the sitemap. Use `^- URL:` lines, not a naive `/learn/` grep, because full course/blog bodies can contain external documentation URLs such as `modelcontextprotocol.io/docs/learn/server-concepts`:
  ```bash
  curl -s http://localhost:3010/llms-full.txt \
    | rg '^- URL: https://academy\.kspl\.tech/learn/[a-z0-9-]+' \
    | sed 's/^- URL: //' \
    | sort -u > /tmp/llms-full-course-entries.txt
  diff -u /tmp/sitemap-courses.txt /tmp/llms-full-course-entries.txt
  ```
- [ ] Production smoke after deploy: re-run the same 12-course probe against `https://academy.kspl.tech`; every URL still present in production `sitemap.xml` returns 200 or an intentional redirect, and the 10 known dead slugs are absent from `sitemap.xml`, `/llms.txt`, and `/llms-full.txt` course-entry URLs.

## Risk
- The sitemap could become temporarily smaller than expected if `KOENIG_VAULT_ROOT` is missing in the build environment. Mitigation: the build/parity checks compare sitemap output with vault outline state, and the PR should call out the environment dependency before merge.

## Out of scope
- Publishing or drafting the 10 missing courses.
- Changing course statuses in `vault/courses/*/outline.md`.
- Fixing user-facing catalog/home/tutor cards that may still mention draft courses.
- Changing `/learn/[slug]` page rendering, schema markup, or course page design.
- Cleaning up unrelated `/llms-full.txt` body links produced by blog/course prose.
