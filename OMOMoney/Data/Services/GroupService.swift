import CoreData
import Foundation

/// Service class for Group entity operations
/// Handles all CRUD operations for Group with proper threading
class GroupService: CoreDataService, GroupServiceProtocol {
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let userGroups = "GroupService.userGroups"
        static let groupExists = "GroupService.groupExists"
        static let currencyGroupCount = "GroupService.currencyGroupCount"
    }
    
    // MARK: - Group CRUD Operations
    
    // NOTE: Use UserGroupService.getGroups(for user: User) for user-specific group filtering
    // This enables dashboard dropdown with user's groups for switching context
    
    /// Fetch group by ID
    /// ✅ REFACTORED: Returns Domain model
    func fetchGroup(by id: UUID) async throws -> GroupDomain? {
        return try await context.perform {
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false

            guard let group = try self.context.fetch(request).first else {
                return nil
            }

            // Convert to Domain INSIDE context.perform
            return group.toDomain()
        }
    }

    /// Create a new group
    /// ✅ REFACTORED: Returns Domain model
    func createGroup(name: String, currency: String) async throws -> GroupDomain {
        // Step 1: Create and save the group entity, convert to Domain
        let (groupDomain, groupId) = try await context.perform {
            let group = Group(context: self.context)
            group.id = UUID()
            group.name = name
            group.currency = currency
            group.createdAt = Date()

            try self.context.save()

            // Convert to Domain INSIDE context.perform
            return (group.toDomain(), group.id!)
        }

        print("✅ [GroupService] Group created: '\(name)' (ID: \(groupId.uuidString))")

        // Step 2: Create default payment methods and categories for the new group
        // ⚠️ CRITICAL: Must complete BEFORE returning to avoid race condition
        do {
            let paymentMethodService = PaymentMethodService(context: context)
            let categoryService = CategoryService(context: context)

            // Create default payment methods: (name, type, icon, color, isDefault)
            let defaultPaymentMethods: [(String, String, String, String, Bool)] = [
                ("Efectivo",        "cash",          "banknote.fill",           "#4CAF50", true),
                ("T. Débito",       "card_debit",    "creditcard.fill",         "#2196F3", false),
                ("T. Crédito",      "card_credit",   "creditcard.fill",         "#9C27B0", false),
                ("Transferencia",   "bank_transfer", "arrow.left.arrow.right",  "#FF9800", false)
            ]

            print("🔄 [GroupService] Creating \(defaultPaymentMethods.count) default payment methods...")
            for (pmName, pmType, pmIcon, pmColor, pmIsDefault) in defaultPaymentMethods {
                let _ = try await paymentMethodService.createPaymentMethod(
                    name: pmName,
                    type: pmType,
                    icon: pmIcon,
                    color: pmColor,
                    isActive: true,
                    isDefault: pmIsDefault,
                    groupId: groupId
                )
            }
            print("✅ [GroupService] Payment methods created")

            // Create default categories: (name, color, icon, isDefault)
            let defaultCategories: [(String, String, String, Bool)] = [
                ("Alimentos",       "#FF6B6B", "cart.fill",             false),
                ("Transporte",      "#4ECDC4", "car.fill",              false),
                ("Hogar",           "#45B7D1", "house.fill",            false),
                ("Ocio",            "#96CEB4", "theatermasks.fill",     false),
                ("Salud",           "#FFEAA7", "heart.fill",            false),
                ("Otros",           "#BDC3C7", "ellipsis.circle.fill",  true)
            ]

            print("🔄 [GroupService] Creating \(defaultCategories.count) default categories...")
            for (categoryName, color, icon, isDefault) in defaultCategories {
                let _ = try await categoryService.createCategory(
                    name: categoryName,
                    color: color,
                    icon: icon,
                    isDefault: isDefault,
                    groupId: groupId
                )
            }
            print("✅ [GroupService] All \(defaultCategories.count) categories created and saved to Core Data")

        } catch {
            // Don't fail group creation if seeding defaults fails — just log
            print("❌ [GroupService] Warning: failed to create default payment methods/categories: \(error.localizedDescription)")
        }

        // Step 3: Invalidate relevant caches
        print("🧹 [GroupService] Invalidating caches...")
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
        print("✅ [GroupService] Caches invalidated")

        // Step 4: Return groupDomain ONLY after categories are saved
        print("✅ [GroupService] createGroup() complete - returning group with all default data")
        return groupDomain
    }

    /// Update an existing group
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func updateGroup(groupId: UUID, name: String? = nil, currency: String? = nil) async throws {
        try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                throw RepositoryError.notFound
            }

            if let name = name {
                group.name = name
            }
            if let currency = currency {
                group.currency = currency
            }
            group.lastModifiedAt = Date()

            try self.context.save()
        }

        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
    }

    /// Delete a group
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func deleteGroup(groupId: UUID) async throws {
        print("🔥 [GroupService] deleteGroup() iniciado")
        print("�� [GroupService] UUID: \(groupId.uuidString)")

        try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                throw RepositoryError.notFound
            }

            print("🔥 [GroupService] Grupo a eliminar: '\(group.name ?? "Sin nombre")' (ObjectID: \(group.objectID))")

            // Verificar si el grupo tiene relaciones antes de eliminar
            let userGroupsCount = group.userGroups?.count ?? 0
            let itemListsCount = group.itemLists?.count ?? 0

            print("🔥 [GroupService] UserGroups relacionados: \(userGroupsCount)")
            print("🔥 [GroupService] ItemLists relacionados: \(itemListsCount)")

            self.context.delete(group)
            try self.context.save()
            print("🔥 [GroupService] save() ejecutado")
        }

        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
        print("✅ [GroupService] Caches limpiados, deleteGroup() completado")
    }
    
    /// Check if group exists by name with caching
    func groupExists(withName name: String, excluding groupId: UUID? = nil) async throws -> Bool {
        let cacheKey = "\(CacheKeys.groupExists).\(name).\(groupId?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }
        
        // Check in Core Data
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        
        if let groupId = groupId {
            request.predicate = NSPredicate(format: "name == %@ AND id != %@", name, groupId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "name == %@", name)
        }
        
        let results = try await fetch(request)
        let exists = !results.isEmpty
        
        // Cache the result
        await CacheManager.shared.cacheValidation(exists, for: cacheKey)
        
        return exists
    }
    
    // MARK: - Batch Operations
    
    /// Bulk delete groups by IDs for better performance
    func bulkDeleteGroups(groupIds: [UUID]) async throws {
        let predicate = NSPredicate(format: "id IN %@", groupIds)
        _ = try await batchDelete(Group.self, predicate: predicate)
        
        // Clear relevant caches
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
    }
    
    /// Bulk update group currency
    func bulkUpdateGroupCurrency(groupIds: [UUID], currency: String) async throws {
        let predicate = NSPredicate(format: "id IN %@", groupIds)
        let properties: [String: Any] = ["currency": currency, "lastModifiedAt": Date()]
        
        _ = try await batchUpdate(Group.self, predicate: predicate, propertiesToUpdate: properties)
        
        // Clear relevant caches
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
    }
    
    /// Bulk update group status (assuming groups have an isActive property)
    func bulkUpdateGroupStatus(groupIds: [UUID], isActive: Bool) async throws {
        let predicate = NSPredicate(format: "id IN %@", groupIds)
        let properties: [String: Any] = ["isActive": isActive, "lastModifiedAt": Date()]
        
        _ = try await batchUpdate(Group.self, predicate: predicate, propertiesToUpdate: properties)
        
        // Clear relevant caches
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
    }
    
    /// Create multiple groups efficiently
    /// ✅ REFACTORED: Returns Domain models
    func createGroups(_ groupDataList: [(name: String, currency: String)]) async throws -> [GroupDomain] {
        // For small batches, use regular creation for better control
        if groupDataList.count <= 10 {
            var createdGroups: [GroupDomain] = []
            for groupData in groupDataList {
                let groupDomain = try await createGroup(name: groupData.name, currency: groupData.currency)
                createdGroups.append(groupDomain)
            }
            return createdGroups
        }

        // For larger batches, use bulk insert
        let groupIds = try await context.perform {
            var groupIds: [UUID] = []
            for groupData in groupDataList {
                let group = Group(context: self.context)
                let groupId = UUID()
                group.id = groupId
                group.name = groupData.name
                group.currency = groupData.currency
                group.createdAt = Date()
                groupIds.append(groupId)
            }
            try self.context.save()
            return groupIds
        }

        // Clear caches
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)

        // Fetch created groups as Domain models
        return try await context.perform {
            let request: NSFetchRequest<Group> = Group.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", groupIds)
            request.returnsObjectsAsFaults = false

            let groups = try self.context.fetch(request)
            return groups.map { $0.toDomain() }
        }
    }
    
    /// Get groups count for specific currency
    func getGroupsCount(for currency: String) async throws -> Int {
        let cacheKey = "\(CacheKeys.currencyGroupCount)_\(currency)"
        
        // Check cache first
        if let cachedCount: Int = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedCount
        }
        
        // Get from Core Data
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.predicate = NSPredicate(format: "currency == %@", currency)
        let count = try await count(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(count, for: cacheKey)
        
        return count
    }
    
    /// Get group members count
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getGroupMembersCount(groupId: UUID) async throws -> Int {
        let cacheKey = "GroupService.membersCount_\(groupId.uuidString)"
        
        // Check cache first
        if let cachedCount: Int = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedCount
        }
        
        // Get from Core Data through UserGroup relationship
        let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "UserGroup")
        request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
        request.resultType = .countResultType
        
        let results = try await context.perform {
            try self.context.fetch(request)
        }
        
        let count = (results.first as? Int) ?? 0
        
        // Cache the result
        await CacheManager.shared.cacheData(count, for: cacheKey)
        
        return count
    }
    
}
