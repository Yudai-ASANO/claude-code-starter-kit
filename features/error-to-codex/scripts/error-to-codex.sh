#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# Extract command and exit code
exit_code="$(printf '%s' "$input" | jq -r '.tool_output.exit_code // empty' 2>/dev/null)" || exit_code=""
command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)" || command_str=""

# Skip if this was a codex command itself (avoid recursion)
if [[ "$command_str" == *"codex "* ]]; then
  printf '%s' "$input"
  exit 0
fi

if [[ -n "$exit_code" ]] && [[ "$exit_code" != "0" ]]; then
  echo "Command failed (exit $exit_code): $command_str" >&2
  echo "   Consider delegating to Codex for root-cause analysis:" >&2
  echo "   codex exec --full-auto -p debug --cd \"\$(pwd)\" \"Debug: command failed with exit $exit_code: $command_str\"" >&2
fi

# Pass through - never block
printf '%s' "$input"
exit 0
