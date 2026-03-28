#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# --- Determine verification commands ---
declare -a verify_cmds=()
declare -a verify_names=()

# Priority 1: explicit env vars
if [[ -n "${VERIFY_TEST:-}" ]]; then
  verify_cmds+=("$VERIFY_TEST")
  verify_names+=("test")
fi
if [[ -n "${VERIFY_LINT:-}" ]]; then
  verify_cmds+=("$VERIFY_LINT")
  verify_names+=("lint")
fi
if [[ -n "${VERIFY_TYPE:-}" ]]; then
  verify_cmds+=("$VERIFY_TYPE")
  verify_names+=("type")
fi

# Priority 2: auto-detect (only if no env vars set)
if [[ ${#verify_cmds[@]} -eq 0 ]]; then
  # Detect package manager
  pkg_runner="npm"
  if [[ -f "pnpm-lock.yaml" ]]; then
    pkg_runner="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pkg_runner="yarn"
  fi

  # package.json scripts
  if [[ -f "package.json" ]]; then
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
      verify_cmds+=("$pkg_runner test")
      verify_names+=("test")
    fi
    if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
      verify_cmds+=("$pkg_runner run lint")
      verify_names+=("lint")
    fi
  fi

  # Makefile
  if [[ -f "Makefile" ]] && grep -q '^test:' Makefile 2>/dev/null; then
    verify_cmds+=("make test")
    verify_names+=("test")
  fi

  # composer.json
  if [[ -f "composer.json" ]] && jq -e '.scripts.test' composer.json >/dev/null 2>&1; then
    verify_cmds+=("composer test")
    verify_names+=("test")
  fi

  # Cargo.toml
  if [[ -f "Cargo.toml" ]]; then
    verify_cmds+=("cargo test")
    verify_names+=("test")
  fi

  # go.mod
  if [[ -f "go.mod" ]]; then
    verify_cmds+=("go test ./...")
    verify_names+=("test")
  fi

  # Justfile
  if [[ -f "Justfile" ]] && grep -q '^test' Justfile 2>/dev/null; then
    verify_cmds+=("just test")
    verify_names+=("test")
  fi
fi

# No commands found — pass through silently
if [[ ${#verify_cmds[@]} -eq 0 ]]; then
  printf '%s' "$input"
  exit 0
fi

# --- Run verifiers with output bounding and exit code preservation ---
_gate_tmp_dir="/tmp/.claude-gate-$$"
mkdir -p "$_gate_tmp_dir"
# shellcheck disable=SC2064
trap "rm -rf '$_gate_tmp_dir'" EXIT

declare -a failed_names=()

for i in "${!verify_cmds[@]}"; do
  cmd="${verify_cmds[$i]}"
  name="${verify_names[$i]}"
  tmp_out="${_gate_tmp_dir}/${name}.out"

  if eval "$cmd" > "$tmp_out" 2>&1; then
    : # pass
  else
    failed_names+=("$name")
  fi
done

# --- Report results ---
if [[ ${#failed_names[@]} -eq 0 ]]; then
  # All passed — silent
  printf '%s' "$input"
  exit 0
fi

# Build summary
failed_str=""
for i in "${!verify_names[@]}"; do
  name="${verify_names[$i]}"
  code=0
  for fn in "${failed_names[@]}"; do
    if [[ "$fn" == "$name" ]]; then code=1; break; fi
  done
  if [[ -n "$failed_str" ]]; then failed_str+=", "; fi
  failed_str+="${name}(${code})"
done

if [[ "${HARNESS_GATE_MODE:-}" == "strict" ]]; then
  echo "[gate] Verification failed: ${failed_str}. Commit blocked (strict mode)." >&2
  # strict mode: NO stdout pass-through on failure (prevents context injection on blocked commit)
  exit 1
else
  echo "[gate] Verification failed: ${failed_str}. Advisory mode — commit proceeds." >&2
  printf '%s' "$input"
  exit 0
fi
