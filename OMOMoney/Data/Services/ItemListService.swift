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
        print("🎬 [SERVICE] ItemListService.createItemList()")
        print("   📋 Input Parameters:")
        print("      - Description: \(description ?? "nil")")
        print("      - Date: \(date)")
        print("      - Category ID: \(categoryId)")
        print("      - Group ID: \(groupId)")
        print("      - Payment Method ID: \(paymentMethodId?.uuidString ?? "nil")")
        
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
                itemList.groupId = groupId  // ✅ FIX: Also set the groupId attribute
                print("✅ ItemListService: Group assigned: \(group.name ?? "Unknown")")
            } else {
                print("❌ ItemListService: Failed to find group with ID: \(groupId)")
            }
            
            // Set category by ID
            if let category = try? self.context.fetch(NSFetchRequest<Category>(entityName: "Category")).first(where: { $0.id == categoryId }) {
                itemList.category = category
                itemList.categoryId = categoryId  // ✅ FIX: Also set the categoryId attribute
                print("✅ ItemListService: Category assigned: \(category.name ?? "Unknown")")
            } else {
                print("❌ ItemListService: Failed to find category with ID: \(categoryId)")
            }
            
            // Set payment method by ID
            if let paymentMethodId = paymentMethodId,
               let paymentMethod = try? self.context.fetch(NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")).first(where: { $0.id == paymentMethodId }) {
                itemList.paymentMethod = paymentMethod
                itemList.paymentMethodId = paymentMethodId  // ✅ FIX: Also set the paymentMethodId attribute
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

            print("✅ [SERVICE] Returning ItemList Core Data entity to Repository")
            return itemList
        }
        
        // ✅ Invalidate cache after creation to ensure consistency
        // The cache must be cleared so next fetch gets fresh data
        let cacheKey = "\(CacheKeys.groupItemLists).\(groupId.uuidString)"
        let timestampKey = "\(cacheKey).timestamp"
        await CacheManager.shared.clearDataCache(for: cacheKey)
        await CacheManager.shared.clearDataCache(for: timestampKey)
        print("🗑️ ItemListService: Cache invalidated for group after creation")

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
                itemList.categoryId = categoryId  // ✅ FIX: Also set the categoryId attribute
            }

            // Update payment method by ID
            if let paymentMethodId = paymentMethodId {
                if let paymentMethod = try? self.context.fetch(NSFetchRequest<PaymentMethod>(entityName: "PaymentMethod")).first(where: { $0.id == paymentMethodId }) {
                    itemList.paymentMethod = paymentMethod
                    itemList.paymentMethodId = paymentMethodId  // ✅ FIX: Also set the paymentMethodId attribute
                }
            } else {
                itemList.paymentMethod = nil
                itemList.paymentMethodId = nil  // ✅ FIX: Also clear the paymentMethodId attribute
            }
            
            itemList.lastModifiedAt = Date()
            
            try self.context.save()
        }
        
        // ✅ INVALIDATE CACHE: Essential for refreshData() to get correct data
        if let groupId = itemList.group?.id {
            let cacheKey = "\(CacheKeys.groupItemLists).\(groupId.uuidString)"
            let timestampKey = "\(cacheKey).timestamp"
            await CacheManager.shared.clearDataCache(for: cacheKey)
            await CacheManager.shared.clearDataCache(for: timestampKey)
            print("🗑️ ItemListService: Cache invalidated for group after update")
        }
    }
    
    /// Delete an itemList
    func deleteItemList(_ itemList: ItemList) async throws {
        // Get the group ID before deleting the itemList
        guard let groupId = itemList.group?.id else {
            print("⚠️ ItemListService: Cannot invalidate cache - ItemList has no group")
            await delete(itemList)
            try await save()
            return
        }

        let itemListDescription = itemList.itemListDescription ?? "Unknown"

        print("🗑️ ItemListService: Deleting ItemList '\(itemListDescription)'")

        await delete(itemList)
        try await save()

        print("✅ ItemListService: ItemList deleted from Core Data")

        // ✅ INVALIDATE CACHE: Essential for refreshData() to get correct data
        // Without this, refreshData() returns stale cached data that includes deleted ItemList
        let cacheKey = "\(CacheKeys.groupItemLists).\(groupId.uuidString)"
        let timestampKey = "\(cacheKey).timestamp"
        await CacheManager.shared.clearDataCache(for: cacheKey)
        await CacheManager.shared.clearDataCache(for: timestampKey)
        print("🗑️ ItemListService: Cache invalidated for group after deletion")
    }
    
    /// Get itemLists for a specific group with caching
    func getItemLists(for group: Group) async throws -> [ItemListDomain] {
        let cacheKey = "\(CacheKeys.groupItemLists).\(group.id?.uuidString ?? "nil")"
        let timestampKey = "\(cacheKey).timestamp"

        print("🔍 ItemListService: Getting ItemLists for group '\(group.name ?? "Unknown")'")
        print("🔍 ItemListService: Cache key: \(cacheKey)")

        // Check cache first with TTL validation
        if let cachedItemLists: [ItemListDomain] = await CacheManager.shared.getCachedData(for: cacheKey),
           let timestamp: Date = await CacheManager.shared.getCachedData(for: timestampKey) {

            let cacheAge = Date().timeIntervalSince(timestamp)
            let cacheTTL: TimeInterval = 300 // 5 minutes

            let minutesOld = Int(cacheAge / 60)
            let secondsOld = Int(cacheAge.truncatingRemainder(dividingBy: 60))

            if cacheAge < cacheTTL {
                print("🟢 [TTL CHECK] CACHE HIT - Data is FRESH ✅")
                print("   📊 Cache Age: \(minutesOld)m \(secondsOld)s old")
                print("   ⏰ TTL Limit: 5 minutes (300 seconds)")
                print("   ✅ Status: VALID (age < TTL)")
                print("   📦 Items: \(cachedItemLists.count)")
                print("   🎯 Source: IN-MEMORY CACHE")
                return cachedItemLists
            } else {
                print("🔴 [TTL CHECK] CACHE EXPIRED - Data is STALE ❌")
                print("   📊 Cache Age: \(minutesOld)m \(secondsOld)s old")
                print("   ⏰ TTL Limit: 5 minutes (300 seconds)")
                print("   ❌ Status: EXPIRED (age >= TTL)")
                print("   🔄 Action: Fetching from Core Data...")
            }
        } else {
            print("⚪️ [TTL CHECK] NO CACHE - First time fetch")
            print("   🔄 Action: Fetching from Core Data...")
        }

        print("🔄 ItemListService: Cache miss - fetching from Core Data...")

        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        if let groupId = group.id {
            request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "group == %@", group)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]

        let domainItemLists: [ItemListDomain] = try await context.perform {
            let results = try self.context.fetch(request)
            return results.map { $0.toDomain() }
        }

        let maxLogItems = 5
        for itemList in domainItemLists.prefix(maxLogItems) {
            print("   - \(itemList.itemListDescription) (ID: \(itemList.id))")
        }
        if domainItemLists.count > maxLogItems {
            print("   - (...and \(domainItemLists.count - maxLogItems) more...)")
        }

        await CacheManager.shared.cacheData(domainItemLists, for: cacheKey)
        await CacheManager.shared.cacheData(Date(), for: timestampKey)
        print("💾 [DATABASE] ItemLists fetched from CORE DATA and cached ✅")
        print("   📦 Items: \(domainItemLists.count)")
        print("   ⏰ Cache valid for: 5 minutes")
        print("   🎯 Source: CORE DATA (SQLite)")

        return domainItemLists
    }
    
    /// Get itemLists for a specific user across all their groups with caching
    func getItemLists(for user: User) async throws -> [ItemListDomain] {
        let cacheKey = "\(CacheKeys.userItemLists).\(user.id?.uuidString ?? "nil")"

        if let cachedItemLists: [ItemListDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItemLists
        }

        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]

        let domainItemLists: [ItemListDomain] = try await context.perform {
            let results = try self.context.fetch(request)
            return results.map { $0.toDomain() }
        }

        await CacheManager.shared.cacheData(domainItemLists, for: cacheKey)
        return domainItemLists
    }

    /// Get itemLists for a specific category with caching
    func getItemLists(for category: Category) async throws -> [ItemListDomain] {
        let cacheKey = "\(CacheKeys.categoryItemLists).\(category.id?.uuidString ?? "nil")"

        if let cachedItemLists: [ItemListDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedItemLists
        }

        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]

        let domainItemLists: [ItemListDomain] = try await context.perform {
            let results = try self.context.fetch(request)
            return results.map { $0.toDomain() }
        }

        await CacheManager.shared.cacheData(domainItemLists, for: cacheKey)
        return domainItemLists
    }

    /// Get itemLists within a date range
    func getItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain] {
        let request: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ItemList.date, ascending: false)]

        return try await context.perform {
            let results = try self.context.fetch(request)
            return results.map { $0.toDomain() }
        }
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
