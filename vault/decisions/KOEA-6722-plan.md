---
ticket: KOEA-6722
agent: Executor
author: operator (Claude Code, V7 SEO/GEO Phase 3)
date: 2026-05-29
estimated_minutes: 35
---

# KOEA-6722 plan — Author byline pages + Person schema

## Goal

E-E-A-T (Experience, Expertise, Authoritativeness, Trust) signal. Per Google 2026 + Sapt.ai data, explicit author attribution with credentials adds ~22% AI search visibility.

## Procedure

### Phase A — author registry (10 min)

Create `learnova-academy/src/lib/authors.ts` (likely already exists per audit). Extend:
```typescript
export interface Author {
  slug: string;
  name: string;
  bio: string;             // 1-3 paragraphs
  jobTitle?: string;
  affiliation?: string;
  url?: string;            // external profile (LinkedIn, etc.)
  imageUrl?: string;       // avatar — falls back to /api/og?type=author&title=<name>
  credentials?: string[];  // ["Microsoft Partner of the Year 2025", "Founder Koenig Solutions", ...]
  socialLinks?: { type: string; url: string }[];
}

export const authors: Record<string, Author> = {
  vardaan: {
    slug: "vardaan",
    name: "Vardaan",
    jobTitle: "Founder & CEO",
    affiliation: "Koenig Solutions",
    bio: "Microsoft Partner of the Year 2025. Building Koenig AI Academy + Learnova LMS.",
    credentials: ["Microsoft Partner of the Year 2025", "Founder Koenig Solutions"],
    url: "https://www.linkedin.com/in/vardaankoenig",
  },
  "claude-code": {
    slug: "claude-code",
    name: "Claude Code (Anthropic)",
    bio: "AI agent powering Koenig AI Academy editorial pipeline. Drafts under operator review.",
  },
  // Backfill other agent slugs (blog-author, course-author, etc.) — they map to "agent-drafted" attribution
};
```

### Phase B — new route `app/authors/[slug]/page.tsx` (10 min)

Render author bio + credentials + linked posts:
```tsx
export async function generateStaticParams() {
  return Object.keys(authors).map((slug) => ({ slug }));
}

export default async function AuthorPage({ params }: { params: { slug: string } }) {
  const author = getAuthor(params.slug);
  if (!author) notFound();
  const posts = listPublishableBlogs().filter(b => b.author === params.slug || b.author_slug === params.slug);
  // Render bio, credentials, jobTitle/affiliation, post list with dates
  // JSON-LD: Person schema (next section)
}
```

### Phase C — Person schema in `lib/seo.ts` (10 min)

Add to `seo.ts`:
```typescript
interface PersonLdInput {
  slug: string;
  name: string;
  jobTitle?: string;
  affiliation?: string;
  url?: string;
  imageUrl?: string;
  credentials?: string[];
}

export function personLd(p: PersonLdInput) {
  return {
    "@context": "https://schema.org",
    "@type": "Person",
    name: p.name,
    ...(p.jobTitle ? { jobTitle: p.jobTitle } : {}),
    ...(p.affiliation ? {
      affiliation: { "@type": "Organization", name: p.affiliation }
    } : {}),
    url: p.url || `${SITE_URL}/authors/${p.slug}`,
    ...(p.imageUrl ? { image: p.imageUrl } : {}),
    ...(p.credentials && p.credentials.length > 0 ? {
      hasCredential: p.credentials.map(c => ({ "@type": "EducationalOccupationalCredential", name: c }))
    } : {}),
  };
}
```

Extend `blogPostingLd()` — author can now be the full Person schema:
```typescript
author: typeof b.author === "string" && authors[b.author]
  ? personLd(authors[b.author])
  : { "@type": "Person", name: b.author || "Koenig AI Academy" },
```

### Phase D — frontmatter additions (5 min)

Update `lib/vault.ts` BlogPost interface:
```typescript
author_slug?: string;  // links to authors directory; falls back to legacy `author` if missing
author_credentials?: string[];
```

## Acceptance

- [ ] `lib/authors.ts` extended with full Author interface + ≥3 real authors backfilled
- [ ] `/authors/[slug]/page.tsx` renders author page with bio + posts + Person JSON-LD
- [ ] BlogPosting JSON-LD on every blog has Person schema with `url`, `jobTitle`, optional `hasCredential`
- [ ] rich-results-test confirms valid Person schema embedded in BlogPosting

## Exit invariant

Executor exits `done` after all 4 phases. No operator action needed unless authors.ts requires bio approval (then exit `blocked` with unblock_owner=operator).
