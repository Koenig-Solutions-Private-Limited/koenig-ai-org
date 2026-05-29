---
name: verify-publish
description: >
  Publish Verifier's primary skill — G5 post-publish gate. Fetch the live URL,
  validate schema, source URLs, og:image, sitemap presence, performance.
  Route BLOCKs to the right team. Use when ticket lands assigned to
  @publish-verifier with metadata.publish_state=published (KOE-101: status stays "done").
---

# Verify Publish

You verify; others fix.

## Scope

- One published URL per pass
- 7 checks: status, JSON-LD, citations, og:image, sitemap, llms.txt, page weight
- PASS routes to CEO retro; BLOCK routes per matrix below

### L5 — Lighthouse CI (pre-prod, KOEA-6715)

**L5 is enforced in CI, not in this G5 heartbeat.** `learnovaBeast` `publish.yml`
deploys a Vercel preview, runs `@lhci/cli` via `treosh/lighthouse-ci-action`, and
**blocks prod deploy** when mobile CWV exceeds gates: LCP > 2500 ms, INP > 200 ms,
CLS > 0.1. `publish-action.sh` Phase 2 maps a failed publish workflow to
`metadata.publish_state=dispatch_failed` — no `published` state, so G5 must not run.

PR previews are audited separately by `.github/workflows/lighthouse.yml` on
`deployment_status`. Operator secrets: `LHCI_GITHUB_APP_TOKEN`,
`VERCEL_AUTOMATION_BYPASS_SECRET` (optional, for protected previews).

## Inputs

- Paperclip ticket with `metadata.publish_state=published` and `metadata.published_url` set (KOE-101: "published" is not a valid Paperclip status enum)
- The vault file (for cross-checking citations)

## Workflow

### 0. Probe-scope rule (HARD — added 2026-05-13 per KOEA-1393)

Run **only** the numbered checks 1–10 below. Do **not** invent additional
URL probes (e.g. `/slides/<slug>.pptx`, `/audio/<slug>.mp3`,
`/transcripts/<slug>.txt`) by guessing a convention. The academy site
currently has no `/slides/` route — `learnova-academy/scripts/sync-vault.mjs`
only mirrors `vault/courses/*` to `public/courses/`. If a slides or audio
affordance is not present as a visible link in the fetched HTML, the
artifact is **not** part of the published surface and probing it produces a
false-positive 404. When the blog-slides feature ships, the team will add a
new numbered check here; until then, leave slides/audio out of the report.

### 1. HTTP status check

```bash
curl -sI -o /dev/null -w "%{http_code}\n" "$URL"
```

Expected: 200. Anything else → BLOCK to chief-engineering ("Production page returns HTTP X — deploy issue or routing").

### 2. JSON-LD validation

Fetch HTML and parse all `<script type="application/ld+json">` blocks:

```bash
curl -s "$URL" | python3 -c "
import re, json, sys
html = sys.stdin.read()
blocks = re.findall(r'<script type=\"application/ld\\+json\"[^>]*>(.*?)</script>', html, re.DOTALL)
for i, b in enumerate(blocks):
    try:
        d = json.loads(b)
        if isinstance(d, list):
            for x in d: print(f'block {i}: type={x.get(\"@type\")}')
        else:
            print(f'block {i}: type={d.get(\"@type\")}')
    except Exception as e:
        print(f'block {i}: PARSE FAIL: {e}')
"
```

Required @types per page kind:
- Blog post: `BlogPosting` + `BreadcrumbList`
- Course: `Course`
- Lesson: `Course` + (optional) `HowTo`
- Home: `Organization` + `WebSite`

Missing required types or parse failures → BLOCK to chief-engineering ("Schema regression: <details>").

### 3. Citation check

For each `https?://...` URL in the source vault file's body (excluding internal `[[wikilinks]]`):

```bash
curl -sI -o /dev/null -w "%{http_code}\t$URL\n" "$URL"
```

Pick 3 at random. Each must:
- Return 200 (or 30x to a 200)
- WebFetch and verify the page actually contains content matching the claim in our prose

Any failure → BLOCK to **content-author** (route through @chief-content): "Citation rot: <URL> → <status>; replace + re-route via G0".

### 4. og:image check

```bash
OG_URL=$(curl -s "$URL" | grep -oE 'property="og:image" content="[^"]+"' | sed 's/.*content="\([^"]*\)".*/\1/' | head -1)
curl -sI -o /dev/null -w "og:image %{http_code}, size %{size_download}\n" "$OG_URL"
```

Expected: 200 + image content-type. Failure → BLOCK to chief-engineering.

### 5. Sitemap presence

```bash
curl -s https://academy.kspl.tech/sitemap.xml | grep -F "$URL"
```

Missing → BLOCK to chief-engineering ("Page not in sitemap.xml — generation regression").

### 6. llms.txt presence (blog + course only)

```bash
curl -s https://academy.kspl.tech/llms.txt | grep -F "$URL"
```

Missing → BLOCK to chief-engineering ("Page not in llms.txt — GEO regression").

### 7. Page weight check (HARD BLOCK at threshold — V5)

```bash
SIZE=$(curl -s "$URL" | wc -c)
echo "Page weight: $SIZE bytes"
```

Threshold: blog ≤80KB, course ≤90KB, lesson ≤100KB. **HARD BLOCK** when over (no warn-only). The thresholds were set tight intentionally; bloat is a regression signal. The MCP-2026-roadmap post hit 107KB live — that should never have escaped this gate.

### 8. Citation density floor (NEW — V3 Citation Authority addendum, hard floor)

```bash
# Count outbound non-academy.kspl.tech links in the body
CITES=$(curl -s "$URL" \
  | grep -oE 'href="https?://[^"]+"' \
  | grep -v 'academy\.kspl\.tech' \
  | grep -v 'koenig-solutions\.com' \
  | sort -u | wc -l)
echo "Outbound citations: $CITES"
```

Threshold: blog ≥3, course ≥5, lesson ≥3. **HARD BLOCK** below threshold → routes to `@content-author` via `@chief-content` ("source-thin draft escaped G0").

### 9. og:image validation (NEW — image format + dimensions)

```bash
OG_URL=$(curl -s "$URL" | grep -oE 'property="og:image"[^>]*content="[^"]+"' | sed -E 's/.*content="([^"]+)".*/\1/')
TYPE=$(curl -sI "$OG_URL" | grep -i '^content-type:')
DIMS=$(curl -s "$OG_URL" | identify -format '%wx%h' - 2>/dev/null || echo "unknown")
echo "og:image $OG_URL → $TYPE → $DIMS"
```

`Content-Type: image/*` and `1200x630` required. **HARD BLOCK** if dynamic `/api/og` returns HTML (a misconfigured 200 error page).

### 10. Author resolution check (NEW — enforces SOUL.md V3 addendum)

```bash
# Pull author URL from BlogPosting JSON-LD
AUTHOR=$(curl -s "$URL" | python3 -c "import json,sys,re; html=sys.stdin.read(); m=re.search(r'<script type=\"application/ld\\+json\">(.*?)</script>',html,re.S); d=json.loads(m.group(1)) if m else {}; print((d.get('author') or {}).get('url',''))")
test -n "$AUTHOR" && curl -sI "$AUTHOR" | head -1
```

Author URL must resolve to `/authors/<slug>` returning 200 + valid `Person` or `Organization` JSON-LD. **HARD BLOCK** if author is a raw agent slug like `blog-author` or returns 404.

### Decide + comment (LOCKED 2026-05-01 — STRUCTURED ONLY)

**First token of comment MUST be ✅ or ❌**. No "Let me look at this…" preamble. No exploratory monologue. If you cannot produce the structured template below, return action=`silent` (do not author a comment) — it is better to wait one tick and try again than to leak a half-formed thought.

**Pre-flight gate (NEW — addresses observed reasoning-loop bug 2026-05-01)**:
Before running ANY checks, query the issue:
- If `issue.metadata.publish_state != 'published'` AND no live URL exists at the expected slug → DO NOT VERIFY. Comment:
  ```
  ❌ G5 SKIP · <slug>
  Content not yet deployed — publish_state=<state>, draft.status=<status>.
  Routing → @chief-content (advance through G0/G3/G4) and/or @chief-engineering (publish-action.sh dispatch).
  ```
  Then return action=`silent` for THIS heartbeat. You have NOT failed the verification; you simply skipped a non-applicable run.
- Only proceed to checks 1-10 if the URL is live.

PASS:
```
✅ G5 PUBLISH VERIFIED · <URL>
- HTTP 200 ✓
- JSON-LD: <N> blocks (BlogPosting ✓ BreadcrumbList ✓)
- Citations: 3/3 verified live + on-claim, citation density <N>/min-3
- og:image: 200, 1200×630, image/png
- Author: <name> resolves to /authors/<slug> ✓
- sitemap.xml ✓ · llms.txt ✓
- Page weight <X>KB (target 80KB)

Routing → @ceo for retro
```

BLOCK (route per matrix):
```
❌ G5 BLOCK · <URL>

ISSUE: Citation 2 is dead.
- URL: https://example.com/foo  → HTTP 404
- Claim affected: para 5 "Anthropic shipped X feature"

Routing → @content-author via @chief-content (revise + replace source URL → re-G0 → republish)
Cc: @ceo
```

### Write vault sidecar

`vault/marketing/publish-verify/<YYYY-MM-DD>-<slug>.md` — frontmatter + 7-check status table.

## Output

PASS/BLOCK comment + vault sidecar.

## Notes

- Per-task cap $0.20. Most checks are shell + curl; reasoning is light (Haiku 4.5).
- Auto-trigger: 2 min after publish event (deploy completes ~90s; small buffer for CDN warmup).
- Don't run on pre-publish drafts. Only trigger when `metadata.publish_state=published`.

## Escalation

- Same regression class 3+ in a week → propose chief-engineering deploy-validation skill upgrade
- Citation rot rate >5% weekly → propose chief-content URL-pre-validate skill update
- 5xx production responses → CEO + chief-engineering same-heartbeat (severity high)
