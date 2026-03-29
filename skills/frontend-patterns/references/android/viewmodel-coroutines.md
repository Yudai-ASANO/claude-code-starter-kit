# Android ViewModel & Coroutines

## ViewModel Best Practices

### Expose StateFlow, Not Suspend Functions

ViewModels must **not** expose `suspend` functions. Expose `StateFlow` and launch coroutines internally.

```kotlin
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val userRepository: UserRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val userId: String = checkNotNull(savedStateHandle["userId"])

    // Expose immutable StateFlow
    val uiState: StateFlow<ProfileUiState> = userRepository
        .observeUser(userId)
        .map<User, ProfileUiState> { ProfileUiState.Success(it) }
        .catch { emit(ProfileUiState.Error(it.message ?: "Unknown error")) }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ProfileUiState.Loading
        )

    // Public function triggers internal coroutine
    fun updateDisplayName(name: String) {
        viewModelScope.launch {
            userRepository.updateDisplayName(userId, name)
        }
    }
}
```

### Why `WhileSubscribed(5_000)`?

- Stops upstream collection 5 seconds after the last subscriber disappears
- Survives quick configuration changes (rotation) without restarting
- Google's standard recommendation for `stateIn()`

### Private Mutable, Public Immutable

```kotlin
// Pattern: encapsulate mutability
private val _events = MutableSharedFlow<UiEvent>()
val events: SharedFlow<UiEvent> = _events.asSharedFlow()

private val _uiState = MutableStateFlow(FormState())
val uiState: StateFlow<FormState> = _uiState.asStateFlow()
```

## Coroutines Best Practices

### Dispatcher Injection (Mandatory)

Never hardcode dispatchers. Inject them for testability.

```kotlin
@HiltViewModel
class ImportViewModel @Inject constructor(
    private val repository: ImportRepository,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : ViewModel() {

    fun importFile(uri: Uri) {
        viewModelScope.launch {
            val data = withContext(ioDispatcher) {
                repository.parseFile(uri)
            }
            repository.saveImportedData(data)
        }
    }
}

// In tests: inject TestDispatcher
@Test
fun importFile_parsesAndSaves() = runTest {
    val viewModel = ImportViewModel(
        repository = fakeRepository,
        ioDispatcher = UnconfinedTestDispatcher(testScheduler)
    )
    viewModel.importFile(testUri)
    assertEquals(expected, fakeRepository.lastSaved)
}
```

### Qualifier Definitions

```kotlin
@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

@Module
@InstallIn(SingletonComponent::class)
object DispatcherModule {
    @IoDispatcher
    @Provides
    fun provideIoDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @DefaultDispatcher
    @Provides
    fun provideDefaultDispatcher(): CoroutineDispatcher = Dispatchers.Default
}
```

### CancellationException Handling

Always rethrow `CancellationException`. Swallowing it breaks structured concurrency.

```kotlin
suspend fun fetchWithRetry(maxRetries: Int = 3): Result {
    repeat(maxRetries) { attempt ->
        try {
            return api.fetch()
        } catch (e: CancellationException) {
            throw e  // MUST rethrow
        } catch (e: Exception) {
            if (attempt == maxRetries - 1) throw e
            delay(1000L * (attempt + 1))
        }
    }
    error("Unreachable")
}
```

### Structured vs Unstructured

```kotlin
// PREFERRED: Structured — cancelled when scope cancelled
suspend fun loadData(): Data {
    return coroutineScope {
        val part1 = async { api.fetchPart1() }
        val part2 = async { api.fetchPart2() }
        Data(part1.await(), part2.await())
    }
}

// AVOID: Unstructured — fire-and-forget, no cancellation propagation
fun loadData() {
    GlobalScope.launch {  // Don't do this
        api.fetchPart1()
    }
}
```

## Testing ViewModels

```kotlin
@OptIn(ExperimentalCoroutinesApi::class)
class ProfileViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private val fakeRepository = FakeUserRepository()

    @Test
    fun initialState_isLoading() = runTest {
        val viewModel = ProfileViewModel(fakeRepository, SavedStateHandle(mapOf("userId" to "1")))
        assertEquals(ProfileUiState.Loading, viewModel.uiState.value)
    }

    @Test
    fun afterLoad_showsUser() = runTest {
        fakeRepository.setUser(User("1", "Alice"))
        val viewModel = ProfileViewModel(fakeRepository, SavedStateHandle(mapOf("userId" to "1")))

        val states = viewModel.uiState.take(2).toList()
        assertIs<ProfileUiState.Success>(states.last())
    }
}

class MainDispatcherRule(
    private val dispatcher: TestDispatcher = UnconfinedTestDispatcher()
) : TestWatcher() {
    override fun starting(description: Description) {
        Dispatchers.setMain(dispatcher)
    }
    override fun finished(description: Description) {
        Dispatchers.resetMain()
    }
}
```

## Version Requirements

| Feature | Minimum |
|---------|---------|
| viewModelScope | lifecycle-viewmodel-ktx 2.2.0+ |
| StateFlow / SharedFlow | kotlinx-coroutines 1.4.0+ |
| collectAsStateWithLifecycle | lifecycle-runtime-compose 2.6.0+ |
| TestDispatcher | kotlinx-coroutines-test 1.6.0+ |
