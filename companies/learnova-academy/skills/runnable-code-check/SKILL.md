---
name: runnable-code-check
description: >
  Code Reviewer sub-skill — extract fenced code blocks from a blog or course
  chapter file, attempt to run each block in a sandboxed worker, and return a
  structured PASS/FAIL report. Dispatched by Content Reviewer when a draft
  contains fenced code blocks. Use when a child ticket lands assigned to
  @code-reviewer with title matching "[CODE-CHECK]".
---

# Runnable Code Check

Verify that fenced code blocks in content are syntactically valid and, where possible, actually execute without errors.

## Scope

- File path supplied in the ticket description
- Languages covered: `bash`, `python`, `typescript`, `javascript`
- Other languages (e.g. `sql`, `yaml`, `json`): syntax-only check (no execution)
- Goal: catch copy-paste errors, broken imports, undefined variables before publish

## Inputs

- Ticket description contains `File: <vault-path>` (absolute or repo-relative)
- Optional `Language-filter: bash,python` to restrict checks
- The file must exist at the given path on the checked-out branch/master

## Workflow

### 1. Extract code blocks

```bash
FILE="<vault-path-from-ticket>"

# Extract all fenced code blocks with language tags
# Outputs: <lang>\t<block-content> pairs to /tmp/code-blocks.json
python3 - "$FILE" <<'EOF'
import sys, re, json, pathlib

text = pathlib.Path(sys.argv[1]).read_text()
# Match ``` optionally followed by a language tag
pattern = re.compile(r'```(\w+)?\n(.*?)```', re.DOTALL)
blocks = []
for i, m in enumerate(pattern.finditer(text)):
    lang = (m.group(1) or 'unknown').lower()
    code = m.group(2)
    blocks.append({"index": i + 1, "lang": lang, "code": code, "lines": code.count('\n') + 1})

print(json.dumps(blocks, indent=2))
EOF
```

### 2. Classify each block

For each block:
- `runnable`: `bash`, `python`, `typescript`, `javascript` → attempt execution
- `syntax-only`: `json`, `yaml`, `sql`, `html`, `css`, `text`, `unknown`, `plaintext` → static check only
- `skip`: `...` (placeholder), empty code, or < 3 non-blank lines → skip with note

### 3. Run runnable blocks

**bash:**
```bash
# Write block to temp file, run with strict mode
tmpfile=$(mktemp /tmp/code-check-XXXX.sh)
echo '#!/usr/bin/env bash' > "$tmpfile"
echo 'set -euo pipefail' >> "$tmpfile"
cat >> "$tmpfile" <<'BLOCK'
<block-content>
BLOCK
timeout 15 bash "$tmpfile" > /tmp/code-out.txt 2>&1; EC=$?
rm -f "$tmpfile"
```

**python:**
```bash
tmpfile=$(mktemp /tmp/code-check-XXXX.py)
cat > "$tmpfile" <<'BLOCK'
<block-content>
BLOCK
timeout 15 python3 "$tmpfile" > /tmp/code-out.txt 2>&1; EC=$?
rm -f "$tmpfile"
```

**typescript / javascript:**
```bash
# Use npx tsx (TypeScript) or node (JavaScript)
tmpfile=$(mktemp /tmp/code-check-XXXX.ts)
cat > "$tmpfile" <<'BLOCK'
<block-content>
BLOCK
timeout 15 npx tsx "$tmpfile" > /tmp/code-out.txt 2>&1; EC=$?
rm -f "$tmpfile"
```

Record per block: `exit_code`, `stdout` (first 20 lines), `stderr` (first 20 lines).

**Acceptable non-zero exit codes (do not fail):**
- Blocks that `exit 1` on purpose as part of a "how to handle errors" example
- Blocks referencing `<your-api-key>` or similar placeholder strings → mark as `SKIP (placeholder)` not FAIL
- Blocks that import missing CLI tools not installed in the environment → mark as `ENV-MISSING` not FAIL

### 4. Syntax-only check

**json:**
```bash
echo '<block>' | python3 -m json.tool > /dev/null 2>&1; EC=$?
```
**yaml:**
```bash
echo '<block>' | python3 -c "import sys,yaml; yaml.safe_load(sys.stdin)" 2>&1; EC=$?
```

### 5. Produce the report

Collect results into a structured report:

```
## Code Block Audit — vault/<path>/draft.md

Total blocks: N
  Runnable (attempted): N
  Syntax-only (checked): N
  Skipped (placeholder/too-short): N

### Results

Block 1 · bash · 8 lines → ✅ PASS (exit 0)
Block 2 · python · 12 lines → ✅ PASS (exit 0)
Block 3 · typescript · 5 lines → ❌ FAIL (exit 1)
  First error: Cannot find module '@anthropic-ai/sdk' (line 1)
Block 4 · json · 3 lines → ✅ PASS (valid JSON)
Block 5 · bash · 2 lines → ⏭ SKIP (placeholder — contains <YOUR_API_KEY>)

### Summary

PASS: 3 / 5 blocks checked
FAIL: 1 block (Block 3 — typescript)
ENV-MISSING: 0

Overall verdict: ❌ FAIL — 1 block has a real error
```

### 6. Verdict + ticket flip

**PASS** (0 blocks with real errors):
- Post report as comment on the child ticket
- Flip child ticket to `done` with a one-line summary
- Content Reviewer's parent ticket will wake and can proceed to PASS

**FAIL** (≥ 1 block with a real error):
- Post full report as comment on the child ticket
- Flip child ticket to `in_progress` with comment directing back to the Author

## Notes

- Timeout per block: 15 seconds. If it exceeds, mark `TIMEOUT` not FAIL.
- Max blocks per run: 20. If file has more, check first 20 and note the cap.
- Do NOT install missing packages inside the check — only test what runs in the existing environment.
- Placeholder detection: strings matching `<[A-Z_]+>` or `YOUR_*` or `<your-*` → `SKIP (placeholder)`.
- The goal is a quick sanity check, not a full integration test suite.

## Escalation

- Python import errors for standard library → real FAIL (author's code is broken)
- Network-dependent code (makes HTTP calls) → mark `SKIP (network-dependent)` — don't attempt
- Code that modifies filesystem outside /tmp → mark `SKIP (filesystem-unsafe)` — don't attempt
