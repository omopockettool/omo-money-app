# 🚀 OMOMoney - Session Quick Start

**You are an expert iOS Swift Developer | Clean Architecture | SwiftUI + SwiftData | iOS 26 | Liquid Glass UI**

---

## ⚡ Critical Rules (NEVER VIOLATE)

### 1. Architecture Layers (Post-SwiftData)
```
View → ViewModel → UseCase → Repository → ModelContext (SwiftData)
  ↓        ↓          ↓           ↓              ↓
Domain  Domain    Domain      Domain       SD* Models
Models  Models    Models      Models       (single source of truth)
```

### 2. Layer Boundaries (STRICT)
| Layer | ✅ Can Use | ❌ FORBIDDEN |
|-------|-----------|--------------|
| **Presentation** (Views/ViewModels) | Domain models, UseCases, AppDIContainer, @Query | CoreData, NSManagedObjectContext, ModelContext directly, Repositories |
| **Domain** (UseCases, Protocols, Entities) | Pure Swift, Foundation only | SwiftData, SwiftUI, Data layer |
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
├── Entities/   ← *Domain.swift models (UserDomain, GroupDomain, etc.)
├── Protocols/  ← Repository contracts only (Services layer DELETED)
└── UseCases/   ← Business logic (one operation per UseCase)

Data/
├── CoreData/   ← Legacy .xcdatamodeld + Persistence.swift (NOT USED by app)
├── SwiftData/  ← SD*.swift @Model classes — THE persistence layer
└── Repositories/ ← ModelContext + FetchDescriptor, return *Domain models

Presentation/
└── Scenes/
    ├── Dashboard/, User/, Group/, ItemList/, etc.
    └── Each has: Views/ and ViewModels/ (@Observable)

Infrastructure/
└── Cache/, Extensions/, Helpers/, Utils/
```

---

## 🎯 Current Architecture Status

**SwiftData Migration: Phases 1–3 Complete** (as of April 2026)
- ✅ SD* SwiftData models replace Core Data entities
- ✅ ModelContainer replaces PersistenceController
- ✅ Service layer fully deleted (~2,700 lines removed)
- ✅ All 7 repositories use ModelContext directly
- ✅ 0 CoreData imports in Presentation layer
- ⏳ Domain model files still exist (Phase 4 will delete them)
- ⏳ ViewModels still use ObservableObject (Phase 4 → @Observable)

**Active Phase:** Phase 4 — @Observable + Liquid Glass

---

## 🔴 Red Flags (Auto-Reject)

```swift
import CoreData                              // ❌ FORBIDDEN in Presentation
@Environment(\.managedObjectContext)         // ❌ FORBIDDEN
let service = UserService(...)               // ❌ Services are DELETED
NSFetchRequest<User>(...)                    // ❌ Use UseCases
context.perform { }                          // ❌ No context in Presentation
class VM: ObservableObject { @Published var } // ⚠️ Phase 4 target → @Observable
```

---

## 🧭 Current Stack

| Concern | Solution |
|---------|----------|
| Persistence | SwiftData `ModelContext` via `ModelContainer.shared` |
| DI | `AppDIContainer` (singleton, `@MainActor`) |
| ViewModels | `ObservableObject` → migrating to `@Observable` (Phase 4) |
| Data fetch | Repositories → UseCases → ViewModels / `@Query` in Views |
| UI | SwiftUI, Liquid Glass materials (iOS 26) |
| Testing device | Dennis's iPhone (iOS 26.1) `00008120-000A190218614032` |

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

**Last Updated:** April 16, 2026
**Framework:** SwiftUI + SwiftData
**iOS Version:** 26.1
**Architecture:** Clean Architecture — SwiftData persistence, @Observable ViewModels (in progress)
