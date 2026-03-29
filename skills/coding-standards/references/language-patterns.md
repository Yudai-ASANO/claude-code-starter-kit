# Language Patterns

## Code Quality Principles

### 1. Readability First
- Code is read more than written
- Clear variable and function names
- Self-documenting code preferred over comments
- Consistent formatting

### 2. KISS (Keep It Simple, Stupid)
- Simplest solution that works
- Avoid over-engineering
- No premature optimization
- Easy to understand > clever code

### 3. DRY (Don't Repeat Yourself)
- Extract common logic into functions
- Create reusable components/modules
- Share utilities across modules
- Avoid copy-paste programming

### 4. YAGNI (You Aren't Gonna Need It)
- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

## Variable Naming

| Language | Good | Bad |
|----------|------|-----|
| JS/TS | `const userSearchQuery = 'term'` | `const q = 'term'` |
| Python | `user_search_query = 'term'` | `q = 'term'` |
| Go | `userSearchQuery := "term"` | `q := "term"` |

Use descriptive names that convey intent. Follow the naming convention of your language (camelCase for JS/TS, snake_case for Python, camelCase for Go).

## Function Naming

| Language | Good | Bad |
|----------|------|-----|
| JS/TS | `async function fetchUserData(userId: string) {}` | `async function user(id) {}` |
| Python | `async def fetch_user_data(user_id: str) -> User:` | `async def user(id):` |
| Go | `func FetchUserData(userID string) (*User, error) {}` | `func User(id string) {}` |

Use verb-noun pattern. Boolean functions start with `is`, `has`, `can`, `should`.

## Immutability Pattern (CRITICAL)

**JS/TS:**
```typescript
// ALWAYS create new objects
const updatedUser = { ...user, name: 'New Name' }
const updatedArray = [...items, newItem]

// NEVER mutate directly
user.name = 'New Name'  // BAD
items.push(newItem)     // BAD
```

**Python:**
```python
# ALWAYS create new instances
updated_user = {**user, "name": "New Name"}
updated_list = [*items, new_item]

# NEVER mutate directly
user["name"] = "New Name"  # BAD
items.append(new_item)     # BAD
```

**Go:**
```go
// ALWAYS create new structs
updatedUser := User{
    ID:   user.ID,
    Name: "New Name",
    Email: user.Email,
}

// For slices, create a new slice
updatedItems := append([]Item{}, items...)
updatedItems = append(updatedItems, newItem)
```

## Error Handling

**JS/TS:**
```typescript
async function fetchData(url: string) {
  try {
    const response = await fetch(url)
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }
    return await response.json()
  } catch (error) {
    console.error('Fetch failed:', error)
    throw new Error('Failed to fetch data')
  }
}
```

**Python:**
```python
async def fetch_data(url: str) -> dict:
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as e:
        raise ValueError(f"HTTP {e.response.status_code}: {e.response.text}") from e
    except httpx.RequestError as e:
        raise ConnectionError(f"Failed to fetch data: {e}") from e
```

**Go:**
```go
func fetchData(url string) ([]byte, error) {
    resp, err := http.Get(url)
    if err != nil {
        return nil, fmt.Errorf("fetch failed: %w", err)
    }
    defer resp.Body.Close()

    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, resp.Status)
    }
    return io.ReadAll(resp.Body)
}
```

## Async/Concurrent Best Practices

**JS/TS:**
```typescript
// GOOD: Parallel execution when possible
const [users, items, stats] = await Promise.all([
  fetchUsers(),
  fetchItems(),
  fetchStats()
])

// BAD: Sequential when unnecessary
const users = await fetchUsers()
const items = await fetchItems()
const stats = await fetchStats()
```

**Python:**
```python
# GOOD: Parallel with asyncio
users, items, stats = await asyncio.gather(
    fetch_users(),
    fetch_items(),
    fetch_stats()
)
```

**Go:**
```go
// GOOD: Parallel with goroutines and errgroup
g, ctx := errgroup.WithContext(ctx)
var users []User
var items []Item

g.Go(func() error {
    var err error
    users, err = fetchUsers(ctx)
    return err
})
g.Go(func() error {
    var err error
    items, err = fetchItems(ctx)
    return err
})
if err := g.Wait(); err != nil {
    return err
}
```

## Type Safety

Use your language's type system to catch errors at compile time or early in development.

**JS/TS:**
```typescript
interface Item {
  id: string
  name: string
  status: 'active' | 'archived' | 'deleted'
  created_at: Date
}

function getItem(id: string): Promise<Item> { /* ... */ }

// BAD: Using 'any'
function getItem(id: any): Promise<any> { /* ... */ }
```

**Python:**
```python
from dataclasses import dataclass
from enum import Enum
from datetime import datetime

class Status(Enum):
    ACTIVE = "active"
    ARCHIVED = "archived"
    DELETED = "deleted"

@dataclass(frozen=True)
class Item:
    id: str
    name: str
    status: Status
    created_at: datetime
```

**Go:**
```go
type Status string

const (
    StatusActive   Status = "active"
    StatusArchived Status = "archived"
    StatusDeleted  Status = "deleted"
)

type Item struct {
    ID        string    `json:"id"`
    Name      string    `json:"name"`
    Status    Status    `json:"status"`
    CreatedAt time.Time `json:"created_at"`
}
```

## Documentation Comments

Use your language's standard documentation format. Explain WHY, not WHAT.

**JS/TS (JSDoc):**
```typescript
/**
 * Searches items using semantic similarity.
 *
 * @param query - Natural language search query
 * @param limit - Maximum number of results (default: 10)
 * @returns Array of items sorted by similarity score
 * @throws {Error} If search service is unavailable
 */
export async function searchItems(query: string, limit: number = 10): Promise<Item[]> {
  // Implementation
}
```

**Python (docstring):**
```python
async def search_items(query: str, limit: int = 10) -> list[Item]:
    """Search items using semantic similarity.

    Args:
        query: Natural language search query.
        limit: Maximum number of results (default: 10).

    Returns:
        List of items sorted by similarity score.

    Raises:
        ConnectionError: If search service is unavailable.
    """
    # Implementation
```

**Go (godoc):**
```go
// SearchItems searches items using semantic similarity.
// It returns up to limit results sorted by similarity score.
// Returns an error if the search service is unavailable.
func SearchItems(query string, limit int) ([]Item, error) {
    // Implementation
}
```

### When to Comment

```
// GOOD: Explain WHY, not WHAT
// Use exponential backoff to avoid overwhelming the API during outages
delay = min(1000 * 2**retry_count, 30000)

// Deliberately using mutation here for performance with large arrays
items.append(new_item)

// BAD: Stating the obvious
// Increment counter by 1
count += 1
```

## Performance Best Practices

### Database Queries

```sql
-- GOOD: Select only needed columns
SELECT id, name, status FROM items WHERE status = 'active' LIMIT 10;

-- BAD: Select everything
SELECT * FROM items;
```

**ORM examples:**

| ORM/Client | Good | Bad |
|------------|------|-----|
| SQLAlchemy | `session.query(Item.id, Item.name).filter_by(status='active').limit(10)` | `session.query(Item).all()` |
| Prisma | `prisma.item.findMany({ select: { id: true, name: true }, where: { status: 'active' }, take: 10 })` | `prisma.item.findMany()` |
| GORM | `db.Select("id", "name").Where("status = ?", "active").Limit(10).Find(&items)` | `db.Find(&items)` |
