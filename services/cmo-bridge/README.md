# Koenig CMO Bridge

Telegram ↔ Paperclip CMO bridge. A VIP (Rohit Aggarwal) DMs the
**@CareerCompassbyKoenigbot** Telegram bot; the bridge routes the message to the
Paperclip **CMO agent** as an issue (or as a comment on the chat's active issue),
streams the CMO's replies back, and lets the VIP **approve / request changes** on
drafts via inline buttons. Optional email copy of drafts via Resend.

Architecture is **DIRECT-ISSUE**: no routine, no HMAC. Mirrors `services/notifier`
(httpx + asyncio + FastAPI long-poll, JSON-file state, Bearer auth helpers).

## How it works

1. **Long-poll** `getUpdates` (offset persisted, dedup by `update_id`,
   `allowed_updates=["message","callback_query"]`).
2. **Whitelist gate** on every message + callback by `from.id`. Non-whitelisted are
   logged and ignored — except `/start`, which always replies (capture mode).
3. **Inbound text / `/ask` / `/draft`**: if the chat has an open CMO issue, post a
   comment to it (with a structured `[@CMO](agent://…)` mention to wake the agent);
   otherwise create a new `[VIP] …` issue assigned to the CMO in the CMO project,
   `status=todo priority=high`. Replies "Got it — routing to the CMO…".
4. **Relay loop** (~15 s): for each chat's active issue, fetch comments, relay new
   **CMO-authored** comments (watermarked; never the bridge's own). Comments starting
   `DRAFT-FOR-APPROVAL:` render as a draft with ✅ Approve / ✏️ Request changes
   buttons (and an emailed copy if configured). Status transitions (blocked/done) are
   surfaced and the thread closes on done/cancelled.
5. **Callbacks**: `approve:<id>` → PATCH issue `done` + comment, strip buttons.
   `changes:<id>` → next free-text message becomes the change request → PATCH
   `in_progress` + comment.
6. **Commands** (`setMyCommands` on startup): `/start /status /ask /draft /approve
   /changes /help`. CEO escalation is internal to the CMO (no `/ceo`).
7. **FastAPI** `/health` on `127.0.0.1:CMO_BRIDGE_PORT` →
   `{status, telegram_configured, whitelist_count, active_chats}`.

## Environment variables (sourced from `.env.koenig`)

| Var | Required | Default | Notes |
|---|---|---|---|
| `CMO_BRIDGE_BOT_TOKEN` | yes | — | Telegram token for @CareerCompassbyKoenigbot. **Read only this name**, never `TELEGRAM_BOT_TOKEN` (ambiguous in .env.koenig). |
| `CMO_BRIDGE_WHITELIST` | yes | — | Comma-separated Telegram **numeric user ids** (Rohit + Vardaan). Empty ⇒ capture mode. |
| `PAPERCLIP_API_KEY` | yes | — | Bearer token. |
| `PAPERCLIP_API_URL` | no | `http://localhost:3100/api` | |
| `PAPERCLIP_COMPANY_ID` | no | `2a77f89b-33f0-4133-a20c-77ddaac5e744` | |
| `CMO_AGENT_ID` | no | `3b3b293d-b47d-40e2-939c-9a19894b0996` | |
| `CEO_AGENT_ID` | no | `5a1e1c39-1ba7-46af-a4df-c6bbef8549e9` | |
| `CMO_PROJECT_ID` | no | `39c1cb6a-3ae6-43b5-9fb7-e7a869dd8598` | |
| `RESEND_API_KEY` | no | — | If set with `ROHIT_EMAIL`, drafts are emailed. |
| `CMO_FROM_EMAIL` | no | `Koenig CMO <cmo@kspl.tech>` | Must be a verified Resend sender. |
| `ROHIT_EMAIL` | no | — | Draft recipient. Empty ⇒ Telegram only. |
| `CMO_BRIDGE_STATE_DIR` | no | `services/cmo-bridge/.state` | |
| `CMO_BRIDGE_PORT` | no | `8301` | |

## Operator setup (one-time, before go-live)

1. **Get Rohit's Telegram id**: have Rohit DM `@CareerCompassbyKoenigbot` with
   `/start`. The service logs `CAPTURE: /start from non-whitelisted telegram
   user_id=<id>` (and replies with his id). Add that id (and Vardaan's) to
   `CMO_BRIDGE_WHITELIST` in `.env.koenig`.
2. **Resend sender**: verify `cmo@kspl.tech` (or your `CMO_FROM_EMAIL`) as a sender
   in Resend so draft emails deliver. Set `RESEND_API_KEY` and `ROHIT_EMAIL`.
   (Leave `ROHIT_EMAIL` empty to skip email and use Telegram only.)
3. **Append env keys** to `.env.koenig` (exact names):
   ```
   CMO_BRIDGE_BOT_TOKEN=<telegram token for @CareerCompassbyKoenigbot>
   CMO_BRIDGE_WHITELIST=<rohit_telegram_id>,<vardaan_telegram_id>
   ROHIT_EMAIL=<rohit's email or leave empty>
   # PAPERCLIP_API_KEY / RESEND_API_KEY / CMO_FROM_EMAIL likely already present
   ```

## Run locally

```sh
cd /Users/vardaankoenig/Documents/Paperclip/koenig-ai-org/services/cmo-bridge
python3 -m venv .venv && .venv/bin/pip install -q -r requirements.txt
set -a; . ../../.env.koenig 2>/dev/null; set +a
.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8301
# health: curl -s http://127.0.0.1:8301/health
```

## Run via launchd

```sh
cp infra/launchd/com.koenig.cmo-bridge.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.koenig.cmo-bridge.plist
# logs: infra/launchd/.logs/cmo-bridge.{out,err}.log
```
The plist `cd`s into `services/cmo-bridge`, sources `.env.koenig` (`set -a; . …`),
creates the venv on first run, and starts uvicorn on 127.0.0.1:8301 with
RunAtLoad + KeepAlive.

## Test (dry-run, no network)

```sh
python3 test_selftest.py   # exercises pure helpers + state; prints PASS/FAIL
```

## State

Persisted at `${CMO_BRIDGE_STATE_DIR}/state.json`: Telegram offset, processed
`update_id`s, `update_id → issue_id` idempotency map, and per-chat active issue +
comment watermark + pending draft. Safe across restarts.
