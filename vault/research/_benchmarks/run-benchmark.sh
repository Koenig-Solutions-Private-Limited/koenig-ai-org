#!/bin/bash
# Master benchmark runner for KOEA-7091: Codex CLI vs Claude Code Opus 4.7
# Runs all (tool × task × trial) combinations and appends results to CSV.
#
# Prerequisites:
#   - codex CLI installed and authenticated (npm install -g @openai/codex)
#   - claude CLI installed and authenticated with opus-4-7 access
#   - Node 20+ with npm available
#   - Run from vault/research/_benchmarks/ directory
#
# Usage:
#   ./run-benchmark.sh [--trials N] [--tools codex,claude] [--tasks task-a,task-b,task-c]
#
# Defaults: 5 trials, both tools, all tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV="$SCRIPT_DIR/codex-vs-claude-code-autonomous-2026-06.csv"

TRIALS=5
TOOLS="codex claude"
TASKS="task-a-express-handler task-b-jwt-scaffold task-c-streaming-leak"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --trials) TRIALS="$2"; shift 2 ;;
    --tools)  TOOLS="${2//,/ }"; shift 2 ;;
    --tasks)  TASKS="${2//,/ }"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "=== Benchmark run: $(date -u +"%Y-%m-%dT%H:%M:%SZ") ===" >&2
echo "  Tools: $TOOLS" >&2
echo "  Tasks: $TASKS" >&2
echo "  Trials per combination: $TRIALS" >&2
echo "" >&2

for TOOL in $TOOLS; do
  for TASK in $TASKS; do
    TASK_DIR="$SCRIPT_DIR/tasks/$TASK"
    if [ ! -d "$TASK_DIR" ]; then
      echo "WARN: task dir not found, skipping: $TASK_DIR" >&2
      continue
    fi
    for i in $(seq 1 "$TRIALS"); do
      echo "  Running: $TOOL / $TASK / trial $i ..." >&2
      ROW=$("$SCRIPT_DIR/run-trial.sh" "$TOOL" "$TASK_DIR" "$i" 2>/dev/null)
      echo "$ROW" | tee -a "$CSV"
      echo "  Done: $ROW" >&2
      sleep 2
    done
  done
done

echo "" >&2
echo "=== Complete. Results appended to $CSV ===" >&2
