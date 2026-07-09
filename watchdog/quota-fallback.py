#!/usr/bin/env python3
"""Quota-aware model fallback (board-directed, 2026-07-09).

Problem: when the ChatGPT/Codex weekly or 5h quota is exhausted, codex_local
agents retry-loop for hours (140 failed runs/48h observed on Chief Engineering)
instead of falling back to another provider.

This daemon (launchd, every 5 min):
1. Scans heartbeat_runs for quota-exhaustion failures in the last 20 min.
2. For each codex_local agent with >=2 recent quota failures and no active
   fallback: backs up adapter config, flips adapter_type -> claude_local and
   model -> claude-sonnet-4-6 (subscription OAuth), and stamps
   metadata.quota_fallback with the original config + revert time parsed from
   the error message ("try again at Jul 10th, 2026 10:09 AM" / "at 2:39 PM").
3. Reverts the flip once the revert time passes.

Fallback ladder (V1): codex_local -> claude_local/sonnet-4-6. Claude-side quota
errors are logged only (Anthropic Max limits are per-org anyway; flipping the
whole fleet to OpenRouter is a board decision, not an automatic one).

All actions append to vault/_audit/quota-fallback.log and are stamped in
agents.metadata so they are auditable and idempotent.
"""

import json
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Runtime copy lives at ~/.koenig/ (launchd cannot read ~/Documents under
# Sequoia TCC); source of truth is koenig-ai-org/watchdog/quota-fallback.py.
# Audit log goes to ~/.koenig/ for the same reason.
AUDIT_LOG = Path.home() / ".koenig" / "quota-fallback-audit.log"
DOCKER = "/usr/local/bin/docker"
PSQL = [DOCKER, "exec", "paperclip-db", "psql", "-U", "paperclip", "-d", "paperclip", "-Atc"]

FALLBACK_ADAPTER = "claude_local"
FALLBACK_MODEL = "claude-sonnet-4-6"
QUOTA_PATTERN = "hit your usage limit"
MIN_FAILURES = 2
DEFAULT_REVERT_HOURS = 3


def q(sql: str) -> str:
    return subprocess.run(PSQL + [sql], capture_output=True, text=True, timeout=30).stdout.strip()


def log(msg: str) -> None:
    AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
    line = f"{datetime.now(timezone.utc).isoformat()} {msg}"
    with AUDIT_LOG.open("a") as f:
        f.write(line + "\n")
    print(line)


def parse_reset(error: str) -> datetime:
    """Parse 'try again at Jul 10th, 2026 10:09 AM' or 'try again at 2:39 PM' (UTC assumed)."""
    now = datetime.now(timezone.utc)
    m = re.search(r"try again at ([A-Z][a-z]{2} \d{1,2})(?:st|nd|rd|th)?, (\d{4}) (\d{1,2}):(\d{2}) (AM|PM)", error)
    if m:
        try:
            dt = datetime.strptime(f"{m.group(1)} {m.group(2)} {m.group(3)}:{m.group(4)} {m.group(5)}", "%b %d %Y %I:%M %p")
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            pass
    m = re.search(r"try again at (\d{1,2}):(\d{2}) (AM|PM)", error)
    if m:
        try:
            t = datetime.strptime(f"{m.group(1)}:{m.group(2)} {m.group(3)}", "%I:%M %p").time()
            dt = datetime.combine(now.date(), t, tzinfo=timezone.utc)
            if dt <= now:
                dt += timedelta(days=1)
            return dt
        except ValueError:
            pass
    return now + timedelta(hours=DEFAULT_REVERT_HOURS)


def flip_pass() -> None:
    rows = q(f"""
        SELECT a.id, a.name, count(*), max(hr.error)
        FROM heartbeat_runs hr JOIN agents a ON a.id = hr.agent_id
        WHERE hr.status = 'failed'
          AND hr.created_at > now() - interval '20 minutes'
          AND hr.error ILIKE '%{QUOTA_PATTERN}%'
          AND a.adapter_type = 'codex_local'
          AND a.status <> 'paused'
          AND (a.metadata IS NULL OR NOT (a.metadata ? 'quota_fallback'))
        GROUP BY a.id, a.name HAVING count(*) >= {MIN_FAILURES};
    """)
    for row in filter(None, rows.splitlines()):
        agent_id, name, n, error = row.split("|", 3)
        revert_at = parse_reset(error)
        marker = json.dumps({
            "original_adapter_type": "codex_local",
            "original_model": q(f"SELECT adapter_config->>'model' FROM agents WHERE id='{agent_id}';"),
            "revert_at": revert_at.isoformat(),
            "flipped_at": datetime.now(timezone.utc).isoformat(),
            "reason": f"{n} codex quota failures in 20min",
        })
        q(f"""
            INSERT INTO _agent_adapter_backups (agent_id, adapter_type, adapter_config, note)
            SELECT id, adapter_type, adapter_config, 'quota-fallback auto-flip' FROM agents WHERE id='{agent_id}';
            UPDATE agents SET
              adapter_type = '{FALLBACK_ADAPTER}',
              adapter_config = jsonb_set(adapter_config, '{{model}}', '"{FALLBACK_MODEL}"'),
              metadata = coalesce(metadata, '{{}}'::jsonb) || jsonb_build_object('quota_fallback', '{marker}'::jsonb),
              updated_at = now()
            WHERE id = '{agent_id}';
        """)
        log(f"FLIP {name} codex_local->{FALLBACK_ADAPTER}/{FALLBACK_MODEL} ({n} quota failures; revert {revert_at.isoformat()})")


CLAUDE_QUOTA_PATTERN = "hit your limit"  # "You've hit your limit · resets 3:20pm (UTC)"


def parse_claude_reset(error: str) -> datetime:
    """Parse 'resets 3:20pm (UTC)' from Claude limit errors."""
    now = datetime.now(timezone.utc)
    m = re.search(r"resets (\d{1,2}):(\d{2})(am|pm)", error, re.I)
    if m:
        try:
            t = datetime.strptime(f"{m.group(1)}:{m.group(2)} {m.group(3).upper()}", "%I:%M %p").time()
            dt = datetime.combine(now.date(), t, tzinfo=timezone.utc)
            if dt <= now:
                dt += timedelta(days=1)
            return dt
        except ValueError:
            pass
    return now + timedelta(hours=DEFAULT_REVERT_HOURS)


def claude_snooze_pass() -> None:
    """Both-subscriptions-exhausted case: a claude_local agent hitting the
    Claude limit has nowhere to flip (Codex is usually what it fell back FROM).
    Instead of letting it fail-loop, disable its heartbeat until the parsed
    reset time; the re-enable is handled by snooze_revert_pass."""
    rows = q(f"""
        SELECT a.id, a.name, count(*), max(hr.error)
        FROM heartbeat_runs hr JOIN agents a ON a.id = hr.agent_id
        WHERE hr.status = 'failed'
          AND hr.created_at > now() - interval '20 minutes'
          AND hr.error ILIKE '%{CLAUDE_QUOTA_PATTERN}%'
          AND a.adapter_type = 'claude_local'
          AND a.status <> 'paused'
          AND (a.metadata IS NULL OR NOT (a.metadata ? 'quota_snooze'))
        GROUP BY a.id, a.name HAVING count(*) >= {MIN_FAILURES};
    """)
    for row in filter(None, rows.splitlines()):
        agent_id, name, n, error = row.split("|", 3)
        resume_at = parse_claude_reset(error)
        marker = json.dumps({
            "resume_at": resume_at.isoformat(),
            "snoozed_at": datetime.now(timezone.utc).isoformat(),
            "reason": f"{n} Claude quota failures in 20min (no fallback tier available)",
        })
        q(f"""
            UPDATE agents SET
              runtime_config = jsonb_set(runtime_config, '{{heartbeat,enabled}}', 'false'),
              metadata = coalesce(metadata, '{{}}'::jsonb) || jsonb_build_object('quota_snooze', '{marker}'::jsonb),
              updated_at = now()
            WHERE id = '{agent_id}';
        """)
        log(f"SNOOZE {name} heartbeat disabled until {resume_at.isoformat()} ({n} Claude quota failures)")


def snooze_revert_pass() -> None:
    rows = q("""
        SELECT id, name FROM agents
        WHERE metadata ? 'quota_snooze'
          AND (metadata->'quota_snooze'->>'resume_at')::timestamptz < now();
    """)
    for row in filter(None, rows.splitlines()):
        agent_id, name = row.split("|", 1)
        q(f"""
            UPDATE agents SET
              runtime_config = jsonb_set(runtime_config, '{{heartbeat,enabled}}', 'true'),
              metadata = metadata - 'quota_snooze',
              updated_at = now()
            WHERE id = '{agent_id}';
        """)
        log(f"RESUME {name} heartbeat re-enabled after Claude quota reset")


def revert_pass() -> None:
    rows = q("""
        SELECT id, name, metadata->'quota_fallback' FROM agents
        WHERE metadata ? 'quota_fallback'
          AND (metadata->'quota_fallback'->>'revert_at')::timestamptz < now();
    """)
    for row in filter(None, rows.splitlines()):
        agent_id, name, marker_json = row.split("|", 2)
        marker = json.loads(marker_json)
        model = marker.get("original_model") or "gpt-5.5"
        q(f"""
            UPDATE agents SET
              adapter_type = '{marker.get("original_adapter_type", "codex_local")}',
              adapter_config = jsonb_set(adapter_config, '{{model}}', '"{model}"'),
              metadata = metadata - 'quota_fallback',
              updated_at = now()
            WHERE id = '{agent_id}';
        """)
        log(f"REVERT {name} back to {marker.get('original_adapter_type')}/{model}")


def main() -> None:
    try:
        flip_pass()
        claude_snooze_pass()
        revert_pass()
        snooze_revert_pass()
    except Exception as exc:  # noqa: BLE001
        log(f"ERROR {exc}")
        sys.exit(1)


if __name__ == "__main__":
    main()
