---
ticket: KOEA-7947
planner: planner
date: 2026-06-12
estimated_complexity: small
estimated_token_cost: $0.20
agent: planner
type: decision
tags:
  - decision
  - seo
  - schema
base_branch: academy/redesign-v1
---

# Plan: Remove invalid Course JSON-LD credential field

## Goal
Remove the invalid boolean `educationalCredentialAwarded: false` field from Course JSON-LD so every generated course page avoids the schema.org type error. Success means `courseLd()` still emits valid Course structured data, but no longer claims a credential field for free Koenig AI Academy courses that do not award formal credentials.

## Context
- Files to read first: `learnovaBeast/learnova-academy/src/lib/seo.ts:120-158`, `learnovaBeast/learnova-academy/package.json:1-20`
- Relevant prior work: KOEA-7947 parent ticket from KOEA-7346 schema audit; no PR is open yet for this fix.
- Constraints: `academy/redesign-v1` is the verified base branch; CEO G3 sign-off is required before merge per SEO SOUL policy; Planner chain alert `c68a184b-be70-40cf-9b52-dae7c1f8b7be` was resolved by Chief Engineering as an authorized gate chain.
- Current finding: `courseLd()` currently emits `educationalCredentialAwarded: false` at `learnova-academy/src/lib/seo.ts:144`.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Remove the field entirely from the `courseLd()` return object. This is the narrowest correct schema fix because Koenig AI Academy courses are free and do not award formal credentials, so omitting `educationalCredentialAwarded` is more accurate than replacing the boolean with placeholder text.
**Rejected**: Replace with `"Certificate of Completion"` - inaccurate because the courses do not currently award formal credentials; keep a false-like string such as `"false"` - schema-valid type but semantically misleading and likely harmful for rich result trust.

## Steps (Executor follows in order)
1. Branch from verified base `academy/redesign-v1` in the `learnovaBeast` worktree.
2. Edit `learnova-academy/src/lib/seo.ts` and remove only the `educationalCredentialAwarded: false,` property from `courseLd()`.
3. Do not add a replacement credential field unless product/SEO explicitly confirms a real credential exists.
4. Run a targeted search from `learnovaBeast`: `rg -n "educationalCredentialAwarded:\\s*false|educationalCredentialAwarded" learnova-academy/src`.
5. Run a narrow app verification from `learnovaBeast/learnova-academy`: `pnpm typecheck`; if typecheck is already known-clean, optionally add `pnpm build` only if Executor touches generated SEO behavior beyond the one-line field removal.
6. Open the implementation PR against `academy/redesign-v1` and note in the PR that CEO G3 is required before merge.

## Verification (QA Verifier checks these)
- [ ] `rg -n "educationalCredentialAwarded:\\s*false" learnova-academy/src` returns no matches after the fix.
- [ ] `courseLd()` still returns a Course object with provider, URL, accessibility, language, teaches, duration, CourseInstance, optional `hasPart`, and optional `coursePrerequisites`.
- [ ] `pnpm typecheck` passes from `learnovaBeast/learnova-academy`, or any failure is documented as pre-existing and unrelated.
- [ ] PR description or issue comment explicitly states CEO G3 is required before merge under SEO SOUL policy.

## Risk
- Removing the field could be mistaken for weakening course metadata; mitigation is to document that omission is deliberate because there is no awarded credential, and future credential-bearing courses can reintroduce the field as schema-valid text only after product confirmation.

## Out of scope
- Adding certificates, learner review data, aggregate ratings, CourseInstance expansion, or broader Course schema redesign.
