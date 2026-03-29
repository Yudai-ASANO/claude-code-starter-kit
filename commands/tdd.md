---
description: Enforce test-driven development workflow. Scaffold interfaces, generate tests FIRST, then implement minimal code to pass. Ensure 80%+ coverage.
---

# TDD Command

This command invokes the **tdd-guide** agent to enforce test-driven development methodology.

## What This Command Does

1. **Scaffold Interfaces** - Define types/interfaces first
2. **Generate Tests First** - Write failing tests (RED)
3. **Implement Minimal Code** - Write just enough to pass (GREEN)
4. **Refactor** - Improve code while keeping tests green (REFACTOR)
5. **Verify Coverage** - Ensure 80%+ test coverage

## When to Use

Use `/tdd` when:
- Implementing new features
- Adding new functions/components
- Fixing bugs (write test that reproduces bug first)
- Refactoring existing code
- Building critical business logic

## How It Works

The tdd-guide agent will:

1. **Define interfaces** for inputs/outputs
2. **Write tests that will FAIL** (because code doesn't exist yet)
3. **Run tests** and verify they fail for the right reason
4. **Write minimal implementation** to make tests pass
5. **Run tests** and verify they pass
6. **Refactor** code while keeping tests green
7. **Check coverage** and add more tests if below 80%

## TDD Cycle

```
RED → GREEN → REFACTOR → REPEAT

RED:      Write a failing test
GREEN:    Write minimal code to pass
REFACTOR: Improve code, keep tests passing
REPEAT:   Next feature/scenario
```

## Example Usage

```
User: /tdd I need a function to calculate a score from multiple weighted factors

Agent (tdd-guide):
# TDD Session: Weighted Score Calculator

## Step 1: Define Interface (SCAFFOLD)

Define the input structure and function signature using the project's language.

Example (pseudocode):
  Input: a record/struct with fields:
    - value_a: number (0-100)
    - value_b: number (0-100)
    - value_c: number (0-100)
    - timestamp: datetime

  Output: number (0-100)

  Function: calculate_score(input) -> number

## Step 2: Write Failing Test (RED)

Write tests using the project's test framework:

- Test: "should return high score when all factors are favorable"
  input = { value_a: 1000, value_b: 0.01, value_c: 500, timestamp: now }
  assert score > 80 and score <= 100

- Test: "should return low score when all factors are unfavorable"
  input = { value_a: 1, value_b: 50, value_c: 2, timestamp: 24 hours ago }
  assert score < 30 and score >= 0

- Test: "should handle edge case: all zeroes"
  input = { value_a: 0, value_b: 0, value_c: 0, timestamp: now }
  assert score == 0

## Step 3: Run Tests - Verify FAIL

Run the project's test command.

Verify tests fail with "Not implemented" or similar.

✅ Tests fail as expected. Ready to implement.

## Step 4: Implement Minimal Code (GREEN)

Write the minimum implementation to make all tests pass:
- Handle edge cases (zero values)
- Calculate component scores on a 0-100 scale
- Apply weights to each component
- Clamp final result to 0-100

## Step 5: Run Tests - Verify PASS

Run the project's test command again.

✅ All tests passing!

## Step 6: Refactor (IMPROVE)

- Extract magic numbers into named constants
- Add a clamp/utility function for readability
- Group related constants together

## Step 7: Verify Tests Still Pass

Run the project's test command again.

✅ Refactoring complete, tests still passing!

## Step 8: Check Coverage

Run the project's test coverage command.

Verify coverage meets the 80% threshold.

✅ TDD session complete!
```

## TDD Best Practices

**DO:**
- ✅ Write the test FIRST, before any implementation
- ✅ Run tests and verify they FAIL before implementing
- ✅ Write minimal code to make tests pass
- ✅ Refactor only after tests are green
- ✅ Add edge cases and error scenarios
- ✅ Aim for 80%+ coverage (100% for critical code)

**DON'T:**
- ❌ Write implementation before tests
- ❌ Skip running tests after each change
- ❌ Write too much code at once
- ❌ Ignore failing tests
- ❌ Test implementation details (test behavior)
- ❌ Mock everything (prefer integration tests)

## Test Types to Include

**Unit Tests** (Function-level):
- Happy path scenarios
- Edge cases (empty, null, max values)
- Error conditions
- Boundary values

**Integration Tests** (Component-level):
- API endpoints
- Database operations
- External service calls

**E2E Tests** (use `/e2e` command):
- Critical user flows
- Multi-step processes
- Full stack integration

## Coverage Requirements

- **80% minimum** for all code
- **100% required** for:
  - Financial calculations
  - Authentication logic
  - Security-critical code
  - Core business logic

## Important Notes

**MANDATORY**: Tests must be written BEFORE implementation. The TDD cycle is:

1. **RED** - Write failing test
2. **GREEN** - Implement to pass
3. **REFACTOR** - Improve code

Never skip the RED phase. Never write code before tests.

## Integration with Other Commands

- Use `/plan` first to understand what to build
- Use `/tdd` to implement with tests
- Use `/build-fix` if build errors occur
- Use `/code-review` to review implementation
- Use `/test-coverage` to verify coverage

## Related Agents

This command invokes the `tdd-guide` agent located at:
`~/.claude/agents/tdd-guide.md`

And can reference the `tdd-workflow` skill at:
`~/.claude/skills/tdd-workflow/`
