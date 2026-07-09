# QA Verification Report — KOEA-8440

**G2 QA Verifier**: Claude Code (Haiku 4.5)  
**Task**: Verify KOEA-8434 fix for Search Visibility Optimizer auth 401 errors  
**Date**: 2026-06-15 06:27 UTC  
**Status**: Awaiting Executor results  

---

## Summary

KOEA-8440 is a G2 QA verification task for KOEA-8434. The fix restores authentication for Search Visibility Optimizer agent (b17b6992-a180-4835-b22d-8dff1e86d615) on `claude_local` adapter, which was failing with 401 errors and blocking the W26 Monday (2026-06-22) weekly SEO run.

The plan (vault/decisions/KOEA-8434-plan.md) outlines a probe-first operational repair: diagnose auth health via environment tests, run a fresh heartbeat to confirm success, then commit credential changes only if necessary.

---

## Verification Gate Setup (G2 Lane)

### What QA Will Verify

1. **Environment Probe**: 
   - Probe status: `pass` (or `warn` with documented exceptions)
   - Check codes present (especially `claude_anthropic_api_key_overrides_subscription`, `claude_subscription_mode_possible`, `claude_hello_probe_passed`)
   - No credentials exposed in vault/comments

2. **Fresh Heartbeat Test**:
   - Heartbeat status: `succeeded`
   - No `api_error_status: 401` or `authentication_error` in logs
   - Run ID recorded for audit trail

3. **Portal Mutation Check**:
   - No unrelated changes to agent config (adapter type, model assignments, budget)
   - No collateral infrastructure changes

4. **Unblock Confirmation**:
   - W26 Monday 2026-06-22 SEO run can be scheduled without auth blocks
   - No follow-up credential patches required

### Pass Criteria

All of the following must be true:
- [ ] Environment probe final status: **pass** or **warn** (with documented intent)
- [ ] Fresh heartbeat: **succeeded** without 401 errors
- [ ] No API keys, tokens, or credential JSON in comments or vault
- [ ] W26 SEO run is unblocked

---

## Executor Checklist (What Needs to Happen)

Per KOEA-8434-plan.md steps 1–7, Executor must:

1. **Fetch Agent Record**  
   `GET /api/agents/b17b6992-a180-4835-b22d-8dff1e86d615`  
   Confirm `adapterType=claude_local`; note adapter config structure (env keys only, no values)

2. **Run Environment Probe**  
   `POST /api/companies/2a77f89b-33f0-4133-a20c-77ddaac5e744/adapters/claude_local/test-environment`  
   Record final `status` + check code list

3. **Invoke Fresh Heartbeat**  
   If probe passes: trigger one b17b6992 heartbeat with `forceFreshSession: true`  
   Inspect result for `api_error_status: 401` or `authentication_error` — none should appear

4. **Conditional Credential Actions**  
   If probe fails: follow steps 4–6 (API key removal, subscription relogin, or bug escalation)  
   If probe passes: proceed to heartbeat verification

5. **Mutation Check**  
   Confirm no unrelated changes to agent config or infrastructure

6. **Post Results to KOEA-8434**  
   Comment with:
   - Probe status + check code list
   - Heartbeat run ID + status
   - Mutation check confirmation
   - Any credential actions taken (description only, no values)

---

## Current State Analysis

### What I Verified Locally
- ✅ Plan file exists and is well-structured: `vault/decisions/KOEA-8434-plan.md`
- ✅ Agent b17b6992 is Search Visibility Optimizer (SEO+GEO optimizer)
- ✅ Agent uses `claude_local` adapter (per plan context)
- ✅ W26 Monday 2026-06-22 SEO run is stakeholder-critical (18-day advance notice for weekly cadence)
- ✅ Prior failed runs show `apiKeySource: "none"` + 401 (suggests transient credential state, not adapter bug)
- ✅ Later run succeeded without code changes (indicates operational repair, not code fix required)

### What I Cannot Verify Without Executor Input
- ❌ Environment probe results (requires Paperclip API access)
- ❌ Fresh heartbeat results (requires agent invocation)
- ❌ Whether credentials were patched (out-of-band operation)
- ❌ Portal mutation inspection (requires Paperclip instance visibility)

### Blocker: API Access
QA Verifier role cannot directly invoke Paperclip API from CLI (no JWT token in sandbox environment). This is intentional: Executor invokes, QA verifies reported results.

---

## Next Action

**→ Executor**: Post a comment on KOEA-8434 with:
1. **Probe Results**  
   Final status + 2–3 key check codes

2. **Heartbeat Results**  
   Run ID + status + "no 401 errors observed"

3. **Mutation Confirmation**  
   "No unrelated config changes"

4. **Blockers**  
   If any step failed, description + context (not credentials)

**→ QA**: Upon receiving executor results, verify against pass criteria above and post G2 PASS or BLOCK on KOEA-8440.

---

## Risk Mitigation Notes

- **Transient 401s**: The 401 may self-resolve. Probe-first approach avoids unnecessary credential rotation (risk: leaks old keys, breaks other agents).
- **Credential Overrides**: Stale `ANTHROPIC_API_KEY` in `adapterConfig.env` can shadow company subscription. Probe will surface this as `claude_anthropic_api_key_overrides_subscription` warning.
- **Subscription Login Expired**: If Claude subscription credentials are invalid, probe will report `claude_hello_probe_auth_required`. May require re-login via board-only flow.
- **Adapter Code Bug**: Unlikely (test.ts auth classification logic is sound). Will escalate to engineering only if probe + heartbeat still fail.

---

## Out of Scope

- Code changes to `claude_local` adapter (only if fresh repro proves adapter bug)
- Full W25/W26 SEO workflow re-run (only the auth verification)
- Credential rotation without probe evidence
- Session/workspace reset beyond `forceFreshSession: true`

---

## Contacts

- **Blocker**: QA cannot verify without Executor's probe + heartbeat results
- **Escalation**: If Executor cannot access Paperclip API, escalate to Chief Engineering for board-only probe invocation
- **Follow-up**: If probe/heartbeat still fail, file engineering ticket with run IDs + check codes

---

**QA Verifier Status**: ⏸️ Awaiting Executor Results  
**Expected Verification Time**: <15 min once results posted  
**Target QA Completion**: Within 1 heartbeat of executor comment  
