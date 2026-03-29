---
name: coding-standards
description: Universal coding standards, best practices, and patterns for software development across any technology stack.
---

# Coding Standards & Best Practices

Universal coding standards applicable across all projects. Detailed patterns and examples are in the `references/` directory.

## Quick Decision Guide

| What you need | Reference file |
|---|---|
| Naming, immutability, types, error handling, async | `references/language-patterns.md` |
| Components, reusable logic, state, memoization, lazy loading | `references/ui-framework-patterns.md` |
| REST API design, file structure, testing, code smells | `references/api-testing-patterns.md` |

## Categories

### Language Patterns
Variable and function naming conventions, immutability (critical), comprehensive error handling, async/concurrent best practices, type safety, comments/documentation style, and database query performance.

See: `references/language-patterns.md`

### UI Framework Patterns
Component structure with typed props, reusable logic extraction (hooks, composables, etc.), proper state updates, conditional rendering, memoization, and lazy loading.

See: `references/ui-framework-patterns.md`

### API Design, Testing & Code Smells
REST conventions, consistent ApiResponse format, schema validation (using project's validation library), project file organization and naming, AAA test pattern, descriptive test naming, and anti-pattern detection (long functions, deep nesting, magic numbers).

See: `references/api-testing-patterns.md`

## Core Principles

1. **Readability First** -- self-documenting code over comments
2. **KISS** -- simplest solution that works
3. **DRY** -- extract and reuse common logic
4. **YAGNI** -- build only what is needed now
5. **Immutability** -- never mutate; create new instances
