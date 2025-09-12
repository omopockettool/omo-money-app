import CoreData
import Foundation

/// Service class for Item entity operations
/// Handles all CRUD operations for Item with proper threading and caching
class ItemService: CoreDataService, ItemServiceProtocol {
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let allItems = "ItemService.allItems"
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
    
    /// Fetch all items with caching
    func fetchItems() async throws -> [Item] {
        // Check cache first
        if let cachedItems: [Item] = await CacheManager.shared.getCachedData(for: CacheKeys.allItems) {
            return cachedItems
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: true)]
        let items = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(items, for: CacheKeys.allItems)
        
        return items
    }
    
    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item? {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, itemList: ItemList) async throws -> Item {
        let item = try await context.perform {
            let item = Item(context: self.context)
            item.id = UUID()
            item.itemDescription = description
            item.amount = amount
            item.quantity = quantity
            item.itemList = itemList
            item.createdAt = Date()
            
            try self.context.save()
            return item
        }
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.allItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.itemListItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItems)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.itemListTotalAmount)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.groupTotalAmount)
        
        return item
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws {
        try await context.perform {
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
        }
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.allItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.itemListItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItems)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.itemListTotalAmount)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.groupTotalAmount)
    }
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws {
        await delete(item)
        try await save()
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.allItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.itemListItems)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItems)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.itemListTotalAmount)
        await CacheManager.shared.clearCalculationCache(for: CacheKeys.groupTotalAmount)
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
    
    /// Get items count
    func getItemsCount() async throws -> Int {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        return try await count(request)
    }
}
