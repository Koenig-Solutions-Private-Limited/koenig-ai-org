---
ticket: KOEA-7404
planner: planner
date: 2026-06-10
estimated_complexity: small
estimated_token_cost: $0.28
base_branch: master
basebranch_verified: true
revision: 2
triggered_by_approval: 7ed81018-f3dc-4160-a124-bec6f9157142
preflight:
  status_ok: true
  assignee_ok: true
  chain_exception: staged_child_chain_created_by_same_agent_at_same_time
  acceptance_criteria_ok: true
  basebranch_verified: true
---

# Plan: Add watchdog to Koenig production compose

## Goal
Production `infra/docker-compose.koenig.yml` starts the watchdog daemon alongside the Paperclip stack so the cost circuit breaker and stall checks run in Docker/Linux, not only via macOS launchd or the upstream quickstart compose. Success is observable in compose config output and in a running `koenig-watchdog` container that can reach `http://paperclip:3100` with the configured company/API key.

## Context
- Files to read first: `docker/docker-compose.yml:38-51`, `infra/docker-compose.koenig.yml:42-165`, `infra/docker-compose.koenig.yml:167-240`, `watchdog/start-watchdog.sh:1-32`, `watchdog/watchdog.mjs:1-93`
- Relevant prior work: PR #69 `https://github.com/Koenig-Solutions-Private-Limited/koenig-ai-org/pull/69` added the watchdog service only to `docker/docker-compose.yml` and explicitly left the production Koenig compose gap out of scope.
- Constraints: plan-only ticket; Executor should edit only `infra/docker-compose.koenig.yml`; preserve Koenig production naming, env-file, logging, and bind-mount patterns; do not introduce secrets into the compose file.

## Approach (1 chosen, alternatives rejected)
**Chosen**: Add a dedicated `watchdog` service to `infra/docker-compose.koenig.yml` immediately after `paperclip`, using the same image/build context as the `paperclip` service, `command: ["/bin/bash", "/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/watchdog/start-watchdog.sh"]`, `PAPERCLIP_HOST: "http://paperclip:3100"`, required `PAPERCLIP_API_KEY`, Koenig company ID, 10-minute interval, `env_file: ../.env.koenig`, the repo bind mount needed for watchdog state and vault audit-log persistence on the host filesystem, `depends_on.paperclip.condition: service_healthy`, `restart: unless-stopped`, and Koenig-style json-file logging.

**Rejected**: Copy PR #69 verbatim because it points at `http://server:3100` and misses Koenig production conventions. **Rejected**: Keep using only `infra/launchd/com.koenig.watchdog.plist` because launchd does not run inside the Docker/Linux production stack.

## Steps (Executor follows in order)
1. Edit `infra/docker-compose.koenig.yml` and insert a `watchdog` service after the `paperclip` service block and before `cron-driver`.
2. Configure the service with the same `build.context`, `build.dockerfile`, `build.args`, and `image: koenig/paperclip-server:dev` pattern as `paperclip`; give it `container_name: koenig-watchdog`.
3. Set `command: ["/bin/bash", "/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/watchdog/start-watchdog.sh"]`, `restart: unless-stopped`, and `depends_on.paperclip.condition: service_healthy`.
4. Add environment values `PAPERCLIP_HOST: "http://paperclip:3100"`, `PAPERCLIP_API_KEY: "${PAPERCLIP_API_KEY:?PAPERCLIP_API_KEY must be set}"`, `KOENIG_COMPANY_ID: "2a77f89b-33f0-4133-a20c-77ddaac5e744"`, and `WATCHDOG_INTERVAL_MS: "600000"`; keep `env_file: ../.env.koenig` so alerts and optional watchdog env vars can flow from the existing secret file.
5. Mount `/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org:/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org:rw` so `watchdog/watchdog.mjs` can persist watchdog state and vault audit logs through the host filesystem across container restarts; do not add a separate state volume in this ticket.
6. Copy the Koenig json-file logging options from nearby lightweight services (`max-size: "5m"`, `max-file: "3"`) unless reviewer prefers the larger paperclip server log cap.
7. Leave `docker/docker-compose.yml`, launchd plists, watchdog JS, server code, and database schema unchanged.

## Verification (QA Verifier checks these)
- [ ] `PAPERCLIP_API_KEY=dummy BETTER_AUTH_SECRET=dummy docker compose -f infra/docker-compose.koenig.yml config` renders a valid `watchdog` service with no unresolved variable errors.
- [ ] `docker compose -f infra/docker-compose.koenig.yml config | rg -n "watchdog:|PAPERCLIP_HOST|KOENIG_COMPANY_ID|WATCHDOG_INTERVAL_MS|condition: service_healthy|/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/watchdog/start-watchdog.sh"` shows the expected service wiring.
- [ ] Optional runtime smoke on a host with Docker: `PAPERCLIP_API_KEY=<valid key> docker compose -f infra/docker-compose.koenig.yml up -d watchdog` then `docker logs koenig-watchdog --tail 80` shows watchdog startup without `paperclip http://paperclip:3100` connection/auth failures.

## Risk
- The watchdog can enter a restart loop if `PAPERCLIP_API_KEY` is missing or invalid; mitigate by keeping the compose variable required and verifying `docker compose config` before deployment.

## Out of scope
- Do not grant new agent permissions, change watchdog pause/escalation logic, persist `watchdog/.state` in a new Docker volume, or change the upstream quickstart compose.
