# Common Patterns

## API Response Format

Use a consistent response envelope for all API endpoints:

```
{
  "success": true/false,
  "data": <payload>,           // present on success
  "error": "<message>",        // present on failure
  "meta": {                    // optional pagination
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

Adapt to your language's type system (TypeScript interface, Python dataclass, Go struct, Kotlin data class, PHP array/DTO, etc.).

## Debounce / Throttle Pattern

Encapsulate reusable timing logic in a dedicated utility or hook:
- **Web (React)**: Custom hook `useDebounce(value, delay)`
- **Web (Vue)**: Composable `useDebounce(value, delay)`
- **iOS (Swift)**: Combine `debounce(for:scheduler:)` or async `Task.sleep`
- **Android (Kotlin)**: Flow `debounce(timeoutMillis)` or coroutine delay
- **Backend**: Utility function with timer/scheduler

## Repository Pattern

Abstract data access behind a repository interface:

```
Repository<T>:
  findAll(filters?) → T[]
  findById(id) → T | null
  create(data) → T
  update(id, data) → T
  delete(id) → void
```

Implement with your ORM/database client. This pattern is universal across languages and frameworks.

## Skeleton Projects

When implementing new functionality:
1. Search for battle-tested skeleton projects
2. Use parallel agents to evaluate options:
   - Security assessment
   - Extensibility analysis
   - Relevance scoring
   - Implementation planning
3. Clone best match as foundation
4. Iterate within proven structure
