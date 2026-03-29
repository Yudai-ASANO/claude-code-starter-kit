---
name: backend-patterns
description: Backend architecture patterns, API design, database optimization, and server-side best practices for server-side applications.
---

# Backend Development Patterns

Backend architecture patterns and best practices for scalable server-side applications. Code examples use PHP; adapt patterns to your stack as needed.

**Start here:** [architecture-layers.md](references/architecture-layers.md) defines the layer model (Controller / UseCase / Repository / Entity) and dependency rules that the other references build on.

## Pattern Categories

### Architecture & API
- **Layer model, constraints, dependency direction** — [architecture-layers.md](references/architecture-layers.md)
- **RESTful structure, Repository interface, Middleware** — [api-patterns.md](references/api-patterns.md)
- **External API clients, webhook controllers** — [external-integration.md](references/external-integration.md)

### Data & Infrastructure
- **Query optimization, N+1 prevention, transactions, caching** — [database-caching.md](references/database-caching.md)
- **Error handler, retry, JWT/RBAC, rate limiting, job queues** — [error-auth-infra.md](references/error-auth-infra.md)
- **HTTP status codes, log levels, exception design** — [http-logging.md](references/http-logging.md)

## Quick Decision Guide

| Need | Pattern | Reference |
|------|---------|-----------|
| Layer responsibility / dependency rules | Clean Architecture layers | architecture-layers |
| Data access abstraction | Repository pattern | api-patterns |
| Business logic isolation | UseCase pattern | architecture-layers |
| Cross-cutting concerns (middleware) | Middleware pattern | api-patterns |
| JWT / RBAC authentication | Token validation + role check | error-auth-infra |
| HTTP status / log level selection | Status & log level guide | http-logging |
| External API integration | Lib + UseCase + Kickback | external-integration |
| Expensive DB queries | Cache-aside (Redis) | database-caching |
| N+1 query problem | Batch fetch with Map | database-caching |
| Atomic multi-table writes | Database transactions | database-caching |
| Which HTTP status to return | Status selection guide | http-logging |
| Which log level to use | Log level definitions | http-logging |
| Unreliable external APIs | Retry with exponential backoff | error-auth-infra |
| Abuse prevention | Rate limiter | error-auth-infra |
| Non-blocking operations | Job queue | error-auth-infra |

**Remember**: Choose patterns that fit your complexity level. Not every project needs every pattern.
