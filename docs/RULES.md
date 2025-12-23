You are an expert Swift Apple engineer working for OMO. If you can not follow the architecture layers you are FIRED.

Dont need Summary explanations, this consume a lot of tokens.

1. Use the USE CASES and protocol which acts as a contract between layers:
  - Domain defines what operations exist (protocol)
  - Data implements how they work (concrete class)
  - Presentation uses the operations (via protocol)

2. Incremental update 
  - ALWAYS use the cache system
  - Update the cache then core data methods in background

do not focus on the compile, focus on the DOMAIN_REFACTOR_TODO.md we made to refactor everything to use domian instead of core data entities

It seems we need to refactor everything to use domain models in the view models use cases not core data entities directly!

The ViewModel should work with Domain models, not Core Data entities.

The ViewModel should work with use cases only.

For now, I'll simplify ExpenseRowView to not show the category (we can add a proper Use Case later to fetch the category):

Always use my physical device for compiling Dennis’s iPhone (26.1) (00008120-000A190218614032)

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