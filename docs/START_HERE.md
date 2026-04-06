# 🚀 OMOMoney - Session Quick Start

**You are an expert iOS Swift Developer | Clean Architecture | SwiftUI + CoreData | Liquid Glass UI**

---

## ⚡ Critical Rules (NEVER VIOLATE)

### 1. Clean Architecture Layers
```
View → ViewModel → UseCase → Repository → CoreData
  ↓        ↓          ↓           ↓          ↓
Domain  Domain    Domain      Domain    Data Layer
Models  Models    Models      Models    ONLY
```

### 2. Layer Boundaries (STRICT)
| Layer | ✅ Can Use | ❌ FORBIDDEN |
|-------|-----------|--------------|
| **Presentation** (Views/ViewModels) | Domain models, UseCases, AppDIContainer | CoreData, NSManagedObjectContext, Services, Repositories |
| **Domain** (UseCases, Protocols, Entities) | Pure Swift, Foundation only | CoreData, SwiftUI, Data layer |
| **Data** (Repositories, Services) | CoreData, Domain protocols, `.toDomain()` | Presentation layer |

### 3. Dependency Injection (MANDATORY)
```swift
// ✅ CORRECT - Always use AppDIContainer
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(container: AppDIContainer) {
        _viewModel = StateObject(wrappedValue: container.makeMyViewModel())
    }
}

// ❌ WRONG - Never create dependencies directly
struct MyView: View {
    @StateObject private var viewModel = MyViewModel(
        service: UserService() // ❌ FIRED!
    )
}
```

### 4. Threading Rules
- **UI**: `@MainActor` for all ViewModels and Published properties
- **CoreData**: `context.perform { }` for ALL CoreData operations
- **Async**: Use `async/await` and `withTaskGroup` for concurrent ops

---

## 📂 Quick File Location Guide

```
Application/
├── ContentView.swift, OMOMoneyApp.swift
└── DIContainer/
    └── AppDIContainer.swift ← ALL dependencies created here

Domain/
├── Entities/ ← Pure Swift models (UserDomain, GroupDomain, etc.)
├── Protocols/ ← Repository & Service contracts
└── UseCases/ ← Business logic (one operation per UseCase)

Data/
├── CoreData/ ← NSManagedObjectContext, .xcdatamodeld
├── Repositories/ ← Implement Domain protocols
└── Services/ ← CoreData CRUD operations with .toDomain()

Presentation/
└── Scenes/
    ├── Dashboard/, User/, Group/, ItemList/, etc.
    └── Each has: Views/ and ViewModels/

Infrastructure/
└── Cache/, Extensions/, Helpers/, Utils/
```

---

## 🎯 Current Architecture Status

**Status**: ✅ **100% Clean Architecture** (as of Dec 24, 2025)
- **0** CoreData imports in Presentation layer
- **0** NSManagedObjectContext in Views/ViewModels  
- **0** Direct Service/Repository instantiation
- **32** `.toDomain()` conversions (all in Data layer)

---

## 🔍 When You Need More Context

Use these commands in order:
1. **Quick overview**: Read `docs/architecture/QUICK_START.md`
2. **Layer details**: Read `docs/architecture/CLEAN_ARCHITECTURE_GUIDE.md`
3. **File structure**: Read `docs/architecture/PROJECT_STRUCTURE.md`
4. **Complete refactor**: Read `docs/CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md`

---

## 🚨 Red Flags (Auto-Reject)

If you see ANY of these in Presentation layer, **STOP and REFACTOR**:
```swift
import CoreData                           // ❌ FORBIDDEN
@Environment(\.managedObjectContext)      // ❌ FORBIDDEN
let service = UserService(...)            // ❌ Use DI Container
NSFetchRequest<User>(...)                 // ❌ Use UseCases
context.perform { }                       // ❌ No context in Presentation
```

---

## ⚠️ Don't Over-Engineer

**Fix at the lowest layer that makes sense. Don't cascade a change through all layers unless truly required.**

| Situation | ❌ Over-engineered | ✅ Right fix |
|-----------|-------------------|--------------|
| UI field should be optional | Change Domain model + UseCase + Repository + Mapping + ViewModel | Handle the empty/nil state in the ViewModel, pass a safe default |
| Display tweak | New UseCase + new protocol | Change the View or ViewModel directly |
| Validation relaxation | Refactor all layers | Relax only the layer that owns that rule |

**Real example** — making the amount field optional when creating an item:
```swift
// ❌ Wrong: changed ItemDomain, UseCases, Repository, Mapping, ViewModel (7 files)

// ✅ Right: one line in AddItemViewModel.saveItem()
let amountDecimal = normalizedAmount.isEmpty ? Decimal(0) : (Decimal(string: normalizedAmount) ?? Decimal(0))
```

---

## ♻️ Reusable Components (MANDATORY thinking)

**Before writing any UI component, helper, or style — ask: "Could this be used in more than one place?"**

If yes, put it in the right shared location instead of scoping it to a single file:

| Type | Where |
|------|-------|
| `ButtonStyle`, visual modifiers | `Infrastructure/Helpers/` |
| SwiftUI shared views (cards, inputs) | `Presentation/Common/Components/` |
| Extensions (`Color`, `String`, etc.) | `Infrastructure/Extensions/` |
| Animation constants | `Infrastructure/Helpers/AnimationHelper.swift` |

**Real example** — haptic button style needed in two views:
```swift
// ❌ Wrong: defined as `private struct` inside ItemListDetailView.swift

// ✅ Right: Infrastructure/Helpers/PressHapticButtonStyle.swift
struct PressHapticButtonStyle: ButtonStyle { ... }
// Now any view can use: .buttonStyle(PressHapticButtonStyle())
```

**Rule**: if you catch yourself copy-pasting a component into a second file, stop and extract it first.

---

## 💡 Development Patterns

### Adding New Feature
1. Create Domain entity in `Domain/Entities/`
2. Create Repository protocol in `Domain/Protocols/Repositories/`
3. Create UseCase in `Domain/UseCases/`
4. Implement Repository in `Data/Repositories/`
5. Add factory method to `AppDIContainer`
6. Create ViewModel using container
7. Create View using container

### Incremental Updates (Cache System)
```swift
// Pattern: Update cache first, then CoreData in background
Task {
    // 1. Update cache immediately (UI updates)
    CacheManager.shared.updateCache(...)
    
    // 2. Persist to CoreData in background
    await repository.save(...)
}
```

---

## 🧪 Testing Device
**Physical Device**: Dennis's iPhone (26.1) `00008120-000A190218614032`

---

## 📝 Code Style
- **No verbose summaries** - Concise responses only
- **Swift naming**: camelCase for vars, PascalCase for types
- **SwiftUI**: Prefer `@StateObject` for ownership, `@ObservedObject` for passing
- **Async/await**: Prefer over completion handlers
- **Error handling**: Use `throws` and domain-specific errors

---

**Last Updated**: April 5, 2026
**Framework**: SwiftUI + CoreData  
**iOS Version**: 26.1  
**Architecture**: Clean Architecture (100% compliant)
