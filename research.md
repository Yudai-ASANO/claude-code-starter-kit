# Research: frontend-patterns iOS/Android 拡張

## Date: 2026-03-29

## Scope

`skills/frontend-patterns/` を React/Next.js 専用からマルチプラットフォーム（Web, iOS, Android）に拡張するにあたり、Apple/Swift.org および Google/Android の公式推奨パターンとの整合性を調査。

## Key Files

| File | Lines | 内容 |
|------|-------|------|
| `skills/frontend-patterns/SKILL.md` | 44 | スキル概要 + Quick Decision Guide |
| `references/component-patterns.md` | 92 | Composition, Compound Components, Render Props |
| `references/hooks-patterns.md` | 68 | useToggle, useQuery, useDebounce |
| `references/state-performance.md` | 126 | Context+Reducer, Memoization, Code Splitting, Virtualization |
| `references/forms-errors-a11y.md` | 161 | Controlled Form, Error Boundary, Animation, A11y |

## Architecture & Patterns (既存)

### スキル構造の規約

- **SKILL.md**: YAML frontmatter (`name`, `description`) + カテゴリ分類 + Quick Decision Guide テーブル
- **references/*.md**: H1/H2 ヘッダー、TypeScript コード例、80〜160行、実用的なコピペ可能な実装
- backend-patterns も同一構造（44行の SKILL.md + references/）

## iOS 公式ガイドライン調査結果

### 1. Swift API Design Guidelines (swift.org)

- **明確さが最優先**: point of use での明確さ > 簡潔さ
- **副作用に基づく命名**: mutating → 命令形動詞 (`sort()`), non-mutating → ed/ing (`sorted()`)
- **Bool プロパティ**: 断言文として読める (`isEmpty`, `intersects`)
- **Protocol 命名**: 「何であるか」→ 名詞 (`Collection`), 「能力」→ -able/-ible/-ing (`Equatable`)

### 2. SwiftUI アーキテクチャ — 重要な修正点

**Apple は SwiftUI で MVVM を公式推奨していない。**

- Apple のサンプルコード (Scrumdinger, Landmarks, FoodTruck) は一貫して **Model-View パターン**を使用
- `@Observable` クラスがモデル層として機能し、SwiftUI View が直接読み取る
- 別途 ViewModel 層を設ける MVVM は **コミュニティ慣習** であり Apple の推奨ではない
- Apple のガイダンス: 「SwiftUI のデータフローに逆らわず、ソースオブトゥルースを SwiftUI に管理させる」

→ **計画への影響**: MVVM をデフォルトとして提示せず、`@Observable` + View を主要パターンとして提示。MVVM はコミュニティ慣習としてトレードオフと共に記載。

### 3. プロパティラッパー選択ガイド

| ラッパー | 用途 | 公式位置づけ |
|---------|------|-------------|
| `@State` | View ローカルの値型 | 推奨（iOS 17+ では @Observable クラスにも使用可） |
| `@Binding` | 親の @State への read-write 参照 | 推奨 |
| `@Bindable` | @Observable オブジェクトからバインディング作成 | **iOS 17+ 推奨**（@ObservedObject の後継） |
| `@Environment` | SwiftUI 環境経由の DI | 推奨 |
| `@StateObject` | ObservableObject のインスタンス所有 | **レガシー**（@Observable + @State が後継） |
| `@ObservedObject` | 外部所有の ObservableObject 参照 | **レガシー**（@Bindable が後継） |

→ **計画への影響**: @Observable (iOS 17+) を主要、@ObservableObject を後方互換として明示。

### 4. NavigationStack (iOS 16+)

- `NavigationStack` + `navigationDestination(for:)` が公式推奨
- `NavigationPath` でプログラマティックなナビゲーション
- `NavigationView` は deprecated
- ナビゲーション状態はモデルオブジェクトに保存（ディープリンク・状態復元対応）

### 5. Swift Concurrency

- **構造化並行処理を優先**: async/await, TaskGroup > unstructured `Task { }`
- **@MainActor**: UI 状態を持つ @Observable クラスに付与
- **Sendable**: Swift 6 strict concurrency mode で必須。値型は暗黙的、クラスは final + immutable let のみ
- **Swift 6 への移行**: Strict Concurrency Checking を有効化し段階的に対応

### 6. UIKit パターン

- **MVC**: Apple 公式のアーキテクチャパターン。Child VC で分解が推奨
- **Coordinator**: **Apple 非公式**。コミュニティパターン（2015年〜Khanlou氏）
- **Diffable Data Sources**: Apple 推奨の UIKit データソースパターン
- **Compositional Layout**: Apple 推奨のモダンレイアウト
- **UICollectionView**: UITableView の後継として推進中（iOS 14+）

→ **計画への影響**: Coordinator を「コミュニティパターン」として明記。Apple 非公式であることを注記。

### 7. アクセシビリティ

- SwiftUI は標準コントロールに**組み込みアクセシビリティ**あり
- `.accessibilityLabel()`, `.accessibilityValue()`, `.accessibilityHint()`
- Dynamic Type は自動サポート（固定フォントサイズは避ける）
- **Apple は必須と位置づけ**: App Store レビューで拒否の可能性あり

## Android 公式ガイドライン調査結果

### 1. アーキテクチャガイド (developer.android.com)

- **3層アーキテクチャ**: UI Layer / Domain Layer (optional) / Data Layer
- **コア原則**: Separation of Concerns, SSOT, UDF
- **UI Layer**: Compose + ViewModel + StateFlow
- **Domain Layer**: **公式にオプション**。UseCase は複数 ViewModel で再利用する場合のみ
- **Data Layer**: Repository パターンは必須。1データタイプ1リポジトリ
- **DI**: **Hilt が公式推奨**。Service Locator は明確に非推奨

→ **計画への影響**: Domain Layer をオプションとして提示。Hilt をデフォルト DI として記載。

### 2. Jetpack Compose State Management

- **Stateless composable 優先**: 再利用性・テスト容易性のため
- **State hoisting**: 最も低い共通親に引き上げる
- **`remember`**: recomposition 間のみ保持
- **`rememberSaveable`**: configuration change + process death を生存
- **`derivedStateOf`**: **閾値ベースの更新のみに使用**。Google は過剰使用を明示的に警告
- **`collectAsStateWithLifecycle()`**: Flow の推奨コレクタ（`collectAsState()` ではない）
- **不変性**: mutableListOf を mutableStateOf 内で使用してはならない

→ **計画への影響**: `collectAsStateWithLifecycle()` を推奨として記載。`derivedStateOf` の過剰使用警告を含める。

### 3. Side Effects

| Effect API | 用途 |
|---|---|
| `LaunchedEffect(key)` | key 変更時に再起動する suspend 関数 |
| `rememberCoroutineScope` | イベントハンドラからのコルーチン起動 |
| `rememberUpdatedState` | 長寿命エフェクト内で最新値を参照 |
| `DisposableEffect(key)` | クリーンアップ必要なエフェクト |
| `SideEffect` | Compose → 非 Compose コードへの状態公開 |
| `produceState` | 非 Compose ソース → Compose State 変換 |

### 4. Kotlin Coroutines ベストプラクティス

- **Dispatcher 注入**: ハードコード禁止。テスト容易性のためコンストラクタパラメータとして受け取る
- **ViewModel は suspend 関数を公開しない**: StateFlow を公開し、内部で viewModelScope.launch
- **Expose immutable types**: `private _uiState: MutableStateFlow` / `val uiState: StateFlow`
- **`SharingStarted.WhileSubscribed(5_000)`**: stateIn() の標準推奨
- **CancellationException は必ず rethrow**

→ **計画への影響**: ViewModel が suspend 関数を公開しないパターンを必須として記載。Dispatcher 注入を含める。

### 5. Navigation Compose

- **型安全ナビゲーション**: `@Serializable` data class をルート定義に使用（文字列ベースはレガシー）
- **最小データ受け渡し**: ID のみ渡し、destination の ViewModel でデータロード
- **NavController を composable に直接渡さない**: ナビゲーションコールバック（ラムダ）で分離

→ **計画への影響**: 型安全ルートをデフォルトとして記載。

### 6. Material Design 3

- 3つのテーマサブシステム: `colorScheme`, `typography`, `shapes`
- Dynamic Color (Android 12+)
- Tonal elevation（影ではなくトーンカラーオーバーレイ）

### 7. アクセシビリティ (Compose)

- Compose コンポーネントは自動的にセマンティクス情報を持つ
- `Modifier.semantics(mergeDescendants = true)` でセマンティクス統合
- `clearAndSetSemantics {}` でカスタム上書き
- `LiveRegionMode.Polite` / `Assertive` で動的更新通知
- テスト: `SemanticsMatcher` で検証可能

### 8. エラー状態モデリング

Google は2つのパターンを公式サポート:
1. **Sealed class**: 画面全体の状態遷移 (`Loading | Success | Error`)
2. **Data class + userMessages**: エラーをオーバーレイ表示する場合

→ **計画への影響**: 両パターンを用途別に記載。

## 計画への重要な修正事項まとめ

### iOS — 必須修正

| # | 修正 | 理由 |
|---|------|------|
| 1 | SwiftUI のデフォルトを MVVM → **Model-View (@Observable)** に変更 | Apple 公式は MVVM を推奨していない |
| 2 | @StateObject/@ObservedObject を**レガシー**と明記 | iOS 17+ では @Observable + @Bindable が後継 |
| 3 | Coordinator を**コミュニティパターン**と明記 | Apple 非公式 |
| 4 | Swift 6 Strict Concurrency / Sendable の記載追加 | Apple が推進中の重要な変更 |
| 5 | Diffable Data Sources + Compositional Layout を UIKit の推奨パターンに | Apple 推奨のモダン UIKit |

### Android — 必須修正

| # | 修正 | 理由 |
|---|------|------|
| 1 | `collectAsStateWithLifecycle()` を推奨 | `collectAsState()` はライフサイクル非対応 |
| 2 | `derivedStateOf` の過剰使用警告を追加 | Google 公式に警告あり |
| 3 | Navigation を型安全ルート (`@Serializable`) に | 文字列ベースはレガシー |
| 4 | ViewModel は suspend 関数を公開しない | StateFlow 公開が公式パターン |
| 5 | Dispatcher 注入を必須に | テスト容易性の公式ベストプラクティス |
| 6 | Domain Layer をオプションと明記 | Google 公式にオプション |
| 7 | Hilt をデフォルト DI に | Google 公式推奨、Service Locator は非推奨 |

## Risks & Considerations

- **バージョン差異**: iOS 17+ / Swift 6 の推奨は古い OS をターゲットとする場合は適用不可。バージョン要件の明記が必須
- **MVVM の扱い**: iOS コミュニティでは MVVM が広く使われているため、否定ではなく「Apple 公式 vs コミュニティ慣習」の形で中立的に提示する必要あり
- **パターン粒度**: 既存 web リファレンスは 68〜161 行。iOS/Android も同範囲に収める

## Recommendations for Planning Phase

1. **計画の修正**: 上記修正事項を Phase 2 (iOS) / Phase 3 (Android) に反映
2. **iOS architecture-patterns.md**: MVVM ではなく @Observable Model-View を主要パターンとして提示
3. **Android state-data.md**: `collectAsStateWithLifecycle()` と Dispatcher 注入を含める
4. **バージョン注記**: 各パターンに最小 OS/API バージョンを明記するルールを追加
5. `/plan` で修正済み計画を作成してから実装に進む
