---
ticket: KOEA-6723
agent: Executor
author: operator (Claude Code, V7 SEO/GEO Phase 3)
date: 2026-05-29
estimated_minutes: 20
---

# KOEA-6723 plan — original_data Report schema

## Goal

When blog/course frontmatter has `original_data: true`, emit Schema.org/Report alongside BlogPosting. Signal to AI engines that the post contains primary data (~+22% citation lift per Sapt.ai 2026 data).

## Procedure

### Phase A — extend `lib/seo.ts` (10 min)

Add new exported function:
```typescript
interface ReportLdInput {
  slug: string;
  title: string;
  description: string;
  datePublished: string;
  dateModified?: string;
  author?: string;
  // What makes this a Report (vs Article):
  measurementSubject?: string;   // "OpenAI Realtime API latency"
  methodology?: string;          // "10 trials per region across 3 regions"
  sampleSize?: number;           // 30
  dataPublic?: boolean;          // true if raw data is downloadable
}

export function reportLd(r: ReportLdInput) {
  return {
    "@context": "https://schema.org",
    "@type": "Report",
    name: r.title,
    description: r.description,
    datePublished: r.datePublished,
    ...(r.dateModified ? { dateModified: r.dateModified } : {}),
    url: `${SITE_URL}/blog/${r.slug}`,
    publisher: { "@type": "Organization", name: ORG_NAME, url: SITE_URL },
    ...(r.author ? { author: { "@type": "Person", name: r.author } } : {}),
    ...(r.measurementSubject ? { about: r.measurementSubject } : {}),
    ...(r.methodology ? { description: `${r.description}\n\nMethodology: ${r.methodology}` } : {}),
  };
}
```

### Phase B — wire into blog page (5 min)

In `learnova-academy/src/app/blog/[slug]/page.tsx`, after emitting `blogPostingLd()`:
```tsx
{post.original_data && (
  <script
    type="application/ld+json"
    dangerouslySetInnerHTML={{ __html: jsonLdScript(reportLd({
      slug: post.slug,
      title: post.title,
      description: post.seo_description || post.whats_new?.[0] || "",
      datePublished: post.date,
      dateModified: post.last_updated,
      author: post.author,
    })) }}
  />
)}
```

### Phase C — verify (5 min)

```bash
# 1. Publish a test blog with original_data: true in frontmatter
# 2. View deployed page source — confirm Report JSON-LD present
# 3. rich-results-test.google.com — confirm Report parses cleanly
```

## Acceptance

- [ ] `reportLd()` exported from lib/seo.ts
- [ ] Blog page conditionally emits Report schema when frontmatter has original_data: true
- [ ] Test blog at /blog/<some-test-slug> has both BlogPosting AND Report JSON-LD in source
- [ ] rich-results-test green

## Exit invariant

Executor exits `done`. No operator action needed.
