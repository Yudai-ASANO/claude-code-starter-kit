# Testing Mistakes, Organization & CI Setup

## Common Testing Mistakes to Avoid

### Testing Implementation Details (WRONG)
```
// Don't test internal state or private methods
expect(component.internalState.count).toBe(5)
```

### Test User-Visible Behavior (CORRECT)
```
// Test what users see and interact with
expect(screen.getByText('Count: 5')).toBeVisible()

// Or in non-UI tests, test public outputs
expect(result.total).toBe(5)
```

### Brittle Selectors (WRONG)
```
// Breaks easily when CSS changes
await page.click('.css-class-xyz')
```

### Semantic Selectors (CORRECT)
```
// Resilient to styling changes
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')
```

### No Test Isolation (WRONG)
```
// Tests depend on each other
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* depends on previous test */ })
```

### Independent Tests (CORRECT)
```
// Each test sets up its own data
test('creates user', () => {
  user = createTestUser()
  // Test logic
})

test('updates user', () => {
  user = createTestUser()
  // Update logic
})
```

## Test File Organization

Place tests close to the code they test. The exact structure depends on your framework and language conventions.

```
project/
├── src/
│   ├── components/
│   │   ├── Button/
│   │   │   ├── Button.tsx (or .vue, .svelte, etc.)
│   │   │   └── Button.test.tsx         # Unit tests
│   │   └── ItemCard/
│   │       ├── ItemCard.tsx
│   │       └── ItemCard.test.tsx
│   ├── services/
│   │   ├── item_service.py
│   │   └── test_item_service.py        # Unit tests
│   └── handlers/
│       ├── items.go
│       └── items_test.go               # Unit tests
└── tests/
    ├── integration/                     # Integration tests
    └── e2e/                            # End-to-end tests
        ├── items.spec.ts
        └── auth.spec.ts
```

## Coverage Configuration

Set coverage thresholds appropriate to your project. 80% is a common minimum target.

```
# Concept: Configure your test runner to enforce minimum coverage thresholds
# Example thresholds:
#   branches:   80%
#   functions:  80%
#   lines:      80%
#   statements: 80%
```

**By test runner:**
| Runner | Config file | Threshold key |
|--------|-------------|---------------|
| Jest | `jest.config.js` | `coverageThreshold.global` |
| pytest | `pyproject.toml` | `[tool.coverage.report] fail_under` |
| Go | (built-in) | `go test -coverprofile` + threshold check |
| Vitest | `vitest.config.ts` | `coverage.thresholds` |

## Continuous Testing

### Watch Mode During Development
```bash
# Run tests automatically on file changes (adapt to your runner)
npm test -- --watch        # Jest/Vitest
pytest-watch               # pytest
```

### Pre-Commit Hook
```bash
# Runs before every commit (configure via husky, pre-commit, lefthook, etc.)
# Use your project's test and lint commands
```

### CI/CD Integration
```yaml
# GitHub Actions example (adapt commands for your stack)
- name: Run Tests
  run: <your-test-command-with-coverage>
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```
