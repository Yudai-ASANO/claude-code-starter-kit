#!/bin/bash
set -euo pipefail

# Get project root
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Compute repo identity hash
repo_hash="$(printf '%s' "$project_root" | shasum | cut -d' ' -f1)"

# Suggested repos tracking file
suggested_file="${HOME}/.claude/.harness-init-suggested"

# Check if already suggested for this repo
if [[ -f "$suggested_file" ]] && grep -q "$repo_hash" "$suggested_file" 2>/dev/null; then
  exit 0
fi

# Check if project already has hooks configured
if [[ -f "${project_root}/.claude/settings.json" ]]; then
  if jq -e '.hooks | length > 0' "${project_root}/.claude/settings.json" >/dev/null 2>&1; then
    # Has hooks — record and exit silently
    mkdir -p "$(dirname "$suggested_file")"
    printf '%s\n' "$repo_hash" >> "$suggested_file"
    exit 0
  fi
fi

# Detect tech stack
stack=""
if [[ -f "${project_root}/package.json" ]] && [[ -f "${project_root}/tsconfig.json" ]]; then
  stack="TypeScript"
elif [[ -f "${project_root}/package.json" ]]; then
  stack="JavaScript"
elif [[ -f "${project_root}/composer.json" ]]; then
  stack="PHP"
elif [[ -f "${project_root}/Package.swift" ]]; then
  stack="Swift"
elif [[ -f "${project_root}/build.gradle" ]] || [[ -f "${project_root}/build.gradle.kts" ]]; then
  stack="Kotlin"
elif [[ -f "${project_root}/Cargo.toml" ]]; then
  stack="Rust"
elif [[ -f "${project_root}/go.mod" ]]; then
  stack="Go"
elif [[ -f "${project_root}/Makefile" ]]; then
  stack="Generic"
fi

# No stack detected — exit silently
if [[ -z "$stack" ]]; then
  exit 0
fi

# Record this repo as suggested
mkdir -p "$(dirname "$suggested_file")"
printf '%s\n' "$repo_hash" >> "$suggested_file"

# Output suggestion to stdout (injected into Claude's context)
printf '[harness] %s project detected. Run /init-harness to set up verification hooks.\n' "$stack"
