---
id: KOEA-11001
title: "/cited — commit fixture test + JSON-LD isPartOf/Article refinements"
status: approved
author: chief-engineering
date: 2026-07-09
issue: KOEA-11001
parent: KOEA-7011
---

# Plan — KOEA-11001

Follow-up from [KOEA-7011] /cited page (PR #162, merged 62ca5f33). Two items in one PR.

## Context

- `academy/redesign-v1` has the /cited page but with incomplete JSON-LD (bare `ListItem{url,name}`, no `isPartOf`)
- Working tree (untracked) has rewritten `citations.ts`, `page.tsx` (importing `citedPageLd`), and `verify-citations.mjs`
- `citedPageLd` is imported in the working-tree `page.tsx` but NOT YET defined in `seo.ts`
- `verify-citations.mjs` is complete and just needs committing

## Branch

`koea-11001/cited-fixture-jsonld` — base: `academy/redesign-v1`

## Implementation steps

### Step 1 — Add `citedPageLd` to `seo.ts`

File: `learnova-academy/src/lib/seo.ts`

Add this function (insert after `jsonLdScript`):

```typescript
interface CitedPageLdInput {
  url: string;
  dateModified: string;
  items: { url: string; headline: string }[];
}

export function citedPageLd(input: CitedPageLdInput) {
  return {
    "@context": "https://schema.org",
    "@type": "CollectionPage",
    name: "AI Citation Hall of Fame",
    url: input.url,
    dateModified: input.dateModified,
    isPartOf: {
      "@type": "WebSite",
      name: ORG_NAME,
      url: SITE_URL,
    },
    ...(input.items.length > 0
      ? {
          mainEntity: {
            "@type": "ItemList",
            itemListElement: input.items.map((item, i) => ({
              "@type": "ListItem",
              position: i + 1,
              item: {
                "@type": "Article",
                url: item.url,
                headline: item.headline,
              },
            })),
          },
        }
      : {}),
  };
}
```

### Step 2 — Commit the updated cited-page files

On the new branch (from `academy/redesign-v1`), commit three changes as one commit:

1. `learnova-academy/src/lib/seo.ts` — `citedPageLd` function added
2. `learnova-academy/src/app/(site)/cited/page.tsx` — replace with working-tree version (uses `citedPageLd`, has `Hall of Fame` title, fixed metadata, full rewrite)
3. `learnova-academy/src/lib/citations.ts` — replace with working-tree version (proper module with `KOENIG_VAULT_ROOT` env override, `AggregatedCitation` interface, all exported functions)

### Step 3 — Commit `verify-citations.mjs`

Separate commit:
- `learnova-academy/scripts/verify-citations.mjs` — the fixture test

Run it before committing to verify assertions pass:
```bash
cd learnova-academy && node --experimental-strip-types scripts/verify-citations.mjs
```

### Step 4 — Open PR to `academy/redesign-v1`

Title: `[KOEA-11001] feat(cited): add citedPageLd with isPartOf/Article + commit fixture test`

## Acceptance criteria

- [ ] `citedPageLd` exported from `@/lib/seo`
- [ ] JSON-LD has `isPartOf.@type=WebSite`, `mainEntity.itemListElement[*].item.@type=Article`
- [ ] `verify-citations.mjs` in repo, passes with `node --experimental-strip-types scripts/verify-citations.mjs`
- [ ] TypeScript build clean (no import errors)
- [ ] PR to `academy/redesign-v1`

## Files changed

- `learnova-academy/src/lib/seo.ts` — add `citedPageLd`
- `learnova-academy/src/app/(site)/cited/page.tsx` — use `citedPageLd`
- `learnova-academy/src/lib/citations.ts` — better version already in working tree
- `learnova-academy/scripts/verify-citations.mjs` — fixture test (new file)
