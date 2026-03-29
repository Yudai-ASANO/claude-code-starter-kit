# iOS Concurrency & Lifecycle

## Swift Concurrency

### Structured Concurrency (Preferred)

Prefer `async/await` and `TaskGroup` over unstructured `Task { }`.

```swift
@Observable
@MainActor
final class SearchModel {
    var results: [Item] = []
    var isLoading = false

    func search(query: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            results = try await api.search(query: query)
        } catch {
            results = []
        }
    }
}
```

### Parallel Execution with async let

```swift
func loadDashboard() async throws -> Dashboard {
    async let profile = api.fetchProfile()
    async let notifications = api.fetchNotifications()
    async let stats = api.fetchStats()

    return Dashboard(
        profile: try await profile,
        notifications: try await notifications,
        stats: try await stats
    )
}
```

### @MainActor

Annotate `@Observable` classes that hold UI state with `@MainActor`. This ensures all property mutations happen on the main thread.

```swift
@Observable
@MainActor
final class CartModel {
    var items: [CartItem] = []
    var total: Decimal { items.reduce(0) { $0 + $1.price } }

    func addItem(_ item: CartItem) {
        items.append(item)
    }

    func checkout() async throws {
        let order = try await api.createOrder(items: items)
        items = []
    }
}
```

## Swift 6 Strict Concurrency

Swift 6 enforces data-race safety at compile time. Prepare incrementally.

### Sendable

- **Value types** (struct, enum): implicitly Sendable if all stored properties are Sendable
- **Classes**: must be `final` with only immutable `let` properties, or use `@unchecked Sendable` with manual synchronization
- **Functions/closures**: `@Sendable` attribute required when crossing isolation boundaries

```swift
// Value type: implicitly Sendable
struct UserID: Sendable {
    let rawValue: UUID
}

// Reference type: explicit conformance
final class APIConfig: Sendable {
    let baseURL: URL
    let apiKey: String

    init(baseURL: URL, apiKey: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
}
```

### Migration Strategy

1. Enable `SWIFT_STRICT_CONCURRENCY=complete` in build settings
2. Fix warnings module by module (start with leaf modules)
3. Use `@MainActor` for UI-bound types
4. Use `nonisolated` for methods that don't need actor isolation

## View Lifecycle

### .task Modifier

Preferred over `.onAppear` for async work. Automatically cancelled when view disappears.

```swift
struct ItemListView: View {
    @State private var model = ItemListModel()

    var body: some View {
        List(model.items) { item in
            ItemRow(item: item)
        }
        .task {
            await model.loadItems()
        }
        .task(id: model.searchQuery) {
            await model.search()
        }
        .refreshable {
            await model.loadItems()
        }
    }
}
```

### Key Points

- `.task` is tied to view lifetime — cancels on disappear
- `.task(id:)` re-runs when `id` changes, cancelling the previous task (not a debounce — add `Task.sleep` if delay is needed)
- `.refreshable` provides pull-to-refresh with async support
- Avoid `Task { }` inside `.onAppear` — no automatic cancellation

## Error Handling Pattern

```swift
@Observable
@MainActor
final class DataModel {
    var items: [Item] = []
    var error: AppError?
    var isLoading = false

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            items = try await api.fetchItems()
        } catch is CancellationError {
            // View disappeared — do nothing
        } catch {
            self.error = AppError(underlying: error)
        }
    }
}
```

## Version Requirements

| Feature | Minimum |
|---------|---------|
| async/await | iOS 15+ (Swift 5.5) |
| .task modifier | iOS 15+ |
| Strict Concurrency | Swift 6.0 |
| @MainActor | iOS 15+ (Swift 5.5) |
