# 🔥 OMOMoney Architecture Rules - MANDATORY

> **You are an expert Swift iOS engineer. Violating these rules = FIRED.**

---

## 🎯 Rule #1: Clean Architecture Boundaries

### Layer Dependency Flow (STRICT)
```
View → ViewModel → UseCase → Repository → Service → CoreData
  ✅       ✅         ✅          ✅          ✅        ⚠️
Domain   Domain    Domain     Domain     Domain    DATA LAYER
Models   Models    Models     Protocols  Protocols  ONLY
```

### What Each Layer Can/Cannot Do

#### ✅ Presentation Layer (Views & ViewModels)
**CAN:**
- Use Domain models (`UserDomain`, `GroupDomain`, `ItemListDomain`)
- Call UseCases for business logic
- Use `AppDIContainer` for ALL dependencies
- Use `@MainActor` for ViewModels
- Import SwiftUI only

**CANNOT (AUTO-REJECT):**
```swift
import CoreData                          // ❌ FORBIDDEN
@Environment(\.managedObjectContext)     // ❌ FORBIDDEN  
let service = UserService(context: ...)  // ❌ Use DI Container
NSFetchRequest<User>(...)                // ❌ Use UseCases
NSManagedObjectContext                   // ❌ FORBIDDEN
```

#### ✅ Domain Layer (UseCases, Protocols, Entities)
**CAN:**
- Define business logic in UseCases
- Define repository/service protocols
- Use pure Swift structs/classes (entities)
- Import Foundation ONLY

**CANNOT:**
```swift
import CoreData      // ❌ FORBIDDEN
import SwiftUI       // ❌ FORBIDDEN
// Any Data or Presentation layer imports
```

#### ✅ Data Layer (Repositories, Services)
**CAN:**
- Import CoreData
- Implement Domain protocols
- Use `.toDomain()` to convert entities
- Use `context.perform { }` for threading
- Return Domain models to upper layers

**CANNOT:**
```swift
// Expose NSManagedObject to other layers
func getUser() -> User { ... }  // ❌ Return UserDomain instead
```

---

## 🎯 Rule #2: Dependency Injection (100% Required)

### ✅ CORRECT Pattern
```swift
// 1. Add factory to AppDIContainer
extension AppDIContainer {
    func makeMyViewModel() -> MyViewModel {
        MyViewModel(useCase: makeMyUseCase())
    }
}

// 2. View uses container
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(container: AppDIContainer) {
        _viewModel = StateObject(wrappedValue: container.makeMyViewModel())
    }
}
```

### ❌ WRONG Pattern (Auto-Reject)
```swift
// NEVER instantiate directly
struct MyView: View {
    @StateObject private var viewModel = MyViewModel(
        service: UserService()  // ❌ FIRED!
    )
}
```

---

## 🎯 Rule #3: Threading Model

| Context | Rule | Pattern |
|---------|------|---------|
| **UI Updates** | Main thread only | `@MainActor` on ViewModels |
| **CoreData** | Background thread | `context.perform { ... }` |
| **Async Ops** | Structured concurrency | `async/await`, `withTaskGroup` |
| **Published Props** | Main thread | `@Published` in `@MainActor` class |

---

## 🎯 Rule #4: Data Update Pattern (Cache-First)

```swift
// ✅ CORRECT - Incremental Update Pattern
Task {
    // 1. Update cache immediately (instant UI update)
    CacheManager.shared.updateCache(newData)
    
    // 2. Persist to CoreData in background
    await repository.save(newData)
}

// ❌ WRONG - Direct CoreData, then cache
await repository.save(newData)
CacheManager.shared.updateCache(newData)
```

---

## 🎯 Rule #5: File Organization

```
Application/DIContainer/
  └── AppDIContainer.swift ← ALL dependency factories here

Domain/
  ├── Entities/ ← Pure Swift models (UserDomain, etc.)
  ├── Protocols/ ← Repository & Service contracts  
  └── UseCases/ ← One operation per UseCase

Data/
  ├── CoreData/ ← NSManagedObjectContext, .xcdatamodeld
  ├── Repositories/ ← Implement protocols, use .toDomain()
  └── Services/ ← CoreData CRUD operations

Presentation/Scenes/
  └── [Feature]/ ← Dashboard, User, Group, ItemList, etc.
      ├── Views/
      └── ViewModels/
```

---

## 📊 Current Status (March 2026)

✅ **100% Clean Architecture Compliant**
- 0 CoreData imports in Presentation
- 0 NSManagedObjectContext in Views/ViewModels
- 0 Direct Service/Repository instantiation
- 32 `.toDomain()` conversions (all in Data layer)

---

## 🔍 Quick Reference Docs

**Need more context? Read in this order:**
1. `docs/START_HERE.md` ← Quick start (THIS FIRST!)
2. `docs/architecture/QUICK_START.md` ← Layer overview
3. `docs/architecture/CLEAN_ARCHITECTURE_GUIDE.md` ← Detailed patterns
4. `docs/architecture/PROJECT_STRUCTURE.md` ← File organization
5. `docs/CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md` ← What was fixed

---

## 🧪 Development Info

- **Device**: Dennis's iPhone (26.1) - `00008120-000A190218614032`
- **Framework**: SwiftUI + CoreData
- **iOS Target**: 26.1
- **Response Style**: Concise, no verbose summaries (saves tokens)

---

## 🚨 Auto-Reject Checklist

Before committing code, verify:
- [ ] No `import CoreData` in Presentation layer
- [ ] No `NSManagedObjectContext` outside Data layer
- [ ] All dependencies through `AppDIContainer`
- [ ] All ViewModels use `@MainActor`
- [ ] All CoreData ops use `context.perform { }`
- [ ] All Data→Presentation returns use `.toDomain()`

**If ANY checklist fails → REFACTOR IMMEDIATELY**

---

**Last Updated**: March 9, 2026  
**Status**: Production-Ready Clean Architecture