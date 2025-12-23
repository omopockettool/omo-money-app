import CoreData
import Foundation

/// Service class for Item entity operations
/// Handles all CRUD operations for Item with proper threading and caching
class ItemService: CoreDataService, ItemServiceProtocol {
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let itemListItems = "ItemService.itemListItems"
        static let groupItems = "ItemService.groupItems"
        static let itemListTotalAmount = "ItemService.itemListTotalAmount"
        static let groupTotalAmount = "ItemService.groupTotalAmount"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Item CRUD Operations

    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item? {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, itemListId: UUID) async throws -> Item {
        print("🔵 [CREATE-ITEM] ========================================")
        print("🔵 [CREATE-ITEM] START - Creating new item")
        print("🔵 [CREATE-ITEM] Description: '\(description ?? "nil")'")
        print("🔵 [CREATE-ITEM] Amount: \(amount)")
        print("🔵 [CREATE-ITEM] Quantity: \(quantity)")
        print("🔵 [CREATE-ITEM] ItemListId: \(itemListId.uuidString)")

        // ✅ SIMPLE FIX: Accept itemListId directly, fetch ItemList in OUR context
        let (item, groupId, itemListDescription, itemId) = try await context.perform {
            print("🔵 [CREATE-ITEM] Inside context.perform - fetching ItemList...")

            // Fetch the ItemList in THIS context to access relationships
            let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", itemListId as CVarArg)
            request.fetchLimit = 1
            // ✅ Force fetch from database with all relationships, don't use faulted objects
            request.returnsObjectsAsFaults = false
            request.relationshipKeyPathsForPrefetching = ["items"]

            guard let itemListInContext = try self.context.fetch(request).first else {
                print("❌ [CREATE-ITEM] ERROR - ItemList not found with ID: \(itemListId.uuidString)")
                throw NSError(domain: "ItemService", code: 2, userInfo: [NSLocalizedDescriptionKey: "ItemList not found"])
            }

            print("✅ [CREATE-ITEM] ItemList found: '\(itemListInContext.itemListDescription ?? "nil")'")
            print("🔵 [CREATE-ITEM] ItemList has \(itemListInContext.items?.count ?? 0) items currently")

            // ✅ Log existing items to verify we see previous saves
            if let existingItems = itemListInContext.items?.allObjects as? [Item] {
                print("🔵 [CREATE-ITEM] Existing items in ItemList:")
                for (index, existingItem) in existingItems.enumerated() {
                    print("   \(index + 1). \(existingItem.itemDescription ?? "nil") - \(existingItem.amount ?? 0)")
                }
            } else {
                print("🔵 [CREATE-ITEM] No existing items (new ItemList)")
            }

            let item = Item(context: self.context)
            item.id = UUID()
            item.itemDescription = description
            item.amount = amount
            item.quantity = quantity
            item.itemList = itemListInContext
            item.createdAt = Date()

            print("🔵 [CREATE-ITEM] Item object created with ID: \(item.id?.uuidString ?? "nil")")
            print("🔵 [CREATE-ITEM] About to save context...")

            try self.context.save()

            print("✅ [CREATE-ITEM] Context saved successfully!")
            print("🔵 [CREATE-ITEM] ItemList now has \(itemListInContext.items?.count ?? 0) items")

            // ✅ FIX: Use groupId attribute directly instead of accessing relationship
            // This avoids Core Data faulting issues with relationships
            let groupId = itemListInContext.groupId
            let itemListDescription = itemListInContext.itemListDescription
            let itemId = item.id

            print("🔵 [CREATE-ITEM] GroupId: \(groupId?.uuidString ?? "nil")")
            print("🔵 [CREATE-ITEM] Returning from context.perform...")

            return (item, groupId, itemListDescription, itemId)
        }

        print("✅ [CREATE-ITEM] Back from context.perform")
        print("🔵 [CREATE-ITEM] Item persisted with ID: \(itemId?.uuidString ?? "nil")")

        // ✅ BUG FIX: Invalidate calculation caches (ItemList totals and Group totals)
        // NOTE: Item data caches removed - Core Data objects cannot be safely cached
        print("🔵 [CREATE-ITEM] ----------------------------------------")
        print("🔵 [CREATE-ITEM] Starting cache invalidation...")

        // Invalidate ItemList calculation caches
        let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"

        print("🗑️ [CREATE-ITEM] Clearing ItemList total cache: '\(itemListTotalCacheKey)'")
        await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)
        print("✅ [CREATE-ITEM] ItemList total cache cleared")

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            print("🔵 [CREATE-ITEM] ItemList belongs to group: \(groupId.uuidString)")

            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"

            print("🗑️ [CREATE-ITEM] Clearing group total cache: '\(groupTotalCacheKey)'")
            await CacheManager.shared.clearCalculationCache(for: groupTotalCacheKey)
            print("✅ [CREATE-ITEM] Group total cache cleared")

            // ✅ CRITICAL: Also invalidate ItemListService cache for the group
            let itemListServiceCacheKey = "ItemListService.groupItemLists.\(groupId.uuidString)"
            let itemListServiceTimestampKey = "\(itemListServiceCacheKey).timestamp"

            print("🗑️ [CREATE-ITEM] Clearing ItemListService cache: '\(itemListServiceCacheKey)'")
            await CacheManager.shared.clearDataCache(for: itemListServiceCacheKey)
            print("✅ [CREATE-ITEM] ItemListService cache cleared")

            print("🗑️ [CREATE-ITEM] Clearing ItemListService timestamp: '\(itemListServiceTimestampKey)'")
            await CacheManager.shared.clearDataCache(for: itemListServiceTimestampKey)
            print("✅ [CREATE-ITEM] ItemListService timestamp cleared")

            print("✅ [CREATE-ITEM] All caches invalidated for ItemList '\(itemListDescription ?? "Unknown")' and Group")
        } else {
            print("⚠️ [CREATE-ITEM] WARNING - ItemList '\(itemListDescription ?? "Unknown")' has no group! Cache invalidation incomplete.")
        }

        print("🔵 [CREATE-ITEM] ========================================")
        print("✅ [CREATE-ITEM] COMPLETE - Item created successfully")
        print("🔵 [CREATE-ITEM] ========================================")

        return item
    }
    
    /// Update an existing item
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data object
    func updateItem(itemId: UUID, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws {
        // ✅ CRITICAL FIX: Fetch item by ID INSIDE context.perform to ensure thread safety
        let (itemListId, groupId) = try await context.perform {
            let request: NSFetchRequest<Item> = Item.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
            request.fetchLimit = 1

            guard let item = try self.context.fetch(request).first else {
                throw NSError(domain: "ItemService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
            }

            if let description = description {
                item.itemDescription = description
            }
            if let amount = amount {
                item.amount = amount
            }
            if let quantity = quantity {
                item.quantity = quantity
            }
            // Item doesn't have updatedAt, using createdAt instead

            try self.context.save()

            // ✅ FIX: Use attributes directly instead of accessing relationships
            // This avoids Core Data faulting issues
            let itemListId = item.itemList?.id
            let groupId = item.itemList?.groupId  // Use attribute instead of relationship
            return (itemListId, groupId)
        }

        // ✅ CRITICAL FIX: Invalidate only calculation caches, not item data caches
        // NOTE: Item data caches removed - Core Data objects cannot be safely cached

        // Invalidate ItemList calculation caches
        if let itemListId = itemListId {
            let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"
            await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)
        }

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"
            await CacheManager.shared.clearCalculationCache(for: groupTotalCacheKey)

            // ✅ CRITICAL: Also invalidate ItemListService cache for the group
            let itemListServiceCacheKey = "ItemListService.groupItemLists.\(groupId.uuidString)"
            let itemListServiceTimestampKey = "\(itemListServiceCacheKey).timestamp"
            await CacheManager.shared.clearDataCache(for: itemListServiceCacheKey)
            await CacheManager.shared.clearDataCache(for: itemListServiceTimestampKey)

            print("🗑️ ItemService: Cache invalidated for ItemList and Group (including ItemListService) after item update")
        } else {
            print("🗑️ ItemService: Cache invalidated for ItemList after item update")
        }
    }
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws {
        // ✅ CRITICAL: Get itemList and groupId INSIDE context.perform to access Core Data relationships
        let (itemListId, groupId) = await context.perform {
            // Get IDs while we're in the correct context, before deleting
            let itemListId = item.itemList?.id
            let groupId = item.itemList?.groupId  // ✅ Use attribute instead of relationship
            return (itemListId, groupId)
        }

        await delete(item)
        try await save()

        // ✅ CRITICAL FIX: Invalidate only calculation caches, not item data caches
        // NOTE: Item data caches removed - Core Data objects cannot be safely cached

        // Invalidate ItemList calculation caches
        if let itemListId = itemListId {
            let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"
            await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)
        }

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"
            await CacheManager.shared.clearCalculationCache(for: groupTotalCacheKey)

            // ✅ CRITICAL: Also invalidate ItemListService cache for the group
            let itemListServiceCacheKey = "ItemListService.groupItemLists.\(groupId.uuidString)"
            let itemListServiceTimestampKey = "\(itemListServiceCacheKey).timestamp"
            await CacheManager.shared.clearDataCache(for: itemListServiceCacheKey)
            await CacheManager.shared.clearDataCache(for: itemListServiceTimestampKey)

            print("🗑️ ItemService: Cache invalidated for ItemList and Group (including ItemListService) after item deletion")
        } else {
            print("🗑️ ItemService: Cache invalidated for ItemList after item deletion")
        }
    }
    
    /// Get items for a specific itemList
    /// ⚠️ CRITICAL FIX: Removed caching of Core Data objects - they become invalid when contexts refresh
    /// TODO: Refactor to return ItemDomain and cache Domain models instead
    func getItems(for itemList: ItemList) async throws -> [Item] {
        print("🟣 [GET-ITEMS] ========================================")
        print("🟣 [GET-ITEMS] Getting items for ItemList: '\(itemList.itemListDescription ?? "nil")'")
        print("🟣 [GET-ITEMS] ItemList ID: \(itemList.id?.uuidString ?? "nil")")
        print("⚪️ [GET-ITEMS] Fetching from Core Data (caching disabled for Core Data objects)...")

        // Fetch from Core Data - DO NOT CACHE Core Data objects
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "itemList == %@", itemList)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        request.returnsObjectsAsFaults = false  // Force full object load
        let items = try await fetch(request)

        print("💾 [GET-ITEMS] ✅ DATABASE FETCH complete")
        print("💾 [GET-ITEMS] Fetched \(items.count) items from Core Data")
        for (index, item) in items.prefix(3).enumerated() {
            print("   \(index + 1). \(item.itemDescription ?? "nil") - \(item.amount ?? 0)")
        }
        if items.count > 3 {
            print("   ...and \(items.count - 3) more items")
        }
        print("🟣 [GET-ITEMS] ========================================")

        return items
    }
    
    /// Get items for a specific group
    /// ⚠️ CRITICAL FIX: Removed caching of Core Data objects - they become invalid when contexts refresh
    /// TODO: Refactor to return ItemDomain and cache Domain models instead
    func getItems(for group: Group) async throws -> [Item] {
        // Fetch from Core Data - DO NOT CACHE Core Data objects
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "itemList.group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        request.returnsObjectsAsFaults = false  // Force full object load
        let items = try await fetch(request)

        return items
    }
    
    /// Calculate total amount for a specific itemList with caching
    func calculateTotalAmount(for itemList: ItemList) async throws -> NSDecimalNumber {
        let cacheKey = "\(CacheKeys.itemListTotalAmount).\(itemList.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedAmount: NSDecimalNumber = await CacheManager.shared.getCachedCalculation(for: cacheKey) {
            return cachedAmount
        }
        
        // Calculate from Core Data
        let items = try await getItems(for: itemList)
        let total = items.reduce(NSDecimalNumber.zero) { total, item in
            total.adding(item.amount ?? NSDecimalNumber.zero)
        }
        
        // Cache the result
        await CacheManager.shared.cacheCalculation(total, for: cacheKey)
        
        return total
    }
    
    /// Calculate total amount for a specific group with caching
    func calculateTotalAmount(for group: Group) async throws -> NSDecimalNumber {
        let cacheKey = "\(CacheKeys.groupTotalAmount).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedAmount: NSDecimalNumber = await CacheManager.shared.getCachedCalculation(for: cacheKey) {
            return cachedAmount
        }
        
        // Calculate from Core Data
        let items = try await getItems(for: group)
        let total = items.reduce(NSDecimalNumber.zero) { total, item in
            total.adding(item.amount ?? NSDecimalNumber.zero)
        }
        
        // Cache the result
        await CacheManager.shared.cacheCalculation(total, for: cacheKey)
        
        return total
    }
}
