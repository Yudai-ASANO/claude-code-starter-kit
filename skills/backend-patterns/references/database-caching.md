# Database & Caching Patterns

## Query Optimization

```sql
-- GOOD: Select only needed columns
SELECT id, name, status, volume
FROM items
WHERE status = 'active'
ORDER BY volume DESC
LIMIT 10;

-- BAD: Select everything
SELECT * FROM items;
```

**ORM equivalent:**
```typescript
// GOOD: Select specific columns
const items = await db.select('id', 'name', 'status', 'volume')
  .from('items')
  .where('status', 'active')
  .orderBy('volume', 'desc')
  .limit(10)

// BAD: Select all columns
const items = await db.select('*').from('items')
```

## N+1 Query Prevention

```typescript
// BAD: N+1 query problem
const items = await getItems()
for (const item of items) {
  item.creator = await getUser(item.creator_id)  // N queries
}

// GOOD: Batch fetch
const items = await getItems()
const creatorIds = items.map(m => m.creator_id)
const creators = await getUsers(creatorIds)  // 1 query
const creatorMap = new Map(creators.map(c => [c.id, c]))
items.forEach(item => {
  item.creator = creatorMap.get(item.creator_id)
})
```

## Transaction Pattern

Wrap multi-table writes in a transaction to ensure atomicity.

```typescript
// Generic transaction pattern
async function createItemWithDetails(
  itemData: CreateItemDto,
  detailData: CreateDetailDto
) {
  return await db.transaction(async (trx) => {
    const item = await trx.insert(itemData).into('items').returning('*')
    const detail = await trx.insert({
      ...detailData,
      item_id: item.id
    }).into('item_details').returning('*')
    return { item, detail }
  })
}
```

```sql
-- Raw SQL equivalent
BEGIN;
  INSERT INTO items (...) VALUES (...) RETURNING *;
  INSERT INTO item_details (...) VALUES (...) RETURNING *;
COMMIT;
```

## Caching Layer (Cache-Aside Pattern)

```typescript
class CachedItemRepository implements ItemRepository {
  constructor(
    private baseRepo: ItemRepository,
    private cache: CacheClient  // Redis, Memcached, or any key-value store
  ) {}

  async findById(id: string): Promise<Item | null> {
    const cached = await this.cache.get(`item:${id}`)
    if (cached) return JSON.parse(cached)

    const item = await this.baseRepo.findById(id)
    if (item) {
      await this.cache.set(`item:${id}`, JSON.stringify(item), { ttl: 300 })
    }
    return item
  }

  async invalidateCache(id: string): Promise<void> {
    await this.cache.del(`item:${id}`)
  }
}
```

**Cache-aside flow:**
1. Check cache for data
2. On cache hit: return cached data
3. On cache miss: fetch from database, store in cache, return data
4. On write: invalidate relevant cache keys
