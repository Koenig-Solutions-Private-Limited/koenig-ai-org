---
schema: agentcompanies/v1
kind: doc
slug: vault-status-spec
name: Vault Content Status Vocabulary
description: Canonical 8-value gate-state vocabulary for all vault/blogs and vault/courses frontmatter. Single source of truth for all agents.
version: "1.0.0"
created: 2026-06-10
updated: 2026-06-10
---

# Vault Content Status Vocabulary

**Single source of truth.** All agents writing or reading `status:` frontmatter in `vault/blogs/` and `vault/courses/` MUST use exactly these 8 values. Any other value is a lint error (caught by `scripts/verify-status.mjs`) and will block the publish pipeline.

## Canonical values

| Status | Meaning | Who sets it |
|---|---|---|
| `draft` | First write; not ready for review. The author is still working. | Blog Author, Content Author, Course Author |
| `awaiting-g0` | Draft complete; queued for G0 source review. | Blog Author, Content Author, Course Author (on hand-off) |
| `g0-blocked` | G0 rejected. Author must revise. **Only status that is hidden from the public site.** | Content Reviewer |
| `g0-passed` | G0 passed; in revision/refinement or awaiting G3. | Content Reviewer |
| `g3-passed` | G3 (CEO/EiC) passed; awaiting G4 publish gate. | CEO |
| `g4-approved` | G4 human-approved. publish-action.sh targets this status to deploy. | Vardaan (human G4) via publish-action |
| `published` | Legacy alias for `g4-approved`. Accepted by the lint; normalized to `g4-approved` on next migration run. | publish-action.sh (legacy) |
| `deprecated` | Intentionally hidden after publish (e.g., outdated content superseded by a newer post). | CEO or Chief Content |

## Pipeline flow

```
draft → awaiting-g0 → g0-blocked → awaiting-g0  (revise loop)
                    ↓
                g0-passed → g3-passed → g4-approved → [live on site]
                                                    → deprecated (later)
```

## What NOT to use

The following strings have appeared in the vault but are **not canonical**. The migration script (`scripts/migrate-status.mjs`) maps them automatically:

| Non-canonical | Maps to |
|---|---|
| `draft-for-review` | `awaiting-g0` |
| `outline-draft-for-review` | `awaiting-g0` |
| `g0-ready` | `awaiting-g0` |
| `g0-draft` | `draft` |
| `g0-approved` | `g0-passed` |
| `g0-revision` | `g0-passed` |
| `g3-approved` | `g3-passed` |
| `reviewed` | `g3-passed` |

If you encounter any other string, **do not use it**. File an issue for Chief Content to extend this spec if a genuine new gate state is needed.

## Enforcement

- **Build-time lint**: `scripts/verify-status.mjs` scans all `draft.md`, `index.md`, and `outline.md` files. Fails build on non-canonical values.
- **Runtime guard**: `vault.ts` checks status against a `Set` of canonical values and emits a `logger.warn` for any unknown value.
- **Agent instructions**: Blog Author, Content Author, Content Reviewer, CEO, Publish Verifier, and Chief Content AGENTS.md all reference this file.

## Adding a new gate state

1. Propose via a Paperclip ticket to Chief Content.
2. Chief Content discusses with CEO and updates this file + `scripts/verify-status.mjs` + `vault.ts` Set.
3. Update relevant AGENTS.md files.
4. Never mint a new value inline — the pipeline will silently mis-route it.
