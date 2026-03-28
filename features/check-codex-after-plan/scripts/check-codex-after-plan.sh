#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# Extract file path
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)" || file_path=""

if [[ -n "$file_path" ]]; then
  echo "Plan/design file updated: $file_path" >&2
  echo "   Consider running Codex design review:" >&2
  echo "   codex exec --full-auto -p review --cd \"\$(pwd)\" \"Review design in $file_path\"" >&2
fi

# Pass through - never block
printf '%s' "$input"
exit 0
