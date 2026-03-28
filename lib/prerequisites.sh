#!/bin/bash
# lib/prerequisites.sh - Dependency checking and installation
#
# Requires: lib/colors.sh, lib/detect.sh
# Uses globals: DISTRO_FAMILY, WIZARD_NONINTERACTIVE, DRY_RUN,
#               _SETUP_ORIG_ARGS[], _SETUP_SCRIPT_PATH, NODE_MAJOR
# Sets globals: _GNU_SED, _GNU_AWK (optional; set when GNU tools are found)
# Exports: check_prerequisites(), check_bash4(), _detect_bash4(),
#          _sed(), _awk()
# Dry-run: check_prerequisites has dry-run fast path (light tools only)
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
# Node.js major version to install when missing
NODE_MAJOR="${NODE_MAJOR:-20}"

# ---------------------------------------------------------------------------
# Package manager wrappers
# ---------------------------------------------------------------------------

# Install packages via the appropriate system package manager
_pkg_install() {
  case "$DISTRO_FAMILY" in
    macos)
      error "Cannot install $* automatically on macOS."
      error "Please install manually from the official website."
      return 1
      ;;
    debian)
      sudo apt-get update -qq && sudo apt-get install -y "$@"
      ;;
    rhel)
      sudo dnf install -y "$@"
      ;;
    alpine)
      sudo apk add --no-cache "$@"
      ;;
    msys)
      error "Package manager not available in Git Bash."
      error "Please install $* manually using winget or from their official websites."
      return 1
      ;;
    *)
      error "Unsupported package manager for DISTRO_FAMILY=$DISTRO_FAMILY"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Individual checks and installers
# ---------------------------------------------------------------------------

check_git() {
  if command -v git &>/dev/null; then
    ok "git $(git --version | awk '{print $3}')"
    return 0
  fi
  if is_msys; then
    error "Git not found. This should not happen in Git Bash."
    error "Please reinstall Git for Windows: https://gitforwindows.org/"
    return 1
  fi
  info "Installing git..."
  _pkg_install git
  ok "git installed"
}

check_jq() {
  if command -v jq &>/dev/null; then
    ok "jq $(jq --version 2>/dev/null || echo '?')"
    return 0
  fi
  if is_msys; then
    info "Installing jq (standalone binary for Windows)..."
    local jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-windows-amd64.exe"
    local jq_dest="$HOME/.local/bin/jq.exe"
    mkdir -p "$HOME/.local/bin"
    if curl -fsSL "$jq_url" -o "$jq_dest" && chmod +x "$jq_dest"; then
      # Also create a symlink without .exe for compatibility
      ln -sf "$jq_dest" "$HOME/.local/bin/jq" 2>/dev/null || true
      export PATH="$HOME/.local/bin:$PATH"
      ok "jq installed to $jq_dest"
      return 0
    else
      error "Failed to download jq. Install manually: https://jqlang.github.io/jq/download/"
      return 1
    fi
  fi
  info "Installing jq..."
  _pkg_install jq
  ok "jq installed"
}

check_curl() {
  if command -v curl &>/dev/null; then
    ok "curl found"
    return 0
  fi
  info "Installing curl..."
  _pkg_install curl
  ok "curl installed"
}

# ---------------------------------------------------------------------------
# GNU sed / GNU awk — optional, preferred when available
#
# The kit's _sed/_awk usage is POSIX-compatible, so BSD sed/awk (macOS
# built-in) work correctly.  When GNU versions are found they are used
# via the _sed()/_awk() wrappers; otherwise the system defaults are used.
# ---------------------------------------------------------------------------
_GNU_SED=""
_GNU_AWK=""

_detect_gnu_sed() {
  # Check if 'sed' itself is GNU
  if sed --version 2>/dev/null | grep -q "GNU sed"; then
    _GNU_SED="sed"
    return 0
  fi
  # Check for gsed (e.g., GNU sed installed as gsed)
  if command -v gsed &>/dev/null && gsed --version 2>/dev/null | grep -q "GNU sed"; then
    _GNU_SED="gsed"
    return 0
  fi
  return 1
}

_detect_gnu_awk() {
  # Check if 'awk' itself is GNU
  if awk --version 2>/dev/null | grep -q "GNU Awk"; then
    _GNU_AWK="awk"
    return 0
  fi
  # Check for gawk
  if command -v gawk &>/dev/null && gawk --version 2>/dev/null | grep -q "GNU Awk"; then
    _GNU_AWK="gawk"
    return 0
  fi
  return 1
}

check_gnu_sed() {
  if _detect_gnu_sed; then
    ok "GNU sed ($_GNU_SED)"
  else
    ok "sed (BSD) — POSIX compatible, OK"
  fi
  return 0
}

check_gnu_awk() {
  if _detect_gnu_awk; then
    ok "GNU awk ($_GNU_AWK)"
  else
    ok "awk (BSD) — POSIX compatible, OK"
  fi
  return 0
}

# Portable wrappers — use these instead of raw sed/awk in kit scripts
_sed() {
  if [[ -n "$_GNU_SED" ]]; then
    "$_GNU_SED" "$@"
  else
    sed "$@"
  fi
}

_awk() {
  if [[ -n "$_GNU_AWK" ]]; then
    "$_GNU_AWK" "$@"
  else
    awk "$@"
  fi
}

check_node() {
  if command -v node &>/dev/null; then
    ok "node $(node --version)"
    return 0
  fi
  # Node.js is optional: Claude Code uses a native installer and no longer requires Node.js.
  # However, Node.js is still needed for Codex CLI and npm-based plugins.
  warn "Node.js not found (optional, needed for Codex CLI / npm plugins)."
  info "Installing Node.js ${NODE_MAJOR}.x..."
  if _install_node && command -v node &>/dev/null; then
    ok "node $(node --version) installed"
  else
    warn "Could not install Node.js. Codex CLI setup will be skipped if selected."
    _show_node_manual_instructions
    # Not fatal - return success since Node.js is no longer required for Claude Code itself
    return 0
  fi
}

_install_node_via_nvm() {
  info "Installing Node.js via nvm (no admin required)..."
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  mkdir -p "$NVM_DIR"
  if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash; then
    # Load nvm into current session
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install "$NODE_MAJOR"
    # nvm installer only writes to the running shell's rc file (bash).
    # If the user's login shell is zsh, also add nvm init to .zshrc.
    _ensure_nvm_in_zshrc
  else
    return 1
  fi
}

_ensure_nvm_in_zshrc() {
  local login_shell
  login_shell="$(basename "${SHELL:-}")"
  # Only needed when the login shell is zsh but we're running under bash
  [[ "$login_shell" == "zsh" ]] || return 0

  local zshrc="$HOME/.zshrc"
  # Skip if nvm init is already present
  if [[ -f "$zshrc" ]] && grep -q 'NVM_DIR' "$zshrc" 2>/dev/null; then
    return 0
  fi

  info "Adding nvm to ~/.zshrc (login shell is zsh)..."
  cat >> "$zshrc" <<'ZSHRC'

# nvm - Node Version Manager (added by claude-code-starter-kit)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
ZSHRC
}

_install_node() {
  case "$DISTRO_FAMILY" in
    macos)
      _install_node_via_nvm
      ;;
    debian)
      # Try NodeSource first, fall back to nvm
      if curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" 2>/dev/null | sudo -E bash - 2>/dev/null \
         && sudo apt-get install -y nodejs 2>/dev/null; then
        :
      else
        warn "NodeSource setup failed. Falling back to nvm..."
        _install_node_via_nvm
      fi
      ;;
    rhel)
      if curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" 2>/dev/null | sudo bash - 2>/dev/null \
         && sudo dnf install -y nodejs 2>/dev/null; then
        :
      else
        warn "NodeSource setup failed. Falling back to nvm..."
        _install_node_via_nvm
      fi
      ;;
    alpine)
      sudo apk add --no-cache "nodejs" "npm"
      ;;
    msys)
      # Try winget (available on Windows 10+), then fall back to nvm
      if command -v winget.exe &>/dev/null; then
        info "Installing Node.js via winget..."
        winget.exe install OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements 2>/dev/null || true
        # winget installs to Program Files; add to PATH
        export PATH="/c/Program Files/nodejs:$PATH"
      fi
      if ! command -v node &>/dev/null; then
        _install_node_via_nvm
      fi
      ;;
    *)
      _install_node_via_nvm
      ;;
  esac
}

_show_node_manual_instructions() {
  error "Could not install Node.js automatically."
  error "Please install Node.js ${NODE_MAJOR}.x manually:"
  error "  - Official installer: https://nodejs.org/en/download/"
  error "  - Using nvm:         https://github.com/nvm-sh/nvm"
  error "  - Using fnm:         https://github.com/Schniz/fnm"
}

check_dos2unix() {
  # Only relevant for WSL environments
  if [[ "$IS_WSL" != "true" ]]; then
    return 0
  fi
  if command -v dos2unix &>/dev/null; then
    ok "dos2unix found (WSL)"
    return 0
  fi
  info "Installing dos2unix (recommended for WSL)..."
  _pkg_install dos2unix
  ok "dos2unix installed"
}

check_gh() {
  if command -v gh &>/dev/null; then
    ok "gh $(gh --version 2>/dev/null | head -1 | awk '{print $3}')"
    return 0
  fi
  warn "GitHub CLI (gh) not found (optional)."
  warn "  Install: https://cli.github.com/"
  case "$DISTRO_FAMILY" in
    macos)  warn "  Or: https://github.com/cli/cli#installation" ;;
    debian) warn "  Or: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
    rhel)   warn "  Or: sudo dnf install gh" ;;
    *)      ;;
  esac
  return 0 # Optional - do not fail
}

# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# Bash 4+ detection and re-exec
# ---------------------------------------------------------------------------

# _detect_bash4 - Find a Bash 4+ binary on the system
# Returns the path via stdout. Returns 1 if none found.
_detect_bash4() {
  # Check current shell first
  if [[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]; then
    printf '%s' "$BASH"
    return 0
  fi

  # Search common locations + PATH lookup
  local candidate path_bash
  path_bash="$(command -v bash 2>/dev/null || true)"
  for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash /usr/bin/bash ${path_bash:+"$path_bash"}; do
    if [[ -x "$candidate" ]]; then
      local ver
      ver="$("$candidate" -c 'echo "${BASH_VERSINFO[0]}"' 2>/dev/null || echo "0")"
      if [[ "$ver" -ge 4 ]]; then
        printf '%s' "$candidate"
        return 0
      fi
    fi
  done

  return 1
}

# check_bash4 - Ensure we're running under Bash 4+, re-exec if not
# Uses _SETUP_ORIG_ARGS (set at setup.sh top-level) to preserve CLI arguments.
# Returns 0 if already Bash 4+, re-execs on success, returns 1 on failure.
check_bash4() {
  # Already Bash 4+?
  if [[ "${BASH_VERSINFO[0]:-0}" -ge 4 ]]; then
    return 0
  fi

  info "Current Bash is ${BASH_VERSION} (< 4.0). Looking for Bash 4+..."

  local new_bash
  if new_bash="$(_detect_bash4)"; then
    info "Found Bash 4+ at: $new_bash"
    info "Re-executing setup.sh under Bash 4+..."
    exec "$new_bash" "$_SETUP_SCRIPT_PATH" "${_SETUP_ORIG_ARGS[@]+"${_SETUP_ORIG_ARGS[@]}"}"
    # exec replaces the process; if we get here, exec failed
    error "Failed to re-exec under $new_bash"
    return 1
  fi

  # No Bash 4+ found
  return 1
}

# ---------------------------------------------------------------------------
# _get_shell_rc_file - Determine the user's shell RC file
#
# Outputs the path to stdout. Handles MSYS (bash_profile), zsh, bash.
# ---------------------------------------------------------------------------
_get_shell_rc_file() {
  if is_msys; then
    printf '%s' "$HOME/.bash_profile"
  else
    case "${SHELL:-/bin/bash}" in
      */zsh)  printf '%s' "$HOME/.zshrc" ;;
      */bash) printf '%s' "$HOME/.bashrc" ;;
      *)      printf '%s' "$HOME/.profile" ;;
    esac
  fi
}

# ---------------------------------------------------------------------------
# _add_to_path_now_and_persist - Add a directory to PATH immediately + persist
#
# Usage: _add_to_path_now_and_persist <dir>
#
# 1. Immediate: export PATH="<dir>:$PATH" (current session)
# 2. Persist: append to shell RC file if not already present
# ---------------------------------------------------------------------------
_add_to_path_now_and_persist() {
  local dir="$1"

  # Immediate export for current session
  case ":${PATH}:" in
    *":${dir}:"*) ;;  # already in PATH
    *) export PATH="${dir}:${PATH}" ;;
  esac

  # Persist to RC file (skip if not writable, e.g. Nix Home Manager symlink)
  local rc_file
  rc_file="$(_get_shell_rc_file)"
  [[ -f "$rc_file" ]] || touch "$rc_file" 2>/dev/null || return 0

  if ! grep -q "$dir" "$rc_file" 2>/dev/null; then
    if [[ -w "$rc_file" ]]; then
      printf '\n# Claude Code CLI\nexport PATH="%s:$PATH"\n' "$dir" >> "$rc_file"
    fi
  fi
}

# Main entry point
# ---------------------------------------------------------------------------

# Run all prerequisite checks. Returns non-zero on critical failure.
check_prerequisites() {
  section "必要なツールを確認中 / Checking prerequisites"

  # Dry-run mode: only light prerequisites (git, jq, curl) are checked.
  # Heavy installs (Node, etc.) are skipped entirely.
  # Interactive: offer to install missing light tools with user consent.
  # Non-interactive: list missing tools and abort without installing.
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    local _dr_missing=()
    command -v git  &>/dev/null && ok "git $(git --version | awk '{print $3}')"  || _dr_missing+=("git")
    command -v jq   &>/dev/null && ok "jq $(jq --version 2>/dev/null || echo '?')" || _dr_missing+=("jq")
    command -v curl &>/dev/null && ok "curl found" || _dr_missing+=("curl")
    # GNU sed/awk are optional — detect but don't require
    if _detect_gnu_sed; then ok "GNU sed ($_GNU_SED)"; else ok "sed (BSD) — OK"; fi
    if _detect_gnu_awk; then ok "GNU awk ($_GNU_AWK)"; else ok "awk (BSD) — OK"; fi

    if [[ ${#_dr_missing[@]} -eq 0 ]]; then
      ok "必要なツールはすべて揃っています / All prerequisites satisfied (dry-run)"
      return 0
    fi

    # Missing tools found
    warn "Dry-run に必要なツールが不足しています / Missing tools for dry-run: ${_dr_missing[*]}"

    if [[ "${WIZARD_NONINTERACTIVE:-false}" == "true" ]]; then
      error "Non-interactive dry-run: 不足ツールの導入は行いません。手動でインストールして再実行してください。"
      error "Non-interactive dry-run: will not install missing tools. Please install manually and re-run."
      return 1
    fi

    # Interactive: ask for consent before installing
    info "Dry-run のシミュレーションに上記ツールが必要です。導入しますか？"
    info "The above tools are needed to run the simulation. Install them?"
    printf "  [Y]es / [N]o ? " >&2
    local _dr_confirm=""
    if read -r _dr_confirm < /dev/tty 2>/dev/null; then
      true
    else
      _dr_confirm="n"
    fi
    case "$_dr_confirm" in
      [Yy]*)
        # Install only light prerequisites via normal check functions
        local _dr_failed=0
        for _dr_tool in "${_dr_missing[@]}"; do
          case "$_dr_tool" in
            git)  check_git  || _dr_failed=1 ;;
            jq)   check_jq   || _dr_failed=1 ;;
            curl) check_curl || _dr_failed=1 ;;
          esac
        done
        if [[ "$_dr_failed" -ne 0 ]]; then
          error "一部のツールをインストールできませんでした / Some tools could not be installed"
          return 1
        fi
        ;;
      *)
        error "Dry-run を中止しました / Dry-run aborted"
        return 1
        ;;
    esac
    ok "必要なツールはすべて揃っています / All prerequisites satisfied (dry-run)"
    return 0
  fi

  # MSYS/Git Bash: ensure ~/.local/bin is in PATH for standalone tools
  if is_msys; then
    export PATH="$HOME/.local/bin:$PATH"
  fi

  local failed=0

  check_git     || failed=1
  check_jq      || failed=1
  check_curl    || failed=1
  check_gnu_sed   # Optional: prefer GNU if available, BSD works fine
  check_gnu_awk   # Optional: prefer GNU if available, BSD works fine
  check_node      # Optional: needed for Codex CLI / npm plugins only
  check_dos2unix
  check_gh

  if [[ "$failed" -ne 0 ]]; then
    error "一部の必須ツールをインストールできませんでした。手動でインストールして再実行してください。"
    error "Some required dependencies could not be installed. Please install them manually and re-run."
    return 1
  fi

  ok "必要なツールはすべて揃っています / All prerequisites satisfied"
  return 0
}
