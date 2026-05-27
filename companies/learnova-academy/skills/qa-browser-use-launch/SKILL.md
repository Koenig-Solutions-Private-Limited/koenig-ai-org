---
name: qa-browser-use-launch
description: >
  Canonical browser-use CLI launch contract for QA Verifier G2. Run doctor,
  named-session smoke, open/state navigation, and cleanup with bounded timeouts.
  Use before any frontend browser walkthrough; do not hand-roll Python
  BrowserSession snippets for normal G2.
---

# QA Browser-Use Launch

Use this skill **before** the task walkthrough in `qa-verify-task` Step 3. The stable path is the installed `browser-use` CLI daemon with named sessions, JSON output, and explicit `timeout` wrappers — not direct Python `BrowserSession(...).start()` calls.

## Binary path

```bash
BROWSER_USE=/Users/vardaankoenig/Documents/Paperclip/learnovaBeast/learnova-academy/.venv-qa/bin/browser-use
```

If `$BROWSER_USE` is missing or not executable, BLOCK and route to Chief Engineering (runtime/env issue). Do not substitute Playwright or curl-only evidence for the mandatory browser gate unless the ticket plan or Chief Engineering explicitly accepts fallback evidence.

## Session naming

Use one named session per QA run:

```bash
SESSION="koea-${PAPERCLIP_TASK_ID:-qa}-g2"
# Example: koea-1382-g2
```

Reuse the same `--session` value for `open`, `state`, and `close` within a run.

## Step 0 — Doctor (once per heartbeat)

```bash
timeout 20s "$BROWSER_USE" doctor
```

Expected: package, browser, and network checks pass. Any failure → BLOCK, route to Chief Engineering.

## Step 1 — Launch smoke (required before G2 walkthrough)

```bash
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open https://example.com
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
```

Expected:

- Both commands exit 0 within 20s.
- `state` JSON/text includes `Example Domain`.

If either command times out or returns `success:false`, BLOCK with `BROWSER (launch smoke)` and route to Chief Engineering — do not fall back silently to Playwright or static curl.

## Step 2 — Task navigation (same session)

After smoke passes, navigate to the URL under test (from the plan Verification section or live preview):

```bash
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open "https://academy.kspl.tech/blog/<slug>"
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
```

Expected: `state` returns page title/text for the target URL — not `BrowserStartEvent` / `BrowserLaunchEvent` watchdog timeouts.

For local dev-server walkthroughs, use the same contract against `http://localhost:3010<path>` once the dev server is bound.

## Step 3 — Walkthrough checks

Run plan verification checks through the **same CLI session contract**:

```bash
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open "<url-for-check>"
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
# Inspect state output for the assertion (title, visible text, etc.)
```

Do **not** embed ad-hoc Python like:

```python
# FORBIDDEN for normal G2 — hangs on CDP lifecycle in current runtime
from browser_use import BrowserSession
session = BrowserSession(...)
await session.start()
```

## Step 4 — Cleanup (always)

```bash
timeout 10s "$BROWSER_USE" --json --session "$SESSION" close || true
```

Named-session cleanup prevents daemon leaks across heartbeats.

## BLOCK routing

| Symptom | Action |
|---|---|
| `doctor` fails | BLOCK → Chief Engineering (missing binary/deps) |
| Smoke `open`/`state` timeout or `success:false` | BLOCK → Chief Engineering (runtime/CDP launch) |
| Smoke passes but task URL fails | BLOCK → Executor (product/routing) unless env-specific |
| Repeated launch timeouts across tickets | Chief Engineering stability investigation |

## Playwright / Lighthouse

- **Playwright** (`qa-playwright-walkthrough`): fallback only when ticket plan or Chief Engineering explicitly accepts Playwright evidence instead of browser-use.
- **Lighthouse** (`browser-qa.md` Path 2): separate performance tooling; does not replace the browser-use launch gate.

## Reference smoke (KOEA-5776 verification)

```bash
SESSION=koea-5776-smoke
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open https://example.com
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
timeout 20s "$BROWSER_USE" --json --session "$SESSION" open https://academy.kspl.tech/blog/2026-04-30-claude-design-visual-workflows
timeout 20s "$BROWSER_USE" --json --session "$SESSION" state
timeout 10s "$BROWSER_USE" --json --session "$SESSION" close || true
```
