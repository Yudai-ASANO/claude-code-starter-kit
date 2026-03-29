# UI Framework Patterns

> **Note:** This file contains patterns primarily from React. Adapt concepts to your UI framework (Vue, SwiftUI, Jetpack Compose, etc.).

## Component Structure

Well-structured components have typed props, sensible defaults, and clear responsibilities.

**React:**
```typescript
interface ButtonProps {
  children: React.ReactNode
  onClick: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({
  children,
  onClick,
  disabled = false,
  variant = 'primary'
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {children}
    </button>
  )
}
```

**Vue 3 (Composition API):**
```vue
<script setup lang="ts">
interface Props {
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

const props = withDefaults(defineProps<Props>(), {
  disabled: false,
  variant: 'primary'
})

const emit = defineEmits<{
  click: []
}>()
</script>

<template>
  <button
    :disabled="props.disabled"
    :class="`btn btn-${props.variant}`"
    @click="emit('click')"
  >
    <slot />
  </button>
</template>
```

## Reusable Logic Extraction

Extract reusable stateful logic into framework-specific abstractions.

**React (Custom Hook):**
```typescript
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)
    return () => clearTimeout(handler)
  }, [value, delay])

  return debouncedValue
}

// Usage
const debouncedQuery = useDebounce(searchQuery, 500)
```

**Vue 3 (Composable):**
```typescript
export function useDebounce<T>(value: Ref<T>, delay: number): Ref<T> {
  const debouncedValue = ref(value.value) as Ref<T>

  watch(value, (newVal) => {
    const handler = setTimeout(() => {
      debouncedValue.value = newVal
    }, delay)
    return () => clearTimeout(handler)
  })

  return debouncedValue
}
```

## State Management

Update state immutably. Use functional updaters when new state depends on previous state.

**React:**
```typescript
const [count, setCount] = useState(0)

// GOOD: Functional update for state based on previous state
setCount(prev => prev + 1)

// BAD: Direct state reference (can be stale in async scenarios)
setCount(count + 1)
```

**Vue 3:**
```typescript
const count = ref(0)

// Vue refs are mutable by design, but keep complex state immutable
count.value = count.value + 1
```

## Conditional Rendering

Avoid deeply nested ternary expressions.

**React:**
```typescript
// GOOD: Clear conditional rendering
{isLoading && <Spinner />}
{error && <ErrorMessage error={error} />}
{data && <DataDisplay data={data} />}

// BAD: Ternary hell
{isLoading ? <Spinner /> : error ? <ErrorMessage error={error} /> : data ? <DataDisplay data={data} /> : null}
```

**Vue:**
```vue
<!-- GOOD: Clear conditional rendering -->
<Spinner v-if="isLoading" />
<ErrorMessage v-else-if="error" :error="error" />
<DataDisplay v-else-if="data" :data="data" />
```

## Memoization / Computed Values

Cache expensive computations that depend on specific inputs.

**React:**
```typescript
import { useMemo, useCallback } from 'react'

const sortedItems = useMemo(() => {
  return items.sort((a, b) => b.volume - a.volume)
}, [items])

const handleSearch = useCallback((query: string) => {
  setSearchQuery(query)
}, [])
```

**Vue 3:**
```typescript
const sortedItems = computed(() => {
  return [...items.value].sort((a, b) => b.volume - a.volume)
})
```

## Lazy Loading / Code Splitting

Load heavy components on demand to improve initial load performance.

**React:**
```typescript
import { lazy, Suspense } from 'react'

const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<Spinner />}>
      <HeavyChart />
    </Suspense>
  )
}
```

**Vue 3:**
```typescript
import { defineAsyncComponent } from 'vue'

const HeavyChart = defineAsyncComponent(() => import('./HeavyChart.vue'))
```

**General principle:** Any component that is not needed on initial render, or that pulls in large dependencies, is a candidate for lazy loading.
