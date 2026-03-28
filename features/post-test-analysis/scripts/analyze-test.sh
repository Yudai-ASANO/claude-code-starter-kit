#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# Extract command
command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)" || command_str=""

# Check if command matches a test runner pattern using grep (avoids case-glob ordering issues)
is_test_runner=false
if printf '%s' "$command_str" | grep -qE \
  '(^|[[:space:]])(npm[[:space:]]+test|npm[[:space:]]+run[[:space:]]+test|pnpm[[:space:]]+test|yarn[[:space:]]+test|npx[[:space:]]+(jest|vitest|mocha)|pnpm[[:space:]]+exec[[:space:]]+vitest|pytest|python[[:space:]]+-m[[:space:]]+pytest|python3[[:space:]]+-m[[:space:]]+pytest|swift[[:space:]]+test|xcodebuild[[:space:]]+test|\.?/?gradlew[[:space:]]+test|gradle[[:space:]]+test|make[[:space:]]+(test|ci-test)|just[[:space:]]+test|cargo[[:space:]]+test|go[[:space:]]+test|jest|vitest|mocha)'; then
  is_test_runner=true
fi

# Not a test runner — pass through silently
if [[ "$is_test_runner" != "true" ]]; then
  printf '%s' "$input"
  exit 0
fi

# Extract test output for analysis
test_output="$(printf '%s' "$input" | jq -r '.tool_output.output // ""' 2>/dev/null)" || test_output=""

# Count failures and extract names (best effort, varies by runner)
fail_count=0
failed_names=""

# Try common failure patterns
if printf '%s' "$test_output" | grep -qE '[0-9]+ failed'; then
  fail_count="$(printf '%s' "$test_output" | grep -oE '[0-9]+ failed' | head -1 | grep -oE '[0-9]+')" || fail_count=0
fi

# Extract up to 3 failed test names
failed_names="$(printf '%s' "$test_output" | grep -E '(FAIL|FAILED|Error|✗|✘|×)' | head -3 | sed 's/^[[:space:]]*//' | tr '\n' ', ' | sed 's/, $//')" || failed_names=""

# Build summary
if [[ "$fail_count" -gt 0 ]] || [[ -n "$failed_names" ]]; then
  summary="[test] "
  if [[ "$fail_count" -gt 0 ]]; then
    summary+="${fail_count} failed"
  else
    summary+="Tests failed"
  fi
  if [[ -n "$failed_names" ]]; then
    summary+=": ${failed_names}"
  fi
  # Output to stderr only (OUTPUT DISCIPLINE: stdout = pass-through only)
  echo "$summary" >&2
fi

# Pass through input on stdout
printf '%s' "$input"
exit 0
