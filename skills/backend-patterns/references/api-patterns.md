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

```typescript
interface ItemRepository {
  findAll(filters?: ItemFilters): Promise<Item[]>
  findById(id: string): Promise<Item | null>
  create(data: CreateItemDto): Promise<Item>
  update(id: string, data: UpdateItemDto): Promise<Item>
  delete(id: string): Promise<void>
}

class DatabaseItemRepository implements ItemRepository {
  async findAll(filters?: ItemFilters): Promise<Item[]> {
    let query = db.select('*').from('items')
    if (filters?.status) query = query.where('status', filters.status)
    if (filters?.limit) query = query.limit(filters.limit)
    const results = await query
    return results
  }
}
```

Swap the concrete implementation (SQL, ORM, in-memory) without changing the interface. This is the key benefit of the Repository pattern.

## Service Layer Pattern

```typescript
class ItemService {
  constructor(private itemRepo: ItemRepository) {}

  async searchItems(query: string, limit: number = 10): Promise<Item[]> {
    const embedding = await generateEmbedding(query)
    const results = await this.vectorSearch(embedding, limit)
    const items = await this.itemRepo.findByIds(results.map(r => r.id))
    return items.sort((a, b) => {
      const scoreA = results.find(r => r.id === a.id)?.score || 0
      const scoreB = results.find(r => r.id === b.id)?.score || 0
      return scoreA - scoreB
    })
  }
}
```

## Middleware Pattern

Middleware wraps HTTP handlers to add cross-cutting concerns (auth, logging, validation).

```typescript
// Generic HTTP middleware (framework-agnostic concept)
function withAuth(handler: RequestHandler): RequestHandler {
  return async (req, res) => {
    const token = req.headers.authorization?.replace('Bearer ', '')
    if (!token) return res.status(401).json({ error: 'Unauthorized' })
    try {
      req.user = await verifyToken(token)
      return handler(req, res)
    } catch (error) {
      return res.status(401).json({ error: 'Invalid token' })
    }
  }
}
```

This pattern works similarly across frameworks: Express middleware, Gin handlers, FastAPI dependencies, Django middleware classes. The core idea is the same -- intercept the request, perform a check, then pass control to the next handler.
