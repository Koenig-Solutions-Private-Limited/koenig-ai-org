---
ticket: KOEA-6712
agent: Executor
author: operator (Claude Code session, V7 SEO/GEO Phase 2)
date: 2026-05-29
phase: implementation
estimated_minutes: 45
---

# KOEA-6712 plan — GSC domain-property OAuth setup

## Goal

Add `sc-domain:academy.kspl.tech` as an authenticated Google Search Console property so `seo-daily-anomaly` routine pulls domain-wide impressions / CTR / avg-position (currently URL-prefix only, which under-counts).

## Why this is blocked today

Search Visibility Optimizer's `seo-daily-anomaly` heartbeat reports authenticated against URL-prefix property `https://academy.kspl.tech/` but returns 403 when probing `sc-domain:academy.kspl.tech`. The OAuth client secret currently in use has only `https://www.googleapis.com/auth/webmasters.readonly` for the URL-prefix; we need the full `webmasters` scope + the domain property added to the GSC account itself.

## Procedure

### Phase A — verify current state (5 min)

```bash
# 1. Confirm current OAuth credential location inside paperclip-server
docker exec paperclip-server bash -c 'ls -la /paperclip/.secrets/ 2>/dev/null'
# Expect: gsc-client.json, gsc-token.json (and possibly stale gsc-token.json.bak)

# 2. Read scope on current token
docker exec paperclip-server bash -c 'python3 -c "import json; t=json.load(open(\"/paperclip/.secrets/gsc-token.json\")); print(t.get(\"scopes\") or t.get(\"scope\"))"'
# If returns only "...readonly" → confirm scope upgrade is needed
```

### Phase B — DNS verification of sc-domain property (5–10 min, USER ACTION REQUIRED)

This step requires Vardaan to add a TXT record to `kspl.tech` DNS. Executor: post a comment listing the exact TXT record value (from GSC), wait for operator confirmation, then proceed.

```bash
# 1. Go to https://search.google.com/search-console
# 2. Click "Add property" → choose "Domain"
# 3. Enter: academy.kspl.tech
# 4. GSC returns a TXT record like google-site-verification=AbCd1234...
# 5. Operator pastes that TXT into kspl.tech DNS (Cloudflare? whoever hosts kspl.tech)
# 6. Wait 10 min for propagation
# 7. Click "Verify" in GSC
```

**Executor: do NOT run gcloud or modify DNS yourself. Post the TXT value as a ticket comment for operator action.**

### Phase C — OAuth scope upgrade (15 min)

The existing `gsc-client.json` is a Web App OAuth client. We need to re-run the interactive auth flow with the full `webmasters` scope.

```bash
# 1. Back up current token
docker exec paperclip-server bash -c 'cp /paperclip/.secrets/gsc-token.json /paperclip/.secrets/gsc-token.json.bak-$(date +%Y%m%d)'

# 2. Write a Python bootstrap script (since the referenced gsc-oauth-setup.py
#    doesn't exist — Executor authors it now)
docker exec -u node paperclip-server bash -c "cat > /tmp/gsc-bootstrap-domain.py" <<'PY'
"""GSC OAuth bootstrap — refresh token with full webmasters scope."""
import os, sys
from google_auth_oauthlib.flow import InstalledAppFlow
from google.oauth2.credentials import Credentials
import google.auth.transport.requests as req

CLIENT_SECRET = "/paperclip/.secrets/gsc-client.json"
TOKEN_PATH = "/paperclip/.secrets/gsc-token.json"
SCOPES = ["https://www.googleapis.com/auth/webmasters"]

flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRET, SCOPES)
# Use console flow (no browser inside container)
creds = flow.run_local_server(port=0, open_browser=False)
with open(TOKEN_PATH, "w") as f:
    f.write(creds.to_json())
print(f"WROTE {TOKEN_PATH} with scopes={creds.scopes}")
PY

# 3. RUN INTERACTIVELY (operator must execute this, not Executor — needs browser):
#    docker exec -it -u node paperclip-server python3 /tmp/gsc-bootstrap-domain.py
# Executor: post a comment with this exact line + wait for operator confirmation that the token was written.

# 4. After operator confirms, verify scope:
docker exec paperclip-server bash -c 'python3 -c "import json; t=json.load(open(\"/paperclip/.secrets/gsc-token.json\")); print(\"scopes:\", t.get(\"scopes\") or t.get(\"scope\"))"'
# Expect: ['https://www.googleapis.com/auth/webmasters']
```

### Phase D — verify sc-domain reachable + add to seo-daily-anomaly (10 min)

```bash
# 1. Probe sc-domain via API
docker exec -u node paperclip-server bash -c "python3 <<'PY'
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
import json
creds = Credentials.from_authorized_user_file('/paperclip/.secrets/gsc-token.json')
svc = build('searchconsole', 'v1', credentials=creds)
sites = svc.sites().list().execute().get('siteEntry', [])
for s in sites:
    print(s['siteUrl'], s.get('permissionLevel'))
PY"
# Expect to see both 'https://academy.kspl.tech/' and 'sc-domain:academy.kspl.tech'

# 2. Probe a sample query on sc-domain
docker exec -u node paperclip-server bash -c "python3 <<'PY'
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
creds = Credentials.from_authorized_user_file('/paperclip/.secrets/gsc-token.json')
svc = build('searchconsole', 'v1', credentials=creds)
body = {'startDate': '2026-05-22', 'endDate': '2026-05-28', 'dimensions': ['query'], 'rowLimit': 10}
res = svc.searchanalytics().query(siteUrl='sc-domain:academy.kspl.tech', body=body).execute()
print('rows:', len(res.get('rows', [])))
for r in res.get('rows', [])[:5]:
    print(r)
PY"
# Expect rows >= 0 (any 200 response with no permission error confirms sc-domain works)
```

### Phase E — wire into seo-daily-anomaly routine (5 min)

The SEO Optimizer's daily routine reads `/paperclip/.secrets/gsc-token.json`. No code change needed; just patching the queried siteUrl from URL-prefix to sc-domain.

```bash
# Find the SEO Optimizer's daily script / config
docker exec paperclip-server bash -c 'find /paperclip/instances/default -name "*.py" -path "*seo*" 2>/dev/null | head -5'
# OR the routine description embedded in DB (if no script file):
docker exec paperclip-db psql -U paperclip -d paperclip -tAc "SELECT description FROM routines WHERE title='seo-daily-anomaly';"

# Edit so the GSC pull uses sc-domain:academy.kspl.tech as siteUrl.
# Commit any code change to koenig-ai-org or in-place AGENTS.md edit if it's instructional.
```

## Acceptance criteria

- [ ] `sc-domain:academy.kspl.tech` verified in GSC (Vardaan confirms via screenshot or `siteVerificationToken=…`)
- [ ] `/paperclip/.secrets/gsc-token.json` has scope `https://www.googleapis.com/auth/webmasters` (full read-write)
- [ ] `svc.sites().list()` returns BOTH URL-prefix and sc-domain entries with `permissionLevel=siteOwner` (or higher)
- [ ] `svc.searchanalytics().query(siteUrl='sc-domain:academy.kspl.tech', ...)` returns 200
- [ ] Next `seo-daily-anomaly` heartbeat output (vault/marketing/seo/<date>-daily-anomaly.md) includes sc-domain stats

## Exit invariant compliance

Executor: per AGENTS.md heartbeat exit invariants, this ticket has 3 valid exits:
1. **status=done** — all Phase A-E complete, acceptance criteria green
2. **status=blocked** — `unblock_owner=operator`, `unblock_action=run 'docker exec -it -u node paperclip-server python3 /tmp/gsc-bootstrap-domain.py' interactively then comment 'token written'`
3. **escalated** — file engineering_escalation to Chief Engineering if a Google API change breaks the bootstrap script

Do NOT exit `in_progress + comment-only`.

## Operator coordination

Two steps need operator action:
1. **DNS TXT record** for sc-domain verification (Phase B step 5)
2. **Interactive OAuth bootstrap** (Phase C step 3) — must be run from a TTY with browser access

For both: post a single comment with the exact required line + paste-ready content; operator will confirm completion in a reply comment. Then Executor resumes.
