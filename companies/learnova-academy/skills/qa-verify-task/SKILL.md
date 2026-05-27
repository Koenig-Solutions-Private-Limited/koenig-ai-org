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

### 3. Browser walkthrough (if frontend)

**3a. Browser-use launch smoke (required)** — follow `qa-browser-use-launch` before any walkthrough:

```bash
BROWSER_USE=/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/.venv-qa/bin/browser-use
SESSION="koea-${PAPERCLIP_TASK_ID:-qa}-g2"

timeout 20s "$BROWSER_USE" doctor
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open https://example.com
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
```

Launch smoke must pass (exit 0, `Example Domain` in state). Timeout or `success:false` → BLOCK and route to Chief Engineering. Do **not** use direct Python `BrowserSession(...).start()` snippets for normal G2 — they hang on CDP lifecycle in the current runtime.

**3b. Task walkthrough (same CLI session)** — navigate and assert plan verification checks via the same named session:

```bash
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open "<target-url>"
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
# repeat per verification check; inspect state output for assertions
timeout 10s "$BROWSER_USE" --json --session "$SESSION" close || true
```

Each verification check must pass. Any failure → BLOCK with the specific check that failed.

**Playwright fallback** — use `qa-playwright-walkthrough` only when the ticket plan or Chief Engineering explicitly accepts Playwright evidence instead of browser-use. Playwright is not the default G2 path.

### 4. Adjacent regression check

Smoke-test untouched features:
- Home page loads
- Catalog page loads with all course cards
- At least one untouched Lesson page renders

Any regression → BLOCK.

### 5. Lighthouse (frontend only)

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

### 6. Content fact-check (content tickets only)

Pick 3 random factual claims from the markdown. For each:
1. Find the cited URL
2. WebFetch the URL — must return 200
3. Verify the URL content matches the claim

Any failure → BLOCK.

### 7. Decide + comment

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

### 8. Flip Paperclip ticket status

- PASS → `awaiting-g3` → @ceo
- BLOCK → `awaiting-execution-fix` → @executor

## Output

A PASS or BLOCK comment + Paperclip ticket flip.

## Notes

- Don't fix anything yourself.
- Don't skip the browser walkthrough or launch smoke — unit tests miss UI bugs.
- Run `qa-browser-use-launch` before task navigation; forbid direct Python `BrowserSession` for normal G2.
- Playwright is fallback-only unless the ticket plan or Chief Engineering accepts it.
- For content fact-checks, fetch the URL; never validate via LLM.
- Lighthouse only on changed pages.
- Launch smoke timeout or `success:false` → BLOCK + Chief Engineering (runtime/env), not Playwright substitution
- Playwright walkthrough fails with browser launch error (not a UI bug) → restart dev server once; if persists, escalate to Chief Engineering

## Escalation

- Same regression appearing in unrelated PRs → chief-engineering for stability investigation
- Cited URL changed (vendor redirect chain) → BLOCK + route to @content-author for source update
