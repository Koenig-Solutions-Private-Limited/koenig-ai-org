#!/usr/bin/env python3
"""Koenig org cron driver — pokes Chief Engineering periodically so the
agent dispatch cascade keeps flowing.

WHY THIS EXISTS
Paperclip's internal scheduler does NOT have a continuous tick loop. Routines
have nextRunAt timestamps but nothing fires them. The historical launchd plists
called `/heartbeat/invoke` directly, but they used the wrong agent UUIDs and
relied on `local_trusted` deployment mode (server now runs `authenticated`).

The watchdog API key's `sub` claim is `b90788a0-d3de-42da-8e77-7dc8f7c01fd3`
(Chief Engineering). The /api/agents/{id}/heartbeat/invoke endpoint enforces
"agent can only invoke itself" — so this token CAN wake Chief Engineering.
Chief Engineering's heartbeat skill reads its inbox, picks up tickets, and
dispatches sub-tickets to other agents (Blog Author, Content Reviewer, etc.).
Those agents auto-wake on assignment via Paperclip's `wake_assignee`
continuation policy. So poking Chief Engineering once cascades into the whole
org doing work.

DESIGN
- Single Python process, infinite loop, sleep between ticks.
- Reads creds from /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/.env.koenig
  (keeps the JWT out of the launchd plist).
- Logs to scripts/.logs/koenig-cron-driver.log (rotated by stat-and-truncate when >5MB).
- HTTP errors are warnings, not crashes — they'll usually be `Internal server error`
  even when the wake actually fires (Paperclip quirk).
"""

import json
import os
import re
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
from datetime import datetime, timedelta, timezone
from pathlib import Path

REPO = Path("/Users/vardaankoenig/Documents/Paperclip/koenig-ai-org")
ENV_FILE = REPO / ".env.koenig"
LOG_DIR = REPO / "scripts" / ".logs"
LOG_FILE = LOG_DIR / "koenig-cron-driver.log"
LOG_MAX_BYTES = 5 * 1024 * 1024  # 5 MB

PAPERCLIP_HOST = os.environ.get("PAPERCLIP_HOST", "http://localhost:3100")
COMPANY_ID = "2a77f89b-33f0-4133-a20c-77ddaac5e744"
CHIEF_ENGINEERING_ID = "b90788a0-d3de-42da-8e77-7dc8f7c01fd3"

# Tick cadence. 5 min keeps the inbox warm without burning Claude Max hours.
TICK_INTERVAL_S = int(os.environ.get("KOENIG_CRON_TICK_S", "300"))

# Daily-cadence agents that need wake calls outside of Chief Engineering's
# delegate loop. These use the BOARD_TOKEN (user-scoped, can invoke any agent),
# not the watchdog JWT (agent-scoped, self-invoke only). Each entry fires once
# per UTC calendar day at the given UTC hour.
VAULT_HISTORIAN_ID = "eeed7524-0662-4ca9-a103-057c921efd96"
DAILY_AGENT_SCHEDULES: list[dict] = [
    # Vault Historian — daily synthesis at 23:00 UTC. Reads the day's vault
    # writes and rolls them into _index/by-date.md. Off-subscription
    # (opencode_local + DeepSeek V4 Pro), so safe even during Claude rate-limit
    # windows.
    {"agent_id": VAULT_HISTORIAN_ID, "name": "Vault Historian", "hour_utc": 23},
]
# Track last-fired UTC date per agent so we don't re-fire within the same day
# even if the cron-driver is restarted.
_LAST_FIRED_DATE: dict[str, str] = {}
_GUARD_TAG = "[daily-synthesis-stale-guard]"
_EVIDENCE_RE = re.compile(
    r"(vault/research/_daily/\d{4}-\d{2}-\d{2}\.md|vault/research/_synthesis/[^\s)]+)",
    re.IGNORECASE,
)
_DATE_RE = re.compile(r"\b(20\d{2}-\d{2}-\d{2})\b")


def parse_env_file(path: Path) -> dict:
    """Tiny .env reader — handles `KEY=value`, `KEY="value with spaces"`, comments."""
    out = {}
    if not path.exists():
        return out
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, val = line.split("=", 1)
        key = key.strip()
        val = val.strip()
        # Strip surrounding quotes if present
        if (val.startswith('"') and val.endswith('"')) or (
            val.startswith("'") and val.endswith("'")
        ):
            val = val[1:-1]
        out[key] = val
    return out


def log(msg: str) -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    # Rotate by truncating when too big — simple, no rotation deps
    if LOG_FILE.exists() and LOG_FILE.stat().st_size > LOG_MAX_BYTES:
        LOG_FILE.write_text("")
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    line = f"{ts} {msg}\n"
    sys.stdout.write(line)
    sys.stdout.flush()
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(line)


def post(url: str, token: str, body: dict | None = None, timeout: float = 10) -> tuple[int, str]:
    data = json.dumps(body or {}).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        method="POST",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            # Paperclip enforces a hostname allowlist; "localhost" is always allowed,
            # so spoof Host even when reaching the server via a docker service name.
            "Host": "localhost:3100",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read().decode("utf-8")[:300]
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")[:300]
    except Exception as e:  # noqa: BLE001 — network timeouts, DNS, etc.
        return 0, f"network error: {e}"


def get_json(url: str, token: str, timeout: float = 10) -> tuple[int, dict | list | None]:
    req = urllib.request.Request(
        url,
        method="GET",
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Host": "localhost:3100",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8")
            return resp.status, json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8", errors="replace"))
        except Exception:  # noqa: BLE001
            return e.code, None
    except Exception:  # noqa: BLE001
        return 0, None


def patch_issue_status(issue_id: str, token: str, status: str, comment: str) -> tuple[int, str]:
    req = urllib.request.Request(
        f"{PAPERCLIP_HOST}/api/issues/{issue_id}",
        method="PATCH",
        data=json.dumps({"status": status, "comment": comment}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Host": "localhost:3100",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            return resp.status, resp.read().decode("utf-8")[:300]
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")[:300]
    except Exception as e:  # noqa: BLE001
        return 0, f"network error: {e}"


def _coerce_items(payload: dict | list | None) -> list[dict]:
    if payload is None:
        return []
    if isinstance(payload, list):
        return [i for i in payload if isinstance(i, dict)]
    for key in ("issues", "items", "data"):
        val = payload.get(key)
        if isinstance(val, list):
            return [i for i in val if isinstance(i, dict)]
    return []


def _parse_dt(raw: str | None) -> datetime | None:
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except Exception:  # noqa: BLE001
        return None


def _text_blob(issue: dict, comments: list[dict] | None = None) -> str:
    parts = [
        str(issue.get("title") or ""),
        str(issue.get("description") or ""),
        str(issue.get("identifier") or ""),
    ]
    for label in issue.get("labels") or []:
        if isinstance(label, dict):
            parts.append(str(label.get("name") or ""))
        else:
            parts.append(str(label))
    for c in comments or []:
        parts.append(str(c.get("comment") or c.get("body") or ""))
    return "\n".join(parts)


def is_synthesis_candidate(issue: dict, comments: list[dict] | None = None) -> bool:
    text = _text_blob(issue, comments).lower()
    return "daily-synthesis" in text or (
        "daily" in text and "synthesis" in text and "research" in text
    )


def extract_cycle_date(issue: dict, comments: list[dict] | None = None) -> str | None:
    text = _text_blob(issue, comments)
    match = _DATE_RE.search(text)
    return match.group(1) if match else None


def extract_evidence_path(issue: dict, comments: list[dict] | None = None) -> str | None:
    text = _text_blob(issue, comments)
    match = _EVIDENCE_RE.search(text)
    return match.group(1) if match else None


def _iso_now(now: datetime) -> str:
    return now.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _issue_identifier(issue: dict) -> str:
    return str(issue.get("identifier") or issue.get("id") or "unknown")


def triage_comment_recent(comments: list[dict], now: datetime) -> bool:
    cutoff = now - timedelta(hours=24)
    for c in comments:
        body = str(c.get("comment") or c.get("body") or "")
        if _GUARD_TAG not in body or "triage requested" not in body:
            continue
        created = _parse_dt(c.get("createdAt"))
        if created and created >= cutoff:
            return True
    return False


def choose_superseder(
    candidate: dict,
    candidate_comments: list[dict],
    superseders: list[dict],
    superseder_comments: dict[str, list[dict]],
) -> tuple[dict | None, str | None, str | None]:
    candidate_cycle = extract_cycle_date(candidate, candidate_comments)
    candidate_updated = _parse_dt(candidate.get("updatedAt"))
    if not candidate_updated:
        return None, None, "missing candidate updatedAt"
    matches: list[tuple[datetime, dict, str]] = []
    for issue in superseders:
        if issue.get("id") == candidate.get("id"):
            continue
        comments = superseder_comments.get(str(issue.get("id")), [])
        if not is_synthesis_candidate(issue, comments):
            continue
        evidence = extract_evidence_path(issue, comments)
        if not evidence:
            continue
        cycle = extract_cycle_date(issue, comments)
        if candidate_cycle and cycle and cycle != candidate_cycle:
            continue
        updated = _parse_dt(issue.get("updatedAt"))
        if not updated or updated <= candidate_updated:
            continue
        matches.append((updated, issue, evidence))
    if not matches:
        return None, None, "no same-cycle terminal superseder with evidence"
    matches.sort(key=lambda x: x[0], reverse=True)
    if len(matches) > 1 and matches[0][0] == matches[1][0]:
        return None, None, "multiple equally recent superseders"
    return matches[0][1], matches[0][2], None


def fetch_issue_details_and_comments(issue_id: str, token: str) -> tuple[dict | None, list[dict]]:
    status, issue_payload = get_json(f"{PAPERCLIP_HOST}/api/issues/{issue_id}", token)
    if status not in (200, 201) or not isinstance(issue_payload, dict):
        return None, []
    c_status, comments_payload = get_json(f"{PAPERCLIP_HOST}/api/issues/{issue_id}/comments", token)
    comments = _coerce_items(comments_payload) if c_status in (200, 201) else []
    return issue_payload, comments


def discover_daily_synthesis_candidates(token: str) -> list[dict]:
    candidates_by_id: dict[str, dict] = {}
    queries = ["daily-synthesis", "research", "synthesis"]
    for q in queries:
        url = (
            f"{PAPERCLIP_HOST}/api/companies/{COMPANY_ID}/issues"
            f"?status=blocked&limit=100&q={urllib.parse.quote(q)}"
        )
        status, payload = get_json(url, token)
        if status not in (200, 201):
            continue
        for issue in _coerce_items(payload):
            issue_id = str(issue.get("id") or "")
            if not issue_id:
                continue
            labels = issue.get("labels") or []
            label_names = []
            for label in labels:
                if isinstance(label, dict):
                    label_names.append(str(label.get("name") or "").upper())
                else:
                    label_names.append(str(label).upper())
            if "daily-synthesis" in q or any(("RESEARCH" in n or "SYNTHESIS" in n) for n in label_names):
                candidates_by_id[issue_id] = issue
    return list(candidates_by_id.values())


def discover_superseders(token: str) -> list[dict]:
    superseders: list[dict] = []
    seen: set[str] = set()
    for status_name in ("done", "in_review"):
        url = (
            f"{PAPERCLIP_HOST}/api/companies/{COMPANY_ID}/issues"
            f"?status={status_name}&limit=100&q=daily-synthesis"
        )
        status, payload = get_json(url, token)
        if status not in (200, 201):
            continue
        for issue in _coerce_items(payload):
            issue_id = str(issue.get("id") or "")
            if issue_id and issue_id not in seen:
                seen.add(issue_id)
                superseders.append(issue)
    return superseders


def run_daily_synthesis_stale_guard(board_token: str | None, now: datetime | None = None) -> None:
    if not board_token:
        return
    now_utc = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
    stale_before = now_utc - timedelta(hours=6)
    candidates = discover_daily_synthesis_candidates(board_token)
    superseders = discover_superseders(board_token)
    superseder_comments: dict[str, list[dict]] = {}

    for sup in superseders:
        issue_id = str(sup.get("id") or "")
        if not issue_id:
            continue
        detail, comments = fetch_issue_details_and_comments(issue_id, board_token)
        if detail:
            sup.update(detail)
        superseder_comments[issue_id] = comments

    cancelled = 0
    triaged = 0
    for row in candidates:
        issue_id = str(row.get("id") or "")
        if not issue_id:
            continue
        issue, comments = fetch_issue_details_and_comments(issue_id, board_token)
        if not issue:
            continue
        updated = _parse_dt(issue.get("updatedAt"))
        if not updated or updated >= stale_before:
            continue
        if not is_synthesis_candidate(issue, comments):
            continue

        superseder, evidence, reason = choose_superseder(
            issue, comments, superseders, superseder_comments
        )
        if superseder and evidence:
            body = (
                f"{_GUARD_TAG} cancelled: superseded by {_issue_identifier(superseder)}; "
                f"evidence: {evidence}; evaluated_at: {_iso_now(now_utc)}"
            )
            status, _ = patch_issue_status(issue_id, board_token, "cancelled", body)
            if status in (200, 201):
                cancelled += 1
            else:
                log(f"stale-guard cancel failed issue={_issue_identifier(issue)} status={status}")
            continue

        if triage_comment_recent(comments, now_utc):
            continue
        triage_body = (
            f"{_GUARD_TAG} triage requested: {reason or 'ambiguous superseder'}; "
            f"evaluated_at: {_iso_now(now_utc)}"
        )
        status, _ = patch_issue_status(issue_id, board_token, "blocked", triage_body)
        if status in (200, 201):
            triaged += 1
        else:
            log(f"stale-guard triage failed issue={_issue_identifier(issue)} status={status}")

    log(f"stale-guard done cancelled={cancelled} triaged={triaged} candidates={len(candidates)}")


def heartbeat_freshness(token: str) -> str:
    """Return a 1-line summary of how many agents heartbeated in the last 10 min."""
    req = urllib.request.Request(
        f"{PAPERCLIP_HOST}/api/companies/{COMPANY_ID}/agents",
        headers={
            "Authorization": f"Bearer {token}",
            "Host": "localhost:3100",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            agents = json.loads(resp.read().decode("utf-8"))
        if isinstance(agents, dict):
            agents = agents.get("agents", agents.get("data", []))
        now = datetime.now(timezone.utc)
        fresh = 0
        for a in agents:
            hb = a.get("lastHeartbeatAt")
            if not hb:
                continue
            t = datetime.fromisoformat(hb.replace("Z", "+00:00"))
            if (now - t).total_seconds() < 600:
                fresh += 1
        return f"{fresh}/{len(agents)} agents fresh (<10min)"
    except Exception as e:  # noqa: BLE001
        return f"poll-failed: {e}"


def has_pending_work(token: str) -> bool:
    """Smart-skip: return True only if there's actionable work in the inbox.
    We pre-check the issues API and only invoke Chief Engineering if we see
    todo/in_progress/in_review items that need orchestration. Saves ~50%+ of
    heartbeat invocations during quiet periods (would be metered $$ if not on
    subscription; on subscription, saves rate-limit headroom).
    """
    req = urllib.request.Request(
        f"{PAPERCLIP_HOST}/api/companies/{COMPANY_ID}/issues?limit=10&status=todo",
        headers={"Authorization": f"Bearer {token}", "Host": "localhost:3100"},
    )
    try:
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        items = data if isinstance(data, list) else data.get("issues", data.get("items", []))
        return len(items) > 0
    except Exception as e:  # noqa: BLE001
        # If pre-check fails, fall back to firing — better safe than starving
        log(f"pre-check failed ({e}), firing anyway")
        return True


def fire_daily_schedules(board_token: str | None) -> None:
    """Once per UTC calendar day, wake the agents in DAILY_AGENT_SCHEDULES at
    their configured hour. Uses the BOARD_TOKEN (user-scoped) so it can invoke
    cross-agent — the watchdog JWT is self-only and would 403 here.
    Silently no-ops if no board token is configured.
    """
    if not board_token:
        return
    now = datetime.now(timezone.utc)
    today_iso = now.strftime("%Y-%m-%d")
    for entry in DAILY_AGENT_SCHEDULES:
        agent_id = entry["agent_id"]
        target_hour = entry.get("hour_utc", 23)
        if now.hour < target_hour:
            continue  # Not yet
        if _LAST_FIRED_DATE.get(agent_id) == today_iso:
            continue  # Already fired today
        url = f"{PAPERCLIP_HOST}/api/agents/{agent_id}/heartbeat/invoke"
        status, body = post(url, board_token)
        if status in (200, 201, 500):
            _LAST_FIRED_DATE[agent_id] = today_iso
            log(f"daily-schedule fired {entry['name']} status={status}")
        else:
            log(f"daily-schedule FAIL {entry['name']} status={status} body={body[:160]}")


def tick(token: str, board_token: str | None) -> None:
    # Smart-skip — don't invoke Chief Engineering when there's nothing to do.
    # Every 6th tick fires unconditionally so the org doesn't go fully dark
    # if pre-check misses something or a periodic-only task is needed.
    global _TICK_COUNT
    _TICK_COUNT += 1

    # First, run the daily schedule check (cheap, no-op most ticks).
    fire_daily_schedules(board_token)
    run_daily_synthesis_stale_guard(board_token, datetime.now(timezone.utc))

    force_fire = (_TICK_COUNT % 6) == 0
    if not force_fire and not has_pending_work(token):
        log(f"tick SKIP (no pending work) :: tick #{_TICK_COUNT}")
        return

    url = f"{PAPERCLIP_HOST}/api/agents/{CHIEF_ENGINEERING_ID}/heartbeat/invoke"
    status, body = post(url, token)
    # Note: 500 "Internal server error" still fires the heartbeat — Paperclip
    # quirk where the response can't include the new run id. Treat 200 OR 500
    # as "fired", anything else as failure to log.
    if status in (200, 201, 500):
        snapshot = heartbeat_freshness(token)
        forced = " (forced)" if force_fire else ""
        log(f"tick OK status={status}{forced} :: {snapshot}")
    else:
        log(f"tick FAIL status={status} body={body[:200]}")


_TICK_COUNT = 0


def main() -> int:
    # Prefer process env (set by docker compose env_file) over the on-disk .env.koenig
    # so the script works inside containers without mounting the env file.
    env_from_file = parse_env_file(ENV_FILE)
    token = os.environ.get("PAPERCLIP_API_KEY") or env_from_file.get("PAPERCLIP_API_KEY")
    board_token = os.environ.get("PAPERCLIP_BOARD_TOKEN") or env_from_file.get("PAPERCLIP_BOARD_TOKEN")
    if not token:
        log("FATAL: PAPERCLIP_API_KEY not in env or .env.koenig")
        return 1
    log(f"cron-driver up — poking {CHIEF_ENGINEERING_ID[:8]} every {TICK_INTERVAL_S}s")
    if board_token and DAILY_AGENT_SCHEDULES:
        names = ", ".join(e["name"] for e in DAILY_AGENT_SCHEDULES)
        log(f"daily-schedule registered: {names} (board-token present)")
    # Fire once immediately
    tick(token, board_token)
    while True:
        try:
            time.sleep(TICK_INTERVAL_S)
            tick(token, board_token)
        except KeyboardInterrupt:
            log("shutdown via SIGINT")
            return 0


if __name__ == "__main__":
    sys.exit(main())
