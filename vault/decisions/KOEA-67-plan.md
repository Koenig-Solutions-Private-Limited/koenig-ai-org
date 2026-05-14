---
ticket: KOEA-67
parent: KOEA-66
planner: planner
date: 2026-04-30
estimated_complexity: large
estimated_token_cost: $0.55
files_touched:
  - learnovaBeast/learnova-academy/src/lib/vault.ts
  - learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx
  - learnovaBeast/learnova-academy/src/app/academy.css
  - learnovaBeast/learnova-academy/src/components/_shared/blog-scroll.tsx  # new
  - learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx
  - companies/learnova-academy/agents/blog-author/skills/blog-write/SKILL.md  # new
---

# Plan: Blog template polish — hero/images, TOC anchors, scroll-spy, right-rail animation

## Goal

Deliver a polished blog reading experience: a hero image section with gradient overlay and chips,
a fixed left-nav TOC with IntersectionObserver scroll-spy, a TutorRail that animates into view
after scrolling past the hero and shows the active H2, and an image pipeline wired into the
blog-author draft workflow. All items 1–5 from KOEA-66 spec. Zero new npm packages.

## Context

- Files to read first:
  - `learnovaBeast/learnova-academy/src/lib/vault.ts:14-28` — BlogPost interface (no image fields yet)
  - `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx:104-175` — current hero/byline + renderBlock (headings render without `id` attrs)
  - `learnovaBeast/learnova-academy/src/app/academy.css:294-340` — lesson-grid + .lesson-nav (grid flow, not fixed)
  - `learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx:41-99` — TutorRailProps + header
  - `companies/learnova-academy/skills/image-gen/SKILL.md` — image-gen sub-skill exists at company level
- Constraints:
  - Zero new npm packages
  - Hero image WebP ≤200KB, responsive srcset
  - Lighthouse mobile perf ≥85, CLS < 0.05 (no layout shift from hero image: must specify width/height)
  - Branch `academy/redesign-v1`, PR → `main`
  - Executor MUST browser-verify at 1280px before opening PR

## Approach (chosen)

**Client island pattern**: `page.tsx` stays a static server component. Extract scroll-driven
interactivity into a single `"use client"` component `BlogScrollLayer`
(`src/components/_shared/blog-scroll.tsx`) that accepts a serializable `headings[]` array
(built at static render time from the body markdown) plus a `heroHeight` estimate. The layer
owns reading-progress state (scroll listener), active-section state (IntersectionObserver),
and passes both into the left-nav TOC and TutorRail. TutorRail gains `activeSection` and
`scrolledPastHero` boolean props. This keeps the static render fast (no JS needed for initial
paint) while adding rich interactivity as a hydration island.

## Approaches rejected

- **Full page client component**: marks `page.tsx` as "use client" → kills static generation, hurts LCP.
- **CSS @scroll-timeline only**: browser support is Chrome 115+ only, not Safari 17; still needs JS for IntersectionObserver TOC spy anyway.

## Steps (Executor follows in order)

### Step 1 — Extend `vault.ts` interface + parser

File: `learnovaBeast/learnova-academy/src/lib/vault.ts`

Add to `BlogPost` interface after line 28 (`sources: string[]`):
```ts
hero_image?: { url: string; alt: string; prompt?: string };
inline_images?: { after_heading: string; url: string; alt: string; caption?: string }[];
seo_description?: string;
```

In `readBlogFile` return object (after `sources`):
```ts
hero_image: data.hero_image,
inline_images: data.inline_images ?? [],
seo_description: data.seo_description,
```

Also update `generateMetadata` in `page.tsx` to prefer `post.seo_description` over
`post.whats_new?.[0]` for the description field.

### Step 2 — Create `blog-write` SKILL.md for blog-author image-gen wiring

File: `companies/learnova-academy/agents/blog-author/skills/blog-write/SKILL.md` (new — also create dir)

Document that blog-author MUST:
1. After full draft is written, identify 1 hero image opportunity and 1-2 inline image slots
   at major H2 boundaries (the most visually significant sections).
2. Call the company-level `image-gen` skill with `aspect: 16:9`, `quality: standard`
   for the hero; `aspect: 3:2` for inlines.
3. Write the resulting URLs into the draft frontmatter using the fields defined in Step 1.
4. Hero prompt style guide: "clean editorial illustration, [topic], muted teal and amber palette,
   no text, no logos, 16:9, WebP". Max 150 chars.
5. Per-task image budget cap: 3 images × $0.04 = $0.12.

### Step 3 — Add slugify util + heading ID extraction to `page.tsx`

File: `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx`

Add a pure `slugify` function (after imports):
```ts
function slugify(text: string): string {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}
```

Build `headings` array from `body` before the JSX return (at server render time):
```ts
const headings = [...body.matchAll(/^(#{2,3})\s+(.+)$/gm)].map(m => ({
  level: m[1].length as 2 | 3,
  text: m[2].trim(),
  id: slugify(m[2].trim()),
}));
```

Update `renderBlock` H2/H3 branches to pass `id={slugify(trimmed.slice(3))}` (H2) and
`id={slugify(trimmed.slice(4))}` (H3) on the rendered heading element. Also wire inline images:
after each H2 render, check `post.inline_images` for an entry whose `after_heading` (slugified)
matches — if found, render an `<img>` beneath the heading with `width={768}`, `height={512}`,
responsive `srcSet`, and a `<figcaption>` if `caption` is set.

### Step 4 — Hero section redesign in `page.tsx`

File: `learnovaBeast/learnova-academy/src/app/blog/[slug]/page.tsx`

Replace the current breadcrumb nav + h1 + byline block (lines ~106-129) inside `<article>` with:

```tsx
{/* Hero image block */}
{post.hero_image && (
  <div className="blog-hero" style={{ marginBottom: 32 }}>
    <img
      src={post.hero_image.url}
      alt={post.hero_image.alt}
      width={1344} height={756}
      style={{ width: '100%', height: 'auto', display: 'block', borderRadius: 'var(--r-5)' }}
    />
    <div className="blog-hero-overlay">
      <h1 className="h1-article blog-hero-title">{post.title}</h1>
    </div>
  </div>
)}
{!post.hero_image && (
  <h1 className="h1-article" style={{ margin: '0 0 16px' }}>{post.title}</h1>
)}

{/* Eyebrow + byline row */}
<div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 8, marginBottom: 24 }}>
  <span className={`chip ${post.vendor_tag.toLowerCase()}`}>{post.vendor_tag}</span>
  <span className={`chip ${post.content_type}`}>{post.content_type}</span>
  <span style={{ flex: 1 }} />
  <span className="chip"><I.clock size={11} /> {post.reading_time_min} min</span>
</div>
<div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 32, fontSize: 13, color: 'var(--ink-muted)' }}>
  {author.avatarUrl && <img src={author.avatarUrl} alt={author.displayName} width={24} height={24} style={{ borderRadius: '50%' }} />}
  <Link href={`/authors/${author.slug}`} style={{ color: 'var(--ink)', fontWeight: 600 }}>{author.displayName}</Link>
  <span>·</span>
  <span>{new Date(post.date + 'T00:00:00').toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })}</span>
  <span>·</span>
  <span>Reviewed by Koenig AI editors</span>
</div>
```

### Step 5 — Create `BlogScrollLayer` client component

File: `learnovaBeast/learnova-academy/src/components/_shared/blog-scroll.tsx` (new)

```ts
"use client";
// Manages: reading-progress bar, IntersectionObserver scroll-spy, TutorRail scroll animation.
// Accepts serializable headings[] from server; owns all scroll state.
```

Interface:
```ts
interface Heading { id: string; text: string; level: 2 | 3 }
interface BlogScrollLayerProps {
  headings: Heading[];
  children: (ctx: { activeSection: string | null; scrolledPastHero: boolean }) => React.ReactNode;
}
```

Implementation:
1. `const [progress, setProgress] = useState(0)` — reading progress 0→1
2. `const [activeSection, setActiveSection] = useState<string|null>(null)` 
3. `const [scrolledPastHero, setScrolledPastHero] = useState(false)`
4. `useEffect` → `window.addEventListener('scroll', handler, { passive: true })`:
   - `progress = window.scrollY / (document.body.scrollHeight - window.innerHeight)`
   - `scrolledPastHero = window.scrollY > window.innerHeight * 0.3`
5. `useEffect` → `IntersectionObserver` on all `[id]` elements matching heading IDs:
   - threshold `0.5`, rootMargin `-20% 0px -60% 0px`
   - on intersect → `setActiveSection(entry.target.id)`
6. Render a `<div className="reading-progress" style={{ width: `${progress*100}%` }} />`
7. Return `<>{children({ activeSection, scrolledPastHero })}</>` (render-prop pattern so server can pass JSX nodes that need the context).

Wire into `page.tsx`: Wrap the entire lesson-grid content (left nav + article + tutor) in `<BlogScrollLayer headings={headings}>` render prop. Thread `activeSection` to TutorRail and to the TOC nav items (highlight matching `id`).

Left nav TOC: In the left rail `<aside className="lesson-nav">`, after sources section, add:
```tsx
{headings.length > 0 && (
  <div style={{ padding: '12px 18px', borderTop: '1px solid var(--rule)' }}>
    <div className="eyebrow" style={{ marginBottom: 8 }}>In this post</div>
    {headings.map(h => (
      <a key={h.id} href={`#${h.id}`}
        className={`toc-item${activeSection === h.id ? ' active' : ''}`}
        style={{ paddingLeft: h.level === 3 ? 12 : 0 }}>
        {h.text}
      </a>
    ))}
  </div>
)}
```

### Step 6 — Update `TutorRail` for activeSection + scroll animation

File: `learnovaBeast/learnova-academy/src/components/_shared/tutor.tsx`

Extend `TutorRailProps`:
```ts
activeSection?: string | null;
scrolledPastHero?: boolean;
```

In the header div (line ~82), replace "Grounded in {chapter}":
```tsx
<div style={{ fontSize: 11, color: 'var(--ink-soft)' }}>
  {activeSection ? `Reading: ${activeSection}` : `Grounded in ${chapter}`}
</div>
```

Wrap the outer `<aside>` with a CSS class for the slide-in animation:
```tsx
<aside
  data-expanded={expanded}
  data-hero-passed={scrolledPastHero}
  className="tutor-rail"
  ...
>
```

### Step 7 — Add CSS to `academy.css`

File: `learnovaBeast/learnova-academy/src/app/academy.css`

Append at end (after `::selection`):

```css
/* ─── Blog hero ─── */
.blog-hero { position: relative; overflow: hidden; border-radius: var(--r-5); }
.blog-hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(to bottom, rgba(0,0,0,0) 30%, rgba(0,0,0,.72) 100%);
  display: flex; align-items: flex-end; padding: 24px;
}
.blog-hero-title {
  color: #fff; text-shadow: 0 1px 4px rgba(0,0,0,.5);
  margin: 0; font-family: var(--font-prose);
}

/* ─── Reading progress bar ─── */
.reading-progress {
  position: fixed; top: 0; left: 0; height: 3px; z-index: 50;
  background: var(--teal-600);
  transition: width .1s linear;
  pointer-events: none;
}

/* ─── TOC nav items ─── */
.toc-item {
  display: block; padding: 4px 0; font-size: 12px;
  color: var(--ink-soft); text-decoration: none;
  transition: color .15s, padding-left .15s;
  border-left: 2px solid transparent;
}
.toc-item:hover { color: var(--ink); }
.toc-item.active {
  color: var(--teal-600); border-left-color: var(--teal-600);
  padding-left: 8px; font-weight: 600;
}

/* ─── Left nav fixed on desktop ─── */
@media (min-width: 1024px) {
  .lesson-nav {
    position: fixed;
    top: var(--topbar);
    left: 0;
    width: var(--rail-left);
    height: calc(100dvh - var(--topbar));
    overflow-y: auto;
    border-right: 1px solid var(--rule);
    background: var(--surface-2);
  }
  /* Compensate main content for fixed left nav */
  .lesson-main { margin-left: var(--rail-left); }
}

/* ─── TutorRail scroll-in animation ─── */
@keyframes railSlideIn {
  from { opacity: .4; transform: translateX(12px); }
  to   { opacity: 1;  transform: translateX(0); }
}
.tutor-rail { opacity: .4; transform: translateX(12px); transition: opacity .4s ease, transform .4s ease; }
.tutor-rail[data-hero-passed="true"] { opacity: 1; transform: translateX(0); }
@media (max-width: 1023px) { .tutor-rail { opacity: 1; transform: none; } }
```

## Verification (QA Verifier checks these)

- [ ] At 1280px: hero image renders with gradient overlay, title on image, eyebrow chips visible
- [ ] At 1280px: left nav is `position:fixed`, TOC items link to correct heading anchors
- [ ] Scrolling blog body: reading-progress bar advances, active TOC item highlights, TutorRail header shows "Reading: <H2>"
- [ ] Scrolling past ~30% viewport height: TutorRail fades/slides in from right (opacity 0.4 → 1)
- [ ] On mobile (375px): left nav hidden, TutorRail bottom sheet, no horizontal overflow
- [ ] Lighthouse mobile: performance ≥85, CLS < 0.05 (hero img has explicit width/height)
- [ ] Build: `pnpm build` succeeds in `learnovaBeast/learnova-academy` with no TS errors

## Risk

- **CLS from hero image**: Mitigated by explicit `width={1344} height={756}` on `<img>` so browser reserves space before image loads. If hero_image is absent (most existing posts), the fallback h1 renders instantly — no shift.

## Out of scope

- Item 6 (citation enforcement) — chief-content task per ticket
- Item 7 (slide + audio) — separate ticket
- Author avatar URL: `getAuthor` must already return `avatarUrl` or the byline avatar img is simply omitted (conditional render covers this)
- Backfilling existing blog posts with `hero_image` frontmatter — content ops task, not engineering
