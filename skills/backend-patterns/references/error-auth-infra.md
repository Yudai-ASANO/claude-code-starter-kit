# Auth, Retry, Rate Limiting, Jobs & Logging

For centralized error handling, HTTP status codes, and log level definitions, see [http-logging.md](http-logging.md).

## Retry with Exponential Backoff

```php
/**
 * @template T
 * @param callable(): T $fn
 * @return T
 */
function fetchWithRetry(callable $fn, int $maxRetries = 3): mixed
{
    if ($maxRetries < 1) {
        throw new \InvalidArgumentException('maxRetries must be >= 1');
    }

    $lastError = null;
    for ($i = 0; $i < $maxRetries; $i++) {
        try {
            return $fn();
        } catch (\Throwable $e) {
            $lastError = $e;
            if ($i < $maxRetries - 1) {
                usleep((int) (pow(2, $i) * 1_000_000));  // seconds
            }
        }
    }
    throw $lastError;
}
```

## JWT Token Validation & RBAC

```php
function verifyToken(string $token): array
{
    try {
        return (array) JWT::decode($token, new Key(env('JWT_SECRET'), 'HS256'));
    } catch (\Exception $e) {
        throw new ApiError(401, 'Invalid token');
    }
}

const ROLE_PERMISSIONS = [
    'admin'     => ['read', 'write', 'delete', 'admin'],
    'moderator' => ['read', 'write', 'delete'],
    'user'      => ['read', 'write'],
];

function hasPermission(User $user, string $permission): bool
{
    $permissions = ROLE_PERMISSIONS[$user->role] ?? [];
    return in_array($permission, $permissions, true);
}
```

**Note:** Always load secrets from environment variables or a secrets manager. Never hardcode tokens, keys, or passwords.

## Simple Rate Limiter

```php
class RateLimiter
{
    /** @var array<string, int[]> */
    private array $requests = [];

    public function checkLimit(string $identifier, int $maxRequests, int $windowMs): bool
    {
        $now = (int) (microtime(true) * 1000);
        $existing = $this->requests[$identifier] ?? [];
        $recent = array_filter($existing, fn (int $time) => $now - $time < $windowMs);

        if (count($recent) >= $maxRequests) {
            return false;
        }

        $recent[] = $now;
        $this->requests[$identifier] = array_values($recent);
        return true;
    }
}
```

For production, use a distributed rate limiter backed by a cache store (e.g., Redis) to work across multiple server instances. Laravel provides `RateLimiter` facade out of the box.

## Background Job Queue

```php
// Laravel queue job (the concept applies to any queue system)
class ProcessItemJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private readonly Item $item,
    ) {}

    public function handle(): void
    {
        // Process the item
    }

    public function failed(\Throwable $e): void
    {
        Log::error('Job failed', ['item_id' => $this->item->id, 'error' => $e->getMessage()]);
    }
}

// Dispatch
ProcessItemJob::dispatch($item);
```

## Structured Logging

```php
class StructuredLogger
{
    public function log(string $level, string $message, array $context = []): void
    {
        Log::channel('stderr')->log($level, $message, [
            'timestamp' => now()->toISOString(),
            ...$context,
        ]);
    }

    public function info(string $message, array $context = []): void
    {
        $this->log('info', $message, $context);
    }

    public function warn(string $message, array $context = []): void
    {
        $this->log('warning', $message, $context);
    }

    public function error(string $message, \Throwable $e, array $context = []): void
    {
        $this->log('error', $message, [
            ...$context,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
        ]);
    }
}
```
