#!/bin/bash
# Benchmark trial runner for KOEA-7091
# Usage: ./run-trial.sh <tool> <task-dir> <trial-num>
# tool: "codex" or "claude"
# Outputs one CSV row to stdout; caller appends to codex-vs-claude-code-autonomous-2026-06.csv

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL="${1:?usage: run-trial.sh <tool> <task-dir> <trial-num>}"
TASK_DIR_ARG="${2:?}"
TRIAL_NUM="${3:-1}"

# Resolve task dir to absolute path
if [[ "$TASK_DIR_ARG" = /* ]]; then
  TASK_DIR="$TASK_DIR_ARG"
else
  TASK_DIR="$SCRIPT_DIR/$TASK_DIR_ARG"
fi

TASK_NAME=$(basename "$TASK_DIR")
START_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_EPOCH=$(date +%s)

# Load per-task prompt from prompts/<task-name>.txt
PROMPT_FILE="$SCRIPT_DIR/prompts/${TASK_NAME}.txt"
if [ ! -f "$PROMPT_FILE" ]; then
  echo "ERROR: prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi
PROMPT=$(cat "$PROMPT_FILE")

# Reset codebase to committed state before each trial
git -C "$SCRIPT_DIR" checkout HEAD -- "tasks/$TASK_NAME"

GIT_HASH=$(git -C "$SCRIPT_DIR" rev-parse --short HEAD)

cd "$TASK_DIR"
# NODE_ENV=development ensures devDependencies (jest) are installed in container environments
NODE_ENV=development npm install --silent 2>/dev/null

# Verify baseline has failing tests (sanity check)
BASELINE_PASS=false
if NODE_ENV=development npm test --silent 2>/dev/null | grep -q "Tests:.*0 failed"; then
  BASELINE_PASS=true
fi

CORRECTNESS="false"
TESTS_PASS_TIME=""

# Run the tool
if [ "$TOOL" = "codex" ]; then
  timeout 1800 codex --approval-policy never -q "$PROMPT" 2>/dev/null || true
elif [ "$TOOL" = "claude" ]; then
  # Claude Code must be configured to use opus-4-7 for benchmark validity
  timeout 1800 claude --model claude-opus-4-7 --allowedTools "Edit,Read,Bash" -p "$PROMPT" 2>/dev/null || true
else
  echo "ERROR: unknown tool: $TOOL (use 'codex' or 'claude')" >&2
  exit 1
fi

END_EPOCH=$(date +%s)
END_UTC=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
ELAPSED=$(( END_EPOCH - START_EPOCH ))

# Check correctness (all tests pass after tool run)
if NODE_ENV=development npm test --silent 2>/dev/null | grep -q "Tests:.*0 failed"; then
  CORRECTNESS="true"
  TESTS_PASS_TIME=$ELAPSED
fi

# Reset codebase after trial for clean state
cd "$SCRIPT_DIR"
git checkout HEAD -- "tasks/$TASK_NAME"

echo "$TOOL,$TASK_NAME,$TRIAL_NUM,$START_UTC,$END_UTC,$ELAPSED,${TESTS_PASS_TIME:-},unknown,$CORRECTNESS,0,git=$GIT_HASH baseline_pass=$BASELINE_PASS"
