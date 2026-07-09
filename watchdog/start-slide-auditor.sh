#!/bin/bash
# Start slide-fake-done-auditor routine (runs every 10 min)

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Source environment
if [ -f .env.koenig ]; then
  set -a
  source .env.koenig
  set +a
fi

# Ensure node_modules
if [ ! -d node_modules ]; then
  echo "Installing dependencies..."
  pnpm install
fi

# Run auditor every 10 minutes
echo "Starting slide-fake-done-auditor (runs every 10 min)..."
while true; do
  node watchdog/slide-fake-done-auditor.mjs 2>&1 | tee -a watchdog/slide-auditor.log
  sleep 600  # 10 minutes
done
