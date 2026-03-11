# 🎯 Quick Reference Card (for user only nor for agents)

**Print this or keep it visible during development sessions**

---

## 🚀 SESSION START (Copy-Paste This)

```
Read docs/START_HERE.md to load OMOMoney architecture context.
Then help me with: [your task]
```

**Tokens**: ~2K | **Time**: ~5s | **Cost**: ~$0.03

---

## 🔥 NEVER DO THIS (Auto-Reject)

```swift
// ❌ In Presentation Layer (Views/ViewModels)
import CoreData
@Environment(\.managedObjectContext) var context
let service = UserService()
NSFetchRequest<User>(...)
context.perform { }
```

**If you see this → REFACTOR IMMEDIATELY**

---

## ✅ ALWAYS DO THIS

```swift
// ✅ In Views
struct MyView: View {
    @StateObject private var viewModel: MyViewModel
    
    init(container: AppDIContainer) {
        _viewModel = StateObject(
            wrappedValue: container.makeMyViewModel()
        )
    }
}

// ✅ In ViewModels
@MainActor
class MyViewModel: ObservableObject {
    @Published var items: [ItemDomain] = []
    private let useCase: MyUseCase
    
    init(useCase: MyUseCase) {
        self.useCase = useCase
    }
}

// ✅ In Repositories (Data Layer)
func getItems() async throws -> [ItemDomain] {
    try await withCheckedThrowingContinuation { continuation in
        context.perform {
            let request = NSFetchRequest<Item>(entityName: "Item")
            let items = try? context.fetch(request)
            let domains = items?.map { $0.toDomain() } ?? []
            continuation.resume(returning: domains)
        }
    }
}
```

---

## 📂 Where to Put Files

```
New User Feature?
├── Domain/Entities/UserDomain.swift
├── Domain/Protocols/Repositories/UserRepository.swift
├── Domain/UseCases/User/CreateUserUseCase.swift
├── Data/Repositories/UserRepositoryImpl.swift
├── Data/Services/UserService.swift
├── Application/DIContainer/AppDIContainer.swift (add factory)
├── Presentation/Scenes/User/ViewModels/UserViewModel.swift
└── Presentation/Scenes/User/Views/UserView.swift
```

---

## 🎯 Clean Architecture Flow

```
User Tap
    ↓
View (SwiftUI)
    ↓
ViewModel (@MainActor, @Published)
    ↓
UseCase (Business Logic)
    ↓
Repository (Protocol Implementation)
    ↓
Service (CoreData Operations)
    ↓
CoreData (NSManagedObjectContext)
    ↓
.toDomain() ← Conversion happens HERE
    ↓
Domain Model (UserDomain, ItemDomain, etc.)
    ↓
Back to ViewModel (@Published triggers UI update)
```

---

## 🔍 Quick Architecture Check

Before committing code, verify:
- [ ] No `import CoreData` in `Presentation/`
- [ ] No `NSManagedObjectContext` in ViewModels
- [ ] All dependencies via `AppDIContainer`
- [ ] All ViewModels have `@MainActor`
- [ ] All CoreData ops use `context.perform { }`
- [ ] All Repository returns use `.toDomain()`

**If ANY fail → Stop and fix**

---

## 📚 Load More Context (On-Demand)

| Need | Read | Tokens |
|------|------|--------|
| Quick overview | `docs/architecture/QUICK_START.md` | +2K |
| Deep dive | `docs/architecture/CLEAN_ARCHITECTURE_GUIDE.md` | +8K |
| File locations | `docs/architecture/PROJECT_STRUCTURE.md` | +3K |
| Refactor examples | `docs/CLEAN_ARCHITECTURE_REFACTOR_SUMMARY.md` | +6K |
| Copy-paste prompts | `docs/SESSION_PROMPTS.md` | +1K |

---

## 🧪 Test Device

**Physical**: Dennis's iPhone (26.1)  
**UDID**: `00008120-000A190218614032`

---

## 💡 Common Patterns

### Incremental Update (Cache-First)
```swift
Task {
    // 1. Update cache (instant UI)
    CacheManager.shared.update(data)
    
    // 2. Persist (background)
    await repository.save(data)
}
```

### Concurrent Operations
```swift
await withTaskGroup(of: ItemDomain.self) { group in
    for id in ids {
        group.addTask {
            await repository.get(id)
        }
    }
}
```

### Threading
```swift
// UI → Main thread
@MainActor
class MyViewModel: ObservableObject { }

// CoreData → Background thread
context.perform {
    // CoreData operations here
}
```

---

## 🚨 Red Flags

If you see these patterns, **STOP IMMEDIATELY**:
1. `import CoreData` in a ViewModel
2. Creating Services/Repositories in Views
3. Passing `NSManagedObjectContext` to ViewModels
4. Core Data entities (`User`, `Item`) in Presentation
5. Direct NSFetchRequest in Views

**Fix**: Refactor using patterns from START_HERE.md

---

## 🎓 Learning Path (3-20 mins)

```
Quick Start (3 min)
    └── docs/START_HERE.md

Layer Overview (5 min)  
    └── docs/architecture/QUICK_START.md

Deep Understanding (20 min)
    └── docs/architecture/CLEAN_ARCHITECTURE_GUIDE.md

File Organization (10 min)
    └── docs/architecture/PROJECT_STRUCTURE.md
```

---

## 📝 Response Style

**Prefer**: Concise, actionable responses  
**Avoid**: Verbose summaries, long explanations  
**Why**: Token efficiency, faster development

---

**Quick Access**: Bookmark `docs/START_HERE.md`  
**Templates**: Copy from `docs/SESSION_PROMPTS.md`  
**Help**: All docs in `docs/` directory
