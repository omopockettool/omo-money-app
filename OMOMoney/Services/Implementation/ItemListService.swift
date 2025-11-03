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
        print("🔄 ItemListService: Creating ItemList with description: \(description ?? "nil")")
        print("🔄 ItemListService: GroupId: \(groupId), CategoryId: \(categoryId)")
        
        let itemList = try await context.perform {
            let itemList = ItemList(context: self.context)
            itemList.id = UUID()
            itemList.itemListDescription = description
            itemList.date = date
            itemList.createdAt = Date()
            
            print("🔄 ItemListService: ItemList created with ID: \(itemList.id?.uuidString ?? "nil")")
            
            // Set group by ID
            if let group = try? self.context.fetch(NSFetchRequest<Group>(entityName: "Group")).first(where: { $0.id == groupId }) {
                itemList.group = group
                print("✅ ItemListService: Group assigned: \(group.name ?? "Unknown")")
            } else {
                print("❌ ItemListService: Failed to find group with ID: \(groupId)")
            }
            
            // Set category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                itemList.category = category
                print("✅ ItemListService: Category assigned: \(category.name ?? "Unknown")")
            } else {
                print("❌ ItemListService: Failed to find category with ID: \(categoryId)")
            }
            
            // Set payment method by ID
            if let paymentMethodId = paymentMethodId,
               let paymentMethod = try? self.context.fetch(NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")).first(where: { $0.id == paymentMethodId }) {
                itemList.paymentMethod = paymentMethod
                print("✅ ItemListService: PaymentMethod assigned: \(paymentMethod.name ?? "Unknown")")
            } else {
                print("⚠️ ItemListService: No payment method assigned (ID: \(paymentMethodId?.uuidString ?? "nil"))")
            }
            
            print("🔄 ItemListService: Attempting to save context...")
            try self.context.save()
            print("✅ ItemListService: Context saved successfully")
            
            // Verify the ItemList was saved with correct relationships
            print("🔍 ItemListService: Verifying saved ItemList:")
            print("   - ID: \(itemList.id?.uuidString ?? "nil")")
            print("   - Description: \(itemList.itemListDescription ?? "nil")")
            print("   - Group: \(itemList.group?.name ?? "nil") (ID: \(itemList.group?.id?.uuidString ?? "nil"))")
            print("   - Category: \(itemList.category?.name ?? "nil") (ID: \(itemList.category?.id?.uuidString ?? "nil"))")
            print("   - PaymentMethod: \(itemList.paymentMethod?.name ?? "nil") (ID: \(itemList.paymentMethod?.id?.uuidString ?? "nil"))")
            
            return itemList
        }
        
        // Invalidate relevant cache itemLists IMMEDIATELY after save
        print("🔄 ItemListService: Clearing all caches...")
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userItemLists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryItemLists)
        
        // Also clear the specific group cache used by getItemLists
        if let groupId = itemList.group?.id?.uuidString {
            let specificCacheKey = "\(CacheKeys.groupItemLists).\(groupId)"
            await CacheManager.shared.clearDataCache(for: specificCacheKey)
            print("🔄 ItemListService: Cleared specific group cache: \(specificCacheKey)")
        }
        
        print("✅ ItemListService: All caches cleared")
        
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
        
        print("🔍 ItemListService: getItemLists for group: \(group.name ?? "nil") (ID: \(group.id?.uuidString ?? "nil"))")
        
        // Check cache first
        if let cachedItemLists: [ItemList] = await CacheManager.shared.getCachedData(for: cacheKey) {
            print("✅ ItemListService: Using cached ItemLists (\(cachedItemLists.count) items)")
            return cachedItemLists
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]
        print("🔍 ItemListService: Executing Core Data query with predicate: \(request.predicate?.description ?? "nil")")
        
        let itemLists = try await fetch(request)
        print("✅ ItemListService: Core Data returned \(itemLists.count) ItemLists")
        
        // Log each ItemList found
        for itemList in itemLists {
            print("   - \(itemList.itemListDescription ?? "No description") (ID: \(itemList.id?.uuidString ?? "nil"))")
        }
        
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
