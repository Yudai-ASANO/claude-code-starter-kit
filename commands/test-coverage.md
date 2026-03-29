# Test Coverage

Analyze test coverage and generate missing tests:

1. Run tests with coverage: use the project's test coverage command

2. Analyze the project's coverage report

3. Identify files below 80% coverage threshold

4. For each under-covered file:
   - Analyze untested code paths
   - Generate unit tests for functions
   - Generate integration tests for APIs
   - Generate E2E tests for critical flows

5. Verify new tests pass

6. Show before/after coverage metrics

7. Ensure project reaches 80%+ overall coverage

Focus on:
- Happy path scenarios
- Error handling
- Edge cases (null, undefined, empty)
- Boundary conditions
