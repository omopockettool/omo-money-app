import CoreData
import Foundation

/// Service class for ItemList entity operations
/// Handles all CRUD operations for ItemList with proper threading and caching
class ItemListService: CoreDataService, ItemListServiceProtocol {
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let groupItemLists = "ItemListService.groupItemLists"
        static let userItemLists = "ItemListService.userItemLists"
        static let categoryItemLists = "ItemListService.categoryItemLists"
        static let dateRangeItemLists = "ItemListService.dateRangeItemLists"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - ItemList CRUD Operations
    
    // NOTE: Use getItemLists(for group: Group) for group-specific ItemLists (most common)
    // NOTE: Use getItemLists(for user: User) for cross-group ItemList access
    
    /// Fetch itemList by ID
    func fetchItemList(by id: UUID) async throws -> ItemList? {
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new itemList
    func createItemList(description: String?, date: Date, categoryId: UUID, groupId: UUID, paymentMethodId: UUID?) async throws -> ItemList {
        let itemList = try await context.perform {
            let itemList = ItemList(context: self.context)
            itemList.id = UUID()
            itemList.itemListDescription = description
            itemList.date = date
            itemList.createdAt = Date()
            
            // Set group by ID
            if let group = try? self.context.fetch(NSFetchRequest<Group>(entityName: "Group")).first(where: { $0.id == groupId }) {
                itemList.group = group
            }
            
            // Set category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                itemList.category = category
            }
            
            // Set payment method by ID
            if let paymentMethodId = paymentMethodId,
               let paymentMethod = try? self.context.fetch(NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")).first(where: { $0.id == paymentMethodId }) {
                itemList.paymentMethod = paymentMethod
            }
            
            try self.context.save()
            return itemList
        }
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryItemLists)
        
        return itemList
    }
    
    /// Update an existing itemList
    func updateItemList(_ itemList: ItemList, description: String? = nil, date: Date? = nil, categoryId: UUID, paymentMethodId: UUID?) async throws {
        try await context.perform {
            if let description = description {
                itemList.itemListDescription = description
            }
            if let date = date {
                itemList.date = date
            }
            
            // Update category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                itemList.category = category
            }
            
            // Update payment method by ID
            if let paymentMethodId = paymentMethodId {
                if let paymentMethod = try? self.context.fetch(NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")).first(where: { $0.id == paymentMethodId }) {
                    itemList.paymentMethod = paymentMethod
                }
            } else {
                itemList.paymentMethod = nil
            }
            
            itemList.lastModifiedAt = Date()
            
            try self.context.save()
        }
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryItemLists)
    }
    
    /// Delete an itemList
    func deleteItemList(_ itemList: ItemList) async throws {
        await delete(itemList)
        try await save()
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryItemLists)
    }
    
    /// Get itemLists for a specific group with caching
    func getItemLists(for group: Group) async throws -> [ItemList] {
        let cacheKey = "\(CacheKeys.groupItemLists).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedItemLists: [ItemList] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItemLists
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]
        let itemLists = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(itemLists, for: cacheKey)
        
        return itemLists
    }
    
    /// Get itemLists for a specific user across all their groups with caching
    func getItemLists(for user: User) async throws -> [ItemList] {
        let cacheKey = "\(CacheKeys.userItemLists).\(user.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedItemLists: [ItemList] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItemLists
        }
        
        // Fetch from Core Data through UserGroup relationship
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]
        let itemLists = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(itemLists, for: cacheKey)
        
        return itemLists
    }
    
    /// Get itemLists for a specific category with caching
    func getItemLists(for category: Category) async throws -> [ItemList] {
        let cacheKey = "\(CacheKeys.categoryItemLists).\(category.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedItemLists: [ItemList] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItemLists
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]
        let itemLists = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(itemLists, for: cacheKey)
        
        return itemLists
    }
    
    /// Get itemLists within a date range
    func getItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemList] {
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]
        return try await fetch(request)
    }
    
    /// Get itemLists count for a specific group
    func getItemListsCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
    
    /// Get itemLists count for a specific user across all their groups
    func getItemListsCount(for user: User) async throws -> Int {
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
        return try await count(request)
    }
}
