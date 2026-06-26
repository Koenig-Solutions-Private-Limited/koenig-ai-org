# G2 QA VERDICT — KOEA-8440

**Status**: ✅ **READY FOR VERIFICATION**  
**Task**: Verify KOEA-8434 auth 401 fix (Search Visibility Optimizer)  
**Date**: 2026-06-15 06:33 UTC  
**QA Verifier**: Claude Code (Haiku 4.5)  

---

## Code Review Summary

✅ **Adapter code is sound** — claude_local already has:
- V6 (2026-05-05) retry-on-401-with-fresh-credentials logic
- 2 retry attempts with 1.5s settle delay for Docker bind-mount propagation
- Proper auth classification (API key vs. subscription vs. Bedrock)
- Auth error detection via `detectClaudeLoginRequired()` regex

✅ **Operational repair approach is correct** — Plan aligns with adapter capabilities:
- Environment probe will surface exact auth issue (API key override, subscription expired, or Bedrock misconfiguration)
- Fresh heartbeat with retries should resolve transient file-system propagation issues
- No code changes needed unless probe + retries still fail

✅ **Risk mitigation is in place** — Probe-first avoids:
- Unnecessary credential rotation (which can leak old keys)
- Blanket session/workspace resets (which discard useful state)
- Code changes without reproducible evidence

---

## Verification Gates (Ready)

| Gate | Criterion | Status |
|------|-----------|--------|
| **1. Environment Probe** | Final status `pass` or `warn` (documented) + check codes | ⏳ Awaiting Executor |
| **2. Fresh Heartbeat** | Status `succeeded` + no `api_error_status: 401` in logs | ⏳ Awaiting Executor |
| **3. Portal Mutation** | No unrelated agent/config changes | ⏳ Awaiting Executor |
| **4. W26 Unblock** | SEO run schedulable for 2026-06-22 Monday | ✅ Verifiable |

---

## What Executor Must Deliver

1. **Probe Status** — Final result from `POST .../adapters/claude_local/test-environment`
   - Expected codes: `claude_anthropic_api_key_overrides_subscription`, `claude_subscription_mode_possible`, or `claude_hello_probe_passed`
   - No credential values

2. **Heartbeat Results** — Fresh b17b6992 run after probe
   - Run ID + final status (`succeeded` or failed)
   - Confirmation: no `api_error_status: 401` in logs
   - Retry count observed (if any)

3. **Mutation Check** — Simple confirmation
   - "No config changes outside of auth repair" or list any changes

4. **Optional: Credential Actions** — If probe failed
   - Description of fix applied (API key removal, subscription relogin, etc.)
   - No credential material

---

## QA Acceptance Criteria (PASS)

All required:
1. Probe final status ∈ `{pass, warn}` (warnings documented as intentional)
2. Heartbeat status = `succeeded`
3. Heartbeat logs: no `api_error_status: 401` OR `authentication_error`
4. No API keys/tokens/credential JSON in vault/comments
5. W26 Monday 2026-06-22 SEO run is unblocked

---

## QA Block Criteria (BLOCK)

Any of:
1. Probe final status = `fail` (unless remediated per plan steps 4-6)
2. Heartbeat status ≠ `succeeded`
3. Heartbeat logs contain `api_error_status: 401` or `authentication_error`
4. Credentials exposed in vault/comments
5. Unrelated agent/portal changes detected

---

## Next Step

**→ Executor**: Post comment on KOEA-8434 with probe + heartbeat results  
**→ QA**: Review results against acceptance criteria → PASS or BLOCK within 1 heartbeat  
**→ Timeline**: Executor work (~5-10 min) + QA verification (~2-3 min) = 15 min total expected

---

## References

- Plan: `vault/decisions/KOEA-8434-plan.md`
- Adapter retry logic: `packages/adapters/claude-local/src/server/execute.ts:781-822`
- Verification details: `KOEA-8440-g2-verification-approach.md`

**QA Verifier**: Ready to verify. Awaiting executor results.
