# 🚀 SwiftData Migration Plan

**Priority:** HIGH  
**Status:** Planning Phase  
**Estimated Effort:** 3-4 weeks  
**Target:** iOS 17.0+

---

## 📋 Executive Summary

OMOMoney currently uses **Core Data** for persistence. While Core Data is mature and stable, **SwiftData** offers significant advantages for modern Swift development:

### Why Migrate to SwiftData?

✅ **Modern Swift API** - Native Swift macros eliminate boilerplate  
✅ **Type Safety** - Compile-time checking vs runtime predicates  
✅ **Simplified Code** - ~50% less persistence code  
✅ **Better SwiftUI Integration** - `@Query` property wrapper  
✅ **Easier Testing** - In-memory containers without setup complexity  
✅ **Actor-Safe** - Built for Swift Concurrency from day one

### Current State Analysis

```swift
// Current: Core Data with Clean Architecture
PersistenceController → NSManagedObjectContext → CoreDataService → Repository → UseCase
```

**Issues:**
- Manual `NSManagedObject` subclasses
- Complex thread management with `context.perform`
- Boilerplate conversions between Core Data entities and Domain models
- Manual relationship management
- Complex migration paths

---

## 🎯 Migration Strategy

### Phase 1: Preparation (Week 1)

#### 1.1 Create SwiftData Models

Convert existing Core Data entities to SwiftData `@Model` classes:

```swift
// BEFORE: Core Data Entity + Domain Model
// User+CoreDataClass.swift (auto-generated)
// UserDomain.swift (manual mapping)

// AFTER: Single SwiftData Model
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships - automatic inverse handling
    @Relationship(deleteRule: .cascade, inverse: \UserGroup.user)
    var userGroups: [UserGroup] = []
    
    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

#### 1.2 Model Mapping Table

| Core Data Entity | SwiftData Model | Relationships | Notes |
|-----------------|-----------------|---------------|-------|
| `User` | `User` | → `UserGroup` (1:N) | Add @Attribute(.unique) on id |
| `Group` | `Group` | → `UserGroup` (1:N), → `Category` (1:N), → `PaymentMethod` (1:N), → `ItemList` (1:N) | Inverse relationships auto-managed |
| `Category` | `Category` | ← `Group` (N:1), → `ItemList` (1:N) | Color stored as String |
| `PaymentMethod` | `PaymentMethod` | ← `Group` (N:1), → `ItemList` (1:N) | isActive boolean flag |
| `ItemList` | `ItemList` | ← `Group` (N:1), ← `Category` (N:1), ← `PaymentMethod` (N:1), → `Item` (1:N) | Date is primary sort key |
| `Item` | `Item` | ← `ItemList` (N:1) | Decimal stored as Double |
| `UserGroup` | `UserGroup` | ← `User` (N:1), ← `Group` (N:1) | Junction table |

#### 1.3 Schema Version Plan

```swift
// Migration from Core Data to SwiftData
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [User.self, Group.self, Category.self, PaymentMethod.self, 
         ItemList.self, Item.self, UserGroup.self]
    }
}

// Future schema evolution
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)
    // Add new fields/models here
}

typealias OMOMoneySchema = SchemaV1
```

---

### Phase 2: Update App Structure (Week 2)

#### 2.1 Replace PersistenceController

```swift
// REMOVE: PersistenceController.swift (Core Data)
// ADD: ModelContainer+Shared.swift (SwiftData)

import SwiftData

extension ModelContainer {
    @MainActor
    static var shared: ModelContainer = {
        let schema = Schema([
            User.self,
            Group.self,
            Category.self,
            PaymentMethod.self,
            ItemList.self,
            Item.self,
            UserGroup.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic // Optional: Enable iCloud sync
        )
        
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    @MainActor
    static var preview: ModelContainer = {
        let schema = Schema([
            User.self, Group.self, Category.self,
            PaymentMethod.self, ItemList.self, Item.self, UserGroup.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try! ModelContainer(for: schema, configurations: configuration)
        
        // Add preview data
        let context = container.mainContext
        let user = User(name: "Preview User", email: "preview@example.com")
        context.insert(user)
        
        return container
    }()
}
```

#### 2.2 Update App Entry Point

```swift
// OMOMoneyApp.swift

import SwiftUI
import SwiftData

@main
struct OMOMoneyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    // ✅ SwiftData ModelContainer
    let modelContainer = ModelContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer) // ✅ Inject ModelContainer
    }
}
```

---

### Phase 3: Simplify Services Layer (Week 2-3)

#### 3.1 Eliminate Core Data Services

**Current Architecture:**
```
UseCase → Repository → CoreDataService → NSManagedObjectContext → Core Data Entity → Domain Model
```

**New Architecture:**
```
UseCase → Repository → ModelContext → SwiftData Model (IS the Domain Model)
```

#### 3.2 Refactor Repositories

```swift
// BEFORE: UserRepository with Core Data
class UserRepository {
    private let service: UserServiceProtocol
    
    func getUser(byId id: UUID) async throws -> UserDomain? {
        return try await service.getUser(byId: id)
    }
}

// AFTER: UserRepository with SwiftData
actor UserRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getUser(byId id: UUID) async throws -> User? {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func createUser(name: String, email: String) async throws -> User {
        let user = User(name: name, email: email)
        modelContext.insert(user)
        try modelContext.save()
        return user
    }
}
```

#### 3.3 Remove Domain Model Duplicates

**DELETE these files** (SwiftData models replace them):
- `UserDomain.swift`
- `GroupDomain.swift`
- `CategoryDomain.swift`
- `PaymentMethodDomain.swift`
- `ItemListDomain.swift`
- `ItemDomain.swift`

**Why?** SwiftData models ARE domain models - no conversion needed!

---

### Phase 4: Update ViewModels (Week 3)

#### 4.1 Use @Query Property Wrapper in Views

```swift
// BEFORE: ViewModel fetches and publishes data
struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    
    var body: some View {
        List(viewModel.itemLists) { itemList in
            // ...
        }
        .task {
            await viewModel.loadDashboardData()
        }
    }
}

// AFTER: Direct @Query in View
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    // ✅ Automatic data fetching with type-safe predicates
    @Query(
        filter: #Predicate<ItemList> { itemList in
            itemList.group.id == selectedGroupId
        },
        sort: \ItemList.date,
        order: .reverse
    )
    private var itemLists: [ItemList]
    
    var body: some View {
        List(itemLists) { itemList in
            ItemListRow(itemList: itemList)
        }
    }
}
```

#### 4.2 Simplify DashboardViewModel

```swift
// BEFORE: 946 lines, complex caching, manual total calculation
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var itemLists: [ItemListDomain] = []
    @Published var totalSpent: Double = 0.0
    // ... 50+ properties
    
    func loadDashboardData() async {
        // ... 100+ lines of fetching/converting
    }
    
    func calculateTotalSpent() async {
        // ... 50+ lines of calculation
    }
}

// AFTER: Minimal ViewModel, @Query handles data
@MainActor
class DashboardViewModel: ObservableObject {
    func deleteItemList(_ itemList: ItemList, from context: ModelContext) {
        context.delete(itemList)
        try? context.save()
    }
    
    func totalSpent(for itemLists: [ItemList]) -> Double {
        itemLists.reduce(0.0) { total, list in
            total + list.items.reduce(0.0) { $0 + (Double($1.amount) * Double($1.quantity)) }
        }
    }
}
```

---

### Phase 5: Testing & Migration (Week 4)

#### 5.1 Create Migration Tests

```swift
import Testing
import SwiftData

@Suite("SwiftData Migration Tests")
struct MigrationTests {
    
    @Test("User model creation")
    func testUserCreation() async throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        
        let user = User(name: "Test User", email: "test@example.com")
        context.insert(user)
        
        let descriptor = FetchDescriptor<User>()
        let users = try context.fetch(descriptor)
        
        #expect(users.count == 1)
        #expect(users.first?.name == "Test User")
    }
    
    @Test("Relationship integrity")
    func testRelationships() async throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        
        let user = User(name: "Test", email: "test@example.com")
        let group = Group(name: "Family", currency: "USD", user: user)
        
        context.insert(user)
        context.insert(group)
        
        #expect(user.userGroups.count == 1)
        #expect(group.userGroups.first?.user === user)
    }
}
```

#### 5.2 Data Migration Script

```swift
// CoreDataToSwiftDataMigrator.swift

import CoreData
import SwiftData

@MainActor
final class CoreDataToSwiftDataMigrator {
    
    func migrate() async throws {
        print("🔄 Starting Core Data → SwiftData migration...")
        
        let coreDataContext = PersistenceController.shared.container.viewContext
        let swiftDataContext = ModelContainer.shared.mainContext
        
        // 1. Migrate Users
        try await migrateUsers(from: coreDataContext, to: swiftDataContext)
        
        // 2. Migrate Groups
        try await migrateGroups(from: coreDataContext, to: swiftDataContext)
        
        // 3. Migrate Categories
        try await migrateCategories(from: coreDataContext, to: swiftDataContext)
        
        // 4. Migrate PaymentMethods
        try await migratePaymentMethods(from: coreDataContext, to: swiftDataContext)
        
        // 5. Migrate ItemLists
        try await migrateItemLists(from: coreDataContext, to: swiftDataContext)
        
        // 6. Migrate Items
        try await migrateItems(from: coreDataContext, to: swiftDataContext)
        
        try swiftDataContext.save()
        
        print("✅ Migration complete!")
    }
    
    private func migrateUsers(from coreData: NSManagedObjectContext, 
                             to swiftData: ModelContext) async throws {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        let coreDataUsers = try coreData.fetch(request)
        
        for cdUser in coreDataUsers {
            let user = User(
                id: cdUser.id ?? UUID(),
                name: cdUser.name ?? "",
                email: cdUser.email ?? ""
            )
            user.createdAt = cdUser.createdAt ?? Date()
            user.updatedAt = cdUser.updatedAt ?? Date()
            
            swiftData.insert(user)
        }
        
        print("✅ Migrated \(coreDataUsers.count) users")
    }
    
    // ... similar methods for other entities
}
```

---

## 🎁 Benefits After Migration

### Code Reduction

| File | Before (LOC) | After (LOC) | Reduction |
|------|--------------|-------------|-----------|
| `CategoryService.swift` | 466 | ~150 | 68% ↓ |
| `ItemListService.swift` | 332 | ~100 | 70% ↓ |
| `DashboardViewModel.swift` | 946 | ~300 | 68% ↓ |
| Domain Models (7 files) | ~500 | **DELETED** | 100% ↓ |
| **Total** | **~2,244** | **~550** | **75% ↓** |

### Performance Improvements

- ⚡️ **No Context Switching** - No more `context.perform` blocks
- 🎯 **Type-Safe Queries** - Compile-time predicate validation
- 💾 **Optimized Fetching** - SwiftData automatically batches
- 🧵 **Actor-Safe** - Built-in thread safety

### Developer Experience

- ✅ **Less Boilerplate** - No manual NSManagedObject subclasses
- ✅ **Easier Testing** - In-memory containers without complex setup
- ✅ **Better Previews** - `ModelContainer.preview` for SwiftUI previews
- ✅ **iCloud Sync** - Enable with one line: `.cloudKitDatabase(.automatic)`

---

## ⚠️ Risks & Mitigation

### Risk 1: Data Loss During Migration

**Mitigation:**
- Create full backup before migration
- Test migration on clone database first
- Implement rollback mechanism
- Keep Core Data stack until migration verified

### Risk 2: Breaking Changes in Production

**Mitigation:**
- Use feature flags to enable SwiftData gradually
- A/B test with subset of users
- Monitor crash reports closely
- Keep Core Data as fallback for 2 releases

### Risk 3: Third-Party Library Compatibility

**Mitigation:**
- Audit dependencies for Core Data usage
- Update or replace incompatible libraries
- Create adapter layer if needed

---

## 📅 Timeline & Milestones

| Week | Milestone | Deliverable |
|------|-----------|-------------|
| 1 | Model Creation | All SwiftData models defined |
| 2 | App Integration | ModelContainer injected, old persistence removed |
| 3 | ViewModels Updated | Using @Query and simplified logic |
| 4 | Testing & Migration | All tests passing, migration script complete |

---

## ✅ Success Criteria

- [ ] All Core Data entities converted to SwiftData models
- [ ] App builds and runs with SwiftData
- [ ] All existing features work identically
- [ ] Migration script successfully transfers test data
- [ ] Code coverage remains ≥ current level
- [ ] Performance metrics improved or equal
- [ ] No data loss in production migration
- [ ] Documentation updated

---

## 📚 References

- [SwiftData Documentation](https://developer.apple.com/documentation/SwiftData)
- [Migrating from Core Data to SwiftData](https://developer.apple.com/documentation/SwiftData/migrating-from-core-data-to-swiftdata)
- [Model Your Schema with SwiftData](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [Adopting Class Inheritance in SwiftData](https://developer.apple.com/documentation/SwiftData/Adopting-inheritance-in-SwiftData)

---

**Next Steps:**
1. Review this plan with team
2. Create backup strategy
3. Set up feature flag for gradual rollout
4. Begin Phase 1: Model creation

**Document Version:** 1.0  
**Last Updated:** April 15, 2026  
**Author:** AI Assistant
