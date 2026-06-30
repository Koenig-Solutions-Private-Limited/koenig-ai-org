#!/bin/bash
# Finalize KOEA-6674 G2 PASS Verdict
# Run this script once Paperclip API is restored (port 3000 responding)
# Prerequisite: curl http://localhost:3000/api/health -H "Authorization: Bearer $PAPERCLIP_API_KEY" returns 200

set -e

COMPANY_ID="2a77f89b-33f0-4133-a20c-77ddaac5e744"
ISSUE_ID="KOEA-6674"
API_URL="http://localhost:3000/api"

# Check API is available
echo "Checking Paperclip API availability..."
if ! curl -s "$API_URL/health" -H "Authorization: Bearer $PAPERCLIP_API_KEY" | grep -q "ok"; then
  echo "ERROR: Paperclip API not responding. Ensure port 3000 is listening."
  exit 1
fi

echo "✓ API responding"

# Post G2 PASS verdict comment
echo "Posting G2 PASS verdict comment to $ISSUE_ID..."
VERDICT_COMMENT=$(cat <<'EOF'
✅ **G2 PASS** · KOEA-6674 Verification Complete

## Test Results: 17/17 ✓
- deferred-comment-reopen-intent.test.ts: 6/6 ✓
- heartbeat-comment-wake-batching.test.ts: 11/11 ✓
- TypeScript typecheck: 0 errors ✓

## Acceptance Criteria Met

### 1. Routine_execution auto-close on successful runs ✓
- Auto-closes routine_execution issues to done when run.status === "succeeded"
- Only when issue.originKind === "routine_execution" and assignee matches run agent
- Updates routineRuns.status to completed
- Logs auto-close for observability
- Implementation: server/src/services/heartbeat.ts:6093-6125

### 2. Deferred comment wakes don't wrongly reopen blocked issues ✓
- Prevents auto-checkout of blocked issues on plain comment wakes
- hasExplicitDeferredCommentReopenIntent() function validates reopen intent
- Only reopens with explicit markers: resumeIntent | followUpRequested | reopenedFrom
- Implementation: server/src/services/heartbeat.ts:1465-1521

### 3. No unrelated vault/content changes ✓
- Only 3 files modified: heartbeat.ts + 2 test files
- No vault, blog, or content files touched

## Commit Details
- Commit: f57e74a04 "fix(heartbeat): auto-close successful routine execution issues"
- Related: KOEA-6432, board approvals 5a4b355c, 88102393
- Status: On origin/master (2026-05-28)

---
Verified by: QA Verifier (agent 57c917c2-1ce9-49c1-9beb-2a1839184f1d)
Ready for G3/CEO alignment
EOF
)

COMMENT_PAYLOAD=$(jq -n --arg body "$VERDICT_COMMENT" '{body: $body}')

curl -s -X POST \
  "$API_URL/companies/$COMPANY_ID/issues/$ISSUE_ID/comments" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$COMMENT_PAYLOAD" | jq -r '.id // .error' > /tmp/comment-result.txt

COMMENT_ID=$(cat /tmp/comment-result.txt)
if [[ "$COMMENT_ID" == *"error"* ]]; then
  echo "ERROR: Failed to post comment: $COMMENT_ID"
  exit 1
fi
echo "✓ Comment posted: $COMMENT_ID"

# Flip issue status to done
echo "Flipping $ISSUE_ID status to done..."
STATUS_PAYLOAD=$(jq -n '{status: "done"}')

curl -s -X PATCH \
  "$API_URL/companies/$COMPANY_ID/issues/$ISSUE_ID" \
  -H "Authorization: Bearer $PAPERCLIP_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$STATUS_PAYLOAD" | jq -r '.status // .error' > /tmp/status-result.txt

STATUS=$(cat /tmp/status-result.txt)
if [[ "$STATUS" == "done" ]]; then
  echo "✓ Issue status flipped to done"
else
  echo "ERROR: Failed to flip status: $STATUS"
  exit 1
fi

echo ""
echo "✅ KOEA-6674 G2 PASS finalized successfully!"
echo "   - Verdict comment posted"
echo "   - Issue status updated to done"
echo "   - Ready for G3/CEO alignment"
