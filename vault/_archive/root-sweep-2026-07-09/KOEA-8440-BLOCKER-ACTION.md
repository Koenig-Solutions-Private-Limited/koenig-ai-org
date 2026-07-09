# KOEA-8440 Blocker & Unblock Action

**Task**: G2 QA verification for KOEA-8434 auth fix  
**Status**: ⏸️ BLOCKED — Awaiting Executor probe results  
**Date**: 2026-06-15 05:36 UTC  

---

## Blocker Summary

**What QA needs to verify**: Search Visibility Optimizer (b17b6992) auth 401 fix is working.

**What blocks QA**: Executor (KOEA-8439 or equivalent) has not completed the probe and heartbeat steps outlined in KOEA-8434-plan.md.

**Evidence**: 
- No probe results posted on KOEA-8434
- No executor work committed to git
- No b17b6992 fresh heartbeat results in system

---

## Unblock Owner & Action

**Owner**: Executor / Chief Engineering (whoever runs KOEA-8439 / executes KOEA-8434-plan.md)

**Action Required**:

Run the KOEA-8434-plan.md steps 1–7:

### Step 1: Fetch Agent
```bash
curl "$PAPERCLIP_URL/api/agents/b17b6992-a180-4835-b22d-8dff1e86d615"
# Verify: adapterType=claude_local
```

### Step 2: Environment Probe
```bash
curl -X POST "$PAPERCLIP_URL/api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment" \
  -H 'Content-Type: application/json' \
  -d '{"config": {...agent config...}}'
# Record: final status + check codes
```

### Step 3: Fresh Heartbeat (if probe passes)
```bash
curl -X POST "$PAPERCLIP_URL/api/agents/b17b6992-a180-4835-b22d-8dff1e86d615/heartbeat/invoke" \
  -H 'Content-Type: application/json' \
  -d '{"context": {"forceFreshSession": true, "trigger": "qa-auth-verification"}}'
# Record: run ID + status + log summary
```

### Steps 4–7: Credential Actions (if needed) + Post Results

If probe fails → follow credential repair steps in plan (remove API key override, relogin to subscription, etc.)

**Post Results to KOEA-8434** (not KOEA-8440):
```
**Probe Results**:
- Final status: [pass/warn/fail]
- Key check codes: [list]

**Heartbeat Results**:
- Run ID: [id]
- Status: [succeeded/failed]
- Auth errors: [none / describe if present]

**Mutation Check**: [no unrelated changes / describe if present]
```

---

## QA Acceptance Criteria (What Unblocks QA)

Once Executor posts results to KOEA-8434, QA will verify:

✅ **PASS conditions** (all required):
- Probe final status ∈ {pass, warn} (with documented exceptions)
- Heartbeat status = `succeeded`
- Heartbeat logs: no `api_error_status: 401` or `authentication_error`
- No API keys/tokens in vault/comments
- W26 Monday 2026-06-22 SEO run is unblocked

❌ **BLOCK conditions** (any one blocks):
- Probe fails without remediation
- Heartbeat fails or status ≠ `succeeded`
- Heartbeat logs contain `api_error_status: 401`
- Credentials exposed in vault/comments
- Unrelated mutations detected

---

## Current QA Readiness

✅ QA verification documents prepared:
- KOEA-8440-g2-verification-approach.md (full methodology)
- KOEA-8440-QA-VERDICT.md (acceptance/block criteria)

✅ Code review completed:
- claude_local adapter V6 auth retry logic is sound
- Plan approach is correct

❌ Blocked on:
- Executor probe + heartbeat results
- No way to invoke probe directly (no API auth in QA context)
- No existing b17b6992 recent heartbeat to verify

---

## Timeline

- **Executor action**: 5-10 min (run probe + heartbeat)
- **QA verification**: 2-3 min (once results posted)
- **Target unblock**: <15 min total from Executor start
- **W26 impact**: Must complete before 2026-06-22 Monday (8 days)

---

## Reference

- Plan: `vault/decisions/KOEA-8434-plan.md`
- QA approach: `KOEA-8440-g2-verification-approach.md`
- QA verdict: `KOEA-8440-QA-VERDICT.md`
- PAPERCLIP_URL: http://localhost:3100
- COMPANY_ID: 2a77f89b-33f0-4133-a20c-77ddaac5e744
- AGENT_ID: b17b6992-a180-4835-b22d-8dff1e86d615

**QA Status**: Ready to verify. Awaiting unblock owner action.
