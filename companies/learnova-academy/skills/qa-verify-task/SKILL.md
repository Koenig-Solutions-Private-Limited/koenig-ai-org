---
name: qa-verify-task
description: >
  QA Verifier's primary skill — final technical gate G2. Run full test suite +
  browser walkthrough + Lighthouse + content fact-check. PASS or BLOCK with
  structured findings. Use when ticket lands assigned to @qa-verifier with
  status awaiting-qa.
---

# QA Verify Task

You PASS or BLOCK. You don't fix.

## Scope

- One ticket → one PASS or BLOCK comment
- Test suite + browser walkthrough + (frontend) Lighthouse + (content) fact-check
- Adjacent regression check

## Inputs

- Paperclip ticket with `status: awaiting-qa`
- PR URL (for engineering tickets) OR vault path (for content tickets)
- Plan in vault/decisions/ (for engineering)

## Workflow

### 1. Check out the PR (engineering) or read the vault file (content)

```bash
gh pr checkout <PR>
pnpm install
```

### 2. Run the full test suite

```bash
pnpm test
pnpm typecheck
pnpm lint
```

Expected: all green. Any failure → BLOCK.

### 3. Browser-use preflight (if frontend)

Before the walkthrough, confirm `browser-use` is available in the QA runtime (required gate; Playwright is not an acceptable substitute for G2):

```bash
export PATH=/paperclip/.local/bin:$PATH
browser-use --help
```

Must print usage text. Failure → BLOCK as runtime/env, escalate to Chief Engineering.

### 4. Browser walkthrough (if frontend)

Run `browser-use` against the local dev server for the verification checks listed in the plan's "Verification" section. Each check must pass. Any failure → BLOCK with the specific check that failed.

### 4b. Course route contract

`/learn/<slug>` route checks require `vault/courses/<slug>/outline.md` in the vault. If the slug appears in issue metadata but `outline.md` is absent, record **route expectation aligned / out-of-scope** on the ticket (e.g. `secure-coding` has no outline — do not BLOCK on `/learn/secure-coding` 404). Walk published slugs that have outlines when verifying deploy paths.

### 5. Adjacent regression check

Smoke-test untouched features:
- Home page loads
- Catalog page loads with all course cards
- At least one untouched Lesson page renders

Any regression → BLOCK.

### 6. Lighthouse (frontend only)

```bash
lighthouse http://localhost:3010<changed-page> \
  --chrome-path /usr/bin/chromium \
  --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
  --preset=desktop \
  --output=json \
  --output-path=/tmp/lh.json
jq '.categories.performance.score, .audits["interaction-to-next-paint"].numericValue, .audits["largest-contentful-paint"].numericValue, .audits["cumulative-layout-shift"].numericValue' /tmp/lh.json
```

Targets:
- INP < 200ms
- LCP < 2.5s
- CLS < 0.1

Regression >5% on any → BLOCK.

### 7. Content fact-check (content tickets only)

Pick 3 random factual claims from the markdown. For each:
1. Find the cited URL
2. WebFetch the URL — must return 200
3. Verify the URL content matches the claim

Any failure → BLOCK.

### 8. Decide + comment

**PASS:**

```
✅ G2 PASS · PR #<n> · <vault-path>

Tests: <N>/<N> ✓ (typecheck ✓ lint ✓)
Browser walkthrough: <N>/<N> verification checks ✓
Regression: Home + Catalog + Lesson Interactive load ✓
Lighthouse on changed page: INP <X>ms ✓ LCP <Y>s ✓ CLS <Z> ✓
(Content tickets) Fact-check: 3/3 cited URLs live + match claims ✓

Routing → @ceo for G3 alignment
```

**BLOCK:**

```
❌ G2 BLOCK · PR #<n>

TESTS (<N> blockers)
- <test-file>:<line> failed: <expected> vs <got>

BROWSER (<N> blockers)
- Verification check <N> ("<text>") failed: button click doesn't update label

PERFORMANCE
- LCP regressed from 1.8s → 2.7s on /catalog. Above target.

→ @executor: revise + re-route through @code-reviewer
```

### 9. Flip Paperclip ticket status

- PASS → `awaiting-g3` → @ceo
- BLOCK → `awaiting-execution-fix` → @executor

## Output

A PASS or BLOCK comment + Paperclip ticket flip.

## Notes

- Don't fix anything yourself.
- Don't skip the browser walkthrough — unit tests miss UI bugs.
- For content fact-checks, fetch the URL; never validate via LLM.
- Lighthouse only on changed pages.
- If the Playwright walkthrough fails with a browser launch error (not a UI bug), restart dev server once; if persists, escalate to Chief Engineering — may be a Chromium/container environment issue.

## Escalation

- Same regression appearing in unrelated PRs → chief-engineering for stability investigation
- Cited URL changed (vendor redirect chain) → BLOCK + route to @content-author for source update
