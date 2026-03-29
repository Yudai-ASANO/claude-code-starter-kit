# Android Architecture & Dependency Injection

## 3-Layer Architecture (Google Official)

```
UI Layer          →  Domain Layer (optional)  →  Data Layer
Compose + ViewModel    UseCases                  Repository + DataSource
```

### Core Principles

- **Separation of Concerns**: UI logic in ViewModel, business logic in UseCase, data access in Repository
- **Single Source of Truth (SSOT)**: Each data type has one authoritative source
- **Unidirectional Data Flow (UDF)**: State flows down, events flow up

## UI Layer: Compose + ViewModel

```kotlin
@HiltViewModel
class ItemListViewModel @Inject constructor(
    private val repository: ItemRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<ItemListUiState>(ItemListUiState.Loading)
    val uiState: StateFlow<ItemListUiState> = _uiState.asStateFlow()

    init {
        loadItems()
    }

    // ViewModel does NOT expose suspend functions
    fun loadItems() {
        viewModelScope.launch {
            _uiState.value = ItemListUiState.Loading
            _uiState.value = try {
                ItemListUiState.Success(repository.getItems())
            } catch (e: Exception) {
                ItemListUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    fun deleteItem(id: String) {
        viewModelScope.launch {
            repository.deleteItem(id)
            loadItems()
        }
    }
}

sealed interface ItemListUiState {
    data object Loading : ItemListUiState
    data class Success(val items: List<Item>) : ItemListUiState
    data class Error(val message: String) : ItemListUiState
}
```

## Domain Layer (Optional)

Google officially marks the Domain Layer as **optional**. Add UseCases only when:
- Business logic is reused across multiple ViewModels
- Complex business rules need isolation for testing

```kotlin
class GetFilteredItemsUseCase @Inject constructor(
    private val itemRepository: ItemRepository,
    private val userRepository: UserRepository
) {
    suspend operator fun invoke(query: String): List<Item> {
        val user = userRepository.getCurrentUser()
        val items = itemRepository.searchItems(query)
        return items.filter { it.isVisibleTo(user) }
    }
}
```

**Do not** create a UseCase that simply delegates to a single Repository method.

## Data Layer: Repository Pattern

One Repository per data type. Repository abstracts data sources.

```kotlin
interface ItemRepository {
    suspend fun getItems(): List<Item>
    suspend fun getItem(id: String): Item
    suspend fun searchItems(query: String): List<Item>
    suspend fun saveItem(item: Item)
    suspend fun deleteItem(id: String)
}

class DefaultItemRepository @Inject constructor(
    private val remoteDataSource: ItemRemoteDataSource,
    private val localDataSource: ItemLocalDataSource,
    @IoDispatcher private val dispatcher: CoroutineDispatcher
) : ItemRepository {

    override suspend fun getItems(): List<Item> = withContext(dispatcher) {
        try {
            val items = remoteDataSource.fetchItems()
            localDataSource.cacheItems(items)
            items
        } catch (e: IOException) {
            localDataSource.getCachedItems()
        }
    }
}
```

## Dependency Injection: Hilt (Google Official)

Hilt is Google's **recommended** DI framework for complex Android apps. For simple apps, manual DI is also acceptable per Google's guidance. Service Locator pattern is explicitly discouraged. Community alternatives (Koin) also exist.

```kotlin
@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds
    @Singleton
    abstract fun bindItemRepository(impl: DefaultItemRepository): ItemRepository
}

@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {
    @IoDispatcher
    @Provides
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO
}

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher
```

### Key Points

- `@HiltViewModel` + `@Inject constructor` for ViewModels
- `@InstallIn` controls component lifecycle scope
- Use `@Binds` for interface-to-implementation mapping
- Use `@Provides` for third-party or complex instances
- Inject `CoroutineDispatcher` for testability (never hardcode `Dispatchers.IO`)

## Error State Modeling

Google supports two patterns:

### 1. Sealed Class (Full-Screen State)

```kotlin
sealed interface UiState<out T> {
    data object Loading : UiState<Nothing>
    data class Success<T>(val data: T) : UiState<T>
    data class Error(val message: String) : UiState<Nothing>
}
```

### 2. Data Class + User Messages (Overlay Errors)

```kotlin
data class ItemListUiState(
    val items: List<Item> = emptyList(),
    val isLoading: Boolean = false,
    val userMessages: List<UserMessage> = emptyList()
)

data class UserMessage(val id: Long, val text: String)
```

Choose sealed class for screens with exclusive states. Choose data class for screens where errors overlay content.

## Version Requirements

| Feature | Minimum |
|---------|---------|
| Jetpack Compose | API 21+ |
| ViewModel (lifecycle-viewmodel) | API 14+ |
| Hilt | API 14+ |
| StateFlow + stateIn | kotlinx-coroutines 1.4.0+ |
