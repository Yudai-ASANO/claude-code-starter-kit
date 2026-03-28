# Wizard Config Mapping

This document explains where each interactive wizard choice or non-interactive CLI flag is applied during setup.

There are three broad categories of config in this starter kit.

1. Values written directly into generated files such as `settings.json` or `CLAUDE.md`
2. Values used by deployment or extra setup steps
3. Values stored mainly for presets, manifests, or future re-runs

Not every saved value is supposed to appear in `settings.json`. In particular, `INSTALL_*` flags mostly control defaults and file deployment rather than final JSON output.

## Wizard Steps

| Step | Saved key / CLI | What it controls | Main destination | Visible in `settings.json` |
|---|---|---|---|---|
| Language | `LANGUAGE` / `--language` | UI language and generated language settings | `settings.json`, `CLAUDE.md`, i18n loading | Yes |
| Codex CLI | `ENABLE_CODEX_CLI` / `--codex-cli` | Whether to run Codex CLI install and auth | Codex CLI setup in `setup.sh` | No |
| New `/init` | `ENABLE_NEW_INIT` / `--new-init` | Enable Claude Code's interactive `/init` flow | `settings.json` `env.CLAUDE_CODE_NEW_INIT` | Yes |
| Editor | `EDITOR_CHOICE` / `--editor` | Editor command for the git push review hook | Hook template substitution, manifest | Indirectly |
| Hooks | `ENABLE_*` / `--hooks` | Which hooks are enabled | Hook fragments merged into `settings.json` | Yes |
| Plugins | `SELECTED_PLUGINS` / `--plugins` | Recommended Claude Code plugins to install | Plugin install flow, manifest | No |
| Claude Code attribution | `COMMIT_ATTRIBUTION` / `--commit-attribution` | Claude Code attribution in commits and PRs | `settings.json` `attribution` | Yes |
| Confirm & Deploy | `WIZARD_RESULT` | Save only, deploy now, or cancel | Execution flow control | No |

## Core Selection Mapping

| Key | Purpose | Main destination | Notes |
|---|---|---|---|
| `LANGUAGE` | UI and generated file language | `settings.json`, `CLAUDE.md`, i18n | Currently written as `English` or `日本語` |
| `ENABLE_NEW_INIT` | Claude Code's new interactive `/init` mode | `settings.json` `env.CLAUDE_CODE_NEW_INIT` | Defaults to `true` |
| `EDITOR_CHOICE` | Editor command for git push review | `features/git-push-review/hooks.json` | Use `none` if you do not want editor integration |
| `COMMIT_ATTRIBUTION` | Claude Code attribution on or off | `settings.json` `attribution.commit`, `attribution.pr` | `false` clears both commit and PR attribution |
| `ENABLE_CODEX_CLI` | Run Codex CLI setup or skip it | Codex CLI install and auth | A setup action, not a JSON setting |
| `SELECTED_PLUGINS` | Recommended plugin selection | Plugin install flow, manifest | Supports `name@marketplace` |

## Content Installation Flags

| Key | What it deploys | Main destination | Behavior during update |
|---|---|---|---|
| `INSTALL_AGENTS` | `~/.claude/agents/` | Initial copy, update | Synced only when enabled |
| `INSTALL_RULES` | `~/.claude/rules/` | Initial copy, update | Same |
| `INSTALL_COMMANDS` | `~/.claude/commands/` | Initial copy, update | Same |
| `INSTALL_SKILLS` | `~/.claude/skills/` | Initial copy, update | Same |
| `INSTALL_MEMORY` | `~/.claude/memory/` | Initial copy, update | Same |

## Hook Flag Mapping

These flags are used to merge the corresponding `features/*/hooks.json` fragments into `settings.json`.

| Key | Hook / feature | Main purpose | Included in `settings.json` |
|---|---|---|---|
| `ENABLE_SAFETY_NET` | Safety Net | Block destructive commands | Yes |
| `ENABLE_AUTO_UPDATE` | Auto Update | Check for starter kit updates on session start | Yes |
| `ENABLE_GIT_PUSH_REVIEW` | Git Push Review | Pause before push and open a diff | Yes |
| `ENABLE_DOC_BLOCKER` | Doc Blocker | Prevent unnecessary `.md` / `.txt` files | Yes |
| `ENABLE_PRETTIER_HOOKS` | Prettier Auto-format | Format JS / TS edits | Yes |
| `ENABLE_CONSOLE_LOG_GUARD` | Console Log Guard | Warn on leftover `console.log` | Yes |
| `ENABLE_MEMORY_PERSISTENCE` | Memory Persistence | Persist important knowledge | Yes |
| `ENABLE_STRATEGIC_COMPACT` | Strategic Compact | Compact suggestion support | Yes |
| `ENABLE_PR_CREATION_LOG` | PR Creation Log | PR creation logging support | Yes |
| `ENABLE_PRE_COMPACT_COMMIT` | Pre-compact Commit | Commit helper before compact | Yes |
| `ENABLE_STATUSLINE` | Statusline | Statusline feature toggle | Yes |
| `ENABLE_DOC_SIZE_GUARD` | Doc Size Guard | Warn when `CLAUDE.md` / `AGENTS.md` is too large | Yes |
| `ENABLE_CHECK_CODEX_AFTER_PLAN` | Codex After Plan | Suggest Codex design review when plan files change | Yes |
| `ENABLE_CHECK_CODEX_BEFORE_WRITE` | Codex Write Counter | Suggest Codex design review after every 5 file writes | Yes |
| `ENABLE_ERROR_TO_CODEX` | Error to Codex | Suggest Codex debugging when commands fail | Yes |

## Common Misunderstandings

### `SELECTED_PLUGINS` is not visible in `settings.json`

That is expected. Plugin selection is consumed by the plugin installation flow and stored in the manifest for later reuse.

### `ENABLE_CODEX_CLI` does not show up in `settings.json`

That is expected. It controls whether Codex CLI install and auth are executed, not whether a JSON key is written.
