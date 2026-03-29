---
name: frontend-patterns
description: Frontend development patterns for Web (React/Next.js), iOS (SwiftUI/UIKit), and Android (Jetpack Compose) — state management, navigation, architecture, and UI best practices.
---

# Frontend Development Patterns

Modern frontend patterns for Web, iOS, and Android platforms.

## Web (React / Next.js)

### Component Patterns
Composition over inheritance, compound components, render props.
See [references/web/component-patterns.md](references/web/component-patterns.md).

### Custom Hooks
Reusable hooks: useToggle, useQuery, useDebounce.
See [references/web/hooks-patterns.md](references/web/hooks-patterns.md).

### State Management & Performance
Context + Reducer, memoization, code splitting, virtualization.
See [references/web/state-performance.md](references/web/state-performance.md).

### Forms, Errors, Animation & Accessibility
Controlled forms, ErrorBoundary, Framer Motion, ARIA, focus management.
See [references/web/forms-errors-a11y.md](references/web/forms-errors-a11y.md).

## iOS (SwiftUI / UIKit)

### Architecture
@Observable Model-View (Apple's sample pattern), MVVM (community convention), UIKit MVC, Coordinator (community).
See [references/ios/architecture-patterns.md](references/ios/architecture-patterns.md).

### State & Navigation
Property wrappers (@State, @Binding, @Bindable), NavigationStack.
See [references/ios/state-navigation.md](references/ios/state-navigation.md).

### Concurrency & Lifecycle
Swift Concurrency (async/await), @MainActor, Swift 6 Sendable, .task modifier.
See [references/ios/concurrency-lifecycle.md](references/ios/concurrency-lifecycle.md).

### UIKit Modern Patterns
Diffable Data Sources, Compositional Layout, UICollectionView.
See [references/ios/uikit-patterns.md](references/ios/uikit-patterns.md).

## Android (Jetpack Compose)

### Architecture & DI
3-layer architecture, Hilt DI, Repository pattern, Domain Layer (optional).
See [references/android/architecture-di.md](references/android/architecture-di.md).

### State & Side Effects
Compose state, collectAsStateWithLifecycle(), Side Effects decision table.
See [references/android/state-effects.md](references/android/state-effects.md).

### Navigation & Theming
Type-safe navigation (@Serializable routes), Material Design 3, accessibility.
See [references/android/navigation-theming.md](references/android/navigation-theming.md).

### ViewModel & Coroutines
StateFlow exposure, Dispatcher injection, structured concurrency, testing.
See [references/android/viewmodel-coroutines.md](references/android/viewmodel-coroutines.md).

## Quick Decision Guide

| Need | Platform | Pattern | Reference |
|------|----------|---------|-----------|
| Shared state across siblings | Web | Context + Reducer | web/state-performance |
| Expensive computation | Web | `useMemo` | web/state-performance |
| Large list rendering | Web | Virtualization | web/state-performance |
| Form validation | Web | Controlled form + error state | web/forms-errors-a11y |
| SwiftUI architecture | iOS | @Observable Model-View / MVVM | ios/architecture-patterns |
| View-local state | iOS | @State | ios/state-navigation |
| Programmatic navigation | iOS | NavigationStack + NavigationPath | ios/state-navigation |
| Async data loading | iOS | .task + Swift Concurrency | ios/concurrency-lifecycle |
| Modern UIKit list/grid | iOS | Diffable Data Sources + Compositional Layout | ios/uikit-patterns |
| Screen state modeling | Android | Sealed interface (Loading/Success/Error) | android/architecture-di |
| Collect Flow in Compose | Android | `collectAsStateWithLifecycle()` | android/state-effects |
| Side effect in Compose | Android | LaunchedEffect / DisposableEffect | android/state-effects |
| Screen-to-screen navigation | Android | Type-safe routes (@Serializable) | android/navigation-theming |
| ViewModel coroutines | Android | StateFlow + Dispatcher injection | android/viewmodel-coroutines |

**Remember**: Choose patterns that fit your project complexity. Not every project needs every pattern.
