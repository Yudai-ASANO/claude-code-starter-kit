#!/usr/bin/env bash
# lib/gemini-setup.sh - Gemini CLI setup (existence check + auth verification + guidance)
#
# Unlike Codex CLI setup (lib/codex-setup.sh), this does NOT auto-install
# or auto-authenticate. It checks if gemini-cli is available and authenticated,
# and provides guidance if not.
#
# Exports: run_gemini_setup()
# Dry-run: guarded externally (setup.sh logs EXTERNAL, does not call run_gemini_setup)

# ---------------------------------------------------------------------------
# Gemini CLI helpers
# ---------------------------------------------------------------------------

_check_gemini_cli() {
  command -v gemini &>/dev/null
}

_check_gemini_auth() {
  # Quick smoke test: run gemini with a trivial prompt in sandbox mode
  # Timeout after 15 seconds to avoid hanging
  local _result
  _result="$(_run_with_timeout 15 gemini --sandbox -p "Reply with just OK" --output-format json 2>/dev/null)" || return 1
  # Check for error in JSON response
  local _error
  _error="$(printf '%s' "$_result" | jq -r '.error // empty' 2>/dev/null)" || return 1
  [[ -z "$_error" ]] || return 1
  # Require a non-empty .response as positive success signal
  local _response
  _response="$(printf '%s' "$_result" | jq -r '.response // empty' 2>/dev/null)" || return 1
  [[ -n "$_response" ]]
}

# ---------------------------------------------------------------------------
# run_gemini_setup - Entry point called from setup.sh
# ---------------------------------------------------------------------------
run_gemini_setup() {
  section "${STR_GEMINI_SETUP_TITLE:-Gemini CLI Setup}"
  info "${STR_GEMINI_SETUP_NOTE:-Note: Gemini CLI requires installation and Google account authentication}"

  if ! _check_gemini_cli; then
    if [[ "$WIZARD_NONINTERACTIVE" == "true" ]]; then
      info "${STR_GEMINI_SETUP_SKIPPED:-Gemini CLI setup skipped (non-interactive)}"
      return 0
    fi
    warn "${STR_GEMINI_CLI_NOT_FOUND:-Gemini CLI not found. To install:}"
    info "${STR_GEMINI_CLI_INSTALL_CMD:-  npm install -g @google/gemini-cli}"
    info "${STR_GEMINI_CLI_AUTH_HINT:-After installing, run 'gemini' once to authenticate with your Google account}"
    return 0
  fi

  # CLI found — verify authentication with smoke test
  info "${STR_GEMINI_AUTH_CHECKING:-Checking Gemini CLI authentication...}"
  if _check_gemini_auth; then
    ok "${STR_GEMINI_CLI_ALREADY:-Gemini CLI is installed and authenticated}"
  else
    warn "${STR_GEMINI_AUTH_FAILED:-Gemini CLI is installed but authentication failed or timed out}"
    info "${STR_GEMINI_CLI_AUTH_HINT:-After installing, run 'gemini' once to authenticate with your Google account}"
  fi
}
