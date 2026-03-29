# iOS State Management & Navigation

## Property Wrapper Selection Guide

| Wrapper | Purpose | Status |
|---------|---------|--------|
| `@State` | View-local value type (iOS 17+: also for @Observable classes) | **Recommended** |
| `@Binding` | Read-write reference to parent's @State | **Recommended** |
| `@Bindable` | Create bindings from @Observable object | **iOS 17+ recommended** |
| `@Environment` | DI via SwiftUI environment | **Recommended** |
| `@StateObject` | Own an ObservableObject instance | **Predecessor** — prefer @Observable + @State on iOS 17+ |
| `@ObservedObject` | Reference external ObservableObject | **Predecessor** — prefer @Bindable on iOS 17+ |

## @Observable Pattern (iOS 17+)

```swift
@Observable
final class UserSettings {
    var theme: Theme = .system
    var notificationsEnabled = true
}

struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        Form {
            Picker("Theme", selection: $settings.theme) {
                ForEach(Theme.allCases, id: \.self) { Text($0.name) }
            }
            Toggle("Notifications", isOn: $settings.notificationsEnabled)
        }
    }
}

struct ParentView: View {
    @State private var settings = UserSettings()

    var body: some View {
        SettingsView(settings: settings)
    }
}
```

## Environment-Based DI

```swift
@Observable
final class AuthService {
    var currentUser: User?

    func signIn(email: String, password: String) async throws {
        // ...
    }
}

extension EnvironmentValues {
    @Entry var authService = AuthService()
}

struct ProfileView: View {
    @Environment(\.authService) private var auth

    var body: some View {
        if let user = auth.currentUser {
            Text("Hello, \(user.name)")
        }
    }
}
```

## ObservableObject Pattern (iOS 13+)

Still a current API. Prefer `@Observable` for new projects on iOS 17+, but `ObservableObject` remains valid for existing codebases and older deployment targets.

```swift
@MainActor
class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []

    func load() async {
        items = await fetchItems()
    }
}

struct ItemListView: View {
    @StateObject private var viewModel = ItemViewModel()

    var body: some View {
        List(viewModel.items) { item in
            Text(item.name)
        }
        .task { await viewModel.load() }
    }
}
```

## NavigationStack (iOS 16+)

`NavigationView` is deprecated. Use `NavigationStack` + `navigationDestination(for:)`.

```swift
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List(categories) { category in
                NavigationLink(value: category) {
                    Text(category.name)
                }
            }
            .navigationDestination(for: Category.self) { category in
                CategoryDetailView(category: category)
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }

    // Programmatic navigation / deep link
    func navigateToItem(_ item: Item) {
        path.append(item)
    }
}
```

### Key Points

- Store `NavigationPath` in model for deep link / state restoration
- Each type needs its own `navigationDestination(for:)` modifier
- Use `Hashable` conformance for navigation values

## Version Requirements

| Feature | Minimum |
|---------|---------|
| @Observable + @Bindable | iOS 17+ |
| @StateObject | iOS 14+ |
| @ObservedObject | iOS 13+ |
| NavigationStack | iOS 16+ |
| NavigationView | iOS 13+ (deprecated) |
| @Environment with @Entry | iOS 17+ |
