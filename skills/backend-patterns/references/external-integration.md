# External System Integration

Patterns for integrating with external APIs, payment gateways, and third-party services.

## Directory Structure

```
src/
├── Lib/
│   └── PaymentService/          # API client per external service
│       ├── PaymentAPI.php
│       └── Exception/
│           └── PaymentApiException.php
├── UseCase/
│   ├── PaymentServiceUseCase.php            # Business logic using the API client
│   └── PaymentServiceCallbackUseCase.php    # Callback processing logic
└── Controller/
    └── PaymentServiceKickbackController.php  # Webhook/callback receiver
```

**Naming convention:** `{ServiceName}` in Lib, `{ServiceName}UseCase` in UseCase, `{ServiceName}KickbackController` for webhooks.

## API Client (Lib Layer)

One function per endpoint. Document the target endpoint above each method.

```php
class PaymentAPI
{
    public function __construct(
        private readonly Client $client,
        private readonly string $apiKey,
        private readonly int $timeout = 30,
    ) {}

    /**
     * POST /api/v1/payments
     * Execute a payment transaction.
     *
     * @param Order $order Domain object — API payload mapping stays in this layer
     */
    public function createPayment(Order $order): array
    {
        $payload = [
            'order_id' => $order->getId(),
            'amount' => $order->getTotalAmount(),
            'currency' => 'JPY',
            'customer_id' => $order->getCustomerId(),
        ];

        $response = $this->client->post('/api/v1/payments', [
            'json' => $payload,
            'timeout' => $this->timeout,
            'http_errors' => false,  // Handle status codes manually
        ]);

        $status = $response->getStatusCode();
        $body = json_decode($response->getBody()->getContents(), true, 512, JSON_THROW_ON_ERROR);

        if ($status !== 200 && $status !== 201) {
            Log::error('Payment API error', [
                'status' => $status,
                'request' => $payload,
                'response' => $body,
            ]);
            throw new PaymentApiException("Unexpected status: {$status}", $status);
        }

        return $body;
    }
}
```

**Key rules:**
- Always set a timeout
- Always check status codes
- Log both request parameters and response on failure
- Load credentials from config/environment, never hardcode

## UseCase (Business Logic)

Orchestrates API calls and domain logic. The UseCase passes domain objects to the Lib layer; payload mapping stays in the API client.

```php
class PaymentServiceUseCase
{
    public function __construct(
        private readonly PaymentAPI $paymentApi,
    ) {}

    public function processOrderPayment(Order $order): array
    {
        // Pass the domain object — PaymentAPI handles field mapping
        return $this->paymentApi->createPayment($order);
    }
}
```

## Kickback (Webhook) Controller

Receives callbacks from external services. **IP restriction is mandatory.**

```php
class PaymentServiceKickbackController
{
    public function __construct(
        private readonly PaymentServiceCallbackUseCase $useCase,
        private readonly array $allowedIps,
    ) {}

    public function handlePaymentComplete(Request $request): JsonResponse
    {
        // IP restriction
        if (!in_array($request->ip(), $this->allowedIps, true)) {
            Log::warning('Unauthorized callback attempt', [
                'ip' => $request->ip(),
            ]);
            return response()->json(['error' => 'Unauthorized'], 403);
        }

        try {
            $this->useCase->processPaymentCallback($request->all());
            return response()->json(['status' => 'success']);
        } catch (\Throwable $e) {
            Log::error('Callback processing error', [
                'message' => $e->getMessage(),
                'payload' => $request->all(),
            ]);
            return response()->json(['error' => 'Processing failed'], 500);
        }
    }
}
```

## Integration Checklist

- [ ] Timeout configured for all external calls
- [ ] Status code validation on every response
- [ ] Error logging includes request params and response body
- [ ] Credentials loaded from environment/config
- [ ] IP restriction on webhook endpoints
- [ ] API version documented (link to external docs in README)
- [ ] Retry logic for transient failures (see [error-auth-infra.md](error-auth-infra.md))
