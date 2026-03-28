#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# Counter file (per-session via PPID)
counter_file="/tmp/.claude-codex-write-counter-${PPID:-0}"
count=0

if [[ -f "$counter_file" ]]; then
  count="$(cat "$counter_file" 2>/dev/null)" || count=0
fi

count=$((count + 1))
printf '%s' "$count" > "$counter_file"

# Suggest every 5 writes
if (( count % 5 == 0 )); then
  echo "$count files written in this session." >&2
  echo "   Consider running Codex design review to check architectural consistency:" >&2
  echo "   codex exec --full-auto -p review --cd \"\$(pwd)\" \"Review recent changes for design consistency\"" >&2
fi

# Pass through - never block
printf '%s' "$input"
exit 0
