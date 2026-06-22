# Git hooks

## commit-msg-blog-seo.sh

Blocks commits that touch `vault/blogs/*/draft.md` when the draft has `status` in `{g0-passed, g3-passed, published}` but `seo_description` fails G0 Rejection Rules (KOEA-1249):

1. missing/empty
2. length `< 80`
3. length `> 160`
4. commit-message opener regex

Install:

```bash
./scripts/install-hooks.sh
```

## Smoke tests

```bash
./scripts/hooks/commit-msg-blog-seo.test.sh
```

Named fixture: `seo_description: Updated Resolume and Blender descriptions for accuracy` (54 chars) must reject with **rule 2**.
