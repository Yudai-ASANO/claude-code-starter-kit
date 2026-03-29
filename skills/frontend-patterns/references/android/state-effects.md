# Android Compose State & Side Effects

## State Management

### Stateless Composables (Preferred)

Prefer stateless composables for reusability and testability. Hoist state to the caller.

```kotlin
// Stateless: receives state, emits events
@Composable
fun SearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    onSearch: () -> Unit,
    modifier: Modifier = Modifier
) {
    TextField(
        value = query,
        onValueChange = onQueryChange,
        modifier = modifier,
        trailingIcon = {
            IconButton(onClick = onSearch) {
                Icon(Icons.Default.Search, contentDescription = "Search")
            }
        }
    )
}
```

### remember vs rememberSaveable

| API | Survives Recomposition | Survives Config Change | Survives Process Death |
|-----|----------------------|----------------------|----------------------|
| `remember` | Yes | No | No |
| `rememberSaveable` | Yes | Yes | Yes |

```kotlin
@Composable
fun Counter() {
    // Lost on rotation
    var transientCount by remember { mutableIntStateOf(0) }

    // Survives rotation and process death
    var persistentCount by rememberSaveable { mutableIntStateOf(0) }
}
```

### Collecting Flow from ViewModel

Use `collectAsStateWithLifecycle()` (**not** `collectAsState()`). It respects the lifecycle and stops collection when the app is in the background.

```kotlin
@Composable
fun ItemListScreen(viewModel: ItemListViewModel = hiltViewModel()) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    when (val state = uiState) {
        is ItemListUiState.Loading -> LoadingIndicator()
        is ItemListUiState.Success -> ItemList(state.items)
        is ItemListUiState.Error -> ErrorMessage(state.message)
    }
}
```

**Requires**: `androidx.lifecycle:lifecycle-runtime-compose`

### derivedStateOf — Use Sparingly

Google explicitly warns against overuse. Use **only** for threshold-based or filtered derivations where the derived value changes less frequently than its inputs.

```kotlin
// GOOD: derived changes less often than scroll state
val showButton by remember {
    derivedStateOf { listState.firstVisibleItemIndex > 0 }
}

// BAD: derived changes as often as input — just use the value directly
val upperName by remember {
    derivedStateOf { name.uppercase() }  // Don't do this
}
```

### Immutability Rule

Never use mutable collections inside `mutableStateOf`. Compose cannot detect internal mutations.

```kotlin
// WRONG: mutations invisible to Compose
val items = mutableStateOf(mutableListOf<Item>())

// CORRECT: replace the entire list
var items by mutableStateOf(listOf<Item>())
fun addItem(item: Item) {
    items = items + item
}
```

## Side Effects

### Decision Table

| Effect API | Use When |
|---|---|
| `LaunchedEffect(key)` | Run suspend function on enter; restart when key changes |
| `rememberCoroutineScope` | Launch coroutines from event handlers (onClick, etc.) |
| `rememberUpdatedState` | Capture latest value in long-lived effect |
| `DisposableEffect(key)` | Need cleanup (listeners, callbacks) |
| `SideEffect` | Publish Compose state to non-Compose code on every recomposition |
| `produceState` | Convert non-Compose observable to Compose State |

### LaunchedEffect

```kotlin
@Composable
fun MessageScreen(messageId: String) {
    val viewModel: MessageViewModel = hiltViewModel()

    // Re-runs when messageId changes
    LaunchedEffect(messageId) {
        viewModel.loadMessage(messageId)
    }
}
```

### DisposableEffect

```kotlin
@Composable
fun LocationTracker(onLocationUpdate: (Location) -> Unit) {
    val context = LocalContext.current

    DisposableEffect(Unit) {
        val locationManager = context.getSystemService<LocationManager>()
        val listener = LocationListener { onLocationUpdate(it) }
        // Note: Permission check omitted for brevity
        locationManager?.requestLocationUpdates(
            LocationManager.GPS_PROVIDER, 1000L, 10f, listener
        )

        onDispose {
            locationManager?.removeUpdates(listener)
        }
    }
}
```

### rememberCoroutineScope

```kotlin
@Composable
fun SnackbarDemo(snackbarHostState: SnackbarHostState) {
    val scope = rememberCoroutineScope()

    Button(onClick = {
        scope.launch {
            snackbarHostState.showSnackbar("Action completed")
        }
    }) {
        Text("Show Snackbar")
    }
}
```

### produceState

```kotlin
@Composable
fun rememberNetworkImage(url: String): State<ImageResult> {
    return produceState<ImageResult>(initialValue = ImageResult.Loading, url) {
        value = try {
            val bitmap = imageLoader.load(url)
            ImageResult.Success(bitmap)
        } catch (e: Exception) {
            ImageResult.Error(e)
        }
    }
}
```

## Version Requirements

| Feature | Minimum |
|---------|---------|
| Compose State (remember, mutableStateOf) | Jetpack Compose 1.0.0+ |
| rememberSaveable | Jetpack Compose 1.0.0+ |
| collectAsStateWithLifecycle | lifecycle-runtime-compose 2.6.0+ |
| Side Effects (LaunchedEffect, etc.) | Jetpack Compose 1.0.0+ |
