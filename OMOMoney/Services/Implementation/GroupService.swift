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
        static let allGroups = "GroupService.allGroups"
        static let groupCount = "GroupService.groupCount"
        static let groupExists = "GroupService.groupExists"
    }
    
    // MARK: - Group CRUD Operations
    
    /// Fetch all groups with caching
    func fetchGroups() async throws -> [Group] {
        // Check cache first
        if let cachedGroups: [Group] = await CacheManager.shared.getCachedData(for: CacheKeys.allGroups) {
            return cachedGroups
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Group.name, ascending: true)]
        let groups = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(groups, for: CacheKeys.allGroups)
        
        return groups
    }
    
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
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupCount)
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
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allGroups)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
    }
    
    /// Delete a group
    func deleteGroup(_ group: Group) async throws {
        await delete(group)
        try await save()
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.groupExists)
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
    
    /// Get groups count with caching
    func getGroupsCount() async throws -> Int {
        // Check cache first
        if let cachedCount: Int = await CacheManager.shared.getCachedData(for: CacheKeys.groupCount) {
            return cachedCount
        }
        
        // Get from Core Data
        let request: NSFetchRequest<Group> = Group.fetchRequest()
        let count = try await count(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(count, for: CacheKeys.groupCount)
        
        return count
    }
    
    /// Get groups by owner (through UserGroup relationship)
    /// This method requires UserGroupService to work properly
    func getGroups(ownedBy user: User) async throws -> [Group] {
        // This method should be implemented in UserGroupService instead
        // as Group doesn't have a direct owner relationship
        throw NSError(domain: "GroupService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Use UserGroupService.getGroups(for:) instead"])
    }
}
