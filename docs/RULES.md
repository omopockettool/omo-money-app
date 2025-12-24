You are an expert Swift Apple engineer working for OMO. If you can not follow the architecture layers you are FIRED.

Dont need Summary explanations, this consume a lot of tokens.

## 1. Clean Architecture Principles (MANDATORY)

### Layer Separation Rules:
1. **Presentation Layer** (Views & ViewModels):
   - ✅ MUST use Domain models ONLY (ItemListDomain, UserDomain, etc.)
   - ✅ MUST use Use Cases for business logic
   - ❌ NEVER import CoreData
   - ❌ NEVER reference NSManagedObjectContext
   - ❌ NEVER instantiate Services or Repositories directly
   - ✅ MUST use AppDIContainer for all dependencies

2. **Domain Layer** (Use Cases & Domain Models):
   - ✅ Define business logic and operations
   - ✅ Use protocols for repository contracts
   - ❌ NEVER depend on Data layer implementations
   - ❌ NEVER import CoreData

3. **Data Layer** (Repositories & Services):
   - ✅ Use `.toDomain()` to convert Core Data entities to Domain models
   - ✅ Handle all CoreData operations
   - ✅ Return Domain models to upper layers
   - ❌ NEVER expose Core Data entities outside this layer

### Dependency Injection:
- ✅ ALL dependencies MUST go through AppDIContainer
- ✅ Views create ViewModels using DI Container
- ✅ ViewModels receive Use Cases via constructor injection
- ❌ NEVER create Services or Repositories in Views or ViewModels

### Current Status:
🎉 **COMPLETE CLEAN ARCHITECTURE REFACTOR** (Dec 24, 2025)
✅ Dashboard, AppContentView, MainView - all using DI Container
✅ ItemListDetailView/ViewModel - **NOW using Domain models only!**
✅ All ViewModels cleaned of CoreData imports
✅ Zero Core Data entities in Presentation layer
✅ All dependencies through AppDIContainer
✅ All `.toDomain()` correctly placed in Data layer (32 usages)

## 2. Incremental Update Pattern
  - ALWAYS use the cache system
  - Update the cache then core data methods in background

Always use my physical device for compiling Dennis's iPhone (26.1) (00008120-000A190218614032)

## 2. Key Technical Concepts:

- **Clean Architecture** - 5 layers: View → ViewModel → Use Case → Repository → Service
- **Domain-Driven Design** - Domain models (`ItemListDomain`) vs Core Data entities (`ItemList`)
- **Threading** - Main thread for UI only, background threads for Core Data via `context.perform()`
- **Swift Concurrency** - async/await, `withTaskGroup` for concurrent operations
- **Use Case Pattern** - Business logic layer between ViewModel and Repository
- **Repository Pattern** - Data access abstraction with `context.perform()` threading
- **Core Data** - NSManagedObjectContext, NSFetchRequest, relationship management
- **SwiftUI** - @Published properties, @MainActor, ObservableObject
- **Incremental Refactoring** - Drop-by-drop approach to maintain progress without full compilation


Check these docs if need more context:
- PROJECT_STRUCTURE.md
- ARCHITECTURE_DIAGRAMS.md 
- CLEAN_ARCHITECTURE_GUIDE.md 


read the RULES.md to get context of the project and then start reviewing the current bugs

Framework concerns stay in the Data layer where they belong.

Priority 4: Other Dependencies - currentGroup, currentUser, availableGroups - Still using Core Data entities