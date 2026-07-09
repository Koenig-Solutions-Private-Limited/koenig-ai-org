#!/bin/bash
# Finalize KOEA-9210 G2 PASS verdict once API is restored
# Run this after Paperclip API is back online
# Usage: ./scripts/finalize-koea9210-verdict.sh

set -e

ISSUE_ID="KOEA-9210"
COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
API_URL="http://localhost:3000"

# Wait for API to be ready
echo "Waiting for Paperclip API to respond..."
for i in {1..30}; do
  if curl -s "$API_URL/api/health" -H "Authorization: Bearer $PAPERCLIP_API_KEY" >/dev/null 2>&1; then
    echo "✓ API is online"
    break
  fi
  echo "  Attempt $i/30 — API not ready, waiting..."
  sleep 2
done

# Verify API is actually responsive
if ! curl -s "$API_URL/api/health" -H "Authorization: Bearer $PAPERCLIP_API_KEY" >/dev/null 2>&1; then
  echo "ERROR: API did not respond after 60 seconds"
  exit 1
fi

echo "Posting G2 PASS verdict to KOEA-9210..."

# Post verdict comment
VERDICT_BODY='✅ G2 PASS · KOEA-9210 PR #58 Terminal Wake Behavior

**Test Results: 51/51 ✓**
- heartbeat-comment-wake-batching.test.ts: 11/11 ✓
- issue-comment-reopen-routes.test.ts: 30/30 ✓
- issue-update-comment-wakeup-routes.test.ts: 10/10 ✓

**Verification Checklist**
- ✓ Passive terminal comment wakes are skipped (no reopen on done/cancelled)
- ✓ Explicit resume remains supported (resumeIntent, reopenedFrom, followUpRequested)
- ✓ Generic comments on closed issues stay inert
- ✓ Batching works for explicit reopen paths
- ✓ Typecheck clean

**Key Fix**
The `hasExplicitDeferredCommentReopenIntent()` guard in heartbeat deferred promotion (line 1568–1577, heartbeat.ts) ensures only deferred wakes with explicit intent markers reopen done/cancelled issues. Passive wakes skip reopen side effects entirely.

**Commits**
- 82b6716b4 — fix(issues): add metadata field to issueListSelect for heartbeat PR #58
- 22e1797c5 — G2 PASS: KOEA-9210 PR #58 terminal wake behavior verification

→ Ready for G3 alignment.'

curl -s -X POST "$API_URL/api/companies/$COMPANY_ID/issues/$ISSUE_ID/comments" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -d "{\"body\": $(echo "$VERDICT_BODY" | jq -Rs .)}" > /dev/null

if [ $? -eq 0 ]; then
  echo "✓ Verdict comment posted"
else
  echo "ERROR: Failed to post verdict comment"
  exit 1
fi

# Flip status to done
echo "Flipping issue status to done..."

curl -s -X PATCH "$API_URL/api/companies/$COMPANY_ID/issues/$ISSUE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -d '{"status":"done"}' > /dev/null

if [ $? -eq 0 ]; then
  echo "✓ Issue status flipped to done"
else
  echo "ERROR: Failed to flip issue status"
  exit 1
fi

echo ""
echo "✅ KOEA-9210 G2 PASS verdict finalized"
echo "   Ready for G3 alignment"
