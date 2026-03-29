# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate:

| Language | Immutable pattern |
|----------|-------------------|
| JS/TS | `{ ...user, name: 'New' }` (spread operator) |
| Python | `{**user, 'name': 'New'}` or `dataclasses.replace(user, name='New')` |
| Swift | `let` by default; use structs with value semantics |
| Kotlin | `data class` + `copy(name = "New")` |
| Go | Create new struct: `User{...old, Name: "New"}` |
| PHP | `clone` + modify on new instance, or use immutable value objects |

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively. Use the language's idiomatic error pattern:

| Language | Pattern |
|----------|---------|
| JS/TS | `try/catch` + typed errors |
| Python | `try/except` with specific exception types |
| Go | `if err != nil { return fmt.Errorf("context: %w", err) }` |
| Swift | `do/catch` + `throws` |
| Kotlin | `try/catch` or `Result<T>` |
| PHP | `try/catch` with specific exception classes |

## Input Validation

ALWAYS validate user input. Use the project's validation library:

| Language | Libraries |
|----------|-----------|
| JS/TS | Zod, Joi, class-validator |
| Python | Pydantic, marshmallow, cerberus |
| Swift | Custom validation or Combine validators |
| Kotlin | Bean Validation (JSR 380), konform |
| PHP | Laravel Validation, Symfony Validator |
| Go | go-playground/validator |

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No debug logging statements left in
- [ ] No hardcoded values
- [ ] No mutation (immutable patterns used)
