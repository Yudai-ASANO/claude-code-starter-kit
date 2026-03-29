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
```php
// GOOD: Select specific columns (Eloquent)
$items = DB::table('items')
    ->select('id', 'name', 'status', 'volume')
    ->where('status', 'active')
    ->orderByDesc('volume')
    ->limit(10)
    ->get();

// BAD: Select all columns
$items = DB::table('items')->get();
```

## N+1 Query Prevention

```php
// BAD: N+1 query problem
$items = Item::all();
foreach ($items as $item) {
    $item->creator = User::find($item->creator_id);  // N queries
}

// GOOD: Eager loading (Eloquent)
$items = Item::with('creator')->get();

// GOOD: Manual batch fetch — returns immutable DTOs
$items = $this->getItems();
$creatorIds = array_map(fn (Item $item) => $item->getCreatorId(), $items);
$creators = User::whereIn('id', $creatorIds)->get()->keyBy('id');
$itemsWithCreators = array_map(
    fn (Item $item) => new ItemWithCreator(
        item: $item,
        creator: $creators[$item->getCreatorId()] ?? null,
    ),
    $items,
);
```

## Transaction Pattern

Wrap multi-table writes in a transaction to ensure atomicity.

```php
function createItemWithDetails(
    CreateItemDto $itemData,
    CreateDetailDto $detailData,
): array {
    return DB::transaction(function () use ($itemData, $detailData) {
        $item = Item::create((array) $itemData);
        $detail = ItemDetail::create([
            ...(array) $detailData,
            'item_id' => $item->id,
        ]);
        return ['item' => $item, 'detail' => $detail];
    });
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

```php
class CachedItemRepository implements ItemRepository
{
    public function __construct(
        private readonly ItemRepository $baseRepo,
        private readonly CacheInterface $cache,  // Redis, Memcached, or any PSR-16 store
    ) {}

    public function findById(string $id): ?Item
    {
        $key = "item:{$id}";
        $cached = $this->cache->get($key);
        if ($cached !== null) {
            return $cached;
        }

        $item = $this->baseRepo->findById($id);
        if ($item !== null) {
            $this->cache->set($key, $item, 300);  // TTL in seconds
        }
        return $item;
    }

    public function invalidateCache(string $id): void
    {
        $this->cache->delete("item:{$id}");
    }
}
```

**Cache-aside flow:**
1. Check cache for data
2. On cache hit: return cached data
3. On cache miss: fetch from database, store in cache, return data
4. On write: invalidate relevant cache keys
