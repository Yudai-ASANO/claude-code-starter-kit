#!/bin/bash
# lib/update.sh - Update mode logic for Claude Code Starter Kit
#
# Requires: lib/colors.sh, lib/snapshot.sh (_repair_snapshot_markers),
#           lib/merge.sh, lib/json-builder.sh,
#           lib/template.sh (_has_kit_markers, _extract_kit_section, _user_section_heading)
# Uses globals: PROJECT_DIR, CLAUDE_DIR, DRY_RUN, _MERGE_INTERACTIVE,
#               _SNAPSHOT_BOOTSTRAPPED, _BACKUP_TIMESTAMP, _SETUP_TMP_FILES[],
#               LANGUAGE, UPDATE_MODE, STR_UPDATE_*
# Exports: run_update(), _check_major_upgrade(), _sync_settings_metadata()
# Dry-run: run_update has dry-run awareness (logs instead of deploying)
set -euo pipefail

# ---------------------------------------------------------------------------
# _check_major_upgrade - Detect major version jumps and warn the user
#
# Compares the manifest's kit_version with the current kit version.
# On major version bumps, displays recovery instructions.
# Does not block — warns only. The backup is created by backup_existing() before this runs.
# ---------------------------------------------------------------------------
_check_major_upgrade() {
  local claude_dir="$1"
  local manifest="${claude_dir}/.starter-kit-manifest.json"

  [[ -f "$manifest" ]] || return 0

  local old_ver
  old_ver="$(jq -r '.kit_version // empty' "$manifest" 2>/dev/null || true)"
  [[ -n "$old_ver" ]] || return 0

  local new_ver
  new_ver="$(git -C "$PROJECT_DIR" describe --tags --always 2>/dev/null || echo "unknown")"

  # Extract major version numbers (strip leading 'v')
  local old_major new_major
  old_major="${old_ver#v}"; old_major="${old_major%%.*}"
  new_major="${new_ver#v}"; new_major="${new_major%%.*}"

  # Only warn on parseable numeric majors that differ
  [[ "$old_major" =~ ^[0-9]+$ ]] || return 0
  [[ "$new_major" =~ ^[0-9]+$ ]] || return 0
  [[ "$old_major" -ne "$new_major" ]] || return 0

  warn "${STR_MAJOR_UPGRADE_WARN:-Major version upgrade detected}: $old_ver → $new_ver"
  info "${STR_MAJOR_UPGRADE_BACKUP:-A backup will be created before updating.}"

  # Show recovery instructions with actual backup path
  local backup_file="${claude_dir}/.starter-kit-last-backup"
  if [[ -f "$backup_file" ]]; then
    local backup_path
    backup_path="$(cat "$backup_file")"
    info "To restore: BACKUP=\"$backup_path\" && mv ~/.claude ~/.claude.broken && cp -a \"\$BACKUP\" ~/.claude"
  fi
}

# ---------------------------------------------------------------------------
# _sync_settings_metadata - Sync LANGUAGE (and other vars) from merged settings
#
# After 3-way merge, the merged settings.json is the ground truth.
# Read back key values so write_manifest() and save_config() record the
# actual deployed state, not the stale manifest/variable values.
# ---------------------------------------------------------------------------
# shellcheck disable=SC2034  # variables used by setup.sh (write_manifest, save_config)
_sync_settings_metadata() {
  local settings_file="$1"
  [[ -f "$settings_file" ]] || return 0

  local lang_value
  lang_value="$(jq -r '.language // empty' "$settings_file" 2>/dev/null || true)"

  case "$lang_value" in
    "日本語"|ja) LANGUAGE="ja" ;;
    English|en)  LANGUAGE="en" ;;
    "") ;;  # no language key, keep current
    *)  ;;  # unknown value, keep current
  esac

  # Sync COMMIT_ATTRIBUTION from merged settings (used by setup.sh write_manifest)
  local has_attribution _commit_attr
  has_attribution="$(jq -r 'if has("attribution") then "has" else "none" end' "$settings_file" 2>/dev/null || true)"
  case "$has_attribution" in
    none) _commit_attr="true"  ;;  # no attribution key = enabled
    has)  _commit_attr="false" ;;  # attribution key present = disabled
    *)    _commit_attr="" ;;
  esac
  if [[ -n "$_commit_attr" ]]; then
    COMMIT_ATTRIBUTION="$_commit_attr"  # used by setup.sh write_manifest/save_config
  fi

  # Sync ENABLE_NEW_INIT from merged settings (used by setup.sh)
  local new_init_val
  new_init_val="$(jq -r '.env.CLAUDE_CODE_NEW_INIT // empty' "$settings_file" 2>/dev/null || true)"
  if [[ -n "$new_init_val" ]]; then
    # shellcheck disable=SC2034
    ENABLE_NEW_INIT="$new_init_val"
  fi
}

# ---------------------------------------------------------------------------
# _merge_settings_bootstrap is now in lib/merge.sh (moved in v0.22.2)

# ---------------------------------------------------------------------------
# _update_claude_md - Section-aware CLAUDE.md update
#
# Usage: _update_claude_md <current> <snapshot_kit_section> <new_kit_file>
#
# Compares only the kit-managed section (between markers).
# User section is always preserved untouched.
# Returns 0 if file was updated, 1 if skipped.
# ---------------------------------------------------------------------------
_update_claude_md() {
  local current="$1"
  local snapshot_kit="$2"
  local new_kit_file="$3"

  # Build new kit content and extract its kit section
  local new_kit_section
  new_kit_section="$(mktemp)"
  _SETUP_TMP_FILES+=("$new_kit_section")
  _extract_kit_section "$new_kit_file" > "$new_kit_section"

  # Case 1: current does not exist → write full new file
  if [[ ! -f "$current" ]]; then
    cp -a "$new_kit_file" "$current"
    return 0
  fi

  # Case 2: current has no markers → detect old kit-generated file
  if ! _has_kit_markers "$current"; then
    # Reconstruct what old kit (no markers) would have generated
    local old_kit_output
    old_kit_output="$(mktemp)"
    _SETUP_TMP_FILES+=("$old_kit_output")
    grep -vF "<!-- BEGIN STARTER-KIT-MANAGED -->" "$new_kit_file" \
      | grep -vF "<!-- END STARTER-KIT-MANAGED -->" \
      | grep -vF "$(_user_section_heading)" \
      | grep -v '^<!-- .*custom instructions' \
      > "$old_kit_output" || true

    # Compare ignoring blank lines: exact match = no user edits
    local current_trimmed old_kit_trimmed
    current_trimmed="$(_sed '/^[[:space:]]*$/d' "$current")"
    old_kit_trimmed="$(_sed '/^[[:space:]]*$/d' "$old_kit_output")"

    if [[ "$current_trimmed" == "$old_kit_trimmed" ]]; then
      # Unmodified old kit output → safe to auto-upgrade
      cp -a "$new_kit_file" "$current"
      info "CLAUDE.md upgraded to section-aware format"
      return 0
    fi

    # Differences found (additions, deletions, or edits) → user customization
    if [[ "${_MERGE_INTERACTIVE:-true}" != "true" ]]; then
      warn "$STR_CLAUDEMD_MIGRATION_SKIP"
      return 1
    fi

    warn "$STR_CLAUDEMD_MIGRATION"
    info "Differences from kit template:"
    diff -u "$old_kit_output" "$current" 2>/dev/null >&2 || true
    printf "\n" >&2
    printf "  %s " "$STR_CLAUDEMD_MIGRATION_PROMPT" >&2
    local reply=""
    if read -r reply < /dev/tty 2>/dev/null; then true; else reply="s"; fi
    case "$reply" in
      [Mm]*)
        # Keep the entire current content as user section
        local kit_section existing_content user_heading
        kit_section="$(< "$new_kit_section")"
        existing_content="$(< "$current")"
        user_heading="$(_user_section_heading)"
        {
          printf '%s\n' "$kit_section"
          printf '\n%s\n\n' "$user_heading"
          printf '%s\n' "$existing_content"
        } > "$current"
        info "CLAUDE.md upgraded — your content preserved in user section"
        return 0
        ;;
      *) return 1 ;;
    esac
  fi

  # Case 3: current has markers → section-aware 3-way compare
  local current_kit_section
  current_kit_section="$(mktemp)"
  _SETUP_TMP_FILES+=("$current_kit_section")
  _extract_kit_section "$current" > "$current_kit_section"

  if [[ ! -f "$snapshot_kit" ]]; then
    # No snapshot → treat as first update, replace kit section
    _replace_kit_section "$current" "$new_kit_section"
    return 0
  fi

  # Repair stale snapshot with duplicated markers (pre-v0.30.0 bug)
  _repair_snapshot_markers "$snapshot_kit"

  # Compare kit sections only
  if ! _file_changed "$snapshot_kit" "$current_kit_section"; then
    # User did not edit kit section → safe to replace
    _replace_kit_section "$current" "$new_kit_section"
    info "$STR_CLAUDEMD_USER_PRESERVED"
    return 0
  fi

  if ! _file_changed "$snapshot_kit" "$new_kit_section"; then
    # Kit has no changes → keep current
    return 1
  fi

  # Both changed → conflict on kit section
  if [[ "${_MERGE_INTERACTIVE:-true}" != "true" ]]; then
    # Non-interactive: keep current (non-destructive)
    return 1
  fi

  warn "$STR_CLAUDEMD_KIT_CONFLICT"
  while true; do
    printf "  %s " "$STR_CLAUDEMD_KIT_CONFLICT_PROMPT" >&2
    local choice=""
    if read -r choice < /dev/tty 2>/dev/null; then true; else choice="k"; fi
    case "$choice" in
      [Uu]*)
        _replace_kit_section "$current" "$new_kit_section"
        info "$STR_CLAUDEMD_USER_PRESERVED"
        return 0
        ;;
      [Kk]*)
        return 1
        ;;
      [Dd]*)
        diff -u "$current_kit_section" "$new_kit_section" 2>/dev/null >&2 || true
        printf "\n" >&2
        continue
        ;;
      *) return 1 ;;
    esac
  done
}

# _user_section_heading is now in lib/template.sh (moved in v0.22.2)

# ---------------------------------------------------------------------------
# _prompt_file_action - Ask user what to do with a changed file
#
# Usage: _prompt_file_action <current_path> <snapshot_path> <newkit_path>
# Returns via global: _FILE_ACTION (append|skip)
#
# Non-interactive: always skip
# Interactive: offer [A]ppend / [S]kip / [D]iff
# ---------------------------------------------------------------------------
_FILE_ACTION=""
_prompt_file_action() {
  local current="$1"
  local snapshot="$2"
  local newkit="$3"
  local display_path="${current#"$HOME"/}"

  if [[ "${_MERGE_INTERACTIVE:-true}" != "true" ]]; then
    _FILE_ACTION="skip"
    return
  fi

  while true; do
    warn "$STR_UPDATE_FILE_CHANGED: ~/${display_path}"
    printf "  [A]ppend / [S]kip / [D]iff ? " >&2
    local choice=""
    if read -r choice < /dev/tty 2>/dev/null; then
      true
    else
      choice="s"
    fi
    case "$choice" in
      a|A)
        _FILE_ACTION="append"
        return
        ;;
      s|S)
        _FILE_ACTION="skip"
        return
        ;;
      d|D)
        printf "\n" >&2
        info "--- Snapshot (kit original)"
        info "+++ Current (your version)"
        diff -u "$snapshot" "$current" 2>/dev/null || true
        printf "\n" >&2
        info "--- Current (your version)"
        info "+++ New kit version"
        diff -u "$current" "$newkit" 2>/dev/null || true
        printf "\n" >&2
        ;;
      *)
        _FILE_ACTION="skip"
        return
        ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# _update_file - Update a single file with user change detection
#
# Usage: _update_file <current_path> <snapshot_path> <newkit_path>
# Returns 0 if file was updated, 1 if skipped
#
# Logic:
#   1. No snapshot file → new from kit → copy, return 0
#   2. Current deleted by user → interactive: ask Restore/Skip; non-interactive: skip
#   3. No user change (snapshot == current) → overwrite with newkit, return 0
#   4. No kit change (snapshot == newkit) → keep current, return 1
#   5. Both changed → prompt user, handle append or skip
# ---------------------------------------------------------------------------
_update_file() {
  local current="$1"
  local snapshot="$2"
  local newkit="$3"

  # New file from kit (not in snapshot)
  if [[ ! -f "$snapshot" ]]; then
    cp -a "$newkit" "$current"
    return 0
  fi

  # Current file was deleted by user
  if [[ ! -f "$current" ]]; then
    if [[ "${_MERGE_INTERACTIVE:-true}" != "true" ]]; then
      return 1
    fi
    info "$STR_MERGE_FILE_DELETED ${current#"$HOME"/}"
    printf "  %s " "$STR_MERGE_FILE_RESTORE_PROMPT" >&2
    local choice=""
    if read -r choice < /dev/tty 2>/dev/null; then
      true
    else
      choice="s"
    fi
    case "$choice" in
      r|R)
        cp -a "$newkit" "$current"
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  fi

  # No user change → safe to overwrite
  # But if snapshot was just bootstrapped from current, we can't tell if user
  # changed — compare current vs newkit directly instead.
  if ! _file_changed "$snapshot" "$current"; then
    if [[ "${_SNAPSHOT_BOOTSTRAPPED:-false}" == "true" ]]; then
      # Snapshot IS current — no real baseline exists.
      if ! _file_changed "$current" "$newkit"; then
        # Current already matches new kit — nothing to do
        return 1
      fi
      # Kit differs from current — non-interactive: keep current (protect
      # user customizations; kit additions come in on subsequent updates
      # once a real snapshot exists). Interactive: ask user.
      if [[ "${_MERGE_INTERACTIVE:-true}" != "true" ]]; then
        return 1
      fi
      _prompt_file_action "$current" "$snapshot" "$newkit"
      case "$_FILE_ACTION" in
        append)
          printf "\n# --- Updated by Claude Code Starter Kit ---\n" >> "$current"
          cat "$newkit" >> "$current"
          return 0
          ;;
        skip|*)
          return 1
          ;;
      esac
    fi
    cp -a "$newkit" "$current"
    return 0
  fi

  # No kit change → keep current
  if ! _file_changed "$snapshot" "$newkit"; then
    return 1
  fi

  # Both changed → ask user
  _prompt_file_action "$current" "$snapshot" "$newkit"
  case "$_FILE_ACTION" in
    append)
      # Append new kit content after current content with separator
      printf "\n# --- Updated by Claude Code Starter Kit ---\n" >> "$current"
      cat "$newkit" >> "$current"
      return 0
      ;;
    skip|*)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# _update_hook_feature - Update hook scripts for a single feature
#
# Usage: _update_hook_feature <feature_name> <src_dir> <claude_dir> <snapshot_dir> <updated_var> <skipped_var>
# ---------------------------------------------------------------------------
_update_hook_feature() {
  local feature_name="$1"
  local src_dir="$2"
  local claude_dir="$3"
  local snapshot_dir="$4"
  local updated_var="$5"
  local skipped_var="$6"

  local dest_dir="${claude_dir}/hooks/${feature_name}"
  local snap_dir="${snapshot_dir}/hooks/${feature_name}"

  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$dest_dir"

  local src_file
  while IFS= read -r -d '' src_file; do
    local basename_file
    basename_file="$(basename "$src_file")"
    local dest_file="${dest_dir}/${basename_file}"
    local snap_file="${snap_dir}/${basename_file}"

    if _update_file "$dest_file" "$snap_file" "$src_file"; then
      chmod +x "$dest_file" 2>/dev/null || true
      eval "${updated_var}+=(\"\$dest_file\")"
    else
      eval "${skipped_var}+=(\"hooks/${feature_name}/${basename_file}\")"
    fi
  done < <(find "$src_dir" -type f -print0 2>/dev/null)
}

# ---------------------------------------------------------------------------
# _update_hook_scripts - Update-aware hook script deployment
#
# Deploys hook scripts through _update_file() so user customizations
# are detected and preserved instead of being silently overwritten.
#
# Usage: _update_hook_scripts <claude_dir> <snapshot_dir> <updated_array_name> <skipped_array_name>
# ---------------------------------------------------------------------------
_update_hook_scripts() {
  local claude_dir="$1"
  local snapshot_dir="$2"
  local updated_var="$3"
  local skipped_var="$4"

  if is_true "$ENABLE_MEMORY_PERSISTENCE"; then
    _update_hook_feature "memory-persistence" \
      "$PROJECT_DIR/features/memory-persistence/scripts" \
      "$claude_dir" "$snapshot_dir" "$updated_var" "$skipped_var"
  fi

  if is_true "$ENABLE_STRATEGIC_COMPACT"; then
    _update_hook_feature "strategic-compact" \
      "$PROJECT_DIR/features/strategic-compact/scripts" \
      "$claude_dir" "$snapshot_dir" "$updated_var" "$skipped_var"
  fi

  if is_true "${ENABLE_AUTO_UPDATE:-false}"; then
    _update_hook_feature "auto-update" \
      "$PROJECT_DIR/features/auto-update/scripts" \
      "$claude_dir" "$snapshot_dir" "$updated_var" "$skipped_var"
  fi

  if is_true "${ENABLE_STATUSLINE:-false}"; then
    _update_hook_feature "statusline" \
      "$PROJECT_DIR/features/statusline/scripts" \
      "$claude_dir" "$snapshot_dir" "$updated_var" "$skipped_var"
  fi

  if is_true "${ENABLE_DOC_SIZE_GUARD:-false}"; then
    _update_hook_feature "doc-size-guard" \
      "$PROJECT_DIR/features/doc-size-guard/scripts" \
      "$claude_dir" "$snapshot_dir" "$updated_var" "$skipped_var"
  fi
}

# ---------------------------------------------------------------------------
# Orphan cleanup: detect and remove kit-managed files that were removed
# from the kit in newer versions.
# ---------------------------------------------------------------------------

# _cleanup_empty_dirs <base_dir> [file_paths...]
#
# Walk up from each file's parent, removing empty dirs until base_dir.
_cleanup_empty_dirs() {
  local base_dir="$1"
  shift

  local f dir
  for f in "$@"; do
    dir="$(dirname "$f")"
    while [[ "$dir" != "$base_dir" ]] && [[ "$dir" == "$base_dir"/* ]]; do
      if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        rmdir "$dir" 2>/dev/null || break
        dir="$(dirname "$dir")"
      else
        break
      fi
    done
  done
}

# _collect_orphan_files <claude_dir> <new_files_json>
#
# Detect files that should be removed during update:
# 1. Manifest-tracked files absent from the new desired managed set
# 2. Files in managed directories that have a snapshot entry (i.e., were
#    previously deployed by the kit) but are absent from the new desired set.
#    This catches files deployed before manifest tracking was introduced.
# User-created files (no manifest entry AND no snapshot) are never touched.
# Outputs orphan file paths (one per line) to stdout.
# Returns 0 if orphans found, 1 if none.
_collect_orphan_files() {
  local claude_dir="$1"
  local new_files_json="$2"
  local manifest="${claude_dir}/.starter-kit-manifest.json"
  local snapshot_dir="${claude_dir}/.starter-kit-snapshot"

  # --- Phase 1: manifest-based orphan detection ---
  local old_files_json="[]"
  if [[ -f "$manifest" ]]; then
    local version
    version="$(jq -r '.version // "1"' "$manifest" 2>/dev/null || echo "1")"
    if [[ "$version" == "2" ]]; then
      local _raw
      _raw="$(jq -r '.files // "null"' "$manifest" 2>/dev/null)" || true
      if [[ "$_raw" != "null" ]]; then
        old_files_json="$_raw"
      fi
    fi
  fi

  # In dry-run mode, CLAUDE_DIR is redirected to a sim dir but manifest still
  # contains real ~/.claude paths. Rebase old manifest paths to current claude_dir
  # so the set difference works in the same path space as new_files_json.
  local _real_home_claude="${HOME}/.claude"
  if [[ "$claude_dir" != "$_real_home_claude" ]]; then
    old_files_json="$(printf '%s' "$old_files_json" | jq --arg old "$_real_home_claude" --arg new "$claude_dir" \
      'map(if startswith($old) then ($new + .[($old | length):]) else . end)'
    )" || return 1
  fi

  # --- Phase 2: scan managed directories for snapshot-backed files ---
  # Only include files that have a corresponding snapshot entry, proving
  # they were previously deployed by the kit. User-created files (no
  # snapshot) are excluded to avoid flagging them as orphans.
  local -a managed_dirs=(
    "$claude_dir/agents"
    "$claude_dir/rules"
    "$claude_dir/commands"
    "$claude_dir/skills"
    "$claude_dir/memory"
    "$claude_dir/hooks"
  )

  local disk_files_json="[]"
  if [[ -d "$snapshot_dir" ]]; then
    local _dir _disk_list="" _f _rel
    for _dir in "${managed_dirs[@]}"; do
      [[ -d "$_dir" ]] || continue
      while IFS= read -r -d '' _f; do
        # Skip platform artifacts
        case "$(basename "$_f")" in
          .DS_Store|Thumbs.db|desktop.ini) continue ;;
        esac
        # Only include files with a snapshot entry (kit-deployed)
        _rel="${_f#"$claude_dir"/}"
        [[ -f "${snapshot_dir}/${_rel}" ]] || continue
        _disk_list="${_disk_list}${_f}"$'\n'
      done < <(find "$_dir" -maxdepth 4 -type f -print0 2>/dev/null)
    done
    if [[ -n "$_disk_list" ]]; then
      disk_files_json="$(printf '%s' "$_disk_list" | jq -R -s 'split("\n") | map(select(length > 0))')"
    fi
  fi

  # Combine: union of manifest files and disk files, then subtract new desired set
  local orphans
  orphans="$(jq -rn \
    --argjson old "$old_files_json" \
    --argjson disk "$disk_files_json" \
    --argjson new "$new_files_json" \
    '($new | map(select(type=="string")) | unique | reduce .[] as $p ({}; . + {($p): true})) as $new_set |
     (($old + $disk) | map(select(type=="string")) | unique) | map(select($new_set[.] == null)) | .[]'
  )" || return 1

  [[ -n "$orphans" ]] || return 1
  printf '%s\n' "$orphans"
}

# _remove_orphan_files <claude_dir> <new_files_json> <snapshot_dir>
#
# Remove orphaned kit-managed files detected by manifest diff.
# Respects user modifications: if user edited the file (snapshot != current),
# interactive mode asks; non-interactive mode preserves the file.
# Dry-run mode logs DELETE without removing.
_remove_orphan_files() {
  local claude_dir="$1"
  local new_files_json="$2"
  local snapshot_dir="$3"
  local _dr="${DRY_RUN:-false}"

  local orphan_list
  if ! orphan_list="$(_collect_orphan_files "$claude_dir" "$new_files_json")"; then
    return 0  # no orphans or manifest issue — safe to continue
  fi

  # Filter to files that exist on disk, exclude legacy AGENTS.md (handled separately)
  local -a orphans=()
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ -f "$line" ]] || continue
    # Skip AGENTS.md — already handled by dedicated legacy cleanup
    [[ "$(basename "$line")" != "AGENTS.md" || "$(dirname "$line")" != "$claude_dir" ]] || continue
    orphans+=("$line")
  done <<< "$orphan_list"

  [[ ${#orphans[@]} -gt 0 ]] || return 0

  # Build display path: in dry-run mode, orphan paths are in sim dir — map
  # back to $HOME/.claude/ for user-facing output.
  _orphan_display() {
    local p="$1"
    local rel="${p#"$claude_dir"/}"
    printf '%s' ".claude/${rel}"
  }

  # Display orphan list
  info "${STR_UPDATE_ORPHAN_TITLE:-Removing files no longer in kit}:"
  local f
  for f in "${orphans[@]}"; do
    info "  - ~/$(  _orphan_display "$f")"
  done

  # Dry-run: model the same preservation logic as the real path.
  # Only log DELETE for files that would actually be deleted.
  if [[ "$_dr" == "true" ]]; then
    for f in "${orphans[@]}"; do
      local rel="${f#"$claude_dir"/}"
      local snap_file="${snapshot_dir}/${rel}"
      local display
      display="\$HOME/$(_orphan_display "$f")"

      local _would_modify=false
      if [[ ! -f "$snap_file" ]]; then
        _would_modify=true
      elif _file_changed "$snap_file" "$f"; then
        _would_modify=true
      fi

      if [[ "$_would_modify" == "true" ]]; then
        # Non-interactive dry-run: would preserve
        _dryrun_log "SKIP" "$display" "orphan: user-modified or no snapshot baseline"
      else
        _dryrun_log "DELETE" "$display" "orphan: no longer in kit"
      fi
    done
    return 0
  fi

  # Check each orphan for user modifications before removing
  local -a removed=()
  local -a preserved=()
  for f in "${orphans[@]}"; do
    local rel="${f#"$claude_dir"/}"
    local snap_file="${snapshot_dir}/${rel}"

    # Determine if user modified the file
    local _user_modified=false
    if [[ ! -f "$snap_file" ]]; then
      # No snapshot baseline — we cannot confirm the file is unmodified.
      # Treat as potentially user-modified (conservative).
      _user_modified=true
    elif _file_changed "$snap_file" "$f"; then
      _user_modified=true
    fi

    if [[ "$_user_modified" == "true" ]]; then
      if [[ "${_MERGE_INTERACTIVE:-true}" == "true" ]]; then
        local display
        display="$(_orphan_display "$f")"
        printf "  ~/%s was modified (or has no snapshot baseline). [R]emove / [K]eep (default: Keep)? " "$display" >&2
        local choice=""
        if read -r choice < /dev/tty 2>/dev/null; then
          true
        else
          choice="k"
        fi
        case "$choice" in
          r|R)
            rm -f "$f"
            removed+=("$f")
            ;;
          *)
            preserved+=("$f")
            ;;
        esac
      else
        # Non-interactive: preserve user-modified / no-baseline files
        preserved+=("$f")
      fi
      continue
    fi

    # Unmodified (snapshot matches current) — safe to remove
    rm -f "$f"
    removed+=("$f")
  done

  # Clean snapshot entries for ALL orphans (both removed and preserved).
  # Preserved files are now user-owned and should not remain in the kit snapshot,
  # which would cause false "user modified kit files" detection on later runs.
  if [[ -d "$snapshot_dir" ]]; then
    local -a _snap_removed=()
    local _all_orphan
    for _all_orphan in "${removed[@]+"${removed[@]}"}" "${preserved[@]+"${preserved[@]}"}"; do
      [[ -n "$_all_orphan" ]] || continue
      local rel="${_all_orphan#"$claude_dir"/}"
      local snap_path="${snapshot_dir}/${rel}"
      if [[ -f "$snap_path" ]]; then
        rm -f "$snap_path"
        _snap_removed+=("$snap_path")
      fi
    done
    if [[ ${#_snap_removed[@]} -gt 0 ]]; then
      _cleanup_empty_dirs "$snapshot_dir" "${_snap_removed[@]}"
    fi
  fi

  # Clean empty parent directories in deployed tree
  if [[ ${#removed[@]} -gt 0 ]]; then
    _cleanup_empty_dirs "$claude_dir" "${removed[@]}"
    ok "${STR_UPDATE_ORPHAN_DONE:-Removed ${#removed[@]} orphaned file(s)}"
  fi

  if [[ ${#preserved[@]} -gt 0 ]]; then
    info "Preserved ${#preserved[@]} user-modified orphan file(s)"
  fi
}

# ---------------------------------------------------------------------------
# run_update - Main entry point for update mode
#
# Usage: run_update <project_dir> <claude_dir>
#
# Phases:
#   1. settings.json: build new, 3-way compare/merge
#   2. CLAUDE.md: build new, _update_file
#   2.5. Orphan cleanup (files removed from kit)
#   3. Content directories (agents, rules, commands, skills, memory)
#   4. Hook scripts: deploy_hook_scripts
#   5. Update snapshot for each updated file
#   6. Report: skipped files list + summary
# ---------------------------------------------------------------------------
run_update() {
  local project_dir="$1"
  local claude_dir="$2"
  local snapshot_dir="${claude_dir}/.starter-kit-snapshot"

  # Check for major version jumps and show recovery info
  _check_major_upgrade "$claude_dir"

  # Eagerly clear merge prefs if --reset-prefs was passed (even if no conflicts)
  if [[ "${_RESET_MERGE_PREFS:-false}" == "true" ]]; then
    _merge_prefs_file
    rm -f "$_MERGE_PREFS_FILE"
    info "$STR_MERGE_PREFS_CLEARED"
  fi

  local _dr="${DRY_RUN:-false}"

  if [[ "$_dr" == "true" ]]; then
    section "Dry Run: Simulating update"
  else
    section "$STR_UPDATE_TITLE"
  fi

  local updated_files=()
  local skipped_files=()

  # --- Migration: prettier-hooks / console-log-guard → project-level ---
  # Detect by inspecting the CURRENT deployed settings.json for hook entries
  # that reference prettier or console.log patterns (does not depend on ENABLE_* flags).
  local _current_settings_for_migration="${claude_dir}/settings.json"
  local _migrated_hooks=false
  if [[ -f "$_current_settings_for_migration" ]]; then
    if jq -e '
      .hooks.PostToolUse[]? |
      select(.hooks[]?.command | test("prettier|console\\.log"))
    ' "$_current_settings_for_migration" >/dev/null 2>&1; then
      _migrated_hooks=true
    fi
  fi

  # --- Phase 1: settings.json ---
  info "$STR_UPDATE_SETTINGS"

  local new_settings
  new_settings="$(mktemp)"
  _SETUP_TMP_FILES+=("$new_settings")
  build_settings_file "$new_settings"

  local current_settings="${claude_dir}/settings.json"
  local snapshot_settings="${snapshot_dir}/settings.json"

  if [[ -f "$snapshot_settings" ]] && [[ -f "$current_settings" ]]; then
    if [[ "${_SNAPSHOT_BOOTSTRAPPED:-false}" == "true" ]]; then
      # Snapshot was bootstrapped from current — no real baseline.
      # Use current-preserving merge: keep all existing keys, adopt new
      # kit-only keys, prompt on value differences (interactive only).
      info "$STR_UPDATE_SETTINGS_MERGING"
      if [[ -n "${_BACKUP_TIMESTAMP:-}" ]]; then
        info "Restore from backup if needed: ~/.claude.backup.${_BACKUP_TIMESTAMP}"
      fi
      _merge_settings_bootstrap "$current_settings" "$new_settings" "$current_settings"
      updated_files+=("$current_settings")
      if [[ "$_dr" == "true" ]]; then
        info "settings.json will be merged (bootstrap)"
      else
        ok "$STR_UPDATE_SETTINGS_MERGED"
      fi
    elif ! _file_changed "$snapshot_settings" "$current_settings"; then
      # User didn't change settings → safe to overwrite
      cp -a "$new_settings" "$current_settings"
      updated_files+=("$current_settings")
      if [[ "$_dr" == "true" ]]; then
        info "settings.json will be updated"
      else
        ok "$STR_UPDATE_SETTINGS_UPDATED"
      fi
    elif ! _file_changed "$snapshot_settings" "$new_settings"; then
      # Kit didn't change → keep current
      if [[ "$_dr" == "true" ]]; then
        info "settings.json — no kit changes"
      else
        ok "$STR_UPDATE_SETTINGS_UNCHANGED"
      fi
    else
      # Both changed → 3-way merge
      info "$STR_UPDATE_SETTINGS_MERGING"
      merge_settings_3way "$snapshot_settings" "$current_settings" "$new_settings" "$current_settings"
      updated_files+=("$current_settings")
      if [[ "$_dr" == "true" ]]; then
        info "settings.json will be merged (3-way)"
      else
        ok "$STR_UPDATE_SETTINGS_MERGED"
      fi
    fi
  else
    # No snapshot → treat as fresh install for settings
    cp -a "$new_settings" "$current_settings"
    updated_files+=("$current_settings")
    if [[ "$_dr" == "true" ]]; then
      info "settings.json will be created"
    else
      ok "$STR_UPDATE_SETTINGS_UPDATED"
    fi
  fi

  # --- Migration: explicitly remove deprecated prettier/console-log hooks ---
  if [[ "$_migrated_hooks" == "true" ]] && [[ -f "$current_settings" ]]; then
    local _cleaned
    _cleaned="$(jq '
      # Kit-generated hooks all start with this exact boilerplate
      def is_kit_hook: .hooks[]?.command | startswith("#!/bin/bash\ninput=$(cat)");

      if .hooks.PostToolUse then
        .hooks.PostToolUse |= map(
          select(
            (is_kit_hook and (.hooks[]?.command | test("prettier --write"))) | not
          )
          | select(
            (is_kit_hook and (.hooks[]?.command | test("console\\\\.log")) and
             (.hooks[]?.command | test("grep -n"))) | not
          )
        )
      else . end
      |
      if .hooks.Stop then
        .hooks.Stop |= map(
          select(
            (is_kit_hook and (.hooks[]?.command | test("console\\\\.log")) and
             (.hooks[]?.command | test("git diff --name-only")) and
             (.hooks[]?.command | test("modified_files"))) | not
          )
        )
      else . end
    ' "$current_settings")" && printf '%s\n' "$_cleaned" > "$current_settings"
  fi

  # Sync metadata variables from merged/deployed settings.json so that
  # write_manifest() and save_config() record the actual deployed values.
  _sync_settings_metadata "$current_settings"

  # --- Phase 2: CLAUDE.md (section-aware) ---
  info "$STR_UPDATE_CLAUDEMD"

  local new_claude_md
  new_claude_md="$(mktemp)"
  _SETUP_TMP_FILES+=("$new_claude_md")
  build_claude_md_to_file "$new_claude_md"

  local current_claude_md="${claude_dir}/CLAUDE.md"
  local snapshot_claude_md="${snapshot_dir}/CLAUDE.md"

  if _update_claude_md "$current_claude_md" "$snapshot_claude_md" "$new_claude_md"; then
    updated_files+=("$current_claude_md")
    if [[ "$_dr" == "true" ]]; then
      info "CLAUDE.md kit section will be updated"
    else
      ok "$STR_CLAUDEMD_KIT_UPDATED"
    fi
  else
    skipped_files+=("CLAUDE.md")
    if [[ "$_dr" == "true" ]]; then
      info "CLAUDE.md — no kit section changes"
    else
      info "$STR_CLAUDEMD_KIT_UNCHANGED"
    fi
  fi

  # Older releases deployed AGENTS.md into ~/.claude. The starter kit no
  # longer manages that file, so remove the stale copy during update.
  local legacy_agents_md="${claude_dir}/AGENTS.md"
  if [[ -f "$legacy_agents_md" ]]; then
    rm -f "$legacy_agents_md"
    ok "Removed legacy AGENTS.md"
  fi

  # --- Phase 2.5: Orphan cleanup (files removed from kit) ---
  local _new_desired_files
  _new_desired_files="$(desired_managed_files_json)"
  _remove_orphan_files "$claude_dir" "$_new_desired_files" "$snapshot_dir"

  # --- Phase 3: Content directories ---
  local dir
  for dir in agents rules commands skills memory; do
    local src_dir="${project_dir}/${dir}"
    local dest_dir="${claude_dir}/${dir}"
    local snap_dir="${snapshot_dir}/${dir}"

    [[ -d "$src_dir" ]] || continue

    # Check INSTALL_* flag (e.g. INSTALL_AGENTS)
    local flag_var
    flag_var="INSTALL_$(printf '%s' "$dir" | tr '[:lower:]' '[:upper:]')"
    if ! is_true "${!flag_var:-false}"; then
      continue
    fi

    mkdir -p "$dest_dir"

    while IFS= read -r -d '' src_file; do
      local rel_file="${src_file#"$src_dir"/}"
      local dest_file="${dest_dir}/${rel_file}"
      local snap_file="${snap_dir}/${rel_file}"

      # Ensure parent directory exists for nested files (e.g. skills/subdir/file.md)
      mkdir -p "$(dirname "$dest_file")"

      if _update_file "$dest_file" "$snap_file" "$src_file"; then
        updated_files+=("$dest_file")
      else
        skipped_files+=("${dir}/${rel_file}")
      fi
    done < <(find "$src_dir" -type f -print0 2>/dev/null)
  done

  # --- Phase 5: Hook scripts (update-aware) ---
  _update_hook_scripts "$claude_dir" "$snapshot_dir" updated_files skipped_files

  # --- Phase 6: Update snapshot for each updated file ---
  # CRITICAL: For settings.json, snapshot must store the NEW KIT version
  # (not the merge result). This ensures the next update's 3-way comparison
  # correctly detects user modifications against the kit baseline.
  # If we stored the merge result, next update would see snapshot==current
  # and conclude "user didn't change anything" — silently overwriting.
  if [[ "$_dr" != "true" ]]; then
    info "$STR_UPDATE_SNAPSHOT"
  fi
  local file
  for file in "${updated_files[@]+"${updated_files[@]}"}"; do
    local _basename
    _basename="$(basename "$file")"
    if [[ "$_basename" == "CLAUDE.md" ]]; then
      _snapshot_claude_md "$claude_dir" "$file"
    elif [[ "$_basename" == "settings.json" ]]; then
      # Snapshot the kit-generated version, not the merge result
      local _snap_dest="${snapshot_dir}/settings.json"
      mkdir -p "$snapshot_dir"
      cp "$new_settings" "$_snap_dest"
      if [[ "$_dr" != "true" ]]; then
        info "Snapshot updated: settings.json (kit baseline)"
      fi
    else
      _update_snapshot_file "$claude_dir" "$file"
    fi
  done
  if [[ "$_dr" != "true" ]]; then
    ok "$STR_UPDATE_SNAPSHOT_DONE"
  fi

  # --- Report ---
  if [[ "$_dr" != "true" ]]; then
    if [[ ${#skipped_files[@]} -gt 0 ]]; then
      printf "\n"
      info "$STR_UPDATE_SKIPPED_TITLE"
      local f
      for f in "${skipped_files[@]}"; do
        info "  - $f"
      done
    fi

    printf "\n"
    ok "$STR_UPDATE_COMPLETE (${#updated_files[@]} updated, ${#skipped_files[@]} skipped)"

    # Show skip notification with recovery info when files were skipped
    if [[ ${#skipped_files[@]} -gt 0 ]]; then
      info "${STR_UPDATE_SKIPPED_HINT:-Skipped files retain your changes. Kit updates for those files will apply on next update after you accept or reset.}"

      local backup_file="${claude_dir}/.starter-kit-last-backup"
      if [[ -f "$backup_file" ]]; then
        local _skip_backup
        _skip_backup="$(cat "$backup_file")"
        info "To restore kit defaults: cp -a \"$_skip_backup\" ~/.claude"
      fi
    fi
  fi

  # Show migration message if old hooks were detected and removed
  if [[ "$_migrated_hooks" == "true" ]]; then
    warn "${STR_MIGRATION_HOOKS_TO_PROJECT:-prettier-hooks and console-log-guard have moved to project-level. Run /init-harness in your project.}"
  fi
}
