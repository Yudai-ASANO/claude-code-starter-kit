# Build and Fix

Incrementally fix compilation and build errors:

1. Run build: use the project's build command

2. Parse error output:
   - Group by file
   - Sort by severity

3. For each error:
   - Show error context (5 lines before/after)
   - Explain the issue
   - Propose fix
   - Apply fix
   - Re-run build
   - Verify error resolved

4. Stop if:
   - Fix introduces new errors
   - Same error persists after 3 attempts
   - User requests pause

5. Show summary:
   - Errors fixed
   - Errors remaining
   - New errors introduced

Fix one error at a time for safety!

## Related Agents

This command invokes the `build-error-resolver` agent located at:
`~/.claude/agents/build-error-resolver.md`
