"""
Dry-run self-test for the CMO bridge. NO network. Exercises pure helpers and
state load/save against a temp dir. Prints PASS/FAIL per check and exits non-zero
on any failure.

Run: python3 test_selftest.py
"""
from __future__ import annotations

import os
import sys
import tempfile

# Configure a known whitelist + temp state dir BEFORE importing main, so module
# constants pick them up.
os.environ["CMO_BRIDGE_WHITELIST"] = "111, 222 ;333"
_TMP = tempfile.mkdtemp(prefix="cmo-bridge-selftest-")
os.environ["CMO_BRIDGE_STATE_DIR"] = _TMP
# leave CMO_BRIDGE_BOT_TOKEN unset => telegram disabled, no network attempted
os.environ.pop("CMO_BRIDGE_BOT_TOKEN", None)
# pin a known CMO agent id so watermark filtering is deterministic
os.environ["CMO_AGENT_ID"] = "cmo-agent-test"

import main  # noqa: E402

PASSED = 0
FAILED = 0


def check(name: str, cond: bool) -> None:
    global PASSED, FAILED
    if cond:
        PASSED += 1
        print(f"PASS  {name}")
    else:
        FAILED += 1
        print(f"FAIL  {name}")


# ── whitelist parsing ──
wl = main.parse_whitelist("111, 222 ;333")
check("parse_whitelist splits on comma and semicolon", wl == {"111", "222", "333"})
check("parse_whitelist empty -> empty set", main.parse_whitelist("") == set())
check("parse_whitelist strips blanks", main.parse_whitelist(" , 5 ,") == {"5"})

# is_whitelisted uses module WHITELIST (from env above)
check("is_whitelisted accepts int id in list", main.is_whitelisted(111) is True)
check("is_whitelisted accepts str id in list", main.is_whitelisted("222") is True)
check("is_whitelisted rejects unknown id", main.is_whitelisted(999) is False)

# empty whitelist => capture mode, nobody actioned
_saved = main.WHITELIST
main.WHITELIST = set()
check("empty whitelist => is_whitelisted False (capture mode)", main.is_whitelisted(111) is False)
main.WHITELIST = _saved

# ── draft marker detection ──
check("is_draft_comment true for marker", main.is_draft_comment("DRAFT-FOR-APPROVAL: Launch email"))
check("is_draft_comment tolerates leading whitespace",
      main.is_draft_comment("\n  DRAFT-FOR-APPROVAL: x"))
check("is_draft_comment false for normal comment", main.is_draft_comment("Working on it") is False)
check("draft_subject extracts subject",
      main.draft_subject("DRAFT-FOR-APPROVAL: Spring promo\n\nbody...") == "Spring promo")
check("draft_subject defaults when empty", main.draft_subject("DRAFT-FOR-APPROVAL:") == "Draft")

# ── callback_data parsing ──
check("parse approve", main.parse_callback_data("approve:abc-123") == ("approve", "abc-123"))
check("parse changes", main.parse_callback_data("changes:xyz") == ("changes", "xyz"))
check("parse rejects unknown action", main.parse_callback_data("delete:1") == ("", ""))
check("parse rejects missing id", main.parse_callback_data("approve:") == ("", ""))
check("parse rejects malformed", main.parse_callback_data("garbage") == ("", ""))

# ── agent mention format ──
check("agent_mention format",
      main.agent_mention("cmo-agent-test") == "[@CMO](agent://cmo-agent-test)")

# ── watermark filtering of CMO comments ──
comments = [
    {"id": "c1", "authorAgentId": None, "body": "rohit msg via bridge"},
    {"id": "c2", "authorAgentId": "cmo-agent-test", "body": "first cmo reply"},
    {"id": "c3", "authorAgentId": "cmo-agent-test", "body": "bridge-relayed? no"},
    {"id": "c4", "authorAgentId": "other-agent", "body": "someone else"},
    {"id": "c5", "authorAgentId": "cmo-agent-test", "body": "newest cmo reply"},
]

# no watermark, no bridge comments => all CMO-authored
got = main.new_cmo_comments(comments, None, [])
check("new_cmo_comments returns all CMO comments when no watermark",
      [c["id"] for c in got] == ["c2", "c3", "c5"])

# watermark at c2 => only later CMO comments
got = main.new_cmo_comments(comments, "c2", [])
check("new_cmo_comments respects watermark", [c["id"] for c in got] == ["c3", "c5"])

# bridge comment ids are excluded
got = main.new_cmo_comments(comments, "c2", ["c3"])
check("new_cmo_comments never relays bridge's own comments",
      [c["id"] for c in got] == ["c5"])

# watermark at newest => nothing new
got = main.new_cmo_comments(comments, "c5", [])
check("new_cmo_comments returns empty when caught up", got == [])

# non-CMO authors never relayed
got = main.new_cmo_comments(comments, None, [])
check("new_cmo_comments excludes non-CMO authors",
      all(c["authorAgentId"] == "cmo-agent-test" for c in got))

# ── state load/save round-trip ──
st = main.load_state()
check("fresh state has expected keys",
      set(["tg_offset", "seen_update_ids", "update_to_issue", "chats"]).issubset(st.keys()))

chat = main.get_chat(st, "chat-1")
check("get_chat creates a chat with default keys",
      chat.get("active_issue_id") is None and "bridge_comment_ids" in chat)

chat["active_issue_id"] = "issue-999"
chat["last_relayed_comment_id"] = "c2"
st["tg_offset"] = 42
main.save_state(st)

st2 = main.load_state()
check("state persisted tg_offset", st2.get("tg_offset") == 42)
check("state persisted active issue",
      st2["chats"]["chat-1"]["active_issue_id"] == "issue-999")
check("state persisted watermark",
      st2["chats"]["chat-1"]["last_relayed_comment_id"] == "c2")

# get_chat backfills new keys on old state shape
st2["chats"]["legacy"] = {"active_issue_id": "x"}
legacy = main.get_chat(st2, "legacy")
check("get_chat backfills missing keys on legacy chat",
      "awaiting_changes" in legacy and legacy["active_issue_id"] == "x")

# corrupt state file => fresh
with open(main.STATE_FILE, "w") as f:
    f.write("{not valid json")
st3 = main.load_state()
check("corrupt state file => fresh state", st3 == main._empty_state())

# ── approve keyboard shape ──
kb = main.approve_keyboard("issue-77")
buttons = kb["inline_keyboard"][0]
check("approve_keyboard has approve+changes callbacks",
      buttons[0]["callback_data"] == "approve:issue-77"
      and buttons[1]["callback_data"] == "changes:issue-77")

print()
print(f"{PASSED} passed, {FAILED} failed")
sys.exit(1 if FAILED else 0)
