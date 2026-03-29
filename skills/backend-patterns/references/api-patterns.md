# API Design Patterns

## RESTful API Structure

```
GET    /api/items                 # List resources
GET    /api/items/:id             # Get single resource
POST   /api/items                 # Create resource
PUT    /api/items/:id             # Replace resource
PATCH  /api/items/:id             # Update resource
DELETE /api/items/:id             # Delete resource

// Query parameters for filtering, sorting, pagination
GET /api/items?status=active&sort=name&limit=20&offset=0
```

## Repository Pattern

```php
interface ItemRepository
{
    /** @return Item[] */
    public function findAll(?ItemFilters $filters = null): array;
    public function findById(string $id): ?Item;
    public function create(CreateItemDto $data): Item;
    public function update(string $id, UpdateItemDto $data): Item;
    public function delete(string $id): void;
}

class DatabaseItemRepository implements ItemRepository
{
    public function findAll(?ItemFilters $filters = null): array
    {
        $query = DB::table('items');
        if ($filters?->status) {
            $query->where('status', $filters->status);
        }
        if ($filters?->limit) {
            $query->limit($filters->limit);
        }

        return $query->get()->map(fn ($row) => new Item(
            $row->id, $row->name, $row->status, $row->volume,
        ))->all();
    }
}
```

Swap the concrete implementation (SQL, ORM, in-memory) without changing the interface. This is the key benefit of the Repository pattern.

## Business Logic Isolation

For isolating business logic from controllers, use the **UseCase pattern** described in [architecture-layers.md](architecture-layers.md). Each UseCase class encapsulates a single business operation and is called by the Controller.

## Middleware Pattern

Middleware wraps HTTP handlers to add cross-cutting concerns (auth, logging, validation).

```php
// Laravel-style middleware (the concept applies to any framework)
class AuthMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (!$token) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        try {
            $request->merge(['user' => $this->verifyToken($token)]);
            return $next($request);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Invalid token'], 401);
        }
    }
}
```

This pattern works similarly across frameworks: Laravel middleware, Symfony event listeners, Slim middleware, CakePHP middleware. The core idea is the same -- intercept the request, perform a check, then pass control to the next handler.
