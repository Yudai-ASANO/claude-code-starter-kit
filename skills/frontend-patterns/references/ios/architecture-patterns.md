# iOS Architecture Patterns

## SwiftUI: Model-View with @Observable (iOS 17+)

Apple's recommended pattern. The `@Observable` class serves as the model layer; SwiftUI Views read it directly.

```swift
import SwiftUI

@Observable
final class CounterModel {
    var count = 0

    func increment() {
        count += 1
    }
}

struct CounterView: View {
    @State private var model = CounterModel()

    var body: some View {
        VStack {
            Text("Count: \(model.count)")
            Button("Increment") {
                model.increment()
            }
        }
    }
}
```

### Key Points

- `@Observable` provides fine-grained tracking (per-property, not per-object)
- View owns model via `@State`; child views receive via parameter or `@Environment`
- No separate ViewModel layer needed — SwiftUI's data flow handles reactivity

### MVVM (Community Convention)

MVVM is widely used in the iOS community. Apple does not explicitly endorse or discourage MVVM, but their sample apps (Scrumdinger, Landmarks, FoodTruck) consistently use the Model-View pattern with `@Observable`.

**Trade-offs:**
- Pro: Familiar to developers from UIKit background, explicit separation of presentation logic
- Con: Extra indirection layer, fights SwiftUI's built-in data flow, duplicates what `@Observable` already provides

Use MVVM when your team has an established convention. For new projects, prefer Model-View.

## UIKit: MVC (Apple Official)

Apple's official architecture for UIKit. Break down massive VCs with Child View Controllers.

```swift
class ParentViewController: UIViewController {
    private let headerVC = HeaderViewController()
    private let listVC = ItemListViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(headerVC)
        view.addSubview(headerVC.view)
        headerVC.didMove(toParent: self)

        addChild(listVC)
        view.addSubview(listVC.view)
        listVC.didMove(toParent: self)
    }
}
```

### Coordinator (Community Pattern)

Coordinator is a **community pattern** (Khanlou, 2015), not Apple-endorsed. It extracts navigation logic from VCs.

```swift
protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = HomeViewController()
        vc.delegate = self
        navigationController.pushViewController(vc, animated: false)
    }
}
```

**Note:** Apple's official guidance uses delegation and segues for navigation. Coordinator adds testability but increases boilerplate.

## Accessibility

- SwiftUI standard controls have **built-in accessibility**
- Use `.accessibilityLabel()`, `.accessibilityValue()`, `.accessibilityHint()`
- Dynamic Type is automatic — avoid fixed font sizes
- Apple treats accessibility as mandatory (App Store review may reject non-compliant apps)

## Version Requirements

| Pattern | Minimum |
|---------|---------|
| @Observable Model-View | iOS 17+ |
| @ObservableObject MVVM | iOS 13+ |
| Child VC composition | iOS 5+ |
| Coordinator | iOS 8+ (community) |
