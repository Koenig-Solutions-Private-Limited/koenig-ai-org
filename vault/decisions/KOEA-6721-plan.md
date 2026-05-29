---
ticket: KOEA-6721
agent: Executor
author: operator (Claude Code, V7 SEO/GEO Phase 3)
date: 2026-05-29
estimated_minutes: 60
---

# KOEA-6721 plan — Convex anonymous enrollment + progress tracking

## Goal

Wire real learner enrollment + progress tracking via Convex. Enables honest `aggregateRating` in Course JSON-LD (V7 Phase 1 dropped the synthetic 4.7★ per [stance:contrarian-no-fake-ratings]).

## Procedure

### Phase A — Convex schema (15 min)

learnova-academy uses anonymous-by-default. **CRITICAL: per `/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/CLAUDE.md`, ALL Convex schema changes must be deployed from `learnova-tc/convex/` (master).** Coordinate with operator before touching schema.

Add to `learnova-tc/convex/schema.ts`:
```typescript
academyEnrollments: defineTable({
  anonSessionId: v.string(),   // signed cookie value, no PII
  courseSlug: v.string(),
  startedAt: v.number(),       // Date.now()
  lastActiveAt: v.number(),
  progressPct: v.number(),     // 0-100
  completedAt: v.optional(v.number()),
}).index("by_course", ["courseSlug"])
  .index("by_session", ["anonSessionId"]),

academyReviews: defineTable({
  anonSessionId: v.string(),
  courseSlug: v.string(),
  rating: v.number(),         // 1-5
  text: v.optional(v.string()),
  submittedAt: v.number(),
}).index("by_course", ["courseSlug"]),
```

Convex functions (in `learnova-tc/convex/academy.ts` — new file):
- `getCourseStats(courseSlug)` → `{ learners: number, avgRating: number | null, reviewCount: number }`
- `enroll(anonSessionId, courseSlug)` → idempotent mutation
- `updateProgress(anonSessionId, courseSlug, pct)`
- `submitReview(anonSessionId, courseSlug, rating, text)`

### Phase B — anonymous session cookie (10 min)

learnova-academy `middleware.ts` (or similar) generates anonymous session ID via signed JWT cookie:
```typescript
// Cookie: koenig_anon_session (httpOnly, secure, sameSite=lax, 365 day)
// Value: signed JWT { sid: <random>, iat: <now> }
// Signed with NEXT_PUBLIC_NOPE / use env var KOENIG_SESSION_SIGNING_KEY
```

### Phase C — `lib/seo.ts` real aggregateRating (10 min)

Update `courseLd()` in `learnova-academy/src/lib/seo.ts`:
```typescript
// At build time, fetch real enrollment data:
const stats = await fetchConvexCourseStats(c.slug);
return {
  ...,
  ...(stats.learners >= 10 && stats.reviewCount >= 1 ? {
    aggregateRating: {
      "@type": "AggregateRating",
      ratingValue: stats.avgRating.toFixed(1),
      reviewCount: stats.reviewCount,
      bestRating: "5",
      worstRating: "1",
    }
  } : {}),
};
```

Build-time fetch via `@convex/api` (or HTTP if SSG):
```typescript
const fetchConvexCourseStats = async (slug: string) => {
  const res = await fetch(`${CONVEX_HTTP_URL}/api/academy.getCourseStats?courseSlug=${slug}`);
  return await res.json();
};
```

### Phase D — wire UI (15 min)

learnova-academy `app/learn/[slug]/page.tsx`:
- Enroll button → calls `enroll(sid, slug)` mutation
- Chapter scroll passes 25/50/75/100% → `updateProgress`
- End-of-course → review modal (rating + optional text) → `submitReview`

### Phase E — verify (10 min)

```bash
# 1. Enroll 12 test sessions (use curl with different cookies)
# 2. Verify Course JSON-LD on /learn/gemini-enterprise-agents has aggregateRating
# 3. rich-results-test.google.com confirms valid AggregateRating
```

## Acceptance

- [ ] Convex schema + functions deployed from `learnova-tc`
- [ ] Anonymous session cookie set on first visit
- [ ] Enroll + progress + review wired in UI
- [ ] Course with ≥10 learners + ≥1 review emits real aggregateRating
- [ ] rich-results-test passes

## Exit invariant

Executor coordinates Convex schema deployment via operator (per CLAUDE.md constraint). Phase A exits `blocked` with unblock_owner=operator + unblock_action="deploy Convex schema from learnova-tc".
