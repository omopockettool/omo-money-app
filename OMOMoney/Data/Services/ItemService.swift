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
        // ✅ SIMPLE FIX: Accept itemListId directly, fetch ItemList in OUR context
        let (item, groupId, itemListDescription) = try await context.perform {
            // Fetch the ItemList in THIS context to access relationships
            let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", itemListId as CVarArg)
            request.fetchLimit = 1

            guard let itemListInContext = try self.context.fetch(request).first else {
                throw NSError(domain: "ItemService", code: 2, userInfo: [NSLocalizedDescriptionKey: "ItemList not found"])
            }

            let item = Item(context: self.context)
            item.id = UUID()
            item.itemDescription = description
            item.amount = amount
            item.quantity = quantity
            item.itemList = itemListInContext
            item.createdAt = Date()

            try self.context.save()

            // Get groupId and description while we're in the correct context
            let groupId = itemListInContext.group?.id
            let itemListDescription = itemListInContext.itemListDescription
            return (item, groupId, itemListDescription)
        }

        // ✅ BUG FIX: Invalidate ItemList-specific, Group-level, AND ItemListService caches
        // Invalidate ItemList-specific caches
        let itemListCacheKey = "\(CacheKeys.itemListItems).\(itemListId.uuidString)"
        let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"
        await CacheManager.shared.clearDataCache(for: itemListCacheKey)
        await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            let groupItemsCacheKey = "\(CacheKeys.groupItems).\(groupId.uuidString)"
            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"
            await CacheManager.shared.clearDataCache(for: groupItemsCacheKey)
            await CacheManager.shared.clearCalculationCache(for: groupTotalCacheKey)

            // ✅ CRITICAL: Also invalidate ItemListService cache for the group
            let itemListServiceCacheKey = "ItemListService.groupItemLists.\(groupId.uuidString)"
            let itemListServiceTimestampKey = "\(itemListServiceCacheKey).timestamp"
            await CacheManager.shared.clearDataCache(for: itemListServiceCacheKey)
            await CacheManager.shared.clearDataCache(for: itemListServiceTimestampKey)

            print("🗑️ ItemService: Cache invalidated for ItemList '\(itemListDescription ?? "Unknown")' and Group (including ItemListService) after item creation")
        } else {
            print("⚠️ ItemService: WARNING - ItemList '\(itemListDescription ?? "Unknown")' has no group! Cache invalidation incomplete.")
        }

        return item
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws {
        // ✅ CRITICAL: Get itemList and groupId INSIDE context.perform to access Core Data relationships
        let (itemListId, groupId) = try await context.perform {
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

            // Get IDs while we're in the correct context
            let itemListId = item.itemList?.id
            let groupId = item.itemList?.group?.id
            return (itemListId, groupId)
        }

        // ✅ PERFORMANCE FIX: Invalidate only specific caches, not all caches with wildcard
        // This prevents clearing unrelated ItemLists' and Groups' caches

        // Invalidate ItemList-specific caches
        if let itemListId = itemListId {
            let itemListCacheKey = "\(CacheKeys.itemListItems).\(itemListId.uuidString)"
            let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"
            await CacheManager.shared.clearDataCache(for: itemListCacheKey)
            await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)
        }

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            let groupItemsCacheKey = "\(CacheKeys.groupItems).\(groupId.uuidString)"
            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"
            await CacheManager.shared.clearDataCache(for: groupItemsCacheKey)
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
            let groupId = item.itemList?.group?.id
            return (itemListId, groupId)
        }

        await delete(item)
        try await save()

        // ✅ PERFORMANCE FIX: Invalidate only specific caches, not all caches with wildcard
        // This prevents clearing unrelated ItemLists' and Groups' caches

        // Invalidate ItemList-specific caches
        if let itemListId = itemListId {
            let itemListCacheKey = "\(CacheKeys.itemListItems).\(itemListId.uuidString)"
            let itemListTotalCacheKey = "\(CacheKeys.itemListTotalAmount).\(itemListId.uuidString)"
            await CacheManager.shared.clearDataCache(for: itemListCacheKey)
            await CacheManager.shared.clearCalculationCache(for: itemListTotalCacheKey)
        }

        // Invalidate group-level caches (if itemList belongs to a group)
        if let groupId = groupId {
            let groupItemsCacheKey = "\(CacheKeys.groupItems).\(groupId.uuidString)"
            let groupTotalCacheKey = "\(CacheKeys.groupTotalAmount).\(groupId.uuidString)"
            await CacheManager.shared.clearDataCache(for: groupItemsCacheKey)
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
    
    /// Get items for a specific itemList with caching
    func getItems(for itemList: ItemList) async throws -> [Item] {
        let cacheKey = "\(CacheKeys.itemListItems).\(itemList.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedItems: [Item] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItems
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "itemList == %@", itemList)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        let items = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(items, for: cacheKey)
        
        return items
    }
    
    /// Get items for a specific group with caching
    func getItems(for group: Group) async throws -> [Item] {
        let cacheKey = "\(CacheKeys.groupItems).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedItems: [Item] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItems
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "itemList.group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        let items = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(items, for: cacheKey)
        
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
