#!/bin/bash
# lib/features.sh - Feature registry for Claude Code Starter Kit
#
# Centralizes the mapping between feature names, ENABLE_* flags, and
# whether they have deploy scripts. Replaces 12+ hardcoded is_true checks.
#
# IMPORTANT: This file MUST be sourced AFTER Bash 4+ re-exec is confirmed.
# Uses: declare -A (Bash 4+ only)
#
# Requires: wizard/wizard.sh (is_true, ENABLE_* globals)
# Sets globals: _FEATURE_FLAGS[], _FEATURE_HAS_SCRIPTS[], _FEATURE_ORDER[]
# Exports: (associative arrays only, no functions)
# Dry-run: transparent (data-only, no side effects)
set -euo pipefail

# ---------------------------------------------------------------------------
# Feature registry: maps feature name → ENABLE_* variable name
# ---------------------------------------------------------------------------
declare -A _FEATURE_FLAGS=(
  [safety-net]=ENABLE_SAFETY_NET
  [doc-blocker]=ENABLE_DOC_BLOCKER
  [memory-persistence]=ENABLE_MEMORY_PERSISTENCE
  [strategic-compact]=ENABLE_STRATEGIC_COMPACT
  [pr-creation-log]=ENABLE_PR_CREATION_LOG
  [pre-compact-commit]=ENABLE_PRE_COMPACT_COMMIT
  [auto-update]=ENABLE_AUTO_UPDATE
  [statusline]=ENABLE_STATUSLINE
  [doc-size-guard]=ENABLE_DOC_SIZE_GUARD
  [check-codex-after-plan]=ENABLE_CHECK_CODEX_AFTER_PLAN
  [check-codex-before-write]=ENABLE_CHECK_CODEX_BEFORE_WRITE
  [error-to-codex]=ENABLE_ERROR_TO_CODEX
  [harness-init]=ENABLE_HARNESS_INIT
  [pre-commit-gate]=ENABLE_PRE_COMMIT_GATE
  [post-test-analysis]=ENABLE_POST_TEST_ANALYSIS
)

# ---------------------------------------------------------------------------
# Features that have deploy scripts in features/<name>/scripts/
# ---------------------------------------------------------------------------
declare -A _FEATURE_HAS_SCRIPTS=(
  [memory-persistence]=true
  [strategic-compact]=true
  [auto-update]=true
  [statusline]=true
  [doc-size-guard]=true
  [check-codex-after-plan]=true
  [check-codex-before-write]=true
  [error-to-codex]=true
  [harness-init]=true
  [pre-commit-gate]=true
  [post-test-analysis]=true
)

# ---------------------------------------------------------------------------
# Ordered feature list (determines hook fragment merge order)
# CRITICAL: safety-net MUST be first (PreToolUse runs in array order)
# ---------------------------------------------------------------------------
_FEATURE_ORDER=(
  safety-net doc-blocker
  memory-persistence strategic-compact pr-creation-log pre-compact-commit
  auto-update statusline doc-size-guard
  check-codex-after-plan check-codex-before-write error-to-codex
  harness-init pre-commit-gate post-test-analysis
)

# ---------------------------------------------------------------------------
# Special-case features (not in _FEATURE_ORDER, handled individually):
#   - git-push-review: EDITOR_CHOICE runtime substitution in build_settings_file()
#   - codex-cli: managed by lib/codex-setup.sh (CLI install + auth only, no hooks)
# ---------------------------------------------------------------------------
