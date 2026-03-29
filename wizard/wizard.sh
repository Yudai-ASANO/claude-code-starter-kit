#!/bin/bash
# wizard/wizard.sh - Interactive setup wizard for Claude Code Starter Kit
# This file is meant to be sourced by setup.sh, not run standalone.
#
# Interface boundary (public functions called by setup.sh):
#   parse_cli_args "$@"    — Parse CLI flags, set WIZARD_* and ENABLE_* globals
#   run_wizard             — Interactive prompt flow (skipped in non-interactive)
#   save_config <path>     — Persist wizard config to file
#   load_config <path>     — Restore wizard config from file
#   is_true <val>          — Boolean normalization (true/1/yes/on → true)
#
# Sets globals: PROFILE, LANGUAGE, EDITOR_CHOICE, COMMIT_ATTRIBUTION,
#               ENABLE_*, INSTALL_*, SELECTED_PLUGINS, SELECTED_HOOKS,
#               UPDATE_MODE, DRY_RUN, WIZARD_NONINTERACTIVE, _RESET_MERGE_PREFS

# ---------------------------------------------------------------------------
# Globals (defaults can be overridden by defaults.conf or loaded config)
# ---------------------------------------------------------------------------
LANGUAGE="${LANGUAGE:-}"
PROFILE="standard"
EDITOR_CHOICE="${EDITOR_CHOICE:-}"
COMMIT_ATTRIBUTION="${COMMIT_ATTRIBUTION:-}"
ENABLE_NEW_INIT="${ENABLE_NEW_INIT:-}"

INSTALL_AGENTS="${INSTALL_AGENTS:-}"
INSTALL_RULES="${INSTALL_RULES:-}"
INSTALL_COMMANDS="${INSTALL_COMMANDS:-}"
INSTALL_SKILLS="${INSTALL_SKILLS:-}"
INSTALL_MEMORY="${INSTALL_MEMORY:-}"

ENABLE_CODEX_CLI="${ENABLE_CODEX_CLI:-}"
ENABLE_CODEX_MCP="${ENABLE_CODEX_MCP:-}"
ENABLE_GEMINI_CLI="${ENABLE_GEMINI_CLI:-}"
ENABLE_GIT_PUSH_REVIEW="${ENABLE_GIT_PUSH_REVIEW:-}"
ENABLE_CHECK_CODEX_AFTER_PLAN="${ENABLE_CHECK_CODEX_AFTER_PLAN:-}"
ENABLE_CHECK_CODEX_BEFORE_WRITE="${ENABLE_CHECK_CODEX_BEFORE_WRITE:-}"
ENABLE_ERROR_TO_CODEX="${ENABLE_ERROR_TO_CODEX:-}"
ENABLE_DOC_BLOCKER="${ENABLE_DOC_BLOCKER:-}"
ENABLE_HARNESS_INIT="${ENABLE_HARNESS_INIT:-}"
ENABLE_PRE_COMMIT_GATE="${ENABLE_PRE_COMMIT_GATE:-}"
ENABLE_POST_TEST_ANALYSIS="${ENABLE_POST_TEST_ANALYSIS:-}"
ENABLE_MEMORY_PERSISTENCE="${ENABLE_MEMORY_PERSISTENCE:-}"
ENABLE_STRATEGIC_COMPACT="${ENABLE_STRATEGIC_COMPACT:-}"
ENABLE_PR_CREATION_LOG="${ENABLE_PR_CREATION_LOG:-}"
ENABLE_PRE_COMPACT_COMMIT="${ENABLE_PRE_COMPACT_COMMIT:-}"
ENABLE_SAFETY_NET="${ENABLE_SAFETY_NET:-}"
ENABLE_AUTO_UPDATE="${ENABLE_AUTO_UPDATE:-}"
ENABLE_STATUSLINE="${ENABLE_STATUSLINE:-}"
ENABLE_DOC_SIZE_GUARD="${ENABLE_DOC_SIZE_GUARD:-}"

SELECTED_PLUGINS="${SELECTED_PLUGINS:-}"
WIZARD_RESULT="${WIZARD_RESULT:-}"

WIZARD_NONINTERACTIVE="${WIZARD_NONINTERACTIVE:-false}"
UPDATE_MODE="${UPDATE_MODE:-false}"
_RESET_MERGE_PREFS="${_RESET_MERGE_PREFS:-false}"
_MERGE_INTERACTIVE="${_MERGE_INTERACTIVE:-true}"
DRY_RUN="${DRY_RUN:-false}"
WIZARD_CONFIG_FILE=""

# Track CLI-overridden variables (restored after load_config/profile)
_CLI_OVERRIDES=()

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
_wizard_dir() {
  local src
  src="${BASH_SOURCE[0]}"
  while [[ -h "$src" ]]; do
    src="$(readlink "$src")"
  done
  cd -P "$(dirname "$src")" >/dev/null 2>&1 && pwd
}

_project_dir() {
  cd -P "$(_wizard_dir)/.." >/dev/null 2>&1 && pwd
}

_bool_normalize() {
  local val
  val="$(printf "%s" "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$val" in
    1|true|yes|y|on) printf "true" ;;
    *) printf "false" ;;
  esac
}

_set_bool() {
  local var="$1"
  local val="$2"
  # Validate variable name to prevent injection
  if [[ ! "$var" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    return 1
  fi
  printf -v "$var" '%s' "$(_bool_normalize "$val")"
}

_bool_label_enabled() {
  if [[ "$(_bool_normalize "$1")" == "true" ]]; then
    printf "%s" "$STR_ENABLED"
  else
    printf "%s" "$STR_DISABLED"
  fi
}

_bool_label_yesno() {
  if [[ "$(_bool_normalize "$1")" == "true" ]]; then
    printf "%s" "$STR_YES"
  else
    printf "%s" "$STR_NO"
  fi
}

_editor_label() {
  case "${1:-none}" in
    vscode) printf "%s" "$STR_EDITOR_VSCODE" ;;
    cursor) printf "%s" "$STR_EDITOR_CURSOR" ;;
    zed)    printf "%s" "$STR_EDITOR_ZED" ;;
    neovim) printf "%s" "$STR_EDITOR_NEOVIM" ;;
    *)      printf "%s" "$STR_EDITOR_NONE" ;;
  esac
}


_language_label() {
  case "${1:-}" in
    ja) printf "日本語" ;;
    *)  printf "English" ;;
  esac
}

# ---------------------------------------------------------------------------
# Defaults, profiles, config persistence
# ---------------------------------------------------------------------------

# Allowed config variable names (used by _safe_source_config for allowlist validation)
_CONFIG_ALLOWED_KEYS="LANGUAGE EDITOR_CHOICE COMMIT_ATTRIBUTION ENABLE_NEW_INIT INSTALL_AGENTS INSTALL_RULES INSTALL_COMMANDS INSTALL_SKILLS INSTALL_MEMORY ENABLE_CODEX_CLI ENABLE_CODEX_MCP ENABLE_GEMINI_CLI ENABLE_GIT_PUSH_REVIEW ENABLE_DOC_BLOCKER ENABLE_HARNESS_INIT ENABLE_PRE_COMMIT_GATE ENABLE_POST_TEST_ANALYSIS ENABLE_MEMORY_PERSISTENCE ENABLE_STRATEGIC_COMPACT ENABLE_PR_CREATION_LOG ENABLE_PRE_COMPACT_COMMIT ENABLE_SAFETY_NET ENABLE_AUTO_UPDATE ENABLE_STATUSLINE ENABLE_DOC_SIZE_GUARD ENABLE_CHECK_CODEX_AFTER_PLAN ENABLE_CHECK_CODEX_BEFORE_WRITE ENABLE_ERROR_TO_CODEX SELECTED_PLUGINS"

# Safe key=value parser: reads a config file line-by-line and only sets
# variables whose names appear in the allowlist. This replaces the previous
# `. "$file"` pattern to prevent arbitrary code execution.
_safe_source_config() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  local key value
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    # Skip blank lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    # Strip surrounding whitespace and quotes
    key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    value="$(printf '%s' "$value" | sed 's/^[[:space:]]*"//;s/"[[:space:]]*$//')"
    # Validate key is alphanumeric/underscore and in allowlist
    if [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] && [[ " $_CONFIG_ALLOWED_KEYS " == *" $key "* ]]; then
      printf -v "$key" '%s' "$value"
    fi
  done < "$file"
}


load_profile_config() {
  local dir
  dir="$(_project_dir)"
  if [[ -f "$dir/profiles/standard.conf" ]]; then
    _safe_source_config "$dir/profiles/standard.conf"
  fi
}

load_config() {
  local file="${1:-$HOME/.claude-starter-kit.conf}"
  if [[ -f "$file" ]]; then
    _safe_source_config "$file"
  fi
  # Backward compat: map old ENABLE_CODEX_MCP to ENABLE_CODEX_CLI
  if [[ -n "${ENABLE_CODEX_MCP:-}" ]] && [[ -z "${ENABLE_CODEX_CLI:-}" ]]; then
    ENABLE_CODEX_CLI="$ENABLE_CODEX_MCP"
  fi
}

fill_missing_profile_defaults() {
  local saved_enable_new_init="${ENABLE_NEW_INIT:-}"
  load_profile_config
  if [[ -n "$saved_enable_new_init" ]]; then
    ENABLE_NEW_INIT="$saved_enable_new_init"
  fi
}

# Sanitize a value for safe inclusion in a key=value config file.
# Strips characters that could be interpreted as shell metacharacters.
_sanitize_config_value() {
  printf '%s' "$1" | tr -cd 'a-zA-Z0-9_,.:@/ -'
}

# Keys to save in config file, in order. Empty string = blank line separator.
_CONFIG_SAVE_KEYS=(
  LANGUAGE EDITOR_CHOICE COMMIT_ATTRIBUTION ENABLE_NEW_INIT
  ""
  INSTALL_AGENTS INSTALL_RULES INSTALL_COMMANDS INSTALL_SKILLS INSTALL_MEMORY
  ""
  ENABLE_CODEX_CLI ENABLE_GEMINI_CLI ENABLE_GIT_PUSH_REVIEW ENABLE_DOC_BLOCKER
  ENABLE_HARNESS_INIT ENABLE_PRE_COMMIT_GATE ENABLE_POST_TEST_ANALYSIS ENABLE_MEMORY_PERSISTENCE
  ENABLE_STRATEGIC_COMPACT ENABLE_PR_CREATION_LOG ENABLE_PRE_COMPACT_COMMIT
  ENABLE_SAFETY_NET ENABLE_AUTO_UPDATE ENABLE_STATUSLINE ENABLE_DOC_SIZE_GUARD
  ENABLE_CHECK_CODEX_AFTER_PLAN ENABLE_CHECK_CODEX_BEFORE_WRITE ENABLE_ERROR_TO_CODEX
  ""
  SELECTED_PLUGINS
)

save_config() {
  local file="${1:-$HOME/.claude-starter-kit.conf}"
  {
    printf '# Claude Code Starter Kit - Wizard Config\n'
    local _key
    for _key in "${_CONFIG_SAVE_KEYS[@]}"; do
      if [[ -z "$_key" ]]; then
        printf '\n'
      else
        printf '%s="%s"\n' "$_key" "$(_sanitize_config_value "${!_key:-}")"
      fi
    done
  } > "$file"
  # Restrict config file permissions (contains user preferences)
  chmod 600 "$file"
}

# ---------------------------------------------------------------------------
# Restore configuration from manifest (for update mode)
# ---------------------------------------------------------------------------
_restore_config_from_manifest() {
  local manifest="$HOME/.claude/.starter-kit-manifest.json"
  [[ -f "$manifest" ]] || return 1

  local config_file current_settings
  local manifest_commit_attribution manifest_new_init
  local saved_has_commit_attribution="false" saved_has_new_init="false"
  local current_commit_attribution="" current_new_init=""
  LANGUAGE="$(jq -r '.language // "en"' "$manifest")"
  EDITOR_CHOICE="$(jq -r '.editor // "none"' "$manifest")"
  SELECTED_PLUGINS="$(jq -r '.plugins // ""' "$manifest")"
  manifest_commit_attribution="$(jq -r '.commit_attribution // ""' "$manifest")"
  manifest_new_init="$(jq -r '.new_init // ""' "$manifest")"
  config_file="${WIZARD_CONFIG_FILE:-$HOME/.claude-starter-kit.conf}"
  current_settings="$HOME/.claude/settings.json"

  if [[ -f "$config_file" ]]; then
    grep -q '^COMMIT_ATTRIBUTION=' "$config_file" && saved_has_commit_attribution="true"
    grep -q '^ENABLE_NEW_INIT=' "$config_file" && saved_has_new_init="true"
  fi

  if [[ -f "$current_settings" ]]; then
    current_commit_attribution="$(
      jq -r 'if has("attribution") then "false" else "true" end' "$current_settings" 2>/dev/null || echo ""
    )"
    current_new_init="$(jq -r '.env.CLAUDE_CODE_NEW_INIT // ""' "$current_settings" 2>/dev/null || echo "")"
  fi

  # Load profile config to get INSTALL_* and ENABLE_* flags
  load_profile_config

  # Load saved wizard config for feature toggles
  load_config "$config_file"

  # Fallback order for keys introduced after older installs:
  # saved config > current deployed settings.json > manifest > profile default.
  if [[ "$saved_has_commit_attribution" != "true" ]]; then
    if [[ -n "$current_commit_attribution" ]]; then
      COMMIT_ATTRIBUTION="$current_commit_attribution"
    elif [[ -n "$manifest_commit_attribution" ]]; then
      COMMIT_ATTRIBUTION="$manifest_commit_attribution"
    fi
  fi

  if [[ "$saved_has_new_init" != "true" ]]; then
    if [[ -n "$current_new_init" ]]; then
      ENABLE_NEW_INIT="$current_new_init"
    elif [[ -n "$manifest_new_init" ]]; then
      ENABLE_NEW_INIT="$manifest_new_init"
    fi
  fi

  # Detect ENABLE_GEMINI_CLI from deployed settings.json if not in saved config
  # (handles upgrades from older installs that lack this key in config)
  if [[ -z "${ENABLE_GEMINI_CLI:-}" ]] && [[ -f "$current_settings" ]]; then
    local _has_gemini
    _has_gemini="$(jq -r '.permissions.allow // [] | map(select(test("gemini"))) | if length > 0 then "true" else "false" end' "$current_settings" 2>/dev/null || echo "false")"
    ENABLE_GEMINI_CLI="$_has_gemini"
  fi

  load_strings "$LANGUAGE"
}

_capture_cli_overrides() {
  local _saved=()
  local _var _val
  for _var in "${_CLI_OVERRIDES[@]+"${_CLI_OVERRIDES[@]}"}"; do
    _val="${!_var:-}"
    if [[ -n "$_val" ]]; then
      _saved+=("${_var}=${_val}")
    fi
  done

  printf '%s\n' "${_saved[@]+"${_saved[@]}"}"
}

_restore_cli_overrides() {
  local _pair _restore_key _restore_val
  for _pair in "$@"; do
    if [[ -n "$_pair" ]]; then
      _restore_key="${_pair%%=*}"
      _restore_val="${_pair#*=}"
      printf -v "$_restore_key" '%s' "$_restore_val"
    fi
  done
}

# ---------------------------------------------------------------------------
# i18n
# ---------------------------------------------------------------------------
load_strings() {
  local lang="${1:-en}"
  local dir
  dir="$(_project_dir)"
  case "$lang" in
    ja)
      # shellcheck source=/dev/null
      . "$dir/i18n/ja/strings.sh"
      ;;
    *)
      # shellcheck source=/dev/null
      . "$dir/i18n/en/strings.sh"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Plugin management
# ---------------------------------------------------------------------------
PLUGIN_NAMES=()
PLUGIN_SELECTED=()
PLUGIN_MARKETPLACES=()

_load_plugins() {
  local dir
  dir="$(_project_dir)"
  local file="$dir/config/plugins.json"
  PLUGIN_NAMES=()
  PLUGIN_SELECTED=()
  PLUGIN_MARKETPLACES=()

  if [[ ! -f "$file" ]] || ! command -v jq &>/dev/null; then
    return
  fi

  local count
  count="$(jq '.plugins | length' "$file")"
  local i
  for ((i = 0; i < count; i++)); do
    local name marketplace
    name="$(jq -r ".plugins[$i].name" "$file")"
    marketplace="$(jq -r '.plugins['"$i"'].marketplace // "claude-plugins-official"' "$file")"
    PLUGIN_NAMES+=("$name")
    PLUGIN_SELECTED+=("false")
    PLUGIN_MARKETPLACES+=("$marketplace")
  done
}

# Bash 3 compatible collision detection (no associative arrays)
# Returns 0 if the given plugin name exists in multiple marketplaces
_plugin_has_collision() {
  local target="$1" i
  local seen_mp=""
  for i in "${!PLUGIN_NAMES[@]}"; do
    if [[ "${PLUGIN_NAMES[$i]}" == "$target" ]]; then
      if [[ -n "$seen_mp" ]] && [[ "$seen_mp" != "${PLUGIN_MARKETPLACES[$i]}" ]]; then
        return 0
      fi
      seen_mp="${PLUGIN_MARKETPLACES[$i]}"
    fi
  done
  return 1
}

_init_plugins_for_profile() {
  local i
  for i in "${!PLUGIN_NAMES[@]}"; do
    PLUGIN_SELECTED[$i]="true"
  done
}

_apply_plugins_from_csv() {
  local csv="$1"
  local i
  for i in "${!PLUGIN_SELECTED[@]}"; do
    PLUGIN_SELECTED[$i]="false"
  done

  IFS=',' read -r -a _wanted <<< "$csv"
  local w _w_name _w_mp
  for i in "${!PLUGIN_NAMES[@]}"; do
    for w in "${_wanted[@]}"; do
      if [[ "$w" == *"@"* ]]; then
        # Qualified name: name@marketplace — exact match
        _w_name="${w%%@*}"
        _w_mp="${w#*@}"
        if [[ "$_w_name" == "${PLUGIN_NAMES[$i]}" ]] && [[ "$_w_mp" == "${PLUGIN_MARKETPLACES[$i]}" ]]; then
          PLUGIN_SELECTED[$i]="true"
        fi
      elif _plugin_has_collision "$w"; then
        # Bare name with collision — match claude-plugins-official (backward compat)
        if [[ "$w" == "${PLUGIN_NAMES[$i]}" ]] && [[ "${PLUGIN_MARKETPLACES[$i]}" == "claude-plugins-official" ]]; then
          PLUGIN_SELECTED[$i]="true"
        fi
      else
        # Bare name without collision — simple match
        if [[ "$w" == "${PLUGIN_NAMES[$i]}" ]]; then
          PLUGIN_SELECTED[$i]="true"
        fi
      fi
    done
  done
}

_compute_selected_plugins() {
  local out=()
  local i entry
  for i in "${!PLUGIN_NAMES[@]}"; do
    if [[ "${PLUGIN_SELECTED[$i]}" == "true" ]]; then
      entry="${PLUGIN_NAMES[$i]}"
      if _plugin_has_collision "${PLUGIN_NAMES[$i]}" \
         || [[ "${PLUGIN_MARKETPLACES[$i]}" != "claude-plugins-official" ]]; then
        entry="${PLUGIN_NAMES[$i]}@${PLUGIN_MARKETPLACES[$i]}"
      fi
      out+=("$entry")
    fi
  done
  if [[ "${#out[@]}" -eq 0 ]]; then
    SELECTED_PLUGINS=""
  else
    local IFS=,
    SELECTED_PLUGINS="${out[*]}"
  fi
}

# ---------------------------------------------------------------------------
# Hook management
# ---------------------------------------------------------------------------
HOOK_KEYS=(
  "ENABLE_SAFETY_NET"
  "ENABLE_AUTO_UPDATE"
  "ENABLE_GIT_PUSH_REVIEW"
  "ENABLE_DOC_BLOCKER"
  "ENABLE_MEMORY_PERSISTENCE"
  "ENABLE_STRATEGIC_COMPACT"
  "ENABLE_PR_CREATION_LOG"
  "ENABLE_PRE_COMPACT_COMMIT"
  "ENABLE_DOC_SIZE_GUARD"
  "ENABLE_CHECK_CODEX_AFTER_PLAN"
  "ENABLE_CHECK_CODEX_BEFORE_WRITE"
  "ENABLE_ERROR_TO_CODEX"
  "ENABLE_HARNESS_INIT"
  "ENABLE_PRE_COMMIT_GATE"
  "ENABLE_POST_TEST_ANALYSIS"
)

# Shared labels for HOOK_KEYS — used by _step_hooks() and _step_confirm().
# Initialized lazily by _init_hook_labels() because STR_* vars are set after
# load_strings(), which runs later than this file is sourced.
HOOK_LABELS=()
_init_hook_labels() {
  [[ ${#HOOK_LABELS[@]} -gt 0 ]] && return
  HOOK_LABELS=(
    "${STR_HOOKS_SAFETY_NET:-Safety Net - Block destructive git/filesystem commands}"
    "${STR_HOOKS_AUTO_UPDATE:-Auto Update - Automatically update starter kit on session start}"
    "$STR_HOOKS_GIT_PUSH"
    "$STR_HOOKS_DOC_BLOCK"
    "$STR_HOOKS_MEMORY"
    "$STR_HOOKS_COMPACT"
    "$STR_HOOKS_PR_LOG"
    "${STR_HOOKS_PRE_COMMIT:-Pre-compact auto-commit}"
    "${STR_HOOKS_DOC_SIZE:-Doc Size Guard - Warn when CLAUDE.md/AGENTS.md is too large}"
    "${STR_HOOKS_CHECK_CODEX_AFTER_PLAN:-Check Codex After Plan - Codex review after plan/design save}"
    "${STR_HOOKS_CHECK_CODEX_BEFORE_WRITE:-Check Codex Before Write - Codex review before large writes}"
    "${STR_HOOKS_ERROR_TO_CODEX:-Error to Codex - Delegate errors to Codex for debugging}"
    "${STR_HOOKS_HARNESS_INIT:-Harness Init - Detect tech stack and suggest /init-harness}"
    "${STR_HOOKS_PRE_COMMIT_GATE:-Pre-Commit Gate - Run verification before git commit (advisory)}"
    "${STR_HOOKS_POST_TEST_ANALYSIS:-Post-Test Analysis - Analyze test failures (opt-in)}"
  )
}

_apply_hooks_csv() {
  local csv="$1"
  local i
  for i in "${!HOOK_KEYS[@]}"; do
    printf -v "${HOOK_KEYS[$i]}" '%s' "false"
  done

  IFS=',' read -r -a _items <<< "$csv"
  local item
  for item in "${_items[@]}"; do
    case "$item" in
      safety-net)  ENABLE_SAFETY_NET="true" ;;
      auto-update) ENABLE_AUTO_UPDATE="true" ;;
      git-push)   ENABLE_GIT_PUSH_REVIEW="true" ;;
      doc-block)  ENABLE_DOC_BLOCKER="true" ;;
      memory)     ENABLE_MEMORY_PERSISTENCE="true" ;;
      compact)    ENABLE_STRATEGIC_COMPACT="true" ;;
      pr-log)     ENABLE_PR_CREATION_LOG="true" ;;
      pre-commit) ENABLE_PRE_COMPACT_COMMIT="true" ;;
      doc-size)   ENABLE_DOC_SIZE_GUARD="true" ;;
      check-codex-after-plan) ENABLE_CHECK_CODEX_AFTER_PLAN="true" ;;
      check-codex-before-write) ENABLE_CHECK_CODEX_BEFORE_WRITE="true" ;;
      error-to-codex) ENABLE_ERROR_TO_CODEX="true" ;;
      harness-init)         ENABLE_HARNESS_INIT="true" ;;
      pre-commit-gate)      ENABLE_PRE_COMMIT_GATE="true" ;;
      post-test-analysis)   ENABLE_POST_TEST_ANALYSIS="true" ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# CLI parsing for --non-interactive mode
# ---------------------------------------------------------------------------
parse_cli_args() {
  local arg
  while [[ "$#" -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --non-interactive)
        WIZARD_NONINTERACTIVE="true"
        _MERGE_INTERACTIVE="false"
        ;;
      --update)
        UPDATE_MODE="true"
        WIZARD_NONINTERACTIVE="true"
        ;;
      --reset-prefs)
        _RESET_MERGE_PREFS="true"
        ;;
      --dry-run)
        DRY_RUN="true"
        ;;
      --language=*)      LANGUAGE="${arg#*=}"; _CLI_OVERRIDES+=("LANGUAGE") ;;
      --language)        shift; LANGUAGE="${1:-}"; _CLI_OVERRIDES+=("LANGUAGE") ;;
      --editor=*)        EDITOR_CHOICE="${arg#*=}"; _CLI_OVERRIDES+=("EDITOR_CHOICE") ;;
      --editor)          shift; EDITOR_CHOICE="${1:-}"; _CLI_OVERRIDES+=("EDITOR_CHOICE") ;;
      --new-init=*)      _set_bool ENABLE_NEW_INIT "${arg#*=}"; _CLI_OVERRIDES+=("ENABLE_NEW_INIT") ;;
      --new-init)        shift; _set_bool ENABLE_NEW_INIT "${1:-}"; _CLI_OVERRIDES+=("ENABLE_NEW_INIT") ;;
      --codex-cli=*)     _set_bool ENABLE_CODEX_CLI "${arg#*=}"; _CLI_OVERRIDES+=("ENABLE_CODEX_CLI") ;;
      --codex-cli)       shift; _set_bool ENABLE_CODEX_CLI "${1:-}"; _CLI_OVERRIDES+=("ENABLE_CODEX_CLI") ;;
      --codex-mcp=*)     _set_bool ENABLE_CODEX_CLI "${arg#*=}"; _CLI_OVERRIDES+=("ENABLE_CODEX_CLI") ;; # deprecated alias
      --codex-mcp)       shift; _set_bool ENABLE_CODEX_CLI "${1:-}"; _CLI_OVERRIDES+=("ENABLE_CODEX_CLI") ;; # deprecated alias
      --gemini-cli=*)    _set_bool ENABLE_GEMINI_CLI "${arg#*=}"; _CLI_OVERRIDES+=("ENABLE_GEMINI_CLI") ;;
      --gemini-cli)      shift; _set_bool ENABLE_GEMINI_CLI "${1:-}"; _CLI_OVERRIDES+=("ENABLE_GEMINI_CLI") ;;
      --commit-attribution=*) _set_bool COMMIT_ATTRIBUTION "${arg#*=}"; _CLI_OVERRIDES+=("COMMIT_ATTRIBUTION") ;;
      --commit-attribution)   shift; _set_bool COMMIT_ATTRIBUTION "${1:-}"; _CLI_OVERRIDES+=("COMMIT_ATTRIBUTION") ;;
      --hooks=*)
        _apply_hooks_csv "${arg#*=}"
        ;;
      --plugins=*)
        _load_plugins
        _apply_plugins_from_csv "${arg#*=}"
        _compute_selected_plugins
        ;;
      --config=*)
        WIZARD_CONFIG_FILE="${arg#*=}"
        load_config "$WIZARD_CONFIG_FILE"
        ;;
      --config)
        shift
        WIZARD_CONFIG_FILE="${1:-}"
        load_config "$WIZARD_CONFIG_FILE"
        ;;
    esac
    shift
  done
}

# ---------------------------------------------------------------------------
# Display width helper (ASCII=1col, CJK/fullwidth=2col)
# ---------------------------------------------------------------------------
_display_width() {
  local str="$1"
  local bytes chars multibyte
  bytes=$(printf '%s' "$str" | LC_ALL=C wc -c | tr -d ' ')
  chars=$(printf '%s' "$str" | wc -m | tr -d ' ')
  multibyte=$(( (bytes - chars) / 2 ))
  printf '%d' $(( chars + multibyte ))
}

_print_banner() {
  local line1="$1"
  local line2="$2"
  local w1 w2 max_w box_inner pad1 pad2

  w1=$(_display_width "$line1")
  w2=$(_display_width "$line2")
  max_w=$w1
  [[ $w2 -gt $max_w ]] && max_w=$w2

  box_inner=$((max_w + 4))

  local border=""
  local i
  for ((i = 0; i < box_inner; i++)); do border+="═"; done

  pad1=$((max_w - w1))
  pad2=$((max_w - w2))

  printf "${BOLD}${CYAN}╔%s╗${NC}\n" "$border"
  printf "${BOLD}${CYAN}║  %s%*s  ║${NC}\n" "$line1" "$pad1" ""
  printf "${BOLD}${CYAN}║  %s%*s  ║${NC}\n" "$line2" "$pad2" ""
  printf "${BOLD}${CYAN}╚%s╝${NC}\n" "$border"
}

# ---------------------------------------------------------------------------
# Interactive steps
# ---------------------------------------------------------------------------
_step_language() {
  if [[ -n "$LANGUAGE" ]]; then return; fi
  printf "\nSelect language: 1) English 2) 日本語\n"
  local choice=""
  read -r -p "Choice: " choice
  case "$choice" in
    2) LANGUAGE="ja" ;;
    *) LANGUAGE="en" ;;
  esac
}

_step_profile() {
  load_profile_config
}

# _prompt_yes_no <var_name> <default>
#
# Reads a 1/2 choice and sets the named variable to "true" or "false".
# <default> is "1" (yes) or "2" (no).
_prompt_yes_no() {
  local _var="$1"
  local _default="${2:-2}"
  local choice=""
  read -r -p "${STR_CHOICE} [${_default}]: " choice
  [[ -z "$choice" ]] && choice="$_default"
  case "$choice" in
    1) printf -v "$_var" '%s' "true" ;;
    *) printf -v "$_var" '%s' "false" ;;
  esac
}

_step_codex() {
  # Skip if explicitly set by CLI arg
  local _ov; for _ov in "${_CLI_OVERRIDES[@]+"${_CLI_OVERRIDES[@]}"}"; do [[ "$_ov" == "ENABLE_CODEX_CLI" ]] && return; done

  section "$STR_CODEX_TITLE"
  printf "  1) %s\n" "$STR_CODEX_YES"
  printf "  2) %s\n" "$STR_CODEX_NO"
  local _default="2"
  if [[ "${ENABLE_CODEX_CLI:-}" == "true" ]]; then _default="1"; fi
  _prompt_yes_no ENABLE_CODEX_CLI "$_default"
}

_step_gemini() {
  # Skip if explicitly set by CLI arg
  local _ov; for _ov in "${_CLI_OVERRIDES[@]+"${_CLI_OVERRIDES[@]}"}"; do [[ "$_ov" == "ENABLE_GEMINI_CLI" ]] && return; done

  section "$STR_GEMINI_TITLE"
  printf "  1) %s\n" "$STR_GEMINI_YES"
  printf "  2) %s\n" "$STR_GEMINI_NO"
  local _default="2"
  if [[ "${ENABLE_GEMINI_CLI:-}" == "true" ]]; then _default="1"; fi
  _prompt_yes_no ENABLE_GEMINI_CLI "$_default"
}

_step_new_init() {
  return
}

_step_editor() {
  if [[ -n "$EDITOR_CHOICE" ]]; then return; fi
  section "$STR_EDITOR_TITLE"
  printf "  1) %s\n" "$STR_EDITOR_VSCODE"
  printf "  2) %s\n" "$STR_EDITOR_CURSOR"
  printf "  3) %s\n" "$STR_EDITOR_ZED"
  printf "  4) %s\n" "$STR_EDITOR_NEOVIM"
  printf "  5) %s\n" "$STR_EDITOR_NONE"
  local choice=""
  read -r -p "${STR_CHOICE}: " choice
  case "$choice" in
    1) EDITOR_CHOICE="vscode" ;;
    2) EDITOR_CHOICE="cursor" ;;
    3) EDITOR_CHOICE="zed" ;;
    4) EDITOR_CHOICE="neovim" ;;
    *) EDITOR_CHOICE="none" ;;
  esac
}

_step_hooks() {
  _init_hook_labels

  section "$STR_HOOKS_TITLE"
  while true; do
    local i
    for i in "${!HOOK_KEYS[@]}"; do
      local key="${HOOK_KEYS[$i]}"
      local state="${!key}"
      local mark="[ ]"
      if [[ "$state" == "true" ]]; then mark="[*]"; fi
      printf "  %2d) %s %s\n" "$((i+1))" "$mark" "${HOOK_LABELS[$i]}"
    done
    printf "\n  %s\n\n" "$STR_TOGGLE_HINT"

    local choice=""
    read -r -p "${STR_CHOICE}: " choice
    if [[ -z "$choice" ]]; then break; fi

    case "$choice" in
      a|A|all)
        for i in "${!HOOK_KEYS[@]}"; do printf -v "${HOOK_KEYS[$i]}" '%s' "true"; done
        ;;
      n|N|none)
        for i in "${!HOOK_KEYS[@]}"; do printf -v "${HOOK_KEYS[$i]}" '%s' "false"; done
        ;;
      *)
        local -a _tokens=()
        read -r -a _tokens <<< "$choice"
        for token in "${_tokens[@]}"; do
          if [[ "$token" =~ ^[0-9]+$ ]] && [[ "$token" -ge 1 ]] && [[ "$token" -le "${#HOOK_KEYS[@]}" ]]; then
            local idx=$((token-1))
            local key="${HOOK_KEYS[$idx]}"
            local current="${!key}"
            if [[ "$current" == "true" ]]; then
              printf -v "$key" '%s' "false"
            else
              printf -v "$key" '%s' "true"
            fi
          fi
        done
        ;;
    esac
    printf "\n"
  done
}

_step_plugins() {
  _load_plugins
  _init_plugins_for_profile

  if [[ -n "$SELECTED_PLUGINS" ]]; then
    _apply_plugins_from_csv "$SELECTED_PLUGINS"
  fi

  section "$STR_PLUGINS_TITLE"
  printf "%s\n\n" "$STR_PLUGINS_NOTE"

  while true; do
    local i _display_name
    for i in "${!PLUGIN_NAMES[@]}"; do
      local mark="[ ]"
      if [[ "${PLUGIN_SELECTED[$i]}" == "true" ]]; then mark="[*]"; fi
      _display_name="${PLUGIN_NAMES[$i]}"
      if _plugin_has_collision "${PLUGIN_NAMES[$i]}"; then
        _display_name="${PLUGIN_NAMES[$i]} [${PLUGIN_MARKETPLACES[$i]}]"
      fi
      printf "  %2d) %s %s\n" "$((i+1))" "$mark" "$_display_name"
    done
    printf "\n  %s\n\n" "$STR_TOGGLE_HINT"

    local choice=""
    read -r -p "${STR_CHOICE}: " choice
    if [[ -z "$choice" ]]; then break; fi

    case "$choice" in
      a|A|all)
        for i in "${!PLUGIN_SELECTED[@]}"; do PLUGIN_SELECTED[$i]="true"; done
        ;;
      n|N|none)
        for i in "${!PLUGIN_SELECTED[@]}"; do PLUGIN_SELECTED[$i]="false"; done
        ;;
      *)
        local -a _tokens=()
        read -r -a _tokens <<< "$choice"
        for token in "${_tokens[@]}"; do
          if [[ "$token" =~ ^[0-9]+$ ]] && [[ "$token" -ge 1 ]] && [[ "$token" -le "${#PLUGIN_NAMES[@]}" ]]; then
            local idx=$((token-1))
            if [[ "${PLUGIN_SELECTED[$idx]}" == "true" ]]; then
              PLUGIN_SELECTED[$idx]="false"
            else
              PLUGIN_SELECTED[$idx]="true"
            fi
          fi
        done
        ;;
    esac
    printf "\n"
  done

  _compute_selected_plugins
}

_step_commit() {
  if [[ -n "$COMMIT_ATTRIBUTION" ]]; then return; fi
  section "$STR_COMMIT_TITLE"
  printf "  1) %s\n" "$STR_COMMIT_YES"
  printf "  2) %s\n" "$STR_COMMIT_NO"
  local choice=""
  read -r -p "${STR_CHOICE}: " choice
  case "$choice" in
    1) COMMIT_ATTRIBUTION="true" ;;
    *) COMMIT_ATTRIBUTION="false" ;;
  esac
}

_step_confirm() {
  _init_hook_labels

  section "$STR_CONFIRM_TITLE"
  printf "%-20s : %s\n" "$STR_CONFIRM_LANGUAGE" "$(_language_label "$LANGUAGE")"
  printf "%-20s : %s\n" "$STR_CONFIRM_CODEX" "$(_bool_label_enabled "$ENABLE_CODEX_CLI")"
  printf "%-20s : %s\n" "$STR_CONFIRM_GEMINI" "$(_bool_label_enabled "$ENABLE_GEMINI_CLI")"
  printf "%-20s : %s\n" "$STR_CONFIRM_NEW_INIT" "$(_bool_label_enabled "$ENABLE_NEW_INIT")"
  printf "%-20s : %s\n" "$STR_CONFIRM_EDITOR" "$(_editor_label "$EDITOR_CHOICE")"
  printf "%-20s : %s\n" "$STR_CONFIRM_STATUSLINE" "$(_bool_label_enabled "${ENABLE_STATUSLINE:-false}")"

  # Hooks summary
  local hook_labels=()
  local i
  for i in "${!HOOK_KEYS[@]}"; do
    local key="${HOOK_KEYS[$i]}"
    local state="${!key}"
    if [[ "$state" == "true" ]]; then
      hook_labels+=("${HOOK_LABELS[$i]}")
    fi
  done
  if [[ "${#hook_labels[@]}" -eq 0 ]]; then
    printf "%-20s : %s\n" "$STR_CONFIRM_HOOKS" "$STR_NONE"
  else
    printf "%-20s : %d %s\n" "$STR_CONFIRM_HOOKS" "${#hook_labels[@]}" "$STR_SELECTED"
  fi

  # Plugins summary
  if [[ -z "$SELECTED_PLUGINS" ]]; then
    printf "%-20s : %s\n" "$STR_CONFIRM_PLUGINS" "$STR_NONE"
  else
    local count
    IFS=',' read -r -a _plist <<< "$SELECTED_PLUGINS"
    printf "%-20s : %d %s\n" "$STR_CONFIRM_PLUGINS" "${#_plist[@]}" "$STR_SELECTED"
  fi

  printf "%-20s : %s\n" "$STR_CONFIRM_COMMIT" "$(_bool_label_yesno "$COMMIT_ATTRIBUTION")"

  section "$STR_CONFIRM_DEPLOY"
  printf "  1) %s\n" "$STR_CONFIRM_YES"
  printf "  2) %s\n" "$STR_CONFIRM_EDIT"
  printf "  3) %s\n" "$STR_CONFIRM_SAVE"
  printf "  4) %s\n" "$STR_CONFIRM_CANCEL"

  local choice=""
  read -r -p "${STR_CHOICE}: " choice
  case "$choice" in
    1) WIZARD_RESULT="deploy" ;;
    2) WIZARD_RESULT="edit" ;;
    3) WIZARD_RESULT="save" ;;
    *) WIZARD_RESULT="cancel" ;;
  esac
}

# ---------------------------------------------------------------------------
# Non-interactive mode: fill in missing values with profile defaults
# ---------------------------------------------------------------------------
_fill_noninteractive_defaults() {
  [[ -z "$LANGUAGE" ]] && LANGUAGE="en"

  # Save CLI-overridden values before loading profile/config
  # (both load_config and load_profile_config unconditionally set ENABLE_* flags)
  local _saved_overrides=()
  while IFS= read -r _override; do
    [[ -n "$_override" ]] && _saved_overrides+=("$_override")
  done < <(_capture_cli_overrides)

  load_profile_config

  # Restore CLI-overridden values (CLI takes precedence over profile/config)
  _restore_cli_overrides "${_saved_overrides[@]+"${_saved_overrides[@]}"}"

  [[ -z "$EDITOR_CHOICE" ]] && EDITOR_CHOICE="none"
  [[ -z "$COMMIT_ATTRIBUTION" ]] && COMMIT_ATTRIBUTION="false"
  [[ -z "$ENABLE_NEW_INIT" ]] && ENABLE_NEW_INIT="true"
  [[ -z "${ENABLE_STATUSLINE:-}" ]] && ENABLE_STATUSLINE="true"
  [[ -z "${ENABLE_CHECK_CODEX_AFTER_PLAN:-}" ]] && ENABLE_CHECK_CODEX_AFTER_PLAN="false"
  [[ -z "${ENABLE_CHECK_CODEX_BEFORE_WRITE:-}" ]] && ENABLE_CHECK_CODEX_BEFORE_WRITE="false"
  [[ -z "${ENABLE_ERROR_TO_CODEX:-}" ]] && ENABLE_ERROR_TO_CODEX="false"

  # Compute plugins if not already set
  if [[ -z "$SELECTED_PLUGINS" ]]; then
    _load_plugins
    _init_plugins_for_profile
    _compute_selected_plugins
  fi

  WIZARD_RESULT="deploy"
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------
run_wizard() {
  local dir
  dir="$(_project_dir)"

  # Source libraries
  # shellcheck source=/dev/null
  . "$dir/lib/colors.sh"
  # shellcheck source=/dev/null
  . "$dir/lib/detect.sh"

  # Update mode: restore from manifest, skip wizard
  local _saved_cli=()
  while IFS= read -r _override; do
    [[ -n "$_override" ]] && _saved_cli+=("$_override")
  done < <(_capture_cli_overrides)

  if [[ "$UPDATE_MODE" == "true" ]]; then
    _restore_config_from_manifest
    _restore_cli_overrides "${_saved_cli[@]+"${_saved_cli[@]}"}"
    WIZARD_RESULT="deploy"
    return
  fi

  # Save CLI-overridden values before loading config file
  # Load previous config if available
  load_config "${WIZARD_CONFIG_FILE:-$HOME/.claude-starter-kit.conf}"

  # Restore CLI-overridden values (CLI takes precedence over saved config)
  _restore_cli_overrides "${_saved_cli[@]+"${_saved_cli[@]}"}"

  # Non-interactive mode: fill defaults and return
  if [[ "$WIZARD_NONINTERACTIVE" == "true" ]]; then
    _fill_noninteractive_defaults
    load_strings "$LANGUAGE"
    info "Non-interactive mode: LANGUAGE=$LANGUAGE"
    return
  fi

  # Detect saved config and offer to reuse
  local _config_file="${WIZARD_CONFIG_FILE:-$HOME/.claude-starter-kit.conf}"
  if [[ -f "$_config_file" ]]; then
    load_strings "${LANGUAGE:-en}"
    printf "\n"
    info "$STR_SAVED_CONFIG_FOUND"
    printf "  1) %s\n" "$STR_SAVED_CONFIG_REUSE"
    printf "  2) %s\n" "$STR_SAVED_CONFIG_FRESH"
    local _config_choice=""
    read -r -p "${STR_CHOICE}: " _config_choice
    if [[ "$_config_choice" == "1" ]]; then
      if [[ -n "$PROFILE" ]]; then
        fill_missing_profile_defaults
      fi
      # Show confirm with saved settings
      _step_confirm
      if [[ "$WIZARD_RESULT" != "edit" ]]; then
        return
      fi
      # User chose to edit - fall through to full wizard
    fi
    # Reset for fresh start (all user choices cleared so wizard asks again)
    LANGUAGE=""
    EDITOR_CHOICE=""
    COMMIT_ATTRIBUTION=""
    ENABLE_NEW_INIT=""
    ENABLE_CODEX_CLI=""
    ENABLE_GEMINI_CLI=""
    ENABLE_CHECK_CODEX_AFTER_PLAN=""
    ENABLE_CHECK_CODEX_BEFORE_WRITE=""
    ENABLE_ERROR_TO_CODEX=""
  fi

  # Interactive wizard loop
  while true; do
    _step_language
    load_strings "$LANGUAGE"

    printf "\n"
    _print_banner "$STR_BANNER" "$STR_BANNER_SUB"

    _step_profile
    _step_codex
    _step_gemini
    _step_new_init
    _step_editor
    _step_hooks
    _step_plugins
    _step_commit
    _step_confirm

    if [[ "$WIZARD_RESULT" == "edit" ]]; then
      # Reset for re-run (all user choices cleared so wizard asks again)
      LANGUAGE=""
      EDITOR_CHOICE=""
      COMMIT_ATTRIBUTION=""
      ENABLE_NEW_INIT=""
      ENABLE_CODEX_CLI=""
      ENABLE_GEMINI_CLI=""
      ENABLE_CHECK_CODEX_AFTER_PLAN=""
      ENABLE_CHECK_CODEX_BEFORE_WRITE=""
      ENABLE_ERROR_TO_CODEX=""
      continue
    fi
    break
  done
}
