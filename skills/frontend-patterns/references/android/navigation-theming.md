# Android Navigation & Theming

## Type-Safe Navigation (Recommended)

Use `@Serializable` data classes for route definitions. String-based routes are legacy.

```kotlin
// Route definitions
@Serializable
data object HomeRoute

@Serializable
data class ItemDetailRoute(val itemId: String)

@Serializable
data class SearchRoute(val query: String = "")
```

### NavHost Setup

```kotlin
@Composable
fun AppNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController = navController, startDestination = HomeRoute) {
        composable<HomeRoute> {
            HomeScreen(
                onItemClick = { itemId ->
                    navController.navigate(ItemDetailRoute(itemId))
                },
                onSearchClick = {
                    navController.navigate(SearchRoute())
                }
            )
        }
        composable<ItemDetailRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<ItemDetailRoute>()
            ItemDetailScreen(itemId = route.itemId)
        }
        composable<SearchRoute> { backStackEntry ->
            val route = backStackEntry.toRoute<SearchRoute>()
            SearchScreen(initialQuery = route.query)
        }
    }
}
```

### Key Rules

1. **Do not pass NavController to composables** — pass navigation callbacks (lambdas) instead

```kotlin
// GOOD: composable is decoupled from navigation
@Composable
fun HomeScreen(
    onItemClick: (String) -> Unit,
    onSearchClick: () -> Unit
) { /* ... */ }

// BAD: tight coupling to NavController
@Composable
fun HomeScreen(navController: NavController) { /* ... */ }
```

2. **Pass minimum data** — pass IDs, not full objects. Load data in the destination's ViewModel

3. **Requires**: `androidx.navigation:navigation-compose` (2.8.0+) and `kotlinx.serialization`

## Material Design 3

### Theme Setup

```kotlin
@Composable
fun AppTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context)
            else dynamicLightColorScheme(context)
        }
        darkTheme -> darkColorScheme()
        else -> lightColorScheme()
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = AppTypography,
        shapes = AppShapes,
        content = content
    )
}
```

### Three Subsystems

| Subsystem | Key Properties |
|-----------|---------------|
| **Color** | `primary`, `onPrimary`, `surface`, `surfaceVariant`, `error` |
| **Typography** | `displayLarge`..`labelSmall` (15 scale levels) |
| **Shapes** | `extraSmall`, `small`, `medium`, `large`, `extraLarge` |

### Dynamic Color (Android 12+)

- Derives theme from user's wallpaper
- Falls back to custom color scheme on older versions
- Use `dynamicLightColorScheme()` / `dynamicDarkColorScheme()`

### Tonal Elevation

MD3 primarily uses tonal color overlays instead of shadows. `Surface` supports both `tonalElevation` and `shadowElevation`.

```kotlin
Surface(
    tonalElevation = 2.dp,  // Tonal color overlay
    modifier = Modifier.fillMaxWidth()
) {
    Text(
        text = "Elevated surface",
        modifier = Modifier.padding(16.dp)
    )
}
```

## Accessibility (Compose)

### Semantics

Compose components automatically carry semantics. Customize when needed:

```kotlin
// Merge child semantics into a single accessible element
Row(
    modifier = Modifier.semantics(mergeDescendants = true) { }
) {
    Icon(Icons.Default.Star, contentDescription = null)
    Text("Favorite")
}

// Override semantics entirely
Box(
    modifier = Modifier.clearAndSetSemantics {
        contentDescription = "5 out of 10 rating"
    }
) {
    RatingBar(value = 5, max = 10)
}
```

### Live Regions

Announce dynamic content changes to screen readers:

```kotlin
Text(
    text = "Items in cart: $count",
    modifier = Modifier.semantics {
        liveRegion = LiveRegionMode.Polite
    }
)
```

### Testing Semantics

```kotlin
@Test
fun ratingBar_hasCorrectSemantics() {
    composeTestRule.setContent { RatingBar(value = 5, max = 10) }
    composeTestRule
        .onNodeWithContentDescription("5 out of 10 rating")
        .assertExists()
}
```

## Version Requirements

| Feature | Minimum |
|---------|---------|
| Type-safe Navigation | navigation-compose 2.8.0+ |
| Material Design 3 | compose-material3 1.0.0+ |
| Dynamic Color | Android 12 (API 31)+ |
| Compose Semantics | Jetpack Compose 1.0.0+ |
