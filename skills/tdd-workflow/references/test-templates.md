# Test Code Templates

Templates for common test patterns. Detect the project's language and test framework, then use the matching section.

## Unit Test Patterns

### JavaScript/TypeScript (Jest/Vitest)
```typescript
describe('calculateScore', () => {
  it('returns high score for valid input', () => {
    const result = calculateScore({ value: 100, weight: 0.5 })
    expect(result).toBeGreaterThan(80)
  })

  it('returns 0 for empty input', () => {
    expect(calculateScore({ value: 0, weight: 0 })).toBe(0)
  })

  it('throws on invalid input', () => {
    expect(() => calculateScore(null)).toThrow()
  })
})
```

### Python (pytest)
```python
def test_calculate_score_valid_input():
    result = calculate_score(value=100, weight=0.5)
    assert result > 80

def test_calculate_score_empty_input():
    assert calculate_score(value=0, weight=0) == 0

def test_calculate_score_invalid_input():
    with pytest.raises(ValueError):
        calculate_score(None)
```

### Go (testing)
```go
func TestCalculateScore(t *testing.T) {
    t.Run("returns high score for valid input", func(t *testing.T) {
        result := CalculateScore(100, 0.5)
        if result <= 80 {
            t.Errorf("expected > 80, got %f", result)
        }
    })

    t.Run("returns 0 for empty input", func(t *testing.T) {
        result := CalculateScore(0, 0)
        if result != 0 {
            t.Errorf("expected 0, got %f", result)
        }
    })
}
```

### Swift (XCTest)
```swift
class ScoreTests: XCTestCase {
    func testCalculateScoreValidInput() {
        let result = calculateScore(value: 100, weight: 0.5)
        XCTAssertGreaterThan(result, 80)
    }

    func testCalculateScoreEmptyInput() {
        XCTAssertEqual(calculateScore(value: 0, weight: 0), 0)
    }
}
```

### Kotlin (JUnit 5)
```kotlin
class ScoreTest {
    @Test
    fun `returns high score for valid input`() {
        val result = calculateScore(value = 100, weight = 0.5)
        assertTrue(result > 80)
    }

    @Test
    fun `returns 0 for empty input`() {
        assertEquals(0.0, calculateScore(value = 0, weight = 0.0))
    }
}
```

### PHP (PHPUnit)
```php
class ScoreTest extends TestCase
{
    public function testCalculateScoreValidInput(): void
    {
        $result = calculateScore(value: 100, weight: 0.5);
        $this->assertGreaterThan(80, $result);
    }

    public function testCalculateScoreEmptyInput(): void
    {
        $this->assertEquals(0, calculateScore(value: 0, weight: 0));
    }
}
```

## API / Integration Test Patterns

### JavaScript/TypeScript (supertest / framework handler)
```typescript
describe('GET /api/items', () => {
  it('returns items successfully', async () => {
    const response = await request(app).get('/api/items')
    expect(response.status).toBe(200)
    expect(response.body.success).toBe(true)
    expect(Array.isArray(response.body.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const response = await request(app).get('/api/items?limit=invalid')
    expect(response.status).toBe(400)
  })
})
```

### Python (httpx / FastAPI TestClient)
```python
def test_get_items(client):
    response = client.get("/api/items")
    assert response.status_code == 200
    assert response.json()["success"] is True

def test_get_items_invalid_params(client):
    response = client.get("/api/items?limit=invalid")
    assert response.status_code == 400
```

### Go (net/http/httptest)
```go
func TestGetItems(t *testing.T) {
    req := httptest.NewRequest("GET", "/api/items", nil)
    w := httptest.NewRecorder()
    handler.ServeHTTP(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("expected 200, got %d", w.Code)
    }
}
```

### PHP (Laravel)
```php
public function testGetItems(): void
{
    $response = $this->getJson('/api/items');
    $response->assertStatus(200)
             ->assertJsonStructure(['success', 'data']);
}
```

## E2E Test Patterns

Use the project's detected E2E framework. See `~/.claude/agents/e2e-runner.md` for full framework-specific guidance.

### Web: Playwright
```typescript
import { test, expect } from '@playwright/test'

test('user can search and view items', async ({ page }) => {
  await page.goto('/items')
  await page.fill('[data-testid="search-input"]', 'test query')
  await page.waitForResponse(resp => resp.url().includes('/api/items'))

  const results = page.locator('[data-testid="item-card"]')
  await expect(results.first()).toBeVisible()
})
```

### Web: Cypress
```typescript
it('user can search and view items', () => {
  cy.visit('/items')
  cy.get('[data-testid="search-input"]').type('test query')
  cy.intercept('GET', '/api/items*').as('search')
  cy.wait('@search')
  cy.get('[data-testid="item-card"]').should('have.length.greaterThan', 0)
})
```

### iOS: XCUITest
```swift
func testSearchAndViewItems() throws {
    let app = XCUIApplication()
    app.launch()

    app.textFields["searchInput"].tap()
    app.textFields["searchInput"].typeText("test query")

    let firstCell = app.cells.matching(identifier: "itemCell").firstMatch
    XCTAssertTrue(firstCell.waitForExistence(timeout: 5))
}
```

### Android: Espresso
```kotlin
@Test
fun searchAndViewItems() {
    onView(withId(R.id.searchInput))
        .perform(typeText("test query"), closeSoftKeyboard())
    onView(withId(R.id.recyclerView))
        .check(matches(hasMinimumChildCount(1)))
}
```

## Mocking External Services

### JavaScript/TypeScript (jest.mock)
```typescript
// Mock database client
jest.mock('@/lib/db', () => ({
  db: {
    query: jest.fn(() => Promise.resolve({
      rows: [{ id: 1, name: 'Test Item' }]
    }))
  }
}))

// Mock external API
jest.mock('@/lib/api-client', () => ({
  fetchData: jest.fn(() => Promise.resolve({ result: 'mock' }))
}))
```

### Python (unittest.mock)
```python
from unittest.mock import patch, MagicMock

@patch('app.db.query')
def test_with_mocked_db(mock_query):
    mock_query.return_value = [{'id': 1, 'name': 'Test Item'}]
    result = get_items()
    assert len(result) == 1
```

### Go (interface + test double)
```go
type MockDB struct{}

func (m *MockDB) Query(q string) ([]Item, error) {
    return []Item{{ID: 1, Name: "Test Item"}}, nil
}

func TestGetItems(t *testing.T) {
    svc := NewService(&MockDB{})
    items, err := svc.GetItems()
    if err != nil { t.Fatal(err) }
    if len(items) != 1 { t.Errorf("expected 1 item, got %d", len(items)) }
}
```
