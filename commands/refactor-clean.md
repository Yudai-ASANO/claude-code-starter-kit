# Refactor Clean

Safely identify and remove dead code with test verification:

1. Run appropriate dead code analysis tools for the project's language
   (e.g., knip/ts-prune for TypeScript, vulture for Python, deadcode for Go, etc.)

2. Generate comprehensive report in .reports/dead-code-analysis.md

3. Categorize findings by severity:
   - SAFE: Test files, unused utilities
   - CAUTION: API routes, components
   - DANGER: Config files, main entry points

4. Propose safe deletions only

5. Before each deletion:
   - Run full test suite
   - Verify tests pass
   - Apply change
   - Re-run tests
   - Rollback if tests fail

6. Show summary of cleaned items

Never delete code without running tests first!

## Related Agents

This command invokes the `refactor-cleaner` agent located at:
`~/.claude/agents/refactor-cleaner.md`
