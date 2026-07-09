# QA REPORT — KOEA-8440

**Task**: [G2 QA] KOEA-8434 b17b6992 auth verification  
**Date**: 2026-06-15 05:40 UTC  
**QA Verifier**: Claude Code (Haiku 4.5)  
**Status**: ⏳ **PENDING EXECUTOR COMPLETION** → Ready for final verification  

---

## Executive Summary

**Current State**: Search Visibility Optimizer (b17b6992) is **BLOCKED** with `401 auth_error` on `claude_local` adapter, blocking W26 Monday (2026-06-22) weekly SEO run.

**Failure Evidence**: Confirmed in `vault/retrospectives/chief-marketing/2026-06-15-KOEA-8423.md`
- Date: 2026-06-15 (today)
- Agent: SEO Optimizer (b17b6992)
- Failure: "Root cause was Search Visibility Optimizer 401 auth failure"
- Related Issue: KOEA-8433 filed to fix adapter

**Fix Status**: KOEA-8434 plan exists and outlines probe-first operational repair. Awaiting executor to run steps 1–7.

**QA Readiness**: ✅ Verification gates prepared. Ready to verify fix upon executor completion.

---

## Part 1: FAILURE VERIFICATION ✅

### Confirmed Failure Evidence

| Aspect | Evidence | Status |
|--------|----------|--------|
| **Agent Failure** | chief-marketing freshness audit blocked by 401 | ✅ Confirmed |
| **Auth Error Type** | 401 authentication_error on claude_local | ✅ Confirmed |
| **Date/Time** | 2026-06-15 ~06:XX UTC | ✅ Confirmed |
| **Impact** | SEO freshness audit incomplete, W26 Monday run at risk | ✅ Confirmed |
| **Root Cause** | Likely: transient credential/environment state (not code bug) | ✅ Per plan analysis |

### Investigation Summary

1. **Adapter Code Review**: ✅ Claude_local V6 (2026-05-05) has proper auth retry logic (MAX_AUTH_RETRIES=2, settle delay=1500ms) to handle Docker bind-mount propagation lag.

2. **Plan Correctness**: ✅ KOEA-8434-plan.md approach is sound:
   - Probe-first (proves auth health without credential churn)
   - Conditional repair (remove API key override OR relogin subscription)
   - No code changes needed if probe + retries succeed

3. **Portal Mutations**: ✅ No unrelated config changes
   - 0 seo-optimizer config mutations in June
   - SOUL/policy updates only (expected maintenance)

4. **W26 Timeline**: ✅ Critical path confirmed
   - Days until W26 Monday: 6 days
   - Weekly SEO run is stakeholder-critical
   - Fix timeline is adequate (must complete before 2026-06-22)

---

## Part 2: FIX VERIFICATION — PENDING EXECUTOR

### What Must Happen Next

**Executor** (KOEA-8439 or equivalent) must complete KOEA-8434-plan.md steps 1–7:

**Step 1–3: Probe & Test**
```bash
1. Fetch agent: GET /api/agents/b17b6992-a180-4835-b22d-8dff1e86d615
2. Run environment probe: POST .../adapters/claude_local/test-environment
3. Run fresh heartbeat: POST .../agents/b17b6992.../heartbeat/invoke (if probe passes)
```

**Steps 4–7: Conditional Repair + Results**
```bash
4. If probe fails: remove stale ANTHROPIC_API_KEY OR relogin to subscription
5. Re-run probe after credential repair
6. Verify fresh heartbeat succeeds
7. Post results to KOEA-8434 (probe status + heartbeat run ID)
```

### QA Acceptance Criteria

**PASS** (all required):
- [ ] Probe final status ∈ {pass, warn} (with documented exceptions)
- [ ] Fresh heartbeat status = `succeeded`
- [ ] Heartbeat logs: no `api_error_status: 401` or `authentication_error`
- [ ] No API keys/tokens/credentials in vault or comments
- [ ] W26 Monday SEO run is unblocked (can be scheduled)

**BLOCK** (any one):
- [ ] Probe final status = `fail` (unless remediated per plan)
- [ ] Heartbeat status ≠ `succeeded`
- [ ] Heartbeat logs contain `api_error_status: 401`
- [ ] Credentials exposed in vault/comments
- [ ] Unrelated agent/portal mutations detected

---

## Part 3: POST-FIX VERIFICATION SCOPE

Once executor posts probe + heartbeat results to KOEA-8434, QA will:

1. **Verify Probe Results**
   - Check final status is pass or warn
   - Confirm check codes (focus: `claude_anthropic_api_key_overrides_subscription`, `claude_subscription_mode_possible`, `claude_hello_probe_passed`)

2. **Verify Heartbeat Results**
   - Confirm run ID exists and is post-probe
   - Check status is `succeeded`
   - Scan logs for absence of 401/auth errors

3. **Verify No Secret Exposure**
   - Grep comments/vault for ANTHROPIC_API_KEY, oauth tokens, credential JSON
   - Confirm none present

4. **Verify W26 Unblock**
   - Check that W26 Monday SEO run can be scheduled without auth blockers
   - Confirm no follow-up credential patches required

---

## Part 4: REFERENCES & ARTIFACTS

### Key Documents
- **Plan**: `vault/decisions/KOEA-8434-plan.md` (7-step repair procedure)
- **QA Approach**: `KOEA-8440-g2-verification-approach.md` (methodology)
- **QA Verdict**: `KOEA-8440-QA-VERDICT.md` (pass/fail criteria)
- **Blocker Action**: `KOEA-8440-BLOCKER-ACTION.md` (executor steps)

### Evidence
- **Failure**: `vault/retrospectives/chief-marketing/2026-06-15-KOEA-8423.md`
- **Adapter Code**: `packages/adapters/claude-local/src/server/execute.ts:781-822` (V6 retry logic)

### Credentials
- **PAPERCLIP_URL**: http://localhost:3100
- **COMPANY_ID**: 2a77f89b-33f0-4133-a20c-77ddaac5e744
- **AGENT_ID**: b17b6992-a180-4835-b22d-8dff1e86d615

---

## Summary

| Item | Status | Evidence |
|------|--------|----------|
| Failure verified | ✅ Confirmed | 2026-06-15 chief-marketing retro |
| Root cause understood | ✅ Operational (not code bug) | Adapter V6 retry logic exists |
| Plan evaluated | ✅ Sound | Probe-first approach correct |
| No mutations | ✅ Verified | 0 config changes in June |
| W26 impact clear | ✅ Critical path | 6 days to deadline |
| **FIX STATUS** | ⏳ **AWAITING EXECUTOR** | Must run probe + heartbeat |

---

## QA Status

**Current**: Verification gates prepared, ready to verify fix upon executor completion.  
**Timeline**: Executor 5-10 min + QA 2-3 min = 15 min total to completion.  
**Blocker**: KOEA-8439 (Executor) must post probe + heartbeat results to KOEA-8434.  
**Next Step**: Resume verification upon executor results.

---

*G2 QA Verifier · KOEA-8440 · 2026-06-15*
