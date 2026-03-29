# UIKit Modern Patterns

## Diffable Data Sources (iOS 13+)

Apple's recommended data source pattern. Replaces manual `reloadData()` with snapshot-based updates.

```swift
class ItemListViewController: UIViewController {
    enum Section { case main }

    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> {
            cell, indexPath, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.name
            content.secondaryText = item.description
            cell.contentConfiguration = content
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(
            collectionView: collectionView
        ) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration, for: indexPath, item: item
            )
        }
    }

    func applyItems(_ items: [Item], animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
```

### Key Points

- Items must conform to `Hashable`
- Call `apply()` from the main queue for UI updates. Background queue is allowed only with `animatingDifferences: false`
- Use `reconfigureItems()` for in-place updates without reloading

## Compositional Layout (iOS 13+)

Apple's recommended layout system. Declarative, composable, section-based.

```swift
private func configureCollectionView() {
    let layout = UICollectionViewCompositionalLayout { sectionIndex, environment in
        // List-style layout
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(60)
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: groupSize, subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 8, leading: 16, bottom: 8, trailing: 16
        )
        return section
    }

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.addSubview(collectionView)
}
```

### Grid Layout Example

```swift
func gridLayout() -> UICollectionViewCompositionalLayout {
    UICollectionViewCompositionalLayout { _, environment in
        let columns = environment.traitCollection.horizontalSizeClass == .regular ? 3 : 2

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(columns)),
            heightDimension: .fractionalWidth(1.0 / CGFloat(columns))
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(
            top: 4, leading: 4, bottom: 4, trailing: 4
        )

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize, repeatingSubitem: item, count: columns
        )

        return NSCollectionLayoutSection(group: group)
    }
}
```

## UICollectionView over UITableView

Apple is migrating toward `UICollectionView` as the universal list/grid component (iOS 14+).

- `UICollectionLayoutListConfiguration` provides table-view appearance with collection-view power
- Supports swipe actions, accessories, and section headers
- Compositional Layout + Diffable Data Sources = full modern UIKit stack

```swift
func listLayout() -> UICollectionViewCompositionalLayout {
    var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    config.trailingSwipeActionsConfigurationProvider = { indexPath in
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {
            _, _, completion in
            // handle delete
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    return UICollectionViewCompositionalLayout.list(using: config)
}
```

## Version Requirements

| Feature | Minimum |
|---------|---------|
| Diffable Data Sources | iOS 13+ |
| Compositional Layout | iOS 13+ |
| Cell Registration | iOS 14+ |
| List Configuration | iOS 14+ |
| reconfigureItems() | iOS 15+ |
