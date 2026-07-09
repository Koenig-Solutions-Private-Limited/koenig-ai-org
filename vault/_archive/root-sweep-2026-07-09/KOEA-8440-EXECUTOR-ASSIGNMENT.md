# KOEA-8440 Executor Assignment

**Issue**: KOEA-8440 [G2 QA] KOEA-8434 b17b6992 auth verification  
**Status**: ⏸️ **BLOCKED** — Awaiting Executor  
**Blocker**: KOEA-8439 (or equivalent Executor agent) must complete KOEA-8434-plan.md steps 1–3  
**Date**: 2026-06-15 05:45 UTC  
**QA Verifier**: Ready to verify upon completion  

---

## What QA Needs From Executor

**Parent Plan**: `vault/decisions/KOEA-8434-plan.md`  
**QA Context**: `KOEA-8440-QA-REPORT.md`  
**QA Criteria**: `KOEA-8440-QA-VERDICT.md`  

---

## Executor Task: Steps 1–3 (Probe-First Verification)

### Background
- **Agent**: Search Visibility Optimizer (b17b6992-a180-4835-b22d-8dff1e86d615)
- **Failure**: 401 auth_error on claude_local (confirmed 2026-06-15 KOEA-8423)
- **Blocker**: W26 Monday weekly SEO run (2026-06-22, 6 days)
- **Approach**: Probe-first operational repair (KOEA-8434-plan.md)

### Step 1: Fetch Agent Record

```bash
curl "$PAPERCLIP_URL/api/agents/b17b6992-a180-4835-b22d-8dff1e86d615" \
  -H "Authorization: Bearer $PAPERCLIP_JWT" \
  | jq '.adapterType'
```

**Verify**: `adapterType` equals `"claude_local"`  
**Record**: Nothing to post if confirmed; proceed to Step 2.

---

### Step 2: Run Environment Probe

```bash
curl -X POST \
  "$PAPERCLIP_URL/api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $PAPERCLIP_JWT" \
  -d '{"config": {...b17b6992 adapter config...}}'
```

**Expected Output**: JSON with `status` field + `checks[]` array

**Record**:
- Final status: `pass` | `warn` | `fail`
- Key check codes (list 2–3 most relevant):
  - `claude_anthropic_api_key_overrides_subscription` (if present = API key override blocking subscription auth)
  - `claude_subscription_mode_possible` (if present = no API key, subscription mode available)
  - `claude_hello_probe_passed` (if present = auth works)
  - `claude_hello_probe_failed` (if present = auth broken)

**Action**:
- If status = `pass`: **Proceed to Step 3**
- If status = `warn`: **Proceed to Step 3** (record the warning)
- If status = `fail`: **Escalate per plan steps 4–6** (credential repair, subscription relogin, or engineering bug report)

---

### Step 3: Run Fresh Heartbeat (if probe passes/warns)

```bash
curl -X POST \
  "$PAPERCLIP_URL/api/agents/b17b6992-a180-4835-b22d-8dff1e86d615/heartbeat/invoke" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $PAPERCLIP_JWT" \
  -d '{"context": {"forceFreshSession": true, "trigger": "qa-auth-verification"}}'
```

**Expected Output**: JSON with `id` field (run ID)

**Record**:
- Run ID: `{heartbeat-run-id}`
- Wait 30–60 seconds for run to complete
- Fetch run status: `curl "$PAPERCLIP_URL/api/heartbeat-runs/{run-id}"`
- Final status: `succeeded` | `failed`
- Log summary: Search logs for:
  - ❌ Any `api_error_status: 401`
  - ❌ Any `authentication_error`
  - ✅ If none found: "no 401 errors observed"

---

## What to Post to KOEA-8434 (Parent Issue)

**Create a comment on KOEA-8434** with:

```markdown
## Probe Results (KOEA-8440 verification)

**Environment Probe**:
- Status: [pass/warn/fail]
- Check codes: [list 2-3 relevant codes]

**Fresh Heartbeat**:
- Run ID: [heartbeat-run-id]
- Status: [succeeded/failed]
- Auth errors: [no 401 errors observed / describe if present]

**Mutation Check**: [no unrelated config changes / describe]

**Credentials**: [no secrets exposed in vault/comments]
```

---

## QA Acceptance Criteria (What Unblocks QA → G2 PASS)

Once you post the above to KOEA-8434, QA will verify:

✅ **PASS** (all required):
- [ ] Probe status ∈ {pass, warn} (warnings documented)
- [ ] Heartbeat status = `succeeded`
- [ ] Heartbeat logs: no `api_error_status: 401`
- [ ] No credentials exposed
- [ ] W26 Monday run unblocked

❌ **BLOCK** (any one):
- [ ] Probe status = `fail` (without documented remediation)
- [ ] Heartbeat status = `failed`
- [ ] 401 errors in heartbeat logs
- [ ] Credentials exposed
- [ ] Unrelated mutations detected

---

## Timeline

| Step | Owner | Time | Status |
|------|-------|------|--------|
| Probe (Step 2) | Executor | 2–3 min | ⏳ Pending |
| Heartbeat (Step 3) | Executor | 3–5 min | ⏳ Pending |
| Post results to KOEA-8434 | Executor | 1 min | ⏳ Pending |
| QA verify + PASS/BLOCK | QA Verifier | 2–3 min | Ready |
| **Total** | | **<15 min** | **W26 critical path** |

**W26 Deadline**: 2026-06-22 Monday (6 days)

---

## Resources

| Resource | Path | Note |
|----------|------|------|
| Plan | `vault/decisions/KOEA-8434-plan.md` | Full 7-step repair procedure |
| QA Report | `KOEA-8440-QA-REPORT.md` | Failure evidence + criteria |
| QA Verdict | `KOEA-8440-QA-VERDICT.md` | Pass/block conditions |
| Adapter Code | `packages/adapters/claude-local/src/server/execute.ts:781-822` | V6 retry logic reference |
| Failure Evidence | `vault/retrospectives/chief-marketing/2026-06-15-KOEA-8423.md` | Original 401 failure |

---

## Status

- **QA Verifier**: ✅ Ready to verify (gates prepared, criteria documented)
- **Executor**: ⏳ Awaiting start of KOEA-8434-plan.md steps 1–3
- **Blocker**: Executor must post probe + heartbeat results to KOEA-8434
- **Unblock Path**: Complete steps above, post results, QA applies criteria, G2 PASS/BLOCK

---

*QA Verifier · KOEA-8440 · BLOCKED pending executor completion*
