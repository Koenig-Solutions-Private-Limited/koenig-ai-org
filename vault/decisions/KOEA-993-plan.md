---
ticket: KOEA-993
planner: planner
date: 2026-05-11
estimated_complexity: small
estimated_token_cost: $0.25
---

# Plan: Repair opencode lock ownership blocking researchers

## Goal
Restore `opencode` availability to researcher agents by clearing the stale root-owned lock directory at `/paperclip/.local/state/opencode/locks/`. Success = any agent container (running as `node` uid 501) can invoke `opencode models` without an EACCES/EPERM on the locks path, and a fresh lock dir is created with `node:dialout` ownership on next run.

## Context

**Observed state (verified from inside an agent container, 2026-05-11):**

```
/paperclip/.local/state/opencode/                  drwxr-xr-x  node:dialout
/paperclip/.local/state/opencode/locks/            drwxr-xr-x  node:dialout
/paperclip/.local/state/opencode/locks/ab9262d3350d9f9d980547b1f5ac750a4c3ea9df.lock/
                                                    drwx------  root:root   (mode 0700, May 1 05:59)
```

- The offending entry is a **directory**, not a file. Its inner contents are unreadable to `node` (mode 700 + root-owned).
- No `opencode` process is running anywhere on the runtime (`ps aux | grep opencode` returns empty).
- The hash `ab9262d3...` is opencode's per-project SHA1 lock key — a single stale entry is enough to block researchers if their working dir hashes to the same key.

**Why it exists:** Pre-KOEA-862 (commit `ee6cd80d`, 2026-04-30), opencode invocations escaped to root inside the bwrap namespace and wrote state as root. The Docker/bwrap fix landed, but state files written by the pre-fix run remained root-owned.

**Runtime constraints:**
- `/paperclip` inside agent containers is the Docker named volume `paperclip-data` (per `/proc/self/mountinfo`: `254:1 /docker/volumes/paperclip-data/_data /paperclip`). It is NOT a host bind-mount under `/Users/vardaankoenig/`.
- Agent containers run as `node` (uid 501, gid 20 dialout). No `sudo`, `su`, `gosu`, or `fakeroot` is installed. `/var/run/docker.sock` is not mounted. There is no in-container path to root.
- The repair therefore must run from a privileged context on the Docker host — either `docker exec -u root <container>` against a live agent container, or directly on the host's `/var/lib/docker/volumes/paperclip-data/_data/...` path as root.

**Files to read first:**
- `services/meeting-attendee/...` — unrelated; ignore
- `companies/learnova-academy/agents/researcher*/config.json` — if Executor wants to confirm researcher adapter is `opencode-local` (optional context)
- Commit `ee6cd80d` — the KOEA-862 Docker/bwrap fix that established node-as-default

## Approach (1 chosen, alternatives rejected)

**Chosen — remove the stale lock dir as root from the host, then verify from a non-privileged agent shell.**

A surgical `rm -rf` of the single offending `*.lock` directory (not the whole `locks/` parent) clears the blocker without touching node-owned state. The parent `locks/` is already correctly owned (`node:dialout`), so opencode will recreate a fresh per-project lock on next invocation with the right ownership. Verification runs `opencode models` and `opencode run` as `node` to confirm researchers can proceed.

**Rejected:**
- *Chown the stale dir to `node:dialout` instead of removing it.* — Rejected: the dir contents are unknown (unreadable as non-root), may contain a stale PID file opencode would interpret as a live lock, and there is no value in preserving 10-day-old lock contents. Removal is strictly safer.
- *Wipe the entire `locks/` directory and recreate it.* — Rejected as unnecessarily broad; only one entry is root-owned, and broader changes risk colliding with any concurrent (legitimate) opencode lock in other research streams.
- *Patch the opencode-local adapter to retry/skip on EPERM.* — Rejected per ticket constraint ("Do not modify adapter code unless runtime repair is insufficient"). If this recurs, file a separate follow-up.

## Steps (Executor follows in order)

> Executor: steps 1–3 require **host root** (Docker host shell, not an agent container). If Executor is itself inside a `node` container, hand off step 1–3 to the host operator (Vardaan / @engineering) via an issue comment with these exact commands, then resume at step 4 from inside any agent container once they confirm.

**1. Identify the running container that mounts `paperclip-data`** (host shell, any user that can run `docker`):

```bash
docker ps --filter "volume=paperclip-data" --format '{{.ID}}\t{{.Names}}\t{{.Image}}'
```

Expected: one or more lines naming the Paperclip agent container(s). Pick any one — the volume is shared. Set `CTR=<chosen container id or name>`.

**2. Confirm the stale lock from a root shell in that container** (host shell):

```bash
docker exec -u root "$CTR" ls -la /paperclip/.local/state/opencode/locks/
```

Expected output (the salient line):
```
drwx------ 2 root root    4096 May  1 05:59 ab9262d3350d9f9d980547b1f5ac750a4c3ea9df.lock
```

If the directory is already gone (e.g. somebody else fixed it), skip to step 4. If there are *additional* root-owned `*.lock` entries beyond the one named here, include them in step 3's removal (the `*.lock` glob below covers that).

**3. Remove the stale root-owned lock dir(s)** (host shell):

```bash
docker exec -u root "$CTR" sh -c 'find /paperclip/.local/state/opencode/locks -mindepth 1 -maxdepth 1 -user root -name "*.lock" -exec rm -rf {} +'
docker exec -u root "$CTR" ls -la /paperclip/.local/state/opencode/locks/
```

Expected: the second `ls` shows only the two `.` and `..` entries under `locks/`, both owned by `node:dialout`. No `*.lock` directories remain.

The `-user root` filter is a safety guard: if opencode is legitimately holding a `node`-owned lock during this window, that lock is left untouched.

**4. Verify from a non-privileged agent shell** (from inside any agent container, as `node`):

```bash
ls -la /paperclip/.local/state/opencode/locks/
opencode --version
opencode models 2>&1 | head -20
```

Expected:
- `ls` shows the locks dir empty (apart from `.`/`..`).
- `opencode --version` prints `1.14.31` (or newer).
- `opencode models` prints a list of model IDs and exits 0. **No** `EACCES`, `EPERM`, or `lock` errors. After the call, a fresh `node:dialout`-owned lock dir may appear under `locks/` — that is the success signal.

**5. Smoke test from a researcher-equivalent invocation** (inside an agent container, as `node`):

```bash
cd /tmp && mkdir -p opencode-smoke && cd opencode-smoke
opencode run --print 'reply with the single word OK' 2>&1 | tail -20
```

Expected: opencode completes a small turn (any successful response) without lock errors. If `opencode run` requires extra config (model selection, auth), prefer the lighter `opencode models` check from step 4 as the source of truth and note this step as best-effort.

**6. Post verification output on KOEA-993** as a comment, including the post-fix `ls -la` of `locks/` and the head of `opencode models` output. Close KOEA-993 with link to this plan and to KOEA-995.

## Verification (QA Verifier checks these)
- [ ] `/paperclip/.local/state/opencode/locks/` contains no `root`-owned entries (check via `ls -la` inside an agent container).
- [ ] `opencode models` exits 0 as `node` inside an agent container, prints at least one model.
- [ ] After running `opencode models`, any newly created lock entry under `locks/` is owned by `node:dialout`, mode `drwx------` or `drwxr-xr-x` — never `root`.
- [ ] Researcher agent (e.g. one assigned a follow-up task using `opencode-local`) completes a turn without lock errors.

## Risk

- **Risk:** A live opencode process is holding the lock and step 3 deletes it mid-run, corrupting that run.
  - **Mitigation:** The `-user root` filter in step 3 only removes root-owned entries; any legitimate live lock would be `node`-owned and untouched. Additionally, `ps aux | grep opencode` on the runtime returned no process at planning time. If Executor wants belt-and-suspenders, add `docker exec -u root "$CTR" pgrep -af opencode` between steps 2 and 3 and abort if any opencode process is running.
- **Rollback:** Not applicable. The removed directory is stale, unreadable state from a pre-fix run; there is nothing inside worth preserving. If somehow this regresses opencode (it shouldn't — opencode auto-creates locks on demand), users restart their opencode invocation and a fresh lock is recreated.

## Out of scope
- Modifying `adapters/` or `packages/adapters/` to gracefully handle EPERM on the locks dir (ticket constraint).
- Adding a container-init script that chowns `/paperclip/.local/state/opencode` on startup as a prophylactic. Recommended as a **separate follow-up issue** if this class of leak recurs; mention it in the KOEA-993 close comment so Chief Engineering can scope it.
- Deploying Convex changes, touching Learnova portal code, or any researcher-task replay work (KOEA-992 / KOEA-994 are downstream of this fix).
- Auditing other `/paperclip/.local/...` paths for similar root-owned leakage. `/paperclip/.local/bin` is also root-owned but contains the cursor-agent binary symlinks and is expected to be root-owned; leave it alone.
