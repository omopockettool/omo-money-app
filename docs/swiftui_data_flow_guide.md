# SwiftUI Data Flow & Rendering — Reference Guide
> Based on "SwiftUI Data Flow" by Karin Prater (swiftyplace.com, April 2026)
> Condensed for OMOMoney / iOS 26 / SwiftData / @Observable stack

---

## 1. The Attribute Graph (Mental Model)

SwiftUI never redraws everything. It builds an **Attribute Graph** — a dependency graph where:
- **State nodes** (blue) hold data
- **View nodes** (green) hold body output
- **Edges** track who depends on who

When state changes:
1. That state node is marked **dirty**
2. SwiftUI follows edges to mark dependent view nodes as **invalid**
3. Bodies of invalid views are re-run and **diffed** against previous output
4. Only actual differences are **committed** to UIKit

**Key insight:** A view whose inputs didn't change has its body call **skipped** — but its `init` still runs when a parent body runs.

```swift
// init always runs when parent body runs.
// body only runs if SwiftUI's diff finds a change.
// → Never do heavy work in init. Use .task or onAppear instead.
```

---

## 2. How the Tree Walk Works

When a parent body runs, SwiftUI creates new struct instances for all children and **diffs** each one:

| Old child value | New child value | Decision |
|---|---|---|
| `FeaturedView()` | `FeaturedView()` | Equal → **STOP, body skipped** |
| `SearchBranch(query: "")` | `SearchBranch(query: "shoes")` | Different → **run body** |

The walk can stop **anywhere** in the tree, not just at the top level.

### The init vs body distinction

```swift
struct FeaturedView: View {
    init() { print("FeaturedView init") }  // runs every time parent body runs
    var body: some View {
        Self._printChanges()               // only runs if SwiftUI decides to re-render
        return Text("Featured Products")
    }
}
```

**Debugging tool:**
```swift
var body: some View {
    let _ = Self._printChanges()  // prints what changed and why
    return YourView()
}
```

---

## 3. Value Types (@State / @Binding)

For value types, **the declaration creates the dependency** — not what you do with the value at runtime.

```swift
struct ChildView: View {
    let text: String  // declared = in tree walk path, even if never read in body
    var body: some View {
        Text("I don't use text at all")  // body still re-runs when parent's @State changes
    }
}
```

**Rule:** Don't pass values to child views that they don't need. Unused declarations still cause body evaluations.

### @Binding is NOT new storage

`@Binding` is just a `get/set` closure pair pointing to someone else's `@State`. No new graph node. No new edge.

```swift
// Custom binding when types don't match:
var usernameBinding: Binding<String> {
    Binding(
        get: { username ?? "" },
        set: { username = $0.isEmpty ? nil : $0 }
    )
}
```

### Collections

SwiftUI treats the **whole collection** as one value. Any element change → parent body re-runs. `ForEach` then diffs which rows changed internally.

---

## 4. Reference Types — @Observable (iOS 17+, preferred)

With `@Observable`, SwiftUI tracks at the **property level**, not the object level. Only the views that read a specific property get invalidated when that property changes.

```swift
@Observable
class ShopViewModel {
    var searchQuery = ""
    var cartCount = 0
}

struct SearchView: View {
    var vm: ShopViewModel
    var body: some View {
        Text(vm.searchQuery)  // only re-renders when searchQuery changes
        // cartCount changes → this view is NOT invalidated
    }
}
```

This is the key advantage of `@Observable` over value types for deep hierarchies: intermediate views that only **pass the reference** don't get invalidated.

### @Observable vs @State for ViewModels

```swift
// ✅ Correct — ViewModel allocated once, SwiftUI owns its lifetime
struct MyView: View {
    @State private var viewModel = MyViewModel()
    // ...
}

// ❌ Wrong — ViewModel recreated every time parent body runs
struct MyView: View {
    var viewModel = MyViewModel()
    // ...
}
```

---

## 5. View Identity & Lifetime

**The view's lifetime = the attribute graph node's lifetime**, NOT the struct instance lifetime.

Structs are created and thrown away constantly. The **node** is what persists.

### What destroys a node

- `if/else` branch switching
- `switch` on an enum (each branch = different node)
- `.sheet` dismissed
- `NavigationStack` popped
- `.id(newValue)` called with changed value
- `LazyVStack/List` row scrolled far off-screen

### State lifetime = Node lifetime

```swift
// When the node is destroyed, all @State it owns is destroyed with it.
// When the node is recreated, @State is initialized fresh.

if showChild {
    ChildView()  // ChildView's @State resets every time showChild toggles
}
```

**Fix — lift state up:**
```swift
struct Parent: View {
    @State private var userInput = ""  // now lives on parent's node
    @State private var showChild = true
    var body: some View {
        if showChild { ChildView(text: $userInput) }
    }
}
```

### Appearance ≠ Lifetime

| Container | onAppear/onDisappear | @State |
|---|---|---|
| `if/else` toggle | fires once per lifetime | resets on toggle |
| `TabView` switch | fires on every tab switch | **survives** across switches |
| `NavigationStack` push/pop | fires on push/pop | resets on pop |
| `.sheet` present/dismiss | fires on present/dismiss | resets on dismiss |

---

## 6. State Ownership Rules

### Single source of truth
One `@State` declaration for each piece of data. Never duplicate.

### Where to place state
1. **Local to the view** — default. `@State private var`.
2. **Lift to common ancestor** — when siblings need the same data.
3. **Never higher than necessary** — keeps blast radius small, improves performance.

```
Rule of thumb: start local, lift only when needed.
```

### Deep hierarchy — use @Observable

When state needs to reach a view 3+ levels deep, wrap it in an `@Observable` class and pass the reference. Intermediate views that only pass the reference won't be invalidated.

---

## 7. Lifecycle Modifiers

### onAppear / onDisappear
- Fires on **visibility**, not node lifetime.
- Safe for light sync work.
- **Don't use for async loading** — no built-in cancellation.

### .task { }
- Fires when view **becomes visible** (same timing as onAppear).
- **Auto-cancels** when view disappears.
- Runs on `@MainActor` by default — safe to assign to `@State` directly.
- Can re-fire if view disappears and reappears (TabView, navigation).

```swift
.task {
    do {
        let data = try await fetchData()
        self.items = data              // safe, already on MainActor
    } catch is CancellationError {
        // view disappeared mid-fetch, ignore
    } catch {
        self.error = error             // show this to user
    }
}
```

### .task(id:) { }
- Re-runs (and cancels previous) whenever `id` changes.
- Good for search-as-you-type patterns.

```swift
.task(id: searchQuery) {
    try? await Task.sleep(for: .milliseconds(300))  // debounce
    await performSearch(query: searchQuery)
}
```

### .onChange(of:)
- Fires synchronously after a value changes.
- Can create infinite loops if you mutate the same value you observe.

### Cancellation is cooperative
Apple's async APIs (`URLSession`, `Task.sleep`) throw on cancellation automatically. Custom loops must check manually:

```swift
for item in largeCollection {
    guard !Task.isCancelled else { return }
    process(item)
}
```

---

## 8. Container Behavior (Critical)

| Container | Node lifetime | onAppear fires |
|---|---|---|
| `TabView` | **Alive** while tab exists | On every tab switch |
| `NavigationStack` | Destroyed on pop | On push |
| `.sheet` | Destroyed on dismiss | On present |
| `LazyVStack/List` | May be destroyed off-screen | On scroll into view |

**TabView gotcha:** `onAppear` fires every time you switch back. If you load data in `onAppear`, you'll re-fetch every tab switch. Use `.task` with a guard or `@State` flag instead.

```swift
.task {
    guard items.isEmpty else { return }  // only load once
    items = try await fetchItems()
}
```

---

## 9. Performance — Only Optimize When Measured

SwiftUI is fast. Don't pre-optimize. Only care when:
- Visible stuttering during scroll
- Instruments shows dropped frames
- Complex views updating frequently (real-time data, animations)

### Strategy: Keep state close to where it's used
State high in the tree → more bodies evaluate on every change.

### Strategy: Scope view inputs
Don't pass a whole model when a child only needs one field:
```swift
// ✅ Better — only re-renders when name changes
NameLabel(name: item.name)

// ❌ Worse — re-renders when any property of item changes
ItemCard(item: item)
```

### Strategy: Don't declare what you don't use
```swift
// ❌ Causes re-render even though text is unused
struct ChildView: View {
    let text: String  // declared but never read
}

// ✅ Remove the property
struct ChildView: View {
    // no dependency = no unnecessary re-renders
}
```

---

## 10. AnyView Pitfalls

`AnyView` erases structural identity — SwiftUI can't tell what changed.

```swift
// ❌ Erases identity, may cause unexpected state resets
var body: some View {
    AnyView(showA ? ViewA() : ViewB())
}

// ✅ Preserve identity with conditional syntax
var body: some View {
    if showA { ViewA() } else { ViewB() }
}
```

---

## 11. ForEach — ID Stability

Unstable IDs (computed from index, or non-stable values) cause SwiftUI to think rows are different entities on every update → expensive full reloads.

```swift
// ❌ Index-based IDs are unstable
ForEach(0..<items.count, id: \.self) { i in ... }

// ✅ Stable, unique IDs
ForEach(items) { item in ... }  // item conforms to Identifiable
```

---

## 12. Quick Reference — Which tool to use?

| Scenario | Tool |
|---|---|
| Local UI state (toggle, text input) | `@State` |
| Pass state down for read | `let` / `var` property |
| Pass state down for read+write | `@Binding` |
| ViewModel / shared state | `@Observable` + `@State` |
| Global app state | `@Observable` + `.environment()` |
| Async work tied to visibility | `.task { }` |
| Reactive async (re-runs on value change) | `.task(id:) { }` |
| Light sync side-effects | `.onAppear` |
| React to value changes | `.onChange(of:)` |
| Reset view completely | `.id(newToken)` |
