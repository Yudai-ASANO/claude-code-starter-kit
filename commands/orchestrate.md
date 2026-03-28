# Orchestrate Command

Sequential agent workflow for complex tasks.

## Usage

`/orchestrate [workflow-type] [task-description]`

## Workflow Types

### feature
Full feature implementation workflow with harness pattern:
```
planner -> [Generator: tdd-guide] -> qa-reviewer -> code-reviewer + security-reviewer
```

#### Phase 1: Planning
planner produces:
- Implementation plan
- **Executable Sprint Contract** (acceptance criteria with verifier commands)

Sprint Contract format:
```markdown
## Sprint Contract
### Acceptance Criteria
| # | Criterion | Verifier Command | Expected Result |
|---|-----------|-----------------|-----------------|
| 1 | Feature works | npm test -- --grep "feature" | exit 0 |
| 2 | Types clean | npx tsc --noEmit | exit 0 |
```

#### Phase 2: Generation
Generator (tdd-guide) receives the plan + sprint contract and implements.
Generator does NOT produce the evidence bundle.

#### Phase 3: Evidence Collection (orchestrator)
The orchestrator (you) collects evidence by running each verifier command
from the sprint contract. Evidence is raw command output, not filtered.

Evidence format:
```markdown
## Evidence (collected by orchestrator)
### Criterion 1: [name]
Command: [verifier command]
Exit code: [actual]
Stdout: [last 20 lines]
```

#### Phase 4: Evaluation
qa-reviewer receives sprint contract + evidence and produces a grading report.

**Repair Loop:**
- If FAIL: repair instructions → Generator re-implements → re-collect evidence → re-evaluate
- Max 3 iterations, then escalate to user

#### Phase 5: Review (after qa-reviewer PASS)
Run in parallel:
- code-reviewer (quality)
- security-reviewer (security)

### bugfix
Bug investigation and fix workflow:
```
explorer -> tdd-guide -> code-reviewer
```

### refactor
Safe refactoring workflow:
```
architect -> code-reviewer -> tdd-guide
```

### security
Security-focused review:
```
security-reviewer -> code-reviewer -> architect
```

## Execution Pattern

For each agent in the workflow:

1. **Invoke agent** with context from previous agent
2. **Collect output** as structured handoff document
3. **Pass to next agent** in chain
4. **Aggregate results** into final report

## Handoff Document Format

Between agents, create handoff document:

```markdown
## HANDOFF: [previous-agent] -> [next-agent]

### Context
[Summary of what was done]

### Findings
[Key discoveries or decisions]

### Files Modified
[List of files touched]

### Open Questions
[Unresolved items for next agent]

### Recommendations
[Suggested next steps]
```

## Example: Feature Workflow

```
/orchestrate feature "Add user authentication"
```

Executes:

1. **Planner Agent**
   - Analyzes requirements
   - Creates implementation plan
   - Identifies dependencies
   - Output: `HANDOFF: planner -> tdd-guide`

2. **TDD Guide Agent**
   - Reads planner handoff
   - Writes tests first
   - Implements to pass tests
   - Output: `HANDOFF: tdd-guide -> code-reviewer`

3. **Code Reviewer Agent**
   - Reviews implementation
   - Checks for issues
   - Suggests improvements
   - Output: `HANDOFF: code-reviewer -> security-reviewer`

4. **Security Reviewer Agent**
   - Security audit
   - Vulnerability check
   - Final approval
   - Output: Final Report

## Final Report Format

```
ORCHESTRATION REPORT
====================
Workflow: feature
Task: Add user authentication
Agents: planner -> tdd-guide -> code-reviewer -> security-reviewer

SUMMARY
-------
[One paragraph summary]

AGENT OUTPUTS
-------------
Planner: [summary]
TDD Guide: [summary]
Code Reviewer: [summary]
Security Reviewer: [summary]

FILES CHANGED
-------------
[List all files modified]

TEST RESULTS
------------
[Test pass/fail summary]

SECURITY STATUS
---------------
[Security findings]

RECOMMENDATION
--------------
[SHIP / NEEDS WORK / BLOCKED]
```

## Parallel Execution

For independent checks, run agents in parallel:

```markdown
### Parallel Phase
Run simultaneously:
- code-reviewer (quality)
- security-reviewer (security)
- architect (design)

### Merge Results
Combine outputs into single report
```

## Arguments

$ARGUMENTS:
- `feature <description>` - Full feature workflow
- `bugfix <description>` - Bug fix workflow
- `refactor <description>` - Refactoring workflow
- `security <description>` - Security review workflow
- `custom <agents> <description>` - Custom agent sequence

## Custom Workflow Example

```
/orchestrate custom "architect,tdd-guide,code-reviewer" "Redesign caching layer"
```

## Tips

1. **Start with planner** for complex features
2. **Always include code-reviewer** before merge
3. **Use security-reviewer** for auth/payment/PII
4. **Keep handoffs concise** - focus on what next agent needs
5. **Run verification** between agents if needed
