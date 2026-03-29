---
description: Generate and run end-to-end tests. Detects the project's E2E framework, creates test journeys, runs tests, captures artifacts, and identifies flaky tests.
---

# E2E Command

This command invokes the **e2e-runner** agent to generate, maintain, and execute end-to-end tests using the project's detected E2E framework.

## What This Command Does

1. **Detect E2E Framework** - Identify Playwright, Cypress, XCUITest, Espresso, Laravel Dusk, or Molecule
2. **Generate Test Journeys** - Create tests for user flows using the detected framework
3. **Run E2E Tests** - Execute tests in the appropriate environment
4. **Capture Artifacts** - Screenshots, videos, traces, logs on failures
5. **Identify Flaky Tests** - Quarantine unstable tests

## When to Use

Use `/e2e` when:
- Testing critical user journeys (login, CRUD, payments)
- Verifying multi-step flows work end-to-end
- Testing UI interactions and navigation
- Validating integration between components
- Preparing for production deployment

## How It Works

The e2e-runner agent will:

1. **Detect E2E framework** from project configuration files
2. **Analyze user flow** and identify test scenarios
3. **Generate tests** using the framework's Page/Screen Object pattern
4. **Run tests** in the appropriate environment
5. **Generate report** with results and artifacts
6. **Identify flaky tests** and recommend fixes

## Example Usage

```
User: /e2e Test the item search and view flow

Agent (e2e-runner):
# E2E Test Generation: Item Search and View Flow

## Framework Detected: [Playwright / Cypress / XCUITest / etc.]

## Test Scenario Identified

**User Journey:** Search Items → View Results → Select Item → View Details

**Test Coverage:**
1. Navigate to items list
2. Perform search
3. Verify search results
4. Select first result
5. Verify details page loads

## Generated Test Code

[Framework-specific test code using Page/Screen Object pattern]

## Running Tests

[Framework-specific run command and output]

## Test Report

╔══════════════════════════════════════════════════════════════╗
║                    E2E Test Results                          ║
╠══════════════════════════════════════════════════════════════╣
║ Framework:  [detected]                                       ║
║ Status:     ALL TESTS PASSED                                 ║
║ Total:      3 tests                                          ║
║ Passed:     3 (100%)                                         ║
║ Duration:   9.1s                                             ║
╚══════════════════════════════════════════════════════════════╝
```

## Test Artifacts

When tests run, the following artifacts are captured:

**On All Tests:**
- Test report in the framework's native format
- JUnit XML / test results for CI integration

**On Failure Only:**
- Screenshot of the failing state
- Logs and traces for debugging
- Video/recording if the framework supports it

## Flaky Test Detection

If a test fails intermittently:

```
FLAKY TEST DETECTED: [test file path]

Test passed 7/10 runs (70% pass rate)

Common failure:
"Timeout waiting for element"

Recommended fixes:
1. Add explicit wait for the target element
2. Increase timeout
3. Check for race conditions
4. Verify element is not hidden by animation

Quarantine recommendation: Mark test as skipped until fixed
```

## Critical Flow Prioritization

Prioritize E2E tests by risk level:

**HIGH (Must Always Pass):**
- Authentication flows (login, logout, registration)
- Data mutation operations (create, update, delete)
- Payment/financial flows (if applicable)
- Core business workflow

**MEDIUM:**
- Search and filtering
- Navigation between sections
- User profile/settings

**LOW:**
- UI polish and animations
- Non-critical features
- Edge case UI states

## Best Practices

**DO:**
- Use Page/Screen Object pattern for maintainability
- Use stable locators (data-testid, accessibility IDs)
- Wait for specific conditions, not arbitrary timeouts
- Test critical user journeys end-to-end
- Run tests before merging to main
- Review artifacts when tests fail

**DON'T:**
- Use brittle selectors (CSS classes, XPath)
- Test implementation details
- Run E2E tests against production with real data
- Ignore flaky tests
- Skip artifact review on failures
- Test every edge case with E2E (use unit tests instead)

## Integration with Other Commands

- Use `/plan` to identify critical journeys to test
- Use `/tdd` for unit tests (faster, more granular)
- Use `/e2e` for integration and user journey tests
- Use `/code-review` to verify test quality

## Related Agents

This command invokes the `e2e-runner` agent located at:
`~/.claude/agents/e2e-runner.md`
