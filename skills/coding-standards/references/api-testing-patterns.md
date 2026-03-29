# API Design, File Organization, Testing & Code Smells

## REST API Conventions

```
GET    /api/items              # List all items
GET    /api/items/:id          # Get specific item
POST   /api/items              # Create new item
PUT    /api/items/:id          # Update item (full)
PATCH  /api/items/:id          # Update item (partial)
DELETE /api/items/:id          # Delete item

# Query parameters for filtering
GET /api/items?status=active&limit=10&offset=0
```

## Response Format

```
// Consistent response structure
{
  "success": true,
  "data": { ... },
  "meta": { "total": 100, "page": 1, "limit": 10 }
}

// Error response
{
  "success": false,
  "error": "Invalid request"
}
```

Return appropriate HTTP status codes: 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), 500 (Internal Server Error).

## Input Validation

Use your project's schema validation library to validate all incoming data before processing.

```
// Pseudocode: Define a schema, parse input, handle validation errors

schema = {
  name: string, min 1, max 200,
  description: string, min 1, max 2000,
  endDate: datetime string,
  categories: array of strings, min 1
}

validated = schema.parse(requestBody)

if validation fails:
  return HTTP 400 { success: false, error: "Validation failed", details: errors }
```

**Examples by language:**
| Language | Library | Pattern |
|----------|---------|---------|
| TypeScript | Zod | `const validated = schema.parse(body)` |
| Python | Pydantic | `validated = MyModel(**body)` |
| Go | go-playground/validator | `err := validate.Struct(input)` |

## File Organization

### Project Structure (Generic)

```
project/
├── src/                       # Application source code
│   ├── handlers/              # HTTP handlers / route controllers
│   ├── services/              # Business logic layer
│   ├── repositories/          # Data access layer
│   ├── models/                # Data models / types
│   ├── middleware/             # HTTP middleware
│   ├── utils/                 # Helper functions
│   └── config/                # Configuration
├── tests/
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   └── e2e/                   # End-to-end tests
├── docs/                      # Documentation
└── scripts/                   # Build and utility scripts
```

### File Naming

Follow the conventions of your language and framework:
- **JS/TS**: `camelCase.ts` for utilities, `PascalCase.tsx` for components
- **Python**: `snake_case.py` for all modules
- **Go**: `snake_case.go` for all files
- **General**: Group by feature/domain, not by file type

## Testing Standards

### Test Structure (AAA Pattern)

```
test('calculates similarity correctly') {
  // Arrange
  vector1 = [1, 0, 0]
  vector2 = [0, 1, 0]

  // Act
  similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect similarity == 0
}
```

### Test Naming

```
// GOOD: Descriptive test names
test('returns empty array when no items match query')
test('throws error when API key is missing')
test('falls back to substring search when cache unavailable')

// BAD: Vague test names
test('works')
test('test search')
```

## Code Smell Detection

Watch for these anti-patterns:

### 1. Long Functions
```
// BAD: Function > 50 lines
function processData() {
  // 100 lines of code
}

// GOOD: Split into smaller functions
function processData() {
  validated = validateData()
  transformed = transformData(validated)
  return saveData(transformed)
}
```

### 2. Deep Nesting
```
// BAD: 5+ levels of nesting
if (user) {
  if (user.isAdmin) {
    if (item) {
      if (item.isActive) {
        if (hasPermission) {
          // Do something
        }
      }
    }
  }
}

// GOOD: Early returns
if (!user) return
if (!user.isAdmin) return
if (!item) return
if (!item.isActive) return
if (!hasPermission) return

// Do something
```

### 3. Magic Numbers
```
// BAD: Unexplained numbers
if (retryCount > 3) { }
setTimeout(callback, 500)

// GOOD: Named constants
MAX_RETRIES = 3
DEBOUNCE_DELAY_MS = 500

if (retryCount > MAX_RETRIES) { }
setTimeout(callback, DEBOUNCE_DELAY_MS)
```

**Remember**: Code quality is not negotiable. Clear, maintainable code enables rapid development and confident refactoring.
