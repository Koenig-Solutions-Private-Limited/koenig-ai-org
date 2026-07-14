---
type: directory-index
purpose: Agent-readable E-E-A-T author registry for G0 validation
last_updated: 2026-07-14
---

# vault/authors — Author Page Schema

Each file in this directory (`<slug>.md`) is the authoritative E-E-A-T source for one blog/course author byline. The slug matches the raw `author:` value in blog frontmatter.

## Required fields (ALL 5 must be present and non-empty)

```yaml
jobTitle: "..."       # For Person: job title. For Organization: editorial role description (never empty).
bio: "..."            # 2-4 sentence bio for schema.org/AI citation panels.
knowsAbout:           # At least 3 topic strings. Must be a YAML list, not a single string.
  - "..."
worksFor: "..."       # Employer or parent organization name.
sameAs:               # At least 1 authoritative URL. LinkedIn or official site required.
  - "..."
```

## Optional fields

```yaml
type: Person | Organization   # Defaults to Person if absent.
displayName: "..."            # Human-readable name; used in JSON-LD.
linkedinUrl: "..."
twitterUrl: "..."
githubUrl: "..."
```

## Validator rule (G0 Step 5)

G0 Content Reviewer checks that:
1. `vault/authors/<slug>.md` exists for the raw `author:` frontmatter slug.
2. All 5 required fields are present and non-empty (non-empty list for `knowsAbout`/`sameAs`).

Missing file or any empty required field → G0 BLOCK.

## Current author files

| Slug | Type | Covers |
|---|---|---|
| `koenig-ai-academy` | Organization | 111 blogs (primary org byline) |
| `vardaan-koenig` | Person | 11 blogs (founder byline) |
| `editorial-team` | Organization | 1 blog + fallback slug |

[[vault/people/_index]]
