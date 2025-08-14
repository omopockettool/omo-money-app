import CoreData
import Foundation

/// Service class for UserGroup entity operations
/// Handles all CRUD operations for UserGroup with proper threading and caching
class UserGroupService: CoreDataService, UserGroupServiceProtocol {
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let allUserGroups = "UserGroupService.allUserGroups"
        static let userUserGroups = "UserGroupService.userUserGroups"
        static let groupUserGroups = "UserGroupService.groupUserGroups"
        static let usersInGroup = "UserGroupService.usersInGroup"
        static let groupsForUser = "UserGroupService.groupsForUser"
        static let isMember = "UserGroupService.isMember"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - UserGroup CRUD Operations
    
    /// Fetch all user groups with caching
    func fetchUserGroups() async throws -> [UserGroup] {
        // Check cache first
        if let cachedUserGroups: [UserGroup] = await CacheManager.shared.getCachedData(for: CacheKeys.allUserGroups) {
            return cachedUserGroups
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        let userGroups = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(userGroups, for: CacheKeys.allUserGroups)
        
        return userGroups
    }
    
    /// Fetch user group by ID
    func fetchUserGroup(by id: UUID) async throws -> UserGroup? {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new user group relationship
    func createUserGroup(user: User, group: Group, role: String = "member") async throws -> UserGroup {
        let userGroup = try await context.perform {
            let userGroup = UserGroup(context: self.context)
            userGroup.id = UUID()
            userGroup.user = user
            userGroup.group = group
            userGroup.role = role
            userGroup.joinedAt = Date()
            
            try self.context.save()
            return userGroup
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.usersInGroup)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupsForUser)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.isMember)
        
        return userGroup
    }
    
    /// Update an existing user group
    func updateUserGroup(_ userGroup: UserGroup, role: String? = nil) async throws {
        try await context.perform {
            if let role = role {
                userGroup.role = role
            }
            // UserGroup doesn't have updatedAt, using joinedAt instead
            
            try self.context.save()
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.usersInGroup)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupsForUser)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.isMember)
    }
    
    /// Delete a user group relationship
    func deleteUserGroup(_ userGroup: UserGroup) async throws {
        await delete(userGroup)
        try await save()
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.usersInGroup)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupsForUser)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.isMember)
    }
    
    /// Get user groups for a specific user with caching
    func getUserGroups(for user: User) async throws -> [UserGroup] {
        let cacheKey = "\(CacheKeys.userUserGroups).\(user.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedUserGroups: [UserGroup] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUserGroups
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        let userGroups = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(userGroups, for: cacheKey)
        
        return userGroups
    }
    
    /// Get user groups for a specific group with caching
    func getUserGroups(for group: Group) async throws -> [UserGroup] {
        let cacheKey = "\(CacheKeys.groupUserGroups).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedUserGroups: [UserGroup] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUserGroups
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
        let userGroups = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(userGroups, for: cacheKey)
        
        return userGroups
    }
    
    /// Get users in a specific group with caching
    func getUsers(in group: Group) async throws -> [User] {
        let cacheKey = "\(CacheKeys.usersInGroup).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedUsers: [User] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUsers
        }
        
        // Get from Core Data
        let userGroups = try await getUserGroups(for: group)
        let users = userGroups.compactMap { $0.user }
        
        // Cache the result
        await CacheManager.shared.cacheData(users, for: cacheKey)
        
        return users
    }
    
    /// Get groups for a specific user with caching
    func getGroups(for user: User) async throws -> [Group] {
        let cacheKey = "\(CacheKeys.groupsForUser).\(user.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedGroups: [Group] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedGroups
        }
        
        // Get from Core Data
        let userGroups = try await getUserGroups(for: user)
        let groups = userGroups.compactMap { $0.group }
        
        // Cache the result
        await CacheManager.shared.cacheData(groups, for: cacheKey)
        
        return groups
    }
    
    /// Check if user is member of group with caching
    func isUser(_ user: User, memberOf group: Group) async throws -> Bool {
        let cacheKey = "\(CacheKeys.isMember).\(user.id?.uuidString ?? "nil").\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }
        
        // Check in Core Data
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@ AND group == %@", user, group)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        let isMember = !results.isEmpty
        
        // Cache the result
        await CacheManager.shared.cacheValidation(isMember, for: cacheKey)
        
        return isMember
    }
    
    /// Get user group count
    func getUserGroupsCount() async throws -> Int {
        let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
        return try await count(request)
    }
}
