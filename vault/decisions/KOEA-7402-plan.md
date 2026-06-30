---
ticket: KOEA-7402
planner: planner
date: 2026-06-26
estimated_complexity: medium
estimated_token_cost: $0.55
base_branch: academy/redesign-v1
basebranch_verified: true
revision: 2
---

# Plan: Deploy claude-tool-use-from-zero to academy.kspl.tech

## Goal
Publish the `claude-tool-use-from-zero` course through the Academy site so `https://academy.kspl.tech/courses/claude-tool-use-from-zero` renders and all 10 chapters are reachable without 404s. Success means the vault-driven course builds from the current vault, production smoke checks pass, and Lighthouse scores at least 90 on the course index. This plan does not authorize production deployment by itself; Executor must confirm the G4/human deploy gate before running the production deploy command.

## Context
- Files to read first: `learnova-academy/src/lib/courses.ts:1`, `learnova-academy/src/app/(site)/learn/[slug]/page.tsx:1`, `learnova-academy/src/app/(site)/learn/[slug]/[chapterSlug]/page.tsx:1`, `learnova-academy/src/app/(site)/courses/[slug]/page.tsx:1`, `learnova-academy/scripts/sync-vault.mjs:1`, `learnova-academy/next.config.ts:100`, `learnova-academy/README.md:109`, `vault/courses/claude-tool-use-from-zero/outline.md:1`.
- Relevant prior work: KOEA-6984 marked the course G3/G4 gate done; KOEA-7427 chain alert `c645d227-4bb8-42a0-951e-c4cb12d478b0` was cancelled as a false positive by Chief Engineering.
- Constraints: no Convex deploy unless Executor proves backend work is required; if Convex is needed, deploy only from `learnova-tc`. Work from `learnovaBeast` base branch `academy/redesign-v1` (verified present). Current vault scan shows 10 chapter markdown files and 10 `chapter-meta.json` sidecars, but `outline.md` still says `status: awaiting-g0`; treat that as a deploy-gate risk to confirm before production. Current Academy lint baseline is not clean: `pnpm lint` fails on 5 pre-existing `react-hooks/set-state-in-effect` errors at `src/app/(site)/catalog/catalog-client.tsx:32`, `src/components/course/ChapterMediaDock.tsx:51`, and `src/components/course/ChapterQuizGate.tsx:195/202/210`, plus warnings in `eslint.config.mjs`, `scripts/verify-g_code-blockers.mjs`, `src/app/(site)/learn/[slug]/page.tsx`, and `src/components/_shared/DigestOptIn.tsx`. Production deploy is blocked unless lint passes or Chief Engineering records an explicit KOEA-7402/KOEA-7429 waiver for those known baseline failures.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Academy-only static deploy verification. The Academy app already reads `vault/courses/<slug>/outline.md` and chapter markdown at build time, mirrors media through `scripts/sync-vault.mjs`, and exposes `/courses/<slug>` via the `/learn/<slug>` renderer. Executor should first prove the current content builds and renders, make only a narrow Academy route/link fix if the no-404 crawl reveals one, then deploy the prebuilt Vercel output after confirming G4 authorization.

**Rejected**: Convex import or schema change — the Academy course path is vault/static-build driven and no current file read showed a Convex dependency for this deploy. **Rejected**: rewrite course content/status in the vault as part of deploy — content governance should remain separate unless Chief Engineering explicitly authorizes updating the course gate metadata. **Rejected**: broad Academy redesign/refactor — this ticket is a deploy, not a UI rebuild.

## Steps (Executor follows in order)
1. In `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast`, create a branch from `academy/redesign-v1`, pull latest, and do not edit or deploy any `learnova-tc/convex` files unless a concrete Convex blocker appears.
2. In `learnova-academy`, run `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault node ./scripts/sync-vault.mjs`, then verify the course reader sees exactly 10 chapters for `claude-tool-use-from-zero` and that chapter media comes from the sidecars or mirrored public files.
3. Confirm the publication gate before production deploy: KOEA-7402/KOEA-6984 must show G4 human deploy approval, or Chief Engineering must explicitly authorize deploy despite the current `outline.md` status mismatch.
4. If the local no-404 crawl finds `/courses/<slug>/<chapterSlug>` chapter links returning 404, add a thin route alias at `learnova-academy/src/app/(site)/courses/[slug]/[chapterSlug]/page.tsx` re-exporting `../../../learn/[slug]/[chapterSlug]/page`; otherwise leave code unchanged.
5. Run minimal verification from `learnova-academy`: `pnpm lint`, `pnpm typecheck`, `pnpm test`, and `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault pnpm build`. `pnpm lint` must pass before production deploy. If it fails only with the known baseline listed in Context and Executor did not touch those files, Executor may continue only after Chief Engineering records an explicit KOEA-7402/KOEA-7429 waiver; if the change touches any failing file or introduces a new lint error, fix the in-scope lint issue before handoff. For any touched files, also run `pnpm exec eslint <touched-file...>` and require that targeted lint passes.
6. Start the built app with `pnpm start -p 3010` and smoke `http://localhost:3010/courses/claude-tool-use-from-zero`, all 10 `/learn/claude-tool-use-from-zero/<chapterSlug>` pages, the chapter prev/next links, and any emitted same-origin `/courses/...` links for non-404 responses.
7. If code changed, open a PR against `academy/redesign-v1` using `.github/PULL_REQUEST_TEMPLATE.md`; after PR approval and G4 deploy authorization, deploy with:
   `vercel pull --yes --environment=production --token "$VERCEL_TOKEN"`;
   `KOENIG_VAULT_ROOT=/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/vault vercel build --prod --token "$VERCEL_TOKEN"`;
   `vercel deploy --prod --prebuilt --token "$VERCEL_TOKEN" --yes`.
   Record the previous production deployment first with `vercel list --prod`; rollback is `vercel rollback <previous-deployment-url-or-id> --token "$VERCEL_TOKEN"` followed by `vercel rollback status`.

## Verification (QA Verifier checks these)
- [ ] `https://academy.kspl.tech/courses/claude-tool-use-from-zero` returns 200 and shows the course title and 10 chapters.
- [ ] Each chapter page returns 200: `01-introduction-to-claude-tool-use`, `02-understanding-mcp`, `03-building-your-first-mcp-server`, `04-handling-advanced-data-and-resources`, `05-observability-and-logging-in-mcp`, `06-security-and-authentication`, `07-creative-connectors`, `08-legal-connectors`, `09-smb-connectors`, `10-dynamic-workflows`.
- [ ] A same-origin link crawl from the course index and chapter pages finds no 404s in chapter navigation or course/chapter links.
- [ ] `pnpm lint` passes before production deploy, or the report shows only the documented 5 pre-existing baseline errors and Chief Engineering has recorded a KOEA-7402/KOEA-7429 deploy waiver; targeted lint passes for every touched file.
- [ ] Lighthouse on the production course index is at least 90.

## Risk
- The vault metadata currently says `status: awaiting-g0` while the ticket says G3-passed. Mitigation: do not deploy production until the G4/human deploy gate is confirmed, and keep any metadata correction separate unless Chief Engineering explicitly authorizes it.
- The Academy repo currently has a lint baseline failure unrelated to this deploy path. Mitigation: Executor must run and record `pnpm lint`, fix any newly introduced or touched-file lint failures, and treat production deploy as blocked unless lint passes or Chief Engineering explicitly waives the documented baseline for this deploy.

## Out of scope
- Rewriting course prose, changing chapter gate statuses, migrating content into Convex, or redesigning the Academy course UI.
