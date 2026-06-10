#!/bin/bash
# Career Compass ⇄ Paperclip reconciler — thin wrapper. The implementation
# lives in career-reconcile.mjs (node + @aws-sdk/client-s3; no aws CLI
# dependency). Kept as .sh so the Chief Learning routine contract
# ("run scripts/career-reconcile.sh") stays stable.
exec node "$(dirname "$0")/career-reconcile.mjs" "$@"
