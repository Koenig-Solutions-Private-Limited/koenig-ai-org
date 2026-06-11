# Infrastructure Blocker: Audio Toolchain Unavailable
## Brief for escalation issue (should be filed as child/sibling to KOEA-7805)

**Parent Issue**: KOEA-7805 (G2 QA Verification)  
**Blocking**: KOEA-7797 (cursor-composer-2 ch5 audio producer)  
**Date Filed**: 2026-06-11  
**Priority**: High  
**Status**: Waiting for action  

---

## Problem Statement

Audio generation for cursor-composer-2 chapter 5 is blocked by unavailable infrastructure. All three audio production tiers are currently inaccessible:

1. **Open-Notebook Docker service** — Docker CLI not found on production system
2. **OpenAI TTS** — API quota exhausted (`insufficient_quota` 429 error)
3. **NotebookLM CLI** — Not installed; requires account setup

**Impact**: KOEA-7797 (producer) cannot generate audio. KOEA-7805 (QA gate) cannot verify. G2 → G3 → G4 pipeline stalled.

---

## Required Action (Choose One)

### Option A: Fund OpenAI TTS Quota ⭐ RECOMMENDED
**Effort**: ~5 min  
**Cost**: ~$10–20 USD (estimated for chapter-5 audio generation)  
**Owner**: Operator  
**Action**:
1. Log in to OpenAI console (https://platform.openai.com/account/billing/overview)
2. Add prepaid credits or update billing method
3. Verify quota available with: `curl -s https://api.openai.com/v1/models -H "Authorization: Bearer $OPENAI_API_KEY" | jq '.data[] | select(.id | contains("tts")) | .id'`
4. Notify KOEA-7804 executor to retry audio generation

**Verification**: KOEA-7804 re-runs `python3 scripts/generate_course_audio.py …` without quota error.

---

### Option B: Start Open-Notebook Docker Service
**Effort**: ~1–2 hours  
**Cost**: Local Docker resources only  
**Owner**: Infrastructure / DevOps  
**Action**:
1. Install Docker Desktop on production system (or restore Docker CLI)
2. Verify Docker daemon is running: `docker ps`
3. Start Open-Notebook container: `docker compose -f observability/open-notebook/docker-compose.yml up -d`
4. Verify health: `curl -fsS http://localhost:5055/health`
5. Notify KOEA-7804 executor that tier-1 is ready

**Verification**: KOEA-7804 successfully calls `curl -fsS -X POST http://localhost:5055/api/sources …` without connection errors.

---

### Option C: Install & Configure NotebookLM CLI
**Effort**: ~2–4 hours  
**Cost**: Free (requires Google account setup)  
**Owner**: Operator  
**Action**:
1. Install NotebookLM CLI: `pip install notebooklm-py` or download from https://github.com/…
2. Authenticate: `notebooklm login` (requires Google OAuth flow)
3. Verify CLI: `notebooklm --version`
4. Test: `notebooklm create-source --help`
5. Notify KOEA-7804 executor that tier-3 is ready

**Verification**: KOEA-7804 successfully invokes `notebooklm` commands without `command not found` error.

---

## Acceptance Criteria

When **any one option** is complete:
- [ ] Chosen tier verified working (e.g., OpenAI quota confirmed, Docker health endpoint returns 200, NotebookLM CLI responds to `--version`)
- [ ] KOEA-7804 executor is notified and re-dispatched
- [ ] KOEA-7804 attempts audio generation and uploads sidecar
- [ ] KOEA-7805 (QA) is re-queued and completes verification
- [ ] This infrastructure blocker is marked complete

---

## Estimated Timeline

| Option | Time to Resolution |
|--------|-------------------|
| **A (Fund OAI)** | 30 min |
| **B (Docker)** | 1–2 hours |
| **C (NotebookLM)** | 2–4 hours |

**Critical Path**: Option A is the fastest unblock for this heartbeat.

---

## Related Evidence

- **G2 Verification Report**: `KOEA-7805-g2-verification-report.md` (detailed infrastructure diagnostics)
- **Recovery Plan**: `vault/decisions/KOEA-7801-audio-toolchain-recovery-plan.md` (revision 3, approved)
- **Generator Script**: `scripts/generate_course_audio.py` (confirmed functional, blocked by quota)
- **OpenAI Error**:
  ```
  openai.RateLimitError: Error code: 429
  {'error': {'message': 'You exceeded your current quota, please check your plan and billing details.', 'code': 'insufficient_quota'}}
  ```

---

## Next Steps (Post-Unblock)

1. Operator/DevOps completes one action above
2. File completion evidence (quota top-up receipt, docker health output, notebooklm version, etc.)
3. Re-dispatch KOEA-7804 executor
4. KOEA-7804 generates audio → uploads to R2
5. Re-queue KOEA-7805 verification
6. Upon G2 PASS, close this blocker and unblock KOEA-7801 → KOEA-7797

---

## Escalation Path

- **If no action within 24h**: Escalate to CEO/board for budget approval (Option A) or infrastructure allocation (Options B/C)
- **If all options rejected**: Document decision and mark G2 as exception approved (slides only, no audio)
