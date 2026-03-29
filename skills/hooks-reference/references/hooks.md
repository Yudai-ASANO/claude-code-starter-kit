# Hooks System

## Hook Types

- **PreToolUse**: Before tool execution (validation, parameter modification)
- **PostToolUse**: After tool execution (auto-format, checks)
- **Stop**: When session ends (final verification)
- **SessionStart**: When session begins (context loading, stack detection)
- **PreCompact**: Before context compaction (memory persistence)

## Current Hooks (in ~/.claude/settings.json)

### PreToolUse
- **safety-net**: Blocks destructive Bash commands via cc-safety-net
- **doc blocker**: Blocks creation of unnecessary .md/.txt files
- **strategic-compact**: Suggests compaction at logical intervals
- **pre-commit-gate**: Runs test/lint/type checks before git commit
- **git push review**: Prompts for review before push

### PostToolUse
- **PR creation**: Logs PR URL when gh pr create executed
- **doc-size-guard**: Validates CLAUDE.md/AGENTS.md file size
- **check-codex-after-plan**: Checks if Codex should be invoked after planning
- **check-codex-before-write**: Checks if Codex should be invoked before writing code
- **error-to-codex**: Routes errors to Codex CLI for analysis
- **post-test-analysis**: Analyzes test failures

### SessionStart
- **session-start.sh**: Load previous session context
- **auto-update.sh**: Check for kit updates (24h cache)
- **detect-stack.sh**: Detect project technology stack

### PreCompact
- **pre-compact.sh**: Memory persistence before compaction
- **auto-commit**: Auto-commit before compact

### Stop
- **session-end.sh**: Session cleanup and memory persistence

## Auto-Accept Permissions

Use with caution:
- Enable for trusted, well-defined plans
- Disable for exploratory work
- Never use dangerously-skip-permissions flag
- Configure `allowedTools` in `~/.claude.json` instead

## TodoWrite Best Practices

Use TodoWrite tool to:
- Track progress on multi-step tasks
- Verify understanding of instructions
- Enable real-time steering
- Show granular implementation steps

Todo list reveals:
- Out of order steps
- Missing items
- Extra unnecessary items
- Wrong granularity
- Misinterpreted requirements
