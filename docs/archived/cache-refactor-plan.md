# Cache System Refactor Plan

## Context

During a code review of the cache architecture, two structural issues were identified:

1. **`ItemListService` caches `[ItemList]` CoreData NSManagedObjects** — the same mistake that already burned `ItemService` (it had item caching removed with a `CRITICAL FIX` comment). CoreData objects are tied to a specific context and become invalid/faulted when that context refreshes. `ItemListService` has the same risk, just hasn't crashed yet.

2. **`ItemService` has two `TODO` comments explicitly flagging this** — `getItems(for itemList:)` and `getItems(for group:)` both say `"TODO: Refactor to return ItemDomain and cache Domain models instead"`.

`CategoryService`, `PaymentMethodService`, and `GroupService` already do this correctly — they convert to domain models inside `context.perform` and cache `[CategoryDomain]`, `[PaymentMethodDomain]`, `[GroupDomain]`. These are the patterns to follow.

---

## Goal

Replace CoreData object caching with domain model caching in two services:
- `ItemListService` → cache `[ItemListDomain]` instead of `[ItemList]`
- `ItemService` → cache `[ItemDomain]` instead of removing caching entirely (resolves the TODO)

---

## Current State

### ItemListService (`Data/Services/ItemListService.swift`)
- `getItemLists(for group: Group)` caches `[ItemList]` with a custom 30-min TTL
- Cache keys: `ItemListService.groupItemLists.<groupId>` + `.timestamp`
- The `[ItemList]` objects are passed back to `DefaultItemListRepository` which calls `.toDomain()` on them

### ItemService (`Data/Services/ItemService.swift`)
- `getItems(for itemList: ItemList)` — **no caching**, fetches CoreData every call
- `getItems(for group: Group)` — **no caching**, fetches CoreData every call
- Both have `/// TODO: Refactor to return ItemDomain and cache Domain models instead`
- Item calculations (`calculateTotalAmount`) ARE cached in `calculationCache`

---

## Plan

### 1. Refactor `ItemListService.getItemLists(for group:)`

**File:** `OMOMoney/Data/Services/ItemListService.swift`

Change the cache to store `[ItemListDomain]` instead of `[ItemList]`:

```swift
// BEFORE: caches [ItemList] CoreData objects
if let cachedItemLists: [ItemList] = await CacheManager.shared.getCachedData(for: cacheKey) { ... }
await CacheManager.shared.cacheData(itemLists, for: cacheKey)
return itemLists

// AFTER: fetch CoreData, convert to domain inside context.perform, cache [ItemListDomain]
let domainItemLists: [ItemListDomain] = try await context.perform {
    let results = try self.context.fetch(request)
    return results.map { $0.toDomain() }
}
await CacheManager.shared.cacheData(domainItemLists, for: cacheKey)
await CacheManager.shared.cacheData(Date(), for: timestampKey)
return domainItemLists
```

**Return type change:** `getItemLists(for group:)` returns `[ItemListDomain]` instead of `[ItemList]`

Update `ItemListServiceProtocol`:
```swift
func getItemLists(for group: Group) async throws -> [ItemListDomain]
```

**Cascade to `DefaultItemListRepository.fetchItemLists(forGroupId:)`:**
Since the service now returns domain models, remove the `.map { $0.toDomain() }` call — it's no longer needed.

**Also update other `getItemLists` methods** that return `[ItemList]` to follow the same pattern:
- `getItemLists(for user: User)` → return `[ItemListDomain]`
- `getItemLists(for category: Category)` → return `[ItemListDomain]`
- `getItemLists(from:to:)` → return `[ItemListDomain]`

Update `ItemListServiceProtocol` signatures accordingly.

---

### 2. Refactor `ItemService.getItems(for itemList:)` and `getItems(for group:)`

**File:** `OMOMoney/Data/Services/ItemService.swift`

Add domain model caching (resolves both TODOs):

```swift
func getItems(for itemList: ItemList) async throws -> [ItemDomain] {
    let cacheKey = "\(CacheKeys.itemListItems).\(itemList.id?.uuidString ?? "nil")"

    if let cached: [ItemDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
        return cached
    }

    let domainItems: [ItemDomain] = try await context.perform {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "itemList == %@", itemList)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        request.returnsObjectsAsFaults = false
        let items = try self.context.fetch(request)
        return items.map { $0.toDomain() }
    }

    await CacheManager.shared.cacheData(domainItems, for: cacheKey)
    return domainItems
}
```

**Return type changes:**
- `getItems(for itemList: ItemList)` → `[ItemDomain]`
- `getItems(for group: Group)` → `[ItemDomain]`

Update `ItemServiceProtocol` signatures accordingly.

**Cache invalidation** — add cache clearing to existing write operations in `ItemService`:
- `createItem()` — already clears `itemListTotalAmount`; also clear `itemListItems.<itemListId>`
- `updateItem()` — already clears `itemListTotalAmount`; also clear `itemListItems.<itemListId>`
- `deleteItem()` — already clears `itemListTotalAmount`; also clear `itemListItems.<itemListId>`
- `setAllItemsPaid()` — already clears `itemListTotalAmount`; also clear `itemListItems.<itemListId>`

**Cascade to `DefaultItemRepository`:**
`fetchItems(forItemListId:)` currently does the CoreData fetch and `.toDomain()` conversion inline inside `context.perform`. Once the service caches domain models and returns them directly, simplify the repository to just call the service.

---

### 3. Remove Redundant `toDomain()` Calls

Once services return domain models:
- `DefaultItemListRepository.fetchItemLists(forGroupId:)` — remove `.map { $0.toDomain() }`
- `DefaultItemRepository.fetchItems(forItemListId:)` — remove the inline `context.perform` fetch + conversion (service handles it)

---

## Files to Touch

| File | Change |
|------|--------|
| `Data/Services/ItemListService.swift` | Cache `[ItemListDomain]`, convert inside `context.perform`, update return types |
| `Domain/Protocols/Services/ItemListServiceProtocol.swift` | Update `getItemLists` return types to `[ItemListDomain]` |
| `Data/Repositories/DefaultItemListRepository.swift` | Remove redundant `.map { $0.toDomain() }` calls |
| `Data/Services/ItemService.swift` | Add `[ItemDomain]` caching to `getItems` methods, add cache invalidation in write methods |
| `Domain/Protocols/Services/ItemServiceProtocol.swift` | Update `getItems` return types to `[ItemDomain]` |
| `Data/Repositories/DefaultItemRepository.swift` | Simplify `fetchItems(forItemListId:)` to delegate to service |

---

## What Does NOT Change

- Cache key strings — same keys, different value types stored
- TTL values — keep 30-min for ItemLists, default 5-min for Items
- `CacheManager` itself — no changes needed
- All UseCases, ViewModels, Views — untouched
- Calculation caching in `ItemService` (`calculateTotalAmount`) — already correct, leave it

---

## Verification

1. Build clean after changes
2. Launch app — all existing data loads correctly
3. Create a new ItemList → appears in dashboard immediately
4. Create items inside it → totals update correctly
5. Toggle paid on a list → icon and total update
6. Kill and relaunch → all data persists correctly (cache is in-memory only, CoreData is source of truth)
7. Switch groups → correct ItemLists shown for each group
