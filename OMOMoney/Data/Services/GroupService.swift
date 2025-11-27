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
    func fetchGroup(by id: UUID) async throws -> Group? {
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new group
    func createGroup(name: String, currency: String) async throws -> Group {
        let group = try await context.perform {
            let group = Group(context: self.context)
            group.id = UUID()
            group.name = name
            group.currency = currency
            group.createdAt = Date()
            
            try self.context.save()
            return group
        }
        
        // Create default payment methods and categories for the new group
        do {
            let paymentMethodService = PaymentMethodService(context: context)
            let categoryService = CategoryService(context: context)
            
            // Create default payment methods
            let defaultPaymentMethods: [(String, String)] = [
                ("Efectivo", "cash"),
                ("Tarjeta Débito", "card_debit"),
                ("Tarjeta Crédito", "card_credit"),
                ("Transferencia", "bank_transfer")
            ]
            
            if let groupId = group.id {
                for (pmName, pmType) in defaultPaymentMethods {
                    let _ = try await paymentMethodService.createPaymentMethod(
                        name: pmName,
                        type: pmType,
                        isActive: true,
                        groupId: groupId
                    )
                }
            }
            
            // Create default categories
            let defaultCategories = [
                ("Alimentos", "#FF6B6B"),
                ("Transporte", "#4ECDC4"),
                ("Hogar", "#45B7D1"),
                ("Entretenimiento", "#96CEB4"),
                ("Salud", "#FFEAA7"),
                ("Compras", "#DDA0DD"),
                ("Otros", "#BDC3C7")
            ]
            
            for (categoryName, color) in defaultCategories {
                let _ = try await categoryService.createCategory(
                    name: categoryName,
                    color: color,
                    group: group
                )
            }
            
        } catch {
            // Don't fail group creation if seeding defaults fails — just log
            print("[GroupService] Warning: failed to create default payment methods/categories: \(error.localizedDescription)")
        }
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
        
        return group
    }
    
    /// Update an existing group
    func updateGroup(_ group: Group, name: String? = nil, currency: String? = nil) async throws {
        try await context.perform {
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
    func deleteGroup(_ group: Group) async throws {
        print("🔥 [GroupService] deleteGroup() iniciado")
        print("🔥 [GroupService] Grupo a eliminar: '\(group.name ?? "Sin nombre")' (ObjectID: \(group.objectID))")
        print("🔥 [GroupService] UUID: \(group.id?.uuidString ?? "nil")")
        
        // Verificar si el grupo tiene relaciones antes de eliminar
        let userGroupsCount = group.userGroups?.count ?? 0
        let itemListsCount = group.itemLists?.count ?? 0
        
        print("🔥 [GroupService] UserGroups relacionados: \(userGroupsCount)")
        print("🔥 [GroupService] ItemLists relacionados: \(itemListsCount)")
        
        await delete(group)
        print("🔥 [GroupService] delete(group) ejecutado")
        
        try await save()
        print("🔥 [GroupService] save() ejecutado")
        
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
    func createGroups(_ groupDataList: [(name: String, currency: String)]) async throws -> [Group] {
        // For small batches, use regular creation for better control
        if groupDataList.count <= 10 {
            var createdGroups: [Group] = []
            for groupData in groupDataList {
                let group = try await createGroup(name: groupData.name, currency: groupData.currency)
                createdGroups.append(group)
            }
            return createdGroups
        }
        
        // For larger batches, use bulk insert
        let objects: [[String: Any]] = groupDataList.map { groupData in
            return [
                "id": UUID(),
                "name": groupData.name,
                "currency": groupData.currency,
                "createdAt": Date(),
                "lastModifiedAt": Date()
            ]
        }
        
        try await bulkInsert(Group.self, objects: objects)
        
        // Clear caches - Note: return empty array since fetchGroups() was removed
        await CacheManager.shared.clearDataCache(for: CacheKeys.userGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currencyGroupCount)
        
        // TODO: Return created groups properly when getGroups(for user: User) is implemented
        return []
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
    func getGroupMembersCount(_ group: Group) async throws -> Int {
        guard let groupId = group.id else {
            throw CoreDataError.invalidObjectID
        }
        
        let cacheKey = "GroupService.membersCount_\(groupId)"
        
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
