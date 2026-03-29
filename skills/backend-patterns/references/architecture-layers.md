# Architecture Layers (Clean Architecture)

Separate code by responsibility. Dependencies always point inward: Controller -> UseCase -> Repository -> Entity.

## Layer Overview

| Layer | Responsibility | Depends On | Must Not |
|-------|---------------|------------|----------|
| **Controller** | HTTP request/response, parameter extraction | UseCase | Contain business logic, call Repository directly |
| **UseCase** | Business logic, validation, orchestration | Repository, Entity | Execute raw SQL (except BEGIN/COMMIT/ROLLBACK) |
| **Repository** | Data persistence and retrieval | Entity, DB | Call UseCase, contain business rules |
| **Entity** | Domain objects, business rules | Nothing | Depend on Repository, UseCase, or external services |

Supporting layers: **Renderer** (view transformation), **Enum** (fixed value sets), **Lib** (shared utilities, external service clients), **Exception** (domain-specific errors).

## Controller

Receives HTTP requests, delegates to UseCase, returns responses. Method names match HTTP verbs.

```php
class UserController
{
    public function __construct(
        private readonly CreateUserUseCase $createUserUseCase,
    ) {}

    public function post(Request $request): JsonResponse
    {
        try {
            $user = $this->createUserUseCase->execute(
                $request->get('name'),
                $request->get('email'),
                $request->get('password'),
            );

            return new JsonResponse([
                'id' => $user->getId(),
                'name' => $user->getName(),
                'email' => $user->getEmail(),
            ], 201);
        } catch (InvalidArgumentException $e) {
            return new JsonResponse(['error' => $e->getMessage()], 400);
        } catch (DomainException $e) {
            return new JsonResponse(['error' => $e->getMessage()], 409);
        }
    }
}
```

## UseCase

One class per business operation. Single responsibility. Owns the transaction boundary.

```php
class CreateUserUseCase
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly EmailService $emailService,
    ) {}

    public function execute(string $name, string $email, string $password): User
    {
        if (empty($name) || empty($email) || empty($password)) {
            throw new InvalidArgumentException('Required fields missing');
        }

        if ($this->userRepository->existsByEmail($email)) {
            throw new DomainException('Email already registered');
        }

        $hashed = password_hash($password, PASSWORD_DEFAULT);
        $user = new User(0, $name, $email);
        $saved = $this->userRepository->save($user, $hashed);

        $this->emailService->sendWelcomeEmail($saved);

        return $saved;
    }
}
```

## Repository

Interface in domain layer, implementation in infrastructure. Returns Entity objects, never raw arrays.

```php
// Domain layer
interface UserRepository
{
    public function findById(int $id): ?User;
    public function findByEmail(string $email): ?User;
    public function existsByEmail(string $email): bool;
    public function save(User $user, string $hashedPassword): User;
    public function delete(int $id): bool;
}

// Infrastructure layer
class DatabaseUserRepository implements UserRepository
{
    public function __construct(private readonly PDO $db) {}

    public function findById(int $id): ?User
    {
        $stmt = $this->db->prepare('SELECT id, name, email FROM users WHERE id = :id');
        $stmt->execute(['id' => $id]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        return $row ? new User($row['id'], $row['name'], $row['email']) : null;
    }
}
```

Method naming: `findBy*` (search), `existsBy*` (check), `save`, `update`, `delete`, `findAll`. See [api-patterns.md](api-patterns.md) for the generic Repository interface.

## Entity

Immutable domain objects. Contain business rules but no external dependencies.

```php
class Order
{
    public function __construct(
        private readonly int $id,
        private readonly array $items,
        private readonly string $status,
        private readonly DateTimeImmutable $createdAt,
    ) {}

    public function calculateTotal(): float
    {
        return array_reduce($this->items, fn (float $total, OrderItem $item) =>
            $total + $item->getSubtotal(), 0.0);
    }

    public function canBeCancelled(): bool
    {
        return !in_array($this->status, ['shipped', 'delivered'], true);
    }
}
```

## Key Constraints

- **No SQL in Controller** -- delegate to UseCase, which calls Repository
- **No SELECT inside transactions** -- fetch data before BEGIN, write inside
- **No long operations inside transactions** -- HTTP requests, image processing, etc. must happen outside
- **Entity is readonly** -- use constructor promotion with `readonly` properties
- **Response-after-work** -- non-essential processing (logging to DB, analytics) should run after sending the response

Based on Clean Architecture principles. For team-specific refinements (naming suffixes, directory structure), see your project-level rules.
