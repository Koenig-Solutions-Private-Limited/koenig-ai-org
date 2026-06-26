"""
Koenig CMO Bridge — Telegram <-> Paperclip CMO agent.

A VIP (Rohit Aggarwal) DMs the @CareerCompassbyKoenigbot Telegram bot; the bridge
relays the message to the Paperclip CMO agent as an issue (or a comment on the
active issue), streams the CMO's replies back, and lets the VIP approve / request
changes on DRAFT-FOR-APPROVAL drafts via inline buttons.

Architecture: DIRECT-ISSUE. No routine, no HMAC. Every inbound VIP message either
opens a new CMO issue or comments on the chat's currently-active issue. A relay
loop watermarks CMO-authored comments and pushes them back to Telegram; drafts get
an approve/changes inline keyboard (and an optional Resend email copy).

Runs as a small FastAPI service exposing /health, mirroring services/notifier.

Environment (sourced from .env.koenig):
- CMO_BRIDGE_BOT_TOKEN     — Telegram bot token (ONLY this name; never TELEGRAM_BOT_TOKEN)
- CMO_BRIDGE_WHITELIST     — comma-separated Telegram numeric user ids (Rohit + Vardaan)
- PAPERCLIP_API_KEY        — Bearer token for Paperclip API
- PAPERCLIP_API_URL        — default http://localhost:3100/api
- PAPERCLIP_COMPANY_ID     — default 2a77f89b-33f0-4133-a20c-77ddaac5e744
- CMO_AGENT_ID             — default 3b3b293d-b47d-40e2-939c-9a19894b0996
- CEO_AGENT_ID             — default 5a1e1c39-1ba7-46af-a4df-c6bbef8549e9
- CMO_PROJECT_ID           — default 39c1cb6a-3ae6-43b5-9fb7-e7a869dd8598
- RESEND_API_KEY           — optional, to email drafts
- CMO_FROM_EMAIL           — e.g. "Koenig CMO <cmo@kspl.tech>"
- ROHIT_EMAIL              — draft recipient; empty => skip email, Telegram only
- CMO_BRIDGE_STATE_DIR     — default services/cmo-bridge/.state
- CMO_BRIDGE_PORT          — default 8301
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import Any

import httpx
from fastapi import FastAPI

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")
log = logging.getLogger("cmo-bridge")

# ───────────────────────────── config ─────────────────────────────
BOT_TOKEN = os.getenv("CMO_BRIDGE_BOT_TOKEN", "").strip()
WHITELIST_RAW = os.getenv("CMO_BRIDGE_WHITELIST", "")
PAPERCLIP_API_URL = os.getenv("PAPERCLIP_API_URL", "http://localhost:3100/api").rstrip("/")
PAPERCLIP_API_KEY = os.getenv("PAPERCLIP_API_KEY", "").strip()
COMPANY_ID = os.getenv("PAPERCLIP_COMPANY_ID", "2a77f89b-33f0-4133-a20c-77ddaac5e744")
CMO_AGENT_ID = os.getenv("CMO_AGENT_ID", "3b3b293d-b47d-40e2-939c-9a19894b0996")
CEO_AGENT_ID = os.getenv("CEO_AGENT_ID", "5a1e1c39-1ba7-46af-a4df-c6bbef8549e9")
CMO_PROJECT_ID = os.getenv("CMO_PROJECT_ID", "39c1cb6a-3ae6-43b5-9fb7-e7a869dd8598")

RESEND_API_KEY = os.getenv("RESEND_API_KEY", "").strip()
CMO_FROM_EMAIL = os.getenv("CMO_FROM_EMAIL", "Koenig CMO <cmo@kspl.tech>").strip()
ROHIT_EMAIL = os.getenv("ROHIT_EMAIL", "").strip()

STATE_DIR = Path(os.getenv("CMO_BRIDGE_STATE_DIR", "services/cmo-bridge/.state"))
STATE_FILE = STATE_DIR / "state.json"
PORT = int(os.getenv("CMO_BRIDGE_PORT", "8301"))

RELAY_TICK_SECONDS = int(os.getenv("CMO_BRIDGE_RELAY_TICK", "15"))
DRAFT_MARKER = "DRAFT-FOR-APPROVAL:"
DONE_STATES = {"done", "cancelled"}

TG_API = f"https://api.telegram.org/bot{BOT_TOKEN}" if BOT_TOKEN else None

app = FastAPI(title="Koenig CMO Bridge", version="0.1.0")


# ───────────────────────────── pure helpers ─────────────────────────────
def parse_whitelist(raw: str) -> set[str]:
    """Comma-separated Telegram numeric ids -> set of stringified ids."""
    out: set[str] = set()
    for piece in (raw or "").replace(";", ",").split(","):
        p = piece.strip()
        if p:
            out.add(p)
    return out


WHITELIST = parse_whitelist(WHITELIST_RAW)


def is_whitelisted(user_id: Any) -> bool:
    """Empty whitelist => capture mode: nobody is actioned beyond /start."""
    if not WHITELIST:
        return False
    return str(user_id) in WHITELIST


def is_draft_comment(body: str) -> bool:
    return (body or "").lstrip().startswith(DRAFT_MARKER)


def draft_subject(body: str) -> str:
    """Extract the subject following the DRAFT-FOR-APPROVAL: marker (first line)."""
    text = (body or "").lstrip()
    if text.startswith(DRAFT_MARKER):
        text = text[len(DRAFT_MARKER):]
    first_line = text.strip().splitlines()[0] if text.strip() else "Draft"
    return first_line.strip()[:200] or "Draft"


def parse_callback_data(data: str) -> tuple[str, str]:
    """'approve:<issue_id>' -> ('approve', '<issue_id>'). Unknown -> ('', '')."""
    if not data or ":" not in data:
        return ("", "")
    action, _, issue_id = data.partition(":")
    action = action.strip()
    issue_id = issue_id.strip()
    if action not in ("approve", "changes") or not issue_id:
        return ("", "")
    return (action, issue_id)


def agent_mention(agent_id: str, display: str = "CMO") -> str:
    """Machine-authored structured mention that wakes the target agent."""
    return f"[@{display}](agent://{agent_id})"


def new_cmo_comments(
    comments: list[dict[str, Any]],
    last_relayed_id: str | None,
    bridge_comment_ids: list[str],
) -> list[dict[str, Any]]:
    """Filter to CMO-authored comments newer than the watermark, never bridge's own.

    Watermark = id of the last comment we relayed. We walk the (chronological)
    comment list and return everything authored by the CMO that appears after the
    watermark. If the watermark id is absent (e.g. comment deleted), we fall back
    to relaying nothing-prior — only comments we have not seen by id.
    """
    bridge_set = set(bridge_comment_ids or [])
    seen_watermark = last_relayed_id is None
    out: list[dict[str, Any]] = []
    for c in comments:
        cid = str(c.get("id", ""))
        if not seen_watermark:
            if cid == str(last_relayed_id):
                seen_watermark = True
            continue
        if cid in bridge_set:
            continue
        if str(c.get("authorAgentId") or "") != CMO_AGENT_ID:
            continue
        out.append(c)
    return out


# ───────────────────────────── state ─────────────────────────────
def _empty_state() -> dict[str, Any]:
    return {
        "tg_offset": 0,
        "seen_update_ids": [],          # dedup of processed update_ids
        "update_to_issue": {},          # update_id -> issue_id (idempotency)
        "chats": {},                    # chat_id -> per-chat state
    }


def _empty_chat() -> dict[str, Any]:
    return {
        "active_issue_id": None,
        "last_relayed_comment_id": None,
        "bridge_comment_ids": [],       # comment ids the bridge itself posted
        "awaiting_changes": False,
        "pending_draft": None,          # {issue_id, subject, message_id}
        "last_status": None,
    }


def load_state() -> dict[str, Any]:
    if STATE_FILE.exists():
        try:
            data = json.loads(STATE_FILE.read_text())
            base = _empty_state()
            base.update(data or {})
            return base
        except Exception:
            log.warning("state file corrupt; starting fresh")
    return _empty_state()


def save_state(state: dict[str, Any]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2))
    tmp.replace(STATE_FILE)


def get_chat(state: dict[str, Any], chat_id: str) -> dict[str, Any]:
    chats = state.setdefault("chats", {})
    if chat_id not in chats:
        chats[chat_id] = _empty_chat()
    else:
        # backfill any new keys on older state
        base = _empty_chat()
        base.update(chats[chat_id])
        chats[chat_id] = base
    return chats[chat_id]


# ───────────────────────────── Telegram I/O ─────────────────────────────
async def tg_send(chat_id: str, text: str, *, reply_markup: dict | None = None,
                  parse_mode: str = "Markdown") -> dict[str, Any] | None:
    if not TG_API:
        log.info("[no bot token] would send to %s: %s", chat_id, text[:200])
        return None
    payload: dict[str, Any] = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": parse_mode,
        "disable_web_page_preview": True,
    }
    if reply_markup is not None:
        payload["reply_markup"] = reply_markup
    async with httpx.AsyncClient(timeout=15) as c:
        try:
            r = await c.post(f"{TG_API}/sendMessage", json=payload)
            if r.status_code != 200:
                log.warning("telegram send %s: %s", r.status_code, r.text[:300])
                return None
            return (r.json() or {}).get("result")
        except Exception as e:
            log.exception("telegram send failed: %s", e)
            return None


async def tg_edit_reply_markup(chat_id: str, message_id: int, reply_markup: dict | None) -> None:
    if not TG_API:
        return
    async with httpx.AsyncClient(timeout=15) as c:
        try:
            await c.post(
                f"{TG_API}/editMessageReplyMarkup",
                json={"chat_id": chat_id, "message_id": message_id,
                      "reply_markup": reply_markup or {"inline_keyboard": []}},
            )
        except Exception as e:
            log.warning("telegram edit markup failed: %s", e)


async def tg_answer_callback(callback_id: str, text: str = "") -> None:
    if not TG_API:
        return
    async with httpx.AsyncClient(timeout=10) as c:
        try:
            await c.post(f"{TG_API}/answerCallbackQuery",
                         json={"callback_query_id": callback_id, "text": text})
        except Exception as e:
            log.warning("telegram answerCallback failed: %s", e)


async def tg_set_commands() -> None:
    if not TG_API:
        return
    commands = [
        {"command": "start", "description": "Greet / register this chat"},
        {"command": "status", "description": "Active CMO issue status + latest reply"},
        {"command": "ask", "description": "Ask the CMO something"},
        {"command": "draft", "description": "Ask the CMO for a draft to approve"},
        {"command": "approve", "description": "Approve the pending draft"},
        {"command": "changes", "description": "Request changes (/changes <text>)"},
        {"command": "help", "description": "Show help"},
    ]
    async with httpx.AsyncClient(timeout=10) as c:
        try:
            await c.post(f"{TG_API}/setMyCommands", json={"commands": commands})
        except Exception as e:
            log.warning("setMyCommands failed: %s", e)


def approve_keyboard(issue_id: str) -> dict[str, Any]:
    return {
        "inline_keyboard": [[
            {"text": "✅ Approve", "callback_data": f"approve:{issue_id}"},
            {"text": "✏️ Request changes", "callback_data": f"changes:{issue_id}"},
        ]]
    }


# ───────────────────────────── Paperclip API ─────────────────────────────
def _headers(json_body: bool = False) -> dict[str, str]:
    h = {}
    if PAPERCLIP_API_KEY:
        h["Authorization"] = f"Bearer {PAPERCLIP_API_KEY}"
    if json_body:
        h["Content-Type"] = "application/json"
    return h


async def pc_create_issue(title: str, description: str) -> dict[str, Any] | None:
    url = f"{PAPERCLIP_API_URL}/companies/{COMPANY_ID}/issues"
    body = {
        "title": title[:200],
        "description": description,
        "assigneeAgentId": CMO_AGENT_ID,
        "projectId": CMO_PROJECT_ID,
        "status": "todo",
        "priority": "high",
    }
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.post(url, json=body, headers=_headers(json_body=True))
            if r.status_code >= 400:
                log.warning("create issue %s: %s", r.status_code, r.text[:300])
                return None
            return r.json()
        except Exception as e:
            log.exception("create issue failed: %s", e)
            return None


async def pc_post_comment(issue_id: str, body_text: str) -> dict[str, Any] | None:
    url = f"{PAPERCLIP_API_URL}/issues/{issue_id}/comments"
    body = {"body": body_text, "authorAgentId": None}
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.post(url, json=body, headers=_headers(json_body=True))
            if r.status_code >= 400:
                log.warning("post comment %s: %s", r.status_code, r.text[:300])
                return None
            return r.json()
        except Exception as e:
            log.exception("post comment failed: %s", e)
            return None


async def pc_get_comments(issue_id: str) -> list[dict[str, Any]]:
    url = f"{PAPERCLIP_API_URL}/issues/{issue_id}/comments"
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.get(url, headers=_headers())
            if r.status_code >= 400:
                log.warning("get comments %s: %s", r.status_code, r.text[:200])
                return []
            data = r.json()
            return data if isinstance(data, list) else (data.get("comments") or [])
        except Exception as e:
            log.exception("get comments failed: %s", e)
            return []


async def pc_get_issue(issue_id: str) -> dict[str, Any] | None:
    url = f"{PAPERCLIP_API_URL}/issues/{issue_id}"
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.get(url, headers=_headers())
            if r.status_code >= 400:
                log.warning("get issue %s: %s", r.status_code, r.text[:200])
                return None
            return r.json()
        except Exception as e:
            log.exception("get issue failed: %s", e)
            return None


async def pc_patch_issue(issue_id: str, body: dict[str, Any]) -> dict[str, Any] | None:
    url = f"{PAPERCLIP_API_URL}/issues/{issue_id}"
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.patch(url, json=body, headers=_headers(json_body=True))
            if r.status_code >= 400:
                log.warning("patch issue %s: %s", r.status_code, r.text[:300])
                return None
            return r.json()
        except Exception as e:
            log.exception("patch issue failed: %s", e)
            return None


# ───────────────────────────── Resend ─────────────────────────────
async def send_draft_email(subject: str, text: str) -> bool:
    if not RESEND_API_KEY or not ROHIT_EMAIL:
        return False
    async with httpx.AsyncClient(timeout=20) as c:
        try:
            r = await c.post(
                "https://api.resend.com/emails",
                headers={"Authorization": f"Bearer {RESEND_API_KEY}",
                         "Content-Type": "application/json"},
                json={
                    "from": CMO_FROM_EMAIL,
                    "to": [ROHIT_EMAIL],
                    "subject": f"[Draft for approval] {subject}",
                    "text": text,
                },
            )
            if r.status_code >= 400:
                log.warning("resend send %s: %s", r.status_code, r.text[:300])
                return False
            return True
        except Exception as e:
            log.exception("resend send failed: %s", e)
            return False


# ───────────────────────────── inbound handling ─────────────────────────────
ACK = "Got it — routing to the CMO. I'll report back here."


async def route_inbound_text(state: dict[str, Any], chat_id: str, user_text: str,
                             update_id: int, is_draft: bool) -> None:
    """Comment on the active issue, or open a new CMO issue. Idempotent by update_id."""
    chat = get_chat(state, chat_id)
    update_key = str(update_id)

    # idempotency: same update already routed?
    if update_key in state.get("update_to_issue", {}):
        return

    active = chat.get("active_issue_id")
    # confirm the active issue is still open
    if active:
        issue = await pc_get_issue(active)
        if not issue or str(issue.get("status")) in DONE_STATES:
            active = None
            chat["active_issue_id"] = None

    mention = agent_mention(CMO_AGENT_ID)
    if active:
        body = f"{mention} Message from Rohit (via Telegram):\n\n{user_text}"
        if is_draft:
            body += ("\n\nPlease respond with a comment beginning "
                     "'DRAFT-FOR-APPROVAL: <subject>'.")
        res = await pc_post_comment(active, body)
        if res and res.get("id"):
            chat.setdefault("bridge_comment_ids", []).append(str(res["id"]))
        state["update_to_issue"][update_key] = active
    else:
        title = f"[VIP] {user_text[:60]}"
        desc = (
            f"{user_text}\n\n"
            "(Relayed from Rohit via Telegram. Coordinate your team; for client-facing "
            "copy, post a comment beginning 'DRAFT-FOR-APPROVAL: <subject>'.)"
        )
        if is_draft:
            desc += (
                "\n\nThis is an explicit DRAFT request: produce a client-facing draft and "
                "post it as a comment beginning 'DRAFT-FOR-APPROVAL: <subject>' so Rohit can "
                "approve it from Telegram."
            )
        issue = await pc_create_issue(title, desc)
        if not issue or not issue.get("id"):
            await tg_send(chat_id, "⚠️ Couldn't reach the CMO right now. Please try again shortly.")
            return
        issue_id = str(issue["id"])
        chat["active_issue_id"] = issue_id
        chat["last_relayed_comment_id"] = None
        chat["bridge_comment_ids"] = []
        state["update_to_issue"][update_key] = issue_id

    save_state(state)
    await tg_send(chat_id, ACK)


async def handle_message(state: dict[str, Any], msg: dict[str, Any], update_id: int) -> None:
    chat_id = str((msg.get("chat") or {}).get("id", ""))
    user_id = (msg.get("from") or {}).get("id")
    text = (msg.get("text") or "").strip()

    # /start is allowed even when not whitelisted (capture mode)
    if text.startswith("/start"):
        if not is_whitelisted(user_id):
            log.info("CAPTURE: /start from non-whitelisted telegram user_id=%s chat_id=%s "
                     "(add to CMO_BRIDGE_WHITELIST to enable)", user_id, chat_id)
            await tg_send(chat_id,
                          "👋 Hi! This is the Koenig CMO bridge. Your access is pending — "
                          f"your Telegram id is `{user_id}`. The operator will enable you shortly.")
            return
        await tg_send(chat_id,
                      "👋 Connected to the Koenig CMO. Send a message or use /ask, /draft, "
                      "/status, /help.")
        return

    if not is_whitelisted(user_id):
        log.info("ignoring message from non-whitelisted telegram user_id=%s", user_id)
        return

    chat = get_chat(state, chat_id)

    # slash commands
    if text.startswith("/"):
        cmd, _, arg = text[1:].partition(" ")
        cmd = cmd.lower()
        arg = arg.strip()
        if cmd == "help":
            await tg_send(chat_id, HELP_TEXT)
            return
        if cmd == "status":
            await cmd_status(state, chat_id)
            return
        if cmd == "approve":
            await approve_pending(state, chat_id)
            return
        if cmd == "changes":
            if not arg:
                chat["awaiting_changes"] = True
                save_state(state)
                await tg_send(chat_id, "Okay — send your change request as the next message.")
                return
            await apply_changes(state, chat_id, arg)
            return
        if cmd in ("ask", "draft"):
            if not arg:
                await tg_send(chat_id, f"Usage: /{cmd} <your message>")
                return
            await route_inbound_text(state, chat_id, arg, update_id, is_draft=(cmd == "draft"))
            return
        await tg_send(chat_id, f"Unknown command: /{cmd}. Try /help.")
        return

    if not text:
        return

    # awaiting a change request (after pressing ✏️ Request changes)
    if chat.get("awaiting_changes"):
        chat["awaiting_changes"] = False
        save_state(state)
        await apply_changes(state, chat_id, text)
        return

    # plain text => route as ask
    await route_inbound_text(state, chat_id, text, update_id, is_draft=False)


async def cmd_status(state: dict[str, Any], chat_id: str) -> None:
    chat = get_chat(state, chat_id)
    active = chat.get("active_issue_id")
    if not active:
        await tg_send(chat_id, "No active CMO request. Send a message or /ask <text> to start one.")
        return
    issue = await pc_get_issue(active)
    if not issue:
        await tg_send(chat_id, "Couldn't fetch the active issue right now.")
        return
    ident = issue.get("identifier") or active
    status = issue.get("status", "?")
    comments = await pc_get_comments(active)
    latest = ""
    for c in reversed(comments):
        if str(c.get("authorAgentId") or "") == CMO_AGENT_ID:
            latest = (c.get("body") or "").strip()[:500]
            break
    msg = f"*[{ident}]* status: `{status}`"
    if latest:
        msg += f"\n\n_Latest from CMO:_\n{latest}"
    await tg_send(chat_id, msg)


async def approve_pending(state: dict[str, Any], chat_id: str) -> None:
    chat = get_chat(state, chat_id)
    pending = chat.get("pending_draft")
    issue_id = (pending or {}).get("issue_id") or chat.get("active_issue_id")
    if not issue_id:
        await tg_send(chat_id, "No pending draft to approve.")
        return
    await do_approve(state, chat_id, issue_id)


async def do_approve(state: dict[str, Any], chat_id: str, issue_id: str) -> None:
    chat = get_chat(state, chat_id)
    res = await pc_patch_issue(issue_id, {"status": "done",
                                          "comment": "Approved by Rohit via Telegram."})
    pending = chat.get("pending_draft") or {}
    if pending.get("issue_id") == issue_id and pending.get("message_id"):
        await tg_edit_reply_markup(chat_id, pending["message_id"], None)
    chat["pending_draft"] = None
    if chat.get("active_issue_id") == issue_id:
        chat["active_issue_id"] = None
        chat["last_relayed_comment_id"] = None
    save_state(state)
    if res is not None:
        await tg_send(chat_id, "✅ Approved — the CMO will proceed.")
    else:
        await tg_send(chat_id, "⚠️ Approval recorded locally but the CMO API call failed. Retry /approve.")


async def apply_changes(state: dict[str, Any], chat_id: str, change_text: str) -> None:
    chat = get_chat(state, chat_id)
    pending = chat.get("pending_draft") or {}
    issue_id = pending.get("issue_id") or chat.get("active_issue_id")
    if not issue_id:
        await tg_send(chat_id, "No active draft/issue to send changes to.")
        return
    res = await pc_patch_issue(
        issue_id,
        {"status": "in_progress",
         "comment": f"Change request from Rohit: {change_text}\n\n{agent_mention(CMO_AGENT_ID)}"},
    )
    if pending.get("issue_id") == issue_id and pending.get("message_id"):
        await tg_edit_reply_markup(chat_id, pending["message_id"], None)
    chat["pending_draft"] = None
    save_state(state)
    if res is not None:
        await tg_send(chat_id, "✏️ Sent your change request to the CMO.")
    else:
        await tg_send(chat_id, "⚠️ Couldn't reach the CMO to send changes. Try again.")


async def handle_callback(state: dict[str, Any], cb: dict[str, Any]) -> None:
    user_id = (cb.get("from") or {}).get("id")
    callback_id = cb.get("id", "")
    data = cb.get("data", "")
    msg = cb.get("message") or {}
    chat_id = str((msg.get("chat") or {}).get("id", ""))

    if not is_whitelisted(user_id):
        log.info("ignoring callback from non-whitelisted telegram user_id=%s", user_id)
        await tg_answer_callback(callback_id, "Not authorized.")
        return

    action, issue_id = parse_callback_data(data)
    if not action:
        await tg_answer_callback(callback_id, "Unrecognized action.")
        return

    if action == "approve":
        await tg_answer_callback(callback_id, "Approving…")
        await do_approve(state, chat_id, issue_id)
    elif action == "changes":
        chat = get_chat(state, chat_id)
        chat["awaiting_changes"] = True
        # ensure subsequent change text targets this issue
        pending = chat.get("pending_draft") or {}
        if not pending.get("issue_id"):
            chat["pending_draft"] = {"issue_id": issue_id,
                                     "subject": pending.get("subject", ""),
                                     "message_id": msg.get("message_id")}
        save_state(state)
        await tg_answer_callback(callback_id, "Send your changes")
        await tg_send(chat_id, "✏️ Send your change request as the next message.")


# ───────────────────────────── relay loop ─────────────────────────────
async def relay_tick(state: dict[str, Any]) -> None:
    """For each chat with an active issue, push new CMO comments back to Telegram."""
    for chat_id, chat in list(state.get("chats", {}).items()):
        active = chat.get("active_issue_id")
        if not active:
            continue
        issue = await pc_get_issue(active)
        if not issue:
            continue
        status = str(issue.get("status", ""))
        ident = issue.get("identifier") or active

        comments = await pc_get_comments(active)
        fresh = new_cmo_comments(comments, chat.get("last_relayed_comment_id"),
                                 chat.get("bridge_comment_ids", []))
        for c in fresh:
            body = (c.get("body") or "").strip()
            if is_draft_comment(body):
                subject = draft_subject(body)
                emailed = await send_draft_email(subject, body)
                sent = await tg_send(
                    chat_id,
                    f"📝 *Draft for approval* — {subject}\n\n{body[:3500]}"
                    + ("\n\n_(also emailed to you)_" if emailed else ""),
                    reply_markup=approve_keyboard(active),
                )
                chat["pending_draft"] = {
                    "issue_id": active,
                    "subject": subject,
                    "message_id": (sent or {}).get("message_id"),
                }
            else:
                await tg_send(chat_id, f"💬 *CMO* on [{ident}]:\n\n{body[:3800]}")
            chat["last_relayed_comment_id"] = str(c.get("id"))

        # surface status transitions
        prev_status = chat.get("last_status")
        if status != prev_status:
            if status == "blocked":
                await tg_send(chat_id, f"🚫 [{ident}] is *blocked* — the CMO needs input.")
            elif status in DONE_STATES:
                await tg_send(chat_id, f"🏁 [{ident}] is *{status}*. Closing this thread.")
                chat["active_issue_id"] = None
                chat["last_relayed_comment_id"] = None
                chat["pending_draft"] = None
            chat["last_status"] = status

        save_state(state)


async def relay_loop() -> None:
    state = STATE
    log.info("relay loop started (tick=%ss)", RELAY_TICK_SECONDS)
    while True:
        try:
            await relay_tick(state)
        except Exception as e:
            log.exception("relay tick failed: %s", e)
        await asyncio.sleep(RELAY_TICK_SECONDS)


# ───────────────────────────── telegram poll loop ─────────────────────────────
async def telegram_poll_loop() -> None:
    if not TG_API:
        log.warning("telegram poll DISABLED (CMO_BRIDGE_BOT_TOKEN not set)")
        return
    state = STATE
    await tg_set_commands()
    log.info("telegram getUpdates poll started")
    while True:
        try:
            async with httpx.AsyncClient(timeout=40) as c:
                r = await c.get(
                    f"{TG_API}/getUpdates",
                    params={"offset": state.get("tg_offset", 0) + 1, "timeout": 30,
                            "allowed_updates": json.dumps(["message", "callback_query"])},
                )
                if r.status_code != 200:
                    log.warning("getUpdates %s: %s", r.status_code, r.text[:200])
                    await asyncio.sleep(3)
                    continue
                data = r.json() or {}
                for upd in data.get("result", []):
                    uid = upd.get("update_id", 0)
                    state["tg_offset"] = max(state.get("tg_offset", 0), uid)
                    seen = state.setdefault("seen_update_ids", [])
                    if uid in seen:
                        continue
                    seen.append(uid)
                    if len(seen) > 1000:
                        del seen[:-1000]
                    try:
                        if "message" in upd:
                            await handle_message(state, upd["message"], uid)
                        elif "callback_query" in upd:
                            await handle_callback(state, upd["callback_query"])
                    except Exception as e:
                        log.exception("handling update %s failed: %s", uid, e)
                    save_state(state)
        except httpx.ReadTimeout:
            continue
        except Exception as e:
            log.warning("telegram poll error: %s", e)
            await asyncio.sleep(5)
        await asyncio.sleep(0.5)


HELP_TEXT = (
    "*Koenig CMO Bridge*\n\n"
    "Just message me and I'll route it to the CMO. Commands:\n"
    "  /ask <text> — ask the CMO\n"
    "  /draft <text> — ask for a draft to approve\n"
    "  /status — active request status + latest CMO reply\n"
    "  /approve — approve the pending draft\n"
    "  /changes <text> — request changes\n"
    "  /help — this menu\n\n"
    "Drafts arrive with ✅ Approve / ✏️ Request changes buttons."
)


# ───────────────────────────── FastAPI ─────────────────────────────
STATE: dict[str, Any] = load_state()


@app.get("/health")
async def health() -> dict[str, Any]:
    active_chats = sum(
        1 for ch in STATE.get("chats", {}).values() if ch.get("active_issue_id")
    )
    return {
        "status": "ok",
        "telegram_configured": bool(TG_API),
        "whitelist_count": len(WHITELIST),
        "active_chats": active_chats,
    }


@app.on_event("startup")
async def on_startup() -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    asyncio.create_task(telegram_poll_loop())
    asyncio.create_task(relay_loop())
    log.info("CMO bridge startup complete — paperclip=%s company=%s telegram=%s whitelist=%d",
             PAPERCLIP_API_URL, COMPANY_ID, "configured" if TG_API else "DISABLED", len(WHITELIST))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=PORT)
