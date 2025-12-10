# Domain ViewModel Refactor TODO

**Goal:** Migrate DashboardViewModel from Core Data entities to Domain models (Clean Architecture)

**Status:** In Progress - `addItemListFromDomain` completed ✅

---

## ✅ Completed

### 1. Fix `addItemListFromDomain` - Clean Architecture
- **File:** `DashboardViewModel.swift` (lines 658-689)
- **Status:** ✅ DONE
- **Changes:**
  - Removed `context.perform()` calls
  - Works purely with Domain models
  - No more Core Data knowledge in this method
  - Uses only Use Cases (proper layering)

### 2. Update Published Properties to Domain Models
- **File:** `DashboardViewModel.swift` (lines 16-23)
- **Status:** ✅ DONE
- **Changes:**
  - `@Published var itemLists: [ItemListDomain]` (was `[ItemList]`)
  - `@Published var currentMonthItemLists: [ItemListDomain]` (was `[ItemList]`)

### 3. Add FetchItemsUseCase Dependency
- **File:** `DashboardViewModel.swift` (lines 33-39, 46-64)
- **Status:** ✅ DONE
- **Changes:**
  - Added `fetchItemsUseCase: FetchItemsUseCase` property
  - Updated init to inject FetchItemsUseCase
  - Updated DashboardView DI setup

### 4. Update View Components for Domain Models
- **Files:** `ExpenseListView.swift`, `ExpenseRowView.swift`
- **Status:** ✅ DONE
- **Changes:**
  - Changed `itemLists` parameter from `[ItemList]` to `[ItemListDomain]`
  - Changed ForEach ID from `.objectID` to `.id`
  - Removed `?.` optional chaining on Domain model properties (they're not optional)
  - Updated previews to use `ItemListDomain`

### 5. Update Navigation for Domain Models
- **File:** `DashboardView.swift` (line 120)
- **Status:** ✅ DONE (temporary solution)
- **Changes:**
  - Changed `.navigationDestination(for: ItemListDomain.self)`
  - Uses `.toCoreData()` conversion for now (TODO: refactor ItemListDetailView)

### 6. Create async `getItemListTotal(ItemListDomain)`
- **File:** `DashboardViewModel.swift` (lines 1106-1140)
- **Status:** ✅ DONE
- **Changes:**
  - Async method that fetches items via `fetchItemsUseCase`
  - Calculates total from `[ItemDomain]`
  - No Core Data knowledge - pure Clean Architecture!
  - Proper error handling

### 7. Create async `getFormattedItemListTotal(ItemListDomain)`
- **File:** `DashboardViewModel.swift` (lines 1142-1158)
- **Status:** ✅ DONE
- **Changes:**
  - Async method that calls `getItemListTotal()`
  - Formats with currency
  - No Core Data knowledge - pure Clean Architecture!

### 8. Refactor `calculateTotalSpent()` - Async + Concurrent
- **File:** `DashboardViewModel.swift` (lines 965-1005)
- **Status:** ✅ DONE
- **Changes:**
  - Now async, works with `[ItemListDomain]`
  - Uses `withTaskGroup` for **concurrent** total calculation (major performance boost!)
  - Calls async `getItemListTotal()` for each ItemList
  - All 9 call sites updated with `await`
  - No more Core Data `.items` relationship access
  - Pure Clean Architecture!

### 9. `loadDashboardData()` - Lines 77-193
- **File:** `DashboardViewModel.swift`
- **Status:** ✅ DONE
- **Changes:**
  - Uses `fetchItemListsUseCase.execute()` to get Domain models
  - Assigns `itemListDomains` directly to `itemLists` (no Core Data fetch)
  - Removed unnecessary Core Data entity fetching

### 10. `refreshData()` - Lines 195-270
- **File:** `DashboardViewModel.swift`
- **Status:** ✅ DONE
- **Changes:**
  - Refactored to work with `[ItemListDomain]`
  - Uses `.id` instead of `.objectID` for comparison
  - Removed Core Data fetch, uses Use Case result directly

---

## 🔄 Session 2 Completed (2025-12-10) - DashboardViewModel CRUD Operations

### Priority 2: CRUD Operations - COMPLETED

#### 7. `deleteItemListDomain()` - NEW METHOD
- **File:** `DashboardViewModel.swift` (lines 1156-1183)
- **Status:** ✅ DONE
- **Changes:**
  - Created new async Domain method
  - Uses `deleteItemListUseCase.execute(id:)` directly
  - Optimistic UI updates with rollback on error
  - No Core Data knowledge

#### 8. `removeItemListDomain()` - NEW METHOD
- **File:** `DashboardViewModel.swift` (lines 1185-1220)
- **Status:** ✅ DONE
- **Changes:**
  - Private helper for removing from UI cache
  - Works with Domain models only
  - Uses `.id` for comparison instead of `.objectID`
  - Recalculates totals after removal (following RULES)

#### 9. `updateItemListDomain()` - NEW METHOD
- **File:** `DashboardViewModel.swift` (lines 1222-1257)
- **Status:** ✅ DONE
- **Changes:**
  - Update ItemList in UI cache
  - Works with Domain models only
  - Re-sorts list after update
  - Recalculates totals after update (following RULES)

### Priority 3: Helper Methods - COMPLETED

#### 10. `isItemListInCurrentContext(ItemListDomain)` - NEW METHOD
- **File:** `DashboardViewModel.swift` (lines 1259-1268)
- **Status:** ✅ DONE
- **Changes:**
  - Domain version created
  - Compares `itemListDomain.groupId` with `currentGroup?.id`
  - No Core Data entity access

#### 11. `getCurrentMonthItemLists()` - NEW METHOD
- **File:** `DashboardViewModel.swift` (lines 1270-1279)
- **Status:** ✅ DONE
- **Changes:**
  - Return type changed to `[ItemListDomain]`
  - Filters `itemLists` (already Domain type)
  - Works perfectly with Domain models

### View Layer Updates - COMPLETED

#### 12. DashboardView - Delete Action
- **File:** `DashboardView.swift` (line 222)
- **Status:** ✅ DONE
- **Changes:**
  - Changed from `deleteItemList(itemList)` to `deleteItemListDomain(itemListDomain)`
  - Removed `.toCoreData()` conversion
  - Clean Architecture: View → ViewModel → Use Case

---

## 🔄 Session 3 Completed (2025-12-10) - ItemListDetailViewModel Domain Refactor

### Item CRUD Operations - COMPLETED ✅

#### 1. ItemListDetailViewModel - Domain Migration
- **Files:** `ItemListDetailViewModel.swift`, `ItemListDetailView.swift`, `AddItemViewModel.swift`
- **Status:** ✅ DONE
- **Changes:**
  - Changed `@Published var items` from `[Item]` to `[ItemDomain]`
  - Refactored `loadItems()` to use Domain models directly via Use Case
  - Refactored `addItemFromDomain()` - works with Domain models only
  - Refactored `updateItemFromDomain()` - works with Domain models only
  - Refactored `deleteItem()` - accepts ItemDomain parameter
  - Fixed `getFormattedTotal()` to use Decimal operators instead of NSDecimalNumber
  - Fixed `getFormattedAmount()` to use Decimal operators
  - Updated `ItemSheetMode` enum to use `ItemDomain` instead of `Item`
  - Changed ForEach ID from `.objectID` to `.id`

#### 2. ItemRowView Component - Domain Support
- **File:** `ItemListDetailView.swift` (lines 236-282)
- **Status:** ✅ DONE
- **Changes:**
  - Changed `item` parameter from `Item` to `ItemDomain`
  - Removed optional chaining on `itemDescription` (non-optional in Domain)
  - Component now fully Domain-aware

#### 3. AddItemView & AddItemViewModel - Domain Support
- **Files:** `AddItemViewModel.swift`, `ItemListDetailView.swift`
- **Status:** ✅ DONE
- **Changes:**
  - Changed `itemToEdit` parameter from `Item?` to `ItemDomain?`
  - Updated pre-population logic to use Domain model properties
  - Fixed `saveItem()` to handle Domain model IDs (non-optional)
  - AddItemView init now accepts `ItemDomain?` for editing

#### 4. Build Status
- **Status:** ✅ BUILD SUCCEEDED
- **Device:** Dennis's iPhone (00008120-000A190218614032)
- **Result:** All compilation errors fixed, clean build

---

## ⏳ TODO: Remaining Work

### Priority 1: Deprecated Methods Cleanup

#### OLD METHODS TO DEPRECATE OR REMOVE:

#### 7. `removeItemList()` - Line 758
**Current:** Expects Core Data `ItemList`, uses `.objectID`
**Needs:**
- Create `removeItemListDomain(_ itemListDomain: ItemListDomain)`
- Compare by `.id` instead of `.objectID`
- **Files to modify:**
  - `DashboardViewModel.swift:758-806`

#### 8. `deleteItemList()` - Line 808
**Current:** Expects Core Data `ItemList`
**Needs:**
- Create `deleteItemListDomain(_ itemListDomain: ItemListDomain)`
- Use `deleteItemListUseCase.execute(id: itemListDomain.id)` directly
- **Files to modify:**
  - `DashboardViewModel.swift:808-843`
  - `DashboardView.swift:218-223` (remove `.toCoreData()` conversion)

#### 9. `updateItemList()` - Line 845
**Current:** Expects Core Data `ItemList`, uses `.objectID`
**Needs:**
- Create `updateItemListDomain(_ itemListDomain: ItemListDomain)`
- Use Use Case for update
- **Files to modify:**
  - `DashboardViewModel.swift:845-886`

---

### Priority 3: Helper Methods

#### 10. `updateTotalSpentForItemList()` - Line 912
**Current:** Takes Core Data `ItemList`, accesses `.items` relationship
**Needs:**
- Create async version with `ItemListDomain`
- Fetch items via Use Case
- **New method signature:**
  ```swift
  private func updateTotalSpentForItemList(_ itemListDomain: ItemListDomain, operation: TotalSpentOperation) async
  ```
- **Files to modify:**
  - `DashboardViewModel.swift:912-949`

#### 11. `isItemListInCurrentContext()` - Line 951
**Current:** Takes Core Data `ItemList`, checks `groupId`
**Needs:**
- Change parameter to `ItemListDomain`
- Compare `itemListDomain.groupId` with `currentGroup?.id`
- **Files to modify:**
  - `DashboardViewModel.swift:951-963`

#### 12. `getCurrentMonthItemLists()` - Line 1027
**Current:** Returns `[ItemList]`
**Needs:**
- Change return type to `[ItemListDomain]`
- Should work as-is since `itemLists` is now `[ItemListDomain]`
- **Files to modify:**
  - `DashboardViewModel.swift:1027-1054`

---

### Priority 4: Other Dependencies

#### 13. `currentGroup` Property - Line 29
**Current:** `Group?` (Core Data entity)
**Needs:**
- Change to `GroupDomain?`
- Update all references to use Domain model
- Create `GroupDomain` if it doesn't exist
- **Files to modify:**
  - `DashboardViewModel.swift:29`
  - All references throughout ViewModel (~20+ places)

#### 14. `currentUser` Property - Line 30
**Current:** `User?` (Core Data entity)
**Needs:**
- Change to `UserDomain?`
- Update all references
- Create `UserDomain` if it doesn't exist
- **Files to modify:**
  - `DashboardViewModel.swift:30`
  - All references throughout ViewModel

#### 15. `availableGroups` Property - Line 31
**Current:** `[Group]` (Core Data)
**Needs:**
- Change to `[GroupDomain]`
- Update group picker logic
- **Files to modify:**
  - `DashboardViewModel.swift:31`
  - Group selection UI

---

## 📋 Domain Models to Create/Verify

### Required Domain Models

1. ✅ **ItemListDomain** - EXISTS
   - Location: `Domain/Entities/ItemListDomain.swift`
   - Properties: id, itemListDescription, date, categoryId, paymentMethodId, groupId, createdAt, lastModifiedAt

2. ✅ **ItemDomain** - EXISTS
   - Location: `Domain/Entities/ItemDomain.swift`
   - Properties: id, itemDescription, amount, quantity, itemListId, createdAt, lastModifiedAt

3. ❓ **GroupDomain** - CHECK IF EXISTS
   - Needs: id, name, currency, createdAt, lastModifiedAt
   - Location: `Domain/Entities/GroupDomain.swift`

4. ❓ **UserDomain** - CHECK IF EXISTS
   - Needs: id, username, email, createdAt, lastModifiedAt
   - Location: `Domain/Entities/UserDomain.swift`

5. ❓ **CategoryDomain** - CHECK IF EXISTS
   - Needs: id, name, color, groupId
   - Location: `Domain/Entities/CategoryDomain.swift`

6. ❓ **PaymentMethodDomain** - CHECK IF EXISTS
   - Needs: id, name, isActive, groupId
   - Location: `Domain/Entities/PaymentMethodDomain.swift`

---

## 🔧 View Layer Updates

### Views That Need Domain Model Support

#### 1. ItemListDetailView
**Current:** Expects Core Data `ItemList`
**Location:** `Presentation/Scenes/ItemList/ItemListDetailView.swift`
**Needs:**
- Accept `ItemListDomain` parameter
- Fetch items via Use Case
- Remove Core Data context dependency

#### 2. ExpenseRowView - Category Display
**Current:** Returns `nil` for category (Domain model only has categoryId)
**Location:** `ExpenseRowView.swift:64-66`
**Needs:**
- Add Use Case to fetch Category by ID
- Display category color/name
- OR: Enhance ItemListDomain to include category name/color (denormalized)

---

## 📐 Architecture Decisions Needed

### 1. Category Display Strategy
**Options:**
- A) Fetch category separately via Use Case (pure Domain)
- B) Denormalize: Add `categoryName`, `categoryColor` to ItemListDomain (performance)
- **Recommendation:** Option A for now (pure), optimize later if needed

### 2. Total Calculation Strategy
**Options:**
- A) Fetch items every time (current approach, accurate)
- B) Cache item totals in ItemListDomain (denormalized, faster)
- **Recommendation:** Option A, then measure performance

### 3. Navigation Strategy
**Options:**
- A) Keep temporary `.toCoreData()` conversion until ItemListDetailView refactored
- B) Refactor ItemListDetailView immediately to accept Domain models
- **Recommendation:** Option A (incremental)

---

## 🎯 Suggested Implementation Order

### Session 1: Core Display (Tomorrow)
1. ✅ `addItemListFromDomain` (DONE)
2. `getItemListTotal` → async Domain version
3. `getFormattedItemListTotal` → async Domain version
4. `calculateTotalSpent` → use async totals
5. Test: Create ItemList with price, verify total shows correctly

### Session 2: Data Loading
6. `loadDashboardData` → use Use Cases only
7. `updateCurrentMonthCache` → verify works with Domain
8. Test: Pull to refresh, verify data loads correctly

### Session 3: CRUD Operations
9. `deleteItemListDomain` → new method
10. `removeItemListDomain` → new method
11. `updateItemListDomain` → new method
12. Remove deprecated `addItemList`, `deleteItemList`, etc.

### Session 4: Polish & Cleanup
13. Remove all `context` references from ViewModel
14. Remove all `.objectID` usages
15. Update `currentGroup`, `currentUser` to Domain models
16. Full integration test

---

## 🧪 Testing Checklist

After each session, verify:
- [ ] Create ItemList with price field → total shows correctly
- [ ] Create ItemList without price → total shows 0,00 €
- [ ] Delete ItemList → UI updates, no crashes
- [ ] Edit ItemList → changes persist
- [ ] Pull to refresh → data reloads
- [ ] Switch groups → correct data shows
- [ ] Navigate to ItemListDetail → works correctly
- [ ] No `context.perform()` calls in ViewModel
- [ ] No Core Data imports in ViewModel (except temporarily for `context` property)

---

## 📝 Notes

- **Keep `context` property temporarily** for `.toCoreData()` conversions in navigation
- **Remove `context` property last** after all views support Domain models
- **Each commit should compile** (or at least have clear TODO comments)
- **Test after each method refactor** to catch regressions early
- **Document technical debt** with TODO comments

---

## 🚀 Final Goal

**DashboardViewModel should:**
- ✅ Store only Domain models (`[ItemListDomain]`, `GroupDomain?`, etc.)
- ✅ Use only Use Cases (no direct Repository/Service access)
- ✅ Have NO `context.perform()` calls
- ✅ Have NO Core Data entity knowledge
- ✅ Be 100% testable with mock Use Cases
- ✅ Follow Clean Architecture perfectly

**When complete, DashboardViewModel will be a pure presentation layer with perfect separation of concerns! 🎉**
