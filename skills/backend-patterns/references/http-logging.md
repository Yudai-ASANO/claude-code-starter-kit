# HTTP Status Codes & Logging

## HTTP Status Selection Guide

| Status | When | User Message | Log Level |
|--------|------|-------------|-----------|
| **400** Bad Request | Invalid parameters, malformed input | "Invalid input" | INFO |
| **401** Unauthorized | Missing or invalid auth token | "Authentication required" | NOTICE |
| **403** Forbidden | Authenticated but insufficient permissions | "Permission denied" | NOTICE |
| **404** Not Found | Resource does not exist | "Not found" | NOTICE |
| **422** Unprocessable | Valid syntax but semantic errors | "Validation failed" | INFO |
| **426** Upgrade Required | Client version too old | "Update required" | INFO |
| **500** Internal Error | Unexpected exception, system failure | "Server error, try later" | ERROR |
| **503** Unavailable | Maintenance, external service down | "Service unavailable" | ERROR |

**Rule of thumb:** 4xx = client's fault (INFO/NOTICE), 5xx = server's fault (ERROR).

## Log Level Definitions

| Level | Purpose | Example |
|-------|---------|---------|
| **DEBUG** | Detailed diagnostic info, dev only | Variable dumps, query parameters |
| **INFO** | Normal operation events | "Request processed", validation failures |
| **NOTICE** | Notable but normal events | Auth failures, missing resources |
| **WARNING** | Potential problems, not yet errors | Deprecated API usage, slow queries |
| **ERROR** | Errors affecting service | Uncaught exceptions, DB connection failures |

## Exception with HTTP Status

Embed the HTTP status and log level in domain exceptions to keep Controller logic thin.

```php
interface HttpExceptionInterface
{
    public function getStatusCode(): int;
    public function getLogLevel(): string;
}

abstract class HttpException extends \RuntimeException implements HttpExceptionInterface
{
    public function __construct(
        string $message,
        private readonly int $statusCode = 500,
        private readonly string $logLevel = 'error',
        int $code = 0,
        ?\Throwable $previous = null,
    ) {
        parent::__construct($message, $code, $previous);
    }

    public function getStatusCode(): int { return $this->statusCode; }
    public function getLogLevel(): string { return $this->logLevel; }
}

class NotFoundException extends HttpException
{
    public function __construct(string $message = 'Not found', ?\Throwable $previous = null)
    {
        parent::__construct($message, 404, 'notice', 0, $previous);
    }
}

class ForbiddenException extends HttpException
{
    public function __construct(string $message = 'Forbidden', ?\Throwable $previous = null)
    {
        parent::__construct($message, 403, 'notice', 0, $previous);
    }
}
```

## Centralized Exception Handler

Use the exception's own status and log level for automatic dispatch.

```php
class ApiExceptionHandler
{
    public function handle(\Throwable $e, Request $request): JsonResponse
    {
        if ($e instanceof HttpExceptionInterface) {
            Log::log($e->getLogLevel(), $e->getMessage(), [
                'status' => $e->getStatusCode(),
                'url' => $request->getPathInfo(),
            ]);

            return response()->json(
                ['success' => false, 'error' => $e->getMessage()],
                $e->getStatusCode(),
            );
        }

        // Unexpected errors: always ERROR level, always 500
        Log::error('Unexpected error', [
            'message' => $e->getMessage(),
            'trace' => $e->getTraceAsString(),
            'url' => $request->getPathInfo(),
        ]);

        return response()->json(
            ['success' => false, 'error' => 'Internal server error'],
            500,
        );
    }
}
```

For error handling patterns (retry, RBAC, rate limiting), see [error-auth-infra.md](error-auth-infra.md).
