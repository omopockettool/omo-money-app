# Refactor Plan: Pure Domain Architecture (Option 2)

**Created:** 2025-12-18
**Status:** Ready to implement
**Goal:** Eliminate `.toDomain()` pattern and make Services work directly with Domain models

---

## Problem Statement

Currently, the architecture has a **mixed approach** that causes Core Data faulting issues:

1. **Services** return Core Data entities (`Category`, `Item`, `ItemList`, etc.)
2. **Repositories** convert Core Data → Domain using `.toDomain()`
3. **Cached Core Data entities become faults** and lose their data when accessed outside `context.perform`

### Current Architecture Flow
```
ViewModel → Use Case → Repository → Service (returns Core Data entities)
                            ↓
                    .toDomain() conversion
                            ↓
                    Domain models returned
```

### Issues with Current Approach
- Core Data entities cached by Services become **faults** (lose data)
- `.toDomain()` conversion outside `context.perform` returns empty/nil values
- Repositories need to fetch fresh + convert inside `context.perform` to work around this
- Violates Clean Architecture: Data layer concerns leak into Repository layer

---

## Target Architecture (Pure Domain)

### New Architecture Flow
```
ViewModel → Use Case → Repository → Service (returns Domain models)
                                         ↓
                                Core Data operations internal
                                         ↓
                                Convert to Domain inside Service
```

### Benefits
- Services handle **all Core Data ↔ Domain conversion internally**
- No `.toDomain()` calls in Repository layer
- Repositories work purely with Domain models
- No faulting issues (conversion happens inside `context.perform`)
- True Clean Architecture separation

---

## Files That Need Refactoring

### 1. Service Protocols (Change return types to Domain)

#### CategoryServiceProtocol
**File:** `OMOMoney/Domain/Protocols/Services/CategoryServiceProtocol.swift`

**Current signatures:**
```swift
func getCategories(for user: User) async throws -> [Category]
func getCategories(for group: Group) async throws -> [Category]
func fetchCategory(by id: UUID) async throws -> Category?
func createCategory(...) async throws -> Category
```

**New signatures:**
```swift
func getCategories(forUserId userId: UUID) async throws -> [CategoryDomain]
func getCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain]
func fetchCategory(by id: UUID) async throws -> CategoryDomain?
func createCategory(...) async throws -> CategoryDomain
```

**Key changes:**
- Return `CategoryDomain` instead of `Category`
- Accept UUIDs instead of Core Data entities as parameters
- Remove Core Data entity exposure

---

#### ItemServiceProtocol
**File:** `OMOMoney/Domain/Protocols/Services/ItemServiceProtocol.swift`

**Current signatures:**
```swift
func getItems(for itemList: ItemList) async throws -> [Item]
func getItems(for group: Group) async throws -> [Item]
func createItem(..., itemListId: UUID) async throws -> Item
func updateItem(_ item: Item, ...) async throws
func deleteItem(_ item: Item) async throws
```

**New signatures:**
```swift
func getItems(forItemListId itemListId: UUID) async throws -> [ItemDomain]
func getItems(forGroupId groupId: UUID) async throws -> [ItemDomain]
func createItem(..., itemListId: UUID) async throws -> ItemDomain
func updateItem(itemId: UUID, ...) async throws
func deleteItem(itemId: UUID) async throws
```

---

#### ItemListServiceProtocol
**File:** `OMOMoney/Domain/Protocols/Services/ItemListServiceProtocol.swift`

**Current signatures:**
```swift
func getItemLists(for group: Group) async throws -> [ItemList]
func fetchItemList(by id: UUID) async throws -> ItemList?
func createItemList(...) async throws -> ItemList
func updateItemList(_ itemList: ItemList, ...) async throws
func deleteItemList(_ itemList: ItemList) async throws
```

**New signatures:**
```swift
func getItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain]
func fetchItemList(by id: UUID) async throws -> ItemListDomain?
func createItemList(...) async throws -> ItemListDomain
func updateItemList(itemListId: UUID, ...) async throws
func deleteItemList(itemListId: UUID) async throws
```

---

### 2. Service Implementations (Implement new Domain-first logic)

#### CategoryService
**File:** `OMOMoney/Data/Services/CategoryService.swift`

**Current implementation (lines 157-185):**
```swift
func getCategories(for group: Group) async throws -> [Category] {
    let cacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"

    // Check cache first
    if let cachedCategories: [Category] = await CacheManager.shared.getCachedData(for: cacheKey) {
        return cachedCategories
    }

    // Fetch from Core Data
    let request: NSFetchRequest<Category> = Category.fetchRequest()
    request.predicate = NSPredicate(format: "group == %@", group)
    let categories = try await fetch(request)

    // Cache the result
    await CacheManager.shared.cacheData(categories, for: cacheKey)

    return categories
}
```

**New implementation:**
```swift
func getCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
    let cacheKey = "\(CacheKeys.groupCategories).\(groupId.uuidString)"

    // Check cache first (cache Domain models, not Core Data entities)
    if let cachedCategories: [CategoryDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
        return cachedCategories
    }

    // Fetch from Core Data and convert to Domain inside context.perform
    let categoryDomains = try await context.perform {
        let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
        groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
        groupRequest.fetchLimit = 1

        guard let group = try self.context.fetch(groupRequest).first else {
            throw RepositoryError.notFound
        }

        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        categoryRequest.predicate = NSPredicate(format: "group == %@", group)
        categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        categoryRequest.returnsObjectsAsFaults = false

        let categories = try self.context.fetch(categoryRequest)

        // Convert to Domain INSIDE context.perform
        return categories.map { $0.toDomain() }
    }

    // Cache Domain models
    await CacheManager.shared.cacheData(categoryDomains, for: cacheKey)

    return categoryDomains
}
```

**Key changes:**
- Cache `[CategoryDomain]` instead of `[Category]`
- Accept `UUID` parameter instead of `Group` entity
- Convert to Domain inside `context.perform`
- Return Domain models

---

#### ItemService
**File:** `OMOMoney/Data/Services/ItemService.swift`

**Methods to refactor:**
- `getItems(for itemList: ItemList)` → `getItems(forItemListId: UUID)`
- `getItems(for group: Group)` → `getItems(forGroupId: UUID)`
- `updateItem(_ item: Item, ...)` → `updateItem(itemId: UUID, ...)`
- `deleteItem(_ item: Item)` → `deleteItem(itemId: UUID)`

**Example - getItems(forItemListId:):**
```swift
func getItems(forItemListId itemListId: UUID) async throws -> [ItemDomain] {
    let cacheKey = "\(CacheKeys.itemListItems).\(itemListId.uuidString)"

    // Check cache for Domain models
    if let cachedItems: [ItemDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
        return cachedItems
    }

    // Fetch and convert inside context.perform
    let itemDomains = try await context.perform {
        let itemListRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        itemListRequest.predicate = NSPredicate(format: "id == %@", itemListId as CVarArg)
        itemListRequest.fetchLimit = 1

        guard let itemList = try self.context.fetch(itemListRequest).first else {
            throw RepositoryError.notFound
        }

        let itemRequest: NSFetchRequest<Item> = Item.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "itemList == %@", itemList)
        itemRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        itemRequest.returnsObjectsAsFaults = false

        let items = try self.context.fetch(itemRequest)

        // Convert to Domain inside context.perform
        return items.map { $0.toDomain() }
    }

    // Cache Domain models
    await CacheManager.shared.cacheData(itemDomains, for: cacheKey)

    return itemDomains
}
```

---

#### ItemListService
**File:** `OMOMoney/Data/Services/ItemListService.swift`

**Methods to refactor:**
- `getItemLists(for group: Group)` → `getItemLists(forGroupId: UUID)`
- `updateItemList(_ itemList: ItemList, ...)` → `updateItemList(itemListId: UUID, ...)`
- `deleteItemList(_ itemList: ItemList)` → `deleteItemList(itemListId: UUID)`

---

### 3. Repository Simplification (Remove .toDomain() calls)

#### DefaultCategoryRepository
**File:** `OMOMoney/Data/Repositories/DefaultCategoryRepository.swift`

**Current implementation (lines 35-62):**
```swift
func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
    // Complex: Fetch Group, call service, convert to Domain
    let categoryDomains = try await context.perform {
        let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
        // ... fetch group ...
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        // ... fetch categories ...
        return categories.map { $0.toDomain() }
    }
    return categoryDomains
}
```

**New implementation:**
```swift
func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
    // Simple: Just call service, it returns Domain models directly
    return try await categoryService.getCategories(forGroupId: groupId)
}
```

**Key change:** Repository becomes a **thin wrapper** around Service, no more Core Data logic

---

#### DefaultItemRepository
**File:** `OMOMoney/Data/Repositories/DefaultItemRepository.swift`

**Methods to simplify:**
```swift
// Before: Complex fetching + conversion
func fetchItems(forItemListId itemListId: UUID) async throws -> [ItemDomain] {
    let itemList = try await context.perform { /* fetch ItemList */ }
    let items = try await itemService.getItems(for: itemList)
    return items.map { $0.toDomain() }
}

// After: Simple passthrough
func fetchItems(forItemListId itemListId: UUID) async throws -> [ItemDomain] {
    return try await itemService.getItems(forItemListId: itemListId)
}
```

---

#### DefaultItemListRepository
**File:** `OMOMoney/Data/Repositories/DefaultItemListRepository.swift`

**Methods to simplify:**
```swift
// Before: Fetch Group entity, pass to service, convert result
func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
    let group = try await context.perform { /* fetch group */ }
    let itemLists = try await itemListService.getItemLists(for: group)
    return itemLists.map { $0.toDomain() }
}

// After: Direct passthrough
func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
    return try await itemListService.getItemLists(forGroupId: groupId)
}
```

---

### 4. Cache Manager Updates

**File:** `OMOMoney/Data/Cache/CacheManager.swift`

**Change:** Ensure caching works with **Domain models** instead of Core Data entities.

**Current:**
```swift
// Caches Core Data entities
await CacheManager.shared.cacheData([Category], for: key)
```

**New:**
```swift
// Caches Domain models
await CacheManager.shared.cacheData([CategoryDomain], for: key)
```

**Note:** This should already work since CacheManager uses generics, but verify all cache operations use Domain types.

---

## Implementation Steps (Sequential)

### Step 1: Create Domain Models (if missing)
- Ensure `ItemDomain` exists (currently only `ItemListDomain` and `CategoryDomain`)
- Create mapping extensions if needed

### Step 2: Update Service Protocols
1. Update `CategoryServiceProtocol`
2. Update `ItemServiceProtocol`
3. Update `ItemListServiceProtocol`
4. Update `PaymentMethodServiceProtocol` (if needed)

### Step 3: Update Service Implementations
1. **CategoryService** - Implement new signatures
2. **ItemService** - Implement new signatures
3. **ItemListService** - Implement new signatures
4. Update cache types from `[Category]` to `[CategoryDomain]`, etc.

### Step 4: Simplify Repositories
1. **DefaultCategoryRepository** - Remove Core Data logic, make thin wrapper
2. **DefaultItemRepository** - Remove Core Data logic
3. **DefaultItemListRepository** - Remove Core Data logic

### Step 5: Update Use Cases (if needed)
- Verify Use Cases still compile
- Most should work unchanged since they already work with Domain models

### Step 6: Test Everything
1. Test category loading (the issue we just fixed)
2. Test item creation/deletion
3. Test ItemList creation/deletion
4. Test group deletion
5. Test cache invalidation still works

---

## Migration Strategy

### Option A: Big Bang (All at once)
- Refactor all Services at once
- Higher risk, but faster completion
- Requires extensive testing afterward

### Option B: Incremental (One entity at a time)
1. Start with **CategoryService** (smallest, just fixed)
2. Then **ItemService**
3. Then **ItemListService**
4. Finally **PaymentMethodService**
- Lower risk, can test after each step
- Takes longer but safer

**Recommendation:** Use **Option B (Incremental)** to minimize risk

---

## Expected Outcomes

### Before Refactor
```swift
// Repository
let categories = try await categoryService.getCategories(for: group)  // Returns [Category]
return categories.map { $0.toDomain() }  // ❌ Faulting issues
```

### After Refactor
```swift
// Repository
return try await categoryService.getCategories(forGroupId: groupId)  // Returns [CategoryDomain] ✅
```

### Architecture Compliance
- ✅ Services expose only Domain models
- ✅ No Core Data entities in Repository layer
- ✅ No `.toDomain()` conversions outside Service layer
- ✅ True Clean Architecture separation
- ✅ No faulting issues (conversion happens in `context.perform`)

---

## Testing Checklist

After completing refactor, verify:

- [ ] Categories display correctly in AddItemListView
- [ ] Creating ItemList with category works
- [ ] Adding items to ItemList works
- [ ] Deleting items works
- [ ] Deleting ItemLists works
- [ ] Deleting groups works
- [ ] Cache invalidation works correctly
- [ ] No Core Data faulting errors
- [ ] App performance is maintained/improved
- [ ] All existing functionality still works

---

## Notes

- Current fix (Option 1) is **working** but keeps `.toDomain()` pattern
- This refactor (Option 2) is **optional but recommended** for proper Clean Architecture
- Can be done incrementally to minimize risk
- Will prevent future Core Data faulting issues
- Makes Repositories truly thin wrappers (single responsibility)

---

## Current Status

**Today (2025-12-18):**
- ✅ Fixed immediate category faulting issue with Option 1
- ✅ Item creation bug fixed with `context.reset()`
- ✅ Categories now display correctly
- 📝 Created this plan for Option 2 refactor

**Tomorrow:**
- Start with Step 1: Create ItemDomain if missing
- Begin Step 2: Update CategoryServiceProtocol
- Follow incremental approach (Option B)
