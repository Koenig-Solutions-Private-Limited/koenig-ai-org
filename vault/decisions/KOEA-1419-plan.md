---
ticket: KOEA-1419
title: Provision browser-use for QA Verifier runtime
planner: planner
date: 2026-05-13
estimated_complexity: small
estimated_token_cost: $0.20
status: ready-to-execute
related: KOEA-251, KOEA-250, KOEA-1393, KOEA-1398
---

# Plan: KOEA-1419 — Close the `browser-use` → Playwright migration in QA Verifier docs

## Goal

Make the QA Verifier stop looking for a `browser-use` CLI / `python3 -m browser_use` / `uvx` that the org already retired on 2026-05-01. Codify Playwright as the canonical browser walkthrough tool in the docs the QA Verifier actually reads at runtime, and add a one-command smoke check the agent runs before each walkthrough so future runs surface launch failures with a clear signal instead of silent fallback.

Success = a fresh QA Verifier heartbeat against any G2-eligible ticket reaches the browser walkthrough step, runs the Playwright smoke (`node /tmp/qa-smoke.cjs` against `https://example.com`), and exits 0, with no reference to `browser-use` in its retro.

## Context

### What's actually broken

`browser-use` was the *original* QA Verifier walkthrough tool (Mac-first). On 2026-05-01 **[[KOEA-251]]** explicitly swapped it for Playwright (`vault/decisions/koea-251-plan.md:22-27` — *"Swap browser-use → Playwright in QA Verifier skill. browser-use is a Mac-first wrapper; Playwright is the correct headless-first equivalent for Linux."*). The Dockerfile, the new `qa-playwright-walkthrough` skill, and `qa-verify-task` skill were all migrated. **`browser-use` was never re-added** because the team decided Playwright covers the use case.

But the operational doc the QA Verifier reads every heartbeat — `agents/qa-verifier/AGENTS.md` — still names `browser-use` six times. That doc-level drift is what produced the [[KOEA-1398]] report: the agent looked for `browser-use`, found nothing, hit fallback Playwright, and Chief Engineering accepted the fallback for that prose-only PR but filed KOEA-1419 to fix the runtime "gap."

There is **no runtime gap**. Playwright + system Chromium have been in the production image since the 2026-05-01 Dockerfile change ([[KOEA-251]] block at `Dockerfile:57-64,128-130`) and verified working in [[KOEA-250]]'s plan (V1–V5 smoke commands). The gap is documentation drift — the agent is asking for a tool the policy already replaced.

### Files to read first

- `companies/learnova-academy/agents/qa-verifier/AGENTS.md` — six dangling `browser-use` references at lines 18, 27, 42, 57, 70, 97 (this is the **operational** doc, read every heartbeat).
- `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md:128-138` — "Path 4 — Mac-local (future state, when browser-use adapter is wired)" with a stale long-term-path narrative; KOEA-251 superseded it.
- `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md` — current canonical skill (no edits needed except adding the smoke-check section).
- `companies/learnova-academy/skills/qa-verify-task/SKILL.md` — already Playwright-canonical (no edits expected; verify on read).
- `Dockerfile:57-64,128-130` — Chromium + Playwright + Lighthouse already installed (no change).
- `vault/decisions/koea-251-plan.md` and `vault/decisions/KOEA-250-plan.md` — prior decision artifacts; preserve their narrative.

### Constraints

- **Scope to QA/runtime/tooling.** The ticket explicitly says do not touch academy product portals. The fix is markdown-only inside `companies/learnova-academy/`. No Dockerfile change, no Convex deploy.
- **Preserve Playwright/Chromium support.** All existing paths in `qa-playwright-walkthrough` and `browser-qa.md` Paths 1–3 keep working as-is.
- **Do not touch slide-audio-producer's `browser-use` mentions** (`agents/slide-audio-producer/AGENTS.md:38,123`). Those reference a Mac-local NotebookLM driver, a completely separate code path not in QA runtime — out of scope.
- **Do not touch README.md / ARCHITECTURE.md / TEAM.md / chief-engineering/AGENTS.md `browser-use` mentions.** Those are high-level narrative docs; rewriting them is doc-cleanup churn, not the runtime fix the ticket asks for. File a separate follow-up.
- Branch policy per `companies/learnova-academy/CLAUDE.md`: code/skill PRs go through G_code → G2 (no G3 for code-only). This change has no production-code impact, so PR should be small and pass G2 trivially with the new smoke check.

## Approach (1 chosen, 2 alternatives rejected)

**Chosen — A: Finish the KOEA-251 doc migration; add a Playwright smoke command.**
The runtime already provides the canonical tool (Playwright). Strip the stale `browser-use` references from the QA Verifier's operational doc + the dead "Path 4 future state" from `browser-qa.md`, and add a one-line smoke command (`node /tmp/qa-smoke.cjs`) to `qa-playwright-walkthrough` so the agent has an explicit "first-touch" verification command for any browser walkthrough step. This is the literal "smallest verification" the ticket asks for and matches the cardinal "inexpensive, not cheap" rule.

**Rejected — B: Actually install `browser-use` (the Python package) in the Docker image.**
Three problems: (1) `browser-use` is LLM-driven and needs its own API key + makes its own LLM calls outside the QA Verifier's $0.50 budget — unbounded cost risk that the Haiku-cheap design explicitly avoids; (2) it's a wrapper around Playwright/Chromium, so installing it duplicates what's already in the image (~200MB+ Python deps via `pip install browser-use playwright-python` plus a venv); (3) KOEA-251 explicitly examined and rejected this path on 2026-05-01 with a written rationale ("Mac-first wrapper… Playwright is the correct headless-first equivalent for Linux"). Adding it now reopens a decision that's only nine workdays old without any new evidence. The ticket leaves the door open ("`browser-use` or the accepted equivalent") — Playwright is the accepted equivalent.

**Rejected — C: Add a `browser-use` shim script that delegates to Playwright (`/usr/local/bin/browser-use` → `node $1`).**
Cute and zero-cost, but it hides the fact that the canonical tool is Playwright and lets future skills keep accruing `browser-use` references that will surprise readers. Better to fix the docs once.

## Steps (Executor follows in order)

1. **Worktree off `origin/master`** to keep this clean of the v7 blog branch the host is on:
   ```
   git fetch origin
   git worktree add -b koea-1419/qa-verifier-browser-use-docs ../wt-koea-1419 origin/master
   cd ../wt-koea-1419
   ```

2. **Edit `companies/learnova-academy/agents/qa-verifier/AGENTS.md`** — replace the six `browser-use` references with Playwright:
   - Line 18: `browser walkthrough of the changed feature using \`browser-use\`` → `browser walkthrough of the changed feature using Playwright (see \`qa-playwright-walkthrough\` skill)`
   - Line 27: `\`browser-use\` script that opens the local dev server` → `Playwright script that opens the local dev server`
   - Line 42 (PASS template): `Browser walkthrough (browser-use script):` → `Browser walkthrough (Playwright):`
   - Line 57 (BLOCK template): `failed in the browser-use run` → `failed in the Playwright walkthrough`
   - Line 70: `browser-use the actual feature` → `walk the actual feature with Playwright`
   - Line 97: `\`browser-use\` script failures that look like environment issues` → `Playwright walkthrough failures that look like environment issues`
   No other edits to AGENTS.md.

3. **Edit `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md`** — delete the dead "Path 4" block (lines 128–138 inclusive, including the heading and code fence). Replace with a one-paragraph "Why no `browser-use` here" note pointing at `vault/decisions/koea-251-plan.md` so a future agent doesn't re-propose it:
   ```
   ## Why no `browser-use` in QA runtime

   `browser-use` was the original Mac-local walkthrough tool. On 2026-05-01 we migrated to Playwright + system Chromium (see [[koea-251-plan]]). Playwright is the canonical, headless-first equivalent for Linux. Do not look for a `browser-use` CLI or `python3 -m browser_use` in this runtime — they are not installed and will not be. If a future Mac-local walkthrough adapter is wired (separate from this Docker runtime), it will be filed as its own ticket.
   ```

4. **Edit `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md`** — add a "Smoke check (run first)" subsection between the existing "Environment" and "Browser Walkthrough via Playwright" sections:
   ```
   ## Smoke check (run first)

   Before writing a per-task walkthrough, prove the runtime can launch a browser:

   ```bash
   cat > /tmp/qa-smoke.cjs <<'EOF'
   const { chromium } = require('playwright');
   (async () => {
     const browser = await chromium.launch({
       executablePath: '/usr/bin/chromium',
       args: ['--headless', '--no-sandbox', '--disable-dev-shm-usage'],
     });
     const page = await browser.newPage();
     await page.goto('https://example.com', { timeout: 15000 });
     const title = await page.title();
     await browser.close();
     if (!title.toLowerCase().includes('example')) throw new Error('unexpected title: ' + title);
     console.log('qa-smoke ok: ' + title);
   })().catch(e => { console.error('qa-smoke FAIL:', e.message); process.exit(1); });
   EOF
   node /tmp/qa-smoke.cjs
   ```

   Must print `qa-smoke ok: Example Domain` and exit 0. Anything else = the
   runtime is broken; do **not** declare PASS via Path 3 static fallback — BLOCK
   the ticket and ping Chief Engineering with the stderr.
   ```

5. **Commit** as a single change:
   ```
   git add companies/learnova-academy/agents/qa-verifier/AGENTS.md \
           companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md \
           companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md \
           vault/decisions/KOEA-1419-plan.md
   git commit -m "$(cat <<'EOF'
   chore(qa-verifier): finish browser-use → Playwright doc migration (KOEA-1419)

   - AGENTS.md: scrub 6 dangling browser-use references; Playwright is canonical.
   - browser-qa.md: drop dead "Path 4 future state" block, add forward-pointer.
   - qa-playwright-walkthrough: add a one-command Playwright smoke check.

   Runtime already migrated by KOEA-251; this only closes the doc drift that
   misled QA Verifier on KOEA-1398. No Dockerfile or product change.
   EOF
   )"
   ```

6. **Open PR** against `master` with the smoke output (Verification §V1) pasted in the body. Title: `chore(qa-verifier): finish browser-use → Playwright doc migration (KOEA-1419)`.

7. **Clean up** worktree after merge: `git worktree remove ../wt-koea-1419`.

## Verification (QA Verifier checks these)

- [ ] **V1 — Smoke check works**: inside the running `paperclip-server` container, paste the heredoc + `node /tmp/qa-smoke.cjs` from Step 4 and confirm `qa-smoke ok: Example Domain`. This is the explicit ticket-asked verification (smallest invocation, trivial page load).
- [ ] **V2 — No browser-use mentions remain in QA Verifier-facing docs**:
   ```
   rg -n 'browser.use|browser_use' companies/learnova-academy/agents/qa-verifier/ companies/learnova-academy/skills/qa-playwright-walkthrough/ companies/learnova-academy/skills/qa-verify-task/
   ```
   Must print exactly one match in `browser-qa.md` — the new "Why no `browser-use` here" header (intentional forward-pointer).
- [ ] **V3 — Slide-audio-producer untouched**:
   ```
   rg -n 'browser.use' companies/learnova-academy/agents/slide-audio-producer/
   ```
   Must still match lines 38 and 123 — preserved on purpose; out of scope.
- [ ] **V4 — Skill semantic still works**: read `qa-verify-task/SKILL.md` end-to-end; the workflow it lays out must still parse logically (it should — qa-verify-task was already Playwright-canonical from KOEA-251).
- [ ] **V5 — Diff size**: `git diff --stat origin/master..HEAD` shows ≤ 4 files changed and ≤ ~80 lines net (the bulk is the new smoke-check block + the new plan doc; the AGENTS.md edits are ≤ ~10 lines).

## Risk

**Low.** Markdown-only change inside `companies/learnova-academy/`. No runtime code, no Dockerfile, no Convex deploy. Worst case: a future QA Verifier reads stale screenshots/cache and tries `browser-use` again — mitigated by the explicit "Why no `browser-use` here" note that survives skill-cache misses.

**Secondary risk**: a future researcher / Chief Engineering opens a new ticket arguing for `browser-use`-via-LLM walkthroughs (semantic clicking) for harder e2e cases. That is a legitimate product question, but explicitly outside this ticket — file a new ticket if so. The "Why no `browser-use` here" paragraph names the prior decision so the new ticket starts informed.

## Rollback

Single `git revert` of the merge commit. No state, no migration, no data path. Total rollback time: one PR.

## Out of scope (file as follow-ups if Chief Engineering wants them)

- **README.md, ARCHITECTURE.md, TEAM.md, chief-engineering/AGENTS.md** still mention `browser-use` in narrative passages. These don't drive QA runtime behavior; rewriting them is doc-cleanup churn beyond this ticket's "QA/runtime/tooling" scope. Suggest a single later doc-sweep ticket.
- **slide-audio-producer's `browser-use` references** (Mac-local NotebookLM path) — a different code path with a different rationale. KOEA-1419 explicitly scopes to QA runtime.
- **Bringing `browser-use` into Docker as an LLM-driven walkthrough tool.** Rejected as Approach B; reopen as a separate decision ticket only if there's a concrete e2e case Playwright cannot do.
- **Mac-local `browser-use` adapter** referenced in the old `browser-qa.md` Path 4 narrative. If anyone still wants it, file a new ticket — the runtime is now Linux Docker and the original "future state" justification no longer applies.
