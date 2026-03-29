---
name: tdd-workflow
description: Use this skill when writing new features, fixing bugs, or refactoring code. Enforces test-driven development with 80%+ coverage including unit, integration, and E2E tests.
---

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Activate

- Writing new features or functionality
- Fixing bugs or issues
- Refactoring existing code
- Adding API endpoints
- Creating new components

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

**Unit Tests** - Individual functions, utilities, component logic, pure functions, helpers.

**Integration Tests** - API endpoints, database operations, service interactions, external API calls.

**E2E Tests** - Critical user flows, complete workflows, UI automation. Framework varies by platform (Playwright, Cypress, XCUITest, Espresso, Laravel Dusk, Molecule, etc.).

## TDD Workflow Steps

### Step 1: Write User Journeys
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for items by keyword,
so that I can find relevant items even without exact names.
```

### Step 2: Generate Test Cases
For each user journey, create comprehensive test cases covering happy paths, edge cases, fallback behavior, and sorting/filtering logic.

### Step 3: Run Tests (They Should Fail)
```bash
# Use your project's test command:
# JS/TS: npm test | Go: go test ./... | Swift: swift test
# Kotlin: ./gradlew test | PHP: ./vendor/bin/phpunit | Python: pytest
# Tests should fail - we haven't implemented yet
```

### Step 4: Implement Code
Write minimal code to make tests pass.

### Step 5: Run Tests Again
```bash
# Run the same test command - tests should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

### Step 7: Verify Coverage
```bash
# Use your project's coverage command:
# JS/TS: npm run test:coverage | Go: go test -cover ./...
# Swift: swift test --enable-code-coverage | Python: pytest --cov
# Kotlin: ./gradlew jacocoTestReport | PHP: ./vendor/bin/phpunit --coverage-text
# Verify 80%+ coverage achieved
```

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - Null, undefined, empty, large
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical user flows
- Tests catch bugs before production

## References

- `references/test-templates.md` - Unit, integration, E2E, and mocking code templates
- `references/testing-mistakes.md` - Common pitfalls, file organization, coverage config, CI setup

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
