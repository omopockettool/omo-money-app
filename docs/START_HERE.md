# 🚀 OMOMoney - Session Quick Start

**You are an expert iOS Swift Developer | Clean Architecture | SwiftUI + SwiftData | iOS 26 | NO Liquid Glass UI for now**

read this .md then let me know if you are ready for new development!

> **This project is built with passion — no shortcuts, no lazy responses.**
> Think hard, write clean code, respect every architecture rule, and bring full effort to every task.
> OMO and Claude are building this together. Match that energy.
---

## ⚡ Critical Rules (NEVER VIOLATE)

### 0. NEVER MAKE COMMITS — Only Suggest the Commit Message
**Claude NEVER runs `git commit`, `git add`, or any git write command.**
When work is complete, only output the suggested commit message so the team can run it himself.

```
❌ git add . && git commit -m "..." → NEVER DO THIS
✅ "Here's the suggested commit message: feat: ..."
```

> Team reviews and commits manually. Claude's job ends at suggesting the message.

---

### 1. Architecture Layers (Post-SwiftData)
```
View → ViewModel → UseCase → Repository → ModelContext (SwiftData)
  ↓        ↓          ↓           ↓              ↓
SD*     SD*        SD*         SD*          SD* Models
Models  Models    Models      Models       (single source of truth)
```

> **Domain entity files deleted.** All layers use SD* types directly (SDUser, SDGroup, SDItemList, etc.)

### 2. Layer Boundaries (STRICT)
| Layer | ✅ Can Use | ❌ FORBIDDEN |
|-------|-----------|--------------|
| **Presentation** (Views/ViewModels) | SD* models, UseCases, AppDIContainer, @Query | CoreData, NSManagedObjectContext, ModelContext directly, Repositories, *Domain structs |
| **Domain** (UseCases, Protocols) | Pure Swift, Foundation, SD* types | SwiftData @Model directly, SwiftUI, Data layer |
| **Data** (Repositories) | ModelContext, SD* models, Domain protocols | Presentation layer |

### 3. Dependency Injection (MANDATORY)
```swift
// ✅ CORRECT - Always use AppDIContainer
struct MyView: View {
    @State private var viewModel: MyViewModel

    init(container: AppDIContainer) {
        _viewModel = State(wrappedValue: container.makeMyViewModel())
    }
}

// ❌ WRONG - Never create dependencies directly
struct MyView: View {
    @State private var viewModel = MyViewModel(repository: DefaultUserRepository(...))
}
```

### 4. Threading Rules
- **ViewModels**: `@Observable` + `@MainActor`
- **Repositories**: `MainActor.run { }` wrapping ModelContext operations
- **Async**: Use `async/await` and `withTaskGroup` for concurrent ops

---

## 📂 Quick File Location Guide

```
Application/
├── ContentView.swift, OMOMoneyApp.swift
└── DIContainer/
    └── AppDIContainer.swift ← ALL dependencies created here (uses ModelContext)

Domain/
├── Entities/   ← EMPTY — Domain struct files deleted in Phase 4 Step 4.2
├── Protocols/  ← Repository contracts only (Services layer DELETED)
└── UseCases/   ← Business logic (one operation per UseCase, returns SD* types)

Data/
├── CoreData/   ← Legacy .xcdatamodeld + Persistence.swift (NOT USED by app)
├── SwiftData/  ← SD*.swift @Model classes — THE persistence layer + source of truth
└── Repositories/ ← ModelContext + FetchDescriptor, return SD* models directly

Presentation/
└── Scenes/
    ├── Dashboard/, User/, Group/, ItemList/, etc.
    └── Each has: Views/ and ViewModels/ (@Observable)

Infrastructure/
└── Cache/, Extensions/, Helpers/, Utils/
```

---

## 🎯 Current Architecture Status

**SwiftData Migration: Phases 1–3 + 4.1–4.2 Complete** (as of April 2026)
- ✅ SD* SwiftData models replace Core Data entities
- ✅ ModelContainer replaces PersistenceController
- ✅ Service layer fully deleted (~2,700 lines removed)
- ✅ All 7 repositories use ModelContext directly
- ✅ 0 CoreData imports in Presentation layer
- ✅ 14 ViewModels migrated to @Observable (Phase 4 Step 4.1)
- ✅ All Domain entity files deleted — 0 *Domain types in codebase (Phase 4 Step 4.2)
- ✅ All 7 CoreData mapping files deleted (Phase 4 Step 4.2)
- ✅ All use cases, repositories, ViewModels, and Views use SD* types directly
- ✅ @Query adoption in picker views (Phase 4 Step 4.3) — CategoryPickerView + PaymentMethodPickerView now use @Query directly; 2 ViewModels deleted

**Active Phase:** Phase 4 — Complete ✅

---

## 🔴 Red Flags (Auto-Reject)

```swift
import CoreData                              // ❌ FORBIDDEN in Presentation
@Environment(\.managedObjectContext)         // ❌ FORBIDDEN
let service = UserService(...)               // ❌ Services are DELETED
NSFetchRequest<User>(...)                    // ❌ Use UseCases
context.perform { }                          // ❌ No context in Presentation
class VM: ObservableObject { @Published var } // ❌ FORBIDDEN — use @Observable
```

---

## 🧭 Current Stack

| Concern | Solution |
|---------|----------|
| Persistence | SwiftData `ModelContext` via `ModelContainer.shared` |
| DI | `AppDIContainer` (singleton, `@MainActor`) |
| ViewModels | `@Observable` + `@MainActor` ✅ |
| Data fetch | Repositories → UseCases → ViewModels / `@Query` in Views |
| UI | SwiftUI, Liquid Glass materials (iOS 26) |
| Testing device | Dennis's iPhone (iOS 26.4) `00008120-000A190218614032` |

---

## 🧠 UX Intent — Key Behaviours (READ BEFORE TOUCHING THESE VIEWS)

| View | Behaviour | Why |
|------|-----------|-----|
| `AddItemListView` — create mode | Shows `HeroAmountInputView` (big money input) + description field below it | Dashboard quick-add: user sets a price AND a concept in one shot |
| `AddItemListView` — edit mode | **Hides** `HeroAmountInputView`; description field becomes larger (`.body` font, extra padding) | Money is an **item-level** property. The item list itself has no "price" — the hero input is a create-only shortcut, not a real field |
| `ItemListDetailView` | Never shows `HeroAmountInputView` | Same reason — money lives on items, not on the list |

---

## 🔔 Shared Helpers (ALWAYS use before creating new ones)

| Helper | File | Usage |
|--------|------|-------|
| `PressHapticButtonStyle` | `Infrastructure/Helpers/PressHapticButtonStyle.swift` | `.buttonStyle(PressHapticButtonStyle())` |
| `AnimationHelper.smoothSpring` | `Infrastructure/Helpers/AnimationHelper.swift` | General transitions |
| `AnimationHelper.quickSpring` | same | Immediate feedback |
| `AnimationHelper.quickEase` | same | View mode switching |
| `AppConstants.UserInterface.padding` | `Infrastructure/Constants/AppConstants.swift` | 16pt standard padding |
| `AppConstants.UserInterface.cornerRadius` | same | 16pt corner radius |

---

## 💡 Adding a New Feature (post-SwiftData)

1. Add SD* model or extend existing in `Data/SwiftData/`
2. Create/update Repository protocol in `Domain/Protocols/Repositories/`
3. Implement in `Data/Repositories/Default*.swift`
4. Create UseCase in `Domain/UseCases/`
5. Add factory method to `AppDIContainer`
6. Create `@Observable` ViewModel
7. Create View using `@State` + DI container

---

## ⚠️ Don't Over-Engineer

Fix at the lowest layer that makes sense. Don't cascade a change through all layers unless truly required.

---

**Last Updated:** April 16, 2026 (Phase 4 complete)
**Framework:** SwiftUI + SwiftData
**iOS Version:** 26.1
**Architecture:** Clean Architecture — SwiftData persistence, @Observable ViewModels (in progress)

---

Finally, when the user says "ok, doc and commit" meaning you have to document in english the changelog.md and give the commit name. This is an example: refactor: mark all repositories @MainActor, remove MainActor.run wrappers [v1.0.53] Never make you the commits.