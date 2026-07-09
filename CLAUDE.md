# Claude Code context for koenig-ai-org

This is **Koenig Solutions' fork of [paperclipai/paperclip](https://github.com/paperclipai/paperclip)** — the AI agent agency that runs our products. The first product is the **Koenig AI Academy** at `academy.kspl.tech`. The Academy product code lives in a sibling repo: `Koenig-Solutions-Private-Limited/learnovaBeast`.

## What's ours vs upstream

**Don't touch upstream files unless absolutely necessary.** Our customizations live entirely in these directories:

- `vault/` — Obsidian markdown vault, agent narrative output
- `companies/` — per-product agent companies (V1 = `learnova-academy`)
- `adapters/` — custom Paperclip adapters
- `shared-skills/` — reusable skill packs
- `watchdog/` — loop-detection + cost circuit breaker
- `observability/` — Langfuse Docker setup
- `infra/` — launchd plists, Cloudflare Tunnel config
- `scripts/` — bootstrap, upstream-rebase, seed-company
- `docs/` — our docs and ADRs
- `README.koenig.md` — our README (upstream `README.md` preserved)
- `.env.example` — Koenig-specific env template

Upstream paths to **leave alone**: `cli/`, `server/`, `ui/`, `packages/`, `evals/`, `tests/`, `releases/`, `report/`, `patches/`, `docker/`, `doc/`, the upstream `docs/`.

## Cardinal rules

1. **Inexpensive, not cheap.** Default ladder: open-source MIT/Apache on the Mac → free SaaS tier → cheap pay-as-you-go → premium SaaS only when quality demands.
2. **No ElevenLabs, ever.** Use Kokoro / OmniVoice / Cartesia / Chatterbox.
3. **CLI-maximalist.** Prefer terminal-driven workflows. `browser-use` is the default browser automation.
4. **Newer/innovative > established** when quality is comparable. Surface the tradeoff.
5. **Obsidian is the knowledge interface.** All agent narrative output goes to `vault/` as markdown (frontmatter + tags + `[[wikilinks]]`).
6. **Two-agent content chain.** Author → Content Reviewer (G0) → G2 → CEO (G3). **Blogs auto-publish at G3 PASS** (policy 2026-05-01, board-reaffirmed 2026-07-09); human G4 ONLY for new-course first publish, pricing/commercial claims, legal/brand-sensitive content, partner/customer mentions. Never publish from a single agent. Word counts + status vocabulary: `companies/learnova-academy/EDITORIAL.md`.
7. **Anonymous-by-default for the Academy.** Optional Convex email-OTP only.
8. **Board oversight = daily publish digest** (Editor in Chief routine, 13:00 UTC) + the Paperclip approvals queue, which is for board DECISIONS only — never notifications, dependency blocks, or routine assignment requests.

## Stack

- **Paperclip core** (upstream): pnpm workspace, Node 20+, embedded Postgres, ESM TypeScript.
- **Adapters wired locally**: `claude-local`, `codex-local`, `gemini-local`, `opencode-local`, `paperclip-adapter-openrouter`, plus our custom adapters.
- **Models**: the DB is the runtime source of truth — see the generated `companies/learnova-academy/ROSTER.live.md` (regenerate with `./scripts/roster-snapshot.sh`; verify with `--check`). Do not hand-maintain model lists in prose docs; they drift.
- **Observability**: Langfuse self-hosted at `localhost:3100`.
- **Watchdog**: `watchdog/watchdog.mjs`, runs under launchd.

## Configuration

`~/.paperclip/adapter-plugins.json` registers our adapters by absolute path into this repo's `adapters/`. Don't symlink into upstream `packages/`.

`~/.paperclip` (NOT in this repo) holds the embedded Postgres data + Paperclip's own state. Back it up from `scripts/backup-paperclip-db.sh`.

## How agents are defined

Each agent is a folder under `companies/<product>/agents/<role>/` with:

- `SOUL.md` — role lane, definition-of-done, escalation triggers, exact reporting format, what they never do
- `skills/` — lazy-loaded skill packs (markdown how-tos)
- `config.json` — model, adapter, monthly + per-task budget, MCP servers, tools

Per-company config in `COMPANY.md` (org chart) and `CLAUDE.md` (per-product context for Claude Code).

## Common pitfalls

- **Never push our customizations to upstream.** `git remote -v` should show two: `origin` (our fork) and `upstream` (paperclipai/paperclip). Only ever push `origin`.
- **`pnpm install` is required after pulling upstream** — adapter packages may have new deps.
- **Watchdog must be running** before you cron-schedule any agent — otherwise cost runaway risk.
- **Don't put secrets in `vault/`** (it's checked in). `.env` only.

## `.env.koenig` editing contract (all agents + CEO)

The operator injects credential blocks into the live `.env.koenig` out-of-band that do **not** exist in any checked-in `.env.koenig.bak-v*` file. Wholesale restore from a backup will silently drop them.

1. Edit `.env.koenig` **additively only** — append new keys, modify specific lines. Never rewrite the file.
2. Never `cp .env.koenig.bak-v* .env.koenig`. If a rebuild is genuinely unavoidable, `diff` the backup against the live file first and carry forward every key/block present in live but not in backup.
3. Any block tagged `# ... injected by operator; DO NOT remove ...` is load-bearing. The current load-bearing block is `CAREER_R2_*` (account id, access key, secret, `CAREER_R2_BUCKET=lms`) — consumed by `scripts/career-reconcile.{sh,mjs}`, `scripts/upload-chapter-assets.mjs`, `scripts/academy-status-export.mjs`.
4. After any env-related recovery, verify load-bearing blocks are still present before declaring done.

Origin: operator note on [KOEA-6012](/KOEA/issues/KOEA-6012) (2026-06-11) after a `bak-v2` restore deleted `CAREER_R2_*` and broke the career-reconciler + academy admin status exporter.

## When in doubt

- New product? `./scripts/seed-company.sh _template <new-product>`
- Upstream merge? `./scripts/upstream-rebase.sh`
- DB backup? `./scripts/backup-paperclip-db.sh`
- Cost spike? Check Langfuse, then `~/.paperclip` agent budgets.
