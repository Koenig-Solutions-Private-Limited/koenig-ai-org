---
ticket: KOEA-250
planner: planner
date: 2026-05-26
estimated_complexity: small
estimated_token_cost: $0.35
base_branch: master
basebranch_verified: true
supersedes: 2026-05-11 KOEA-250 plan
replan_issue: KOEA-5073
chain_alert_approval: 7b4de33d-6108-46a5-89f1-d22900237fa6
---

# Plan: Restore QA Chromium runtime libraries with a writable execution path

## Goal

Make the QA Verifier Docker runtime able to launch both system Chromium and Playwright's bundled Chromium/headless shell for visual walkthroughs and Lighthouse checks. Success is a Docker-only infra change that adds the missing runtime libraries, avoids the root-owned parent worktree path that blocked the previous implementation, and leaves app code untouched.

## Context

- Files to read first: `Dockerfile:57-63`, `infra/docker-compose.koenig.yml:42-50`, `companies/learnova-academy/agents/qa-verifier/skills/browser-qa.md:139-158`, `companies/learnova-academy/skills/qa-playwright-walkthrough/SKILL.md:83-89`
- Relevant prior work: KOEA-251 installed system Chromium, Lighthouse, and Playwright; the 2026-05-11 KOEA-250 plan chose additive apt libraries but specified unwritable `../wt-koea-250`; approval `7b4de33d-6108-46a5-89f1-d22900237fa6` authorizes this sequential KOEA-250 gate chain despite active sibling gate issues.
- Constraints: `/Users/vardaankoenig/Documents/Paperclip` is `root:root` and not writable by Executor, while `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org` is writable; use `origin/master` because it exists and is the repo production branch; no Convex deploy; no app-code, database, UI, or skill-doc edits unless Executor proves a referenced infra file moved.

## Approach (1 chosen, alternatives rejected)

**Chosen**: Use a clean writable worktree under `/tmp/paperclip-worktrees/koea-250` and make one additive Dockerfile apt dependency change. This avoids the root-owned parent directory, isolates the change from the currently dirty shared checkout, and preserves the original runtime fix: add the shared libraries required by Playwright/Chromium without changing QA workflows or application behavior.

**Rejected**: Repair ownership of `/Users/vardaankoenig/Documents/Paperclip` — requires operator/root action and is unnecessary for this fix; edit the dirty shared checkout directly — faster but risks mixing unrelated local changes into the PR; replace the apt list with `npx playwright install-deps chromium` or a Playwright base image — broader and less deterministic than adding the specific runtime libraries.

## Steps (Executor follows in order)

1. Create an isolated writable worktree, not `../wt-koea-250`:
   ```sh
   cd /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org
   git fetch origin
   mkdir -p /tmp/paperclip-worktrees
   git worktree add -b koea-250/qa-chromium-libs-v2 /tmp/paperclip-worktrees/koea-250 origin/master
   cd /tmp/paperclip-worktrees/koea-250
   ```
2. Edit `Dockerfile` production-stage browser tooling block only. Keep existing packages, update the comment to include KOEA-250, and append the missing runtime libraries from the current QA escalation doc: `libglib2.0-0t64 libatk1.0-0t64 libdbus-1-3 libatspi2.0-0t64 libx11-6 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libxcb1 libxkbcommon0 libnspr4 libcairo2 libpango-1.0-0`.
3. Do not edit `infra/docker-compose.koenig.yml`, QA skill docs, app code, package manifests, lockfiles, database files, or UI files. If Executor discovers the Dockerfile line has already been changed on `origin/master`, stop and comment with the exact diff instead of stacking a second dependency edit.
4. Build and start the Docker service locally without pulling a new base image unless necessary:
   ```sh
   docker compose -f infra/docker-compose.koenig.yml build --pull=false paperclip
   docker compose -f infra/docker-compose.koenig.yml up -d paperclip
   ```
5. Run the verification commands below inside `paperclip-server`. If any command fails, block back with the failing command and first relevant stderr line; do not replace this plan with retries or unrelated package additions.
6. Commit only the Dockerfile change, then open the PR against `master` using `.github/PULL_REQUEST_TEMPLATE.md`. In the PR body, call out the writable worktree path, no operator permission repair required, verification output, and rollback command.

## Verification (QA Verifier checks these)

- [ ] `docker exec paperclip-server chromium --version` prints a Chromium version.
- [ ] `docker exec paperclip-server node -e "require('playwright'); console.log('playwright ok')"` prints `playwright ok`.
- [ ] Bundled Playwright Chromium launches:
  ```sh
  docker exec paperclip-server bash -lc 'PLAYWRIGHT_BROWSERS_PATH=/tmp/ms-pw npx --yes playwright install chromium >/tmp/pw-install.log 2>&1 && PLAYWRIGHT_BROWSERS_PATH=/tmp/ms-pw node -e "const {chromium}=require(\"playwright\"); chromium.launch({headless:true,args:[\"--no-sandbox\",\"--disable-dev-shm-usage\"]}).then(async b=>{console.log(\"bundled chromium ok\"); await b.close();}).catch(e=>{console.error(e.message.split(\"\\n\")[0]); process.exit(1);})"'
  ```
- [ ] System Chromium through Playwright launches:
  ```sh
  docker exec paperclip-server node -e "const {chromium}=require('playwright'); chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--disable-dev-shm-usage']}).then(async b=>{console.log('system chromium ok'); await b.close();})"
  ```
- [ ] Lighthouse can drive Chromium:
  ```sh
  docker exec paperclip-server bash -lc 'lighthouse https://example.com --chrome-path /usr/bin/chromium --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" --quiet --output=json --output-path=/tmp/lh.json && jq ".categories.performance.score" /tmp/lh.json'
  ```

## Risk

- Image rebuild affects all agents using `koenig/paperclip-server:dev`; mitigation is that the change is additive apt runtime libraries only, with rollback by reverting the Dockerfile commit and rebuilding `paperclip`.
- `/tmp/paperclip-worktrees/koea-250` is a temporary workspace; mitigation is to push the branch/open the PR before ending Executor work and remove the worktree after merge.

## Out of scope

- Fixing ownership of `/Users/vardaankoenig/Documents/Paperclip`.
- Consolidating duplicated QA browser skills or changing QA policy.
- Convex deploys, app-code changes, database migrations, package upgrades, or browser-use adapter work.

Telemetry: preflight_status=passed; sibling_chain_approved=7b4de33d-6108-46a5-89f1-d22900237fa6; basebranch_verified=true
