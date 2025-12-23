import CoreData
import Foundation

/// Service class for UserGroup entity operations
/// Handles all CRUD operations for UserGroup with proper threading and caching
/// ✅ REFACTORED: Pure Domain Architecture - returns Domain models, accepts UUIDs
class UserGroupService: CoreDataService, UserGroupServiceProtocol {

    // MARK: - Cache Keys
    enum CacheKeys {
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

    /// Fetch user group by ID
    /// ✅ REFACTORED: Returns UserGroupDomain
    func fetchUserGroup(by id: UUID) async throws -> UserGroupDomain? {
        let userGroupDomain: UserGroupDomain? = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            guard let userGroup = try self.context.fetch(request).first else {
                return nil
            }

            return userGroup.toDomain()
        }

        return userGroupDomain
    }

    /// Create a new user group relationship
    /// ✅ REFACTORED: Accepts UUIDs, returns UserGroupDomain
    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> UserGroupDomain {
        let userGroupDomain = try await context.perform {
            // Fetch User and Group entities in this context
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let user = try self.context.fetch(userRequest).first else {
                throw NSError(domain: "UserGroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }

            guard let group = try self.context.fetch(groupRequest).first else {
                throw NSError(domain: "UserGroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found"])
            }

            // Create UserGroup
            let userGroup = UserGroup(context: self.context)
            userGroup.id = UUID()
            userGroup.user = user
            userGroup.group = group
            userGroup.userId = userId
            userGroup.groupId = groupId
            userGroup.role = role
            userGroup.joinedAt = Date()

            try self.context.save()

            // Convert to Domain model INSIDE context.perform
            return userGroup.toDomain()
        }

        // Invalidate relevant cache entries
        await invalidateAllCaches()

        return userGroupDomain
    }

    /// Update an existing user group
    /// ✅ REFACTORED: Accepts UUID parameter
    func updateUserGroup(userGroupId: UUID, role: String?) async throws {
        try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", userGroupId as CVarArg)
            request.fetchLimit = 1

            guard let userGroup = try self.context.fetch(request).first else {
                throw NSError(domain: "UserGroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "UserGroup not found"])
            }

            if let role = role {
                userGroup.role = role
            }

            try self.context.save()
        }

        // Invalidate relevant cache entries
        await invalidateAllCaches()
    }

    /// Delete a user group relationship
    /// ✅ REFACTORED: Accepts UUID parameter
    func deleteUserGroup(userGroupId: UUID) async throws {
        try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", userGroupId as CVarArg)
            request.fetchLimit = 1

            guard let userGroup = try self.context.fetch(request).first else {
                throw NSError(domain: "UserGroupService", code: 404, userInfo: [NSLocalizedDescriptionKey: "UserGroup not found"])
            }

            self.context.delete(userGroup)
            try self.context.save()
        }

        // Invalidate relevant cache entries
        await invalidateAllCaches()
    }

    /// Get user groups for a specific user with caching
    /// ✅ REFACTORED: Accepts UUID, returns UserGroupDomain array
    func getUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain] {
        let cacheKey = "\(CacheKeys.userUserGroups).\(userId.uuidString)"

        // Check cache first
        if let cachedUserGroups: [UserGroupDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUserGroups
        }

        // Fetch from Core Data and convert to Domain
        let userGroupDomains: [UserGroupDomain] = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]

            let userGroups = try self.context.fetch(request)

            // Convert to Domain models INSIDE context.perform
            return userGroups.map { $0.toDomain() }
        }

        // Cache the Domain models
        await CacheManager.shared.cacheData(userGroupDomains, for: cacheKey)

        return userGroupDomains
    }

    /// Get user groups for a specific group with caching
    /// ✅ REFACTORED: Accepts UUID, returns UserGroupDomain array
    func getUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain] {
        let cacheKey = "\(CacheKeys.groupUserGroups).\(groupId.uuidString)"

        // Check cache first
        if let cachedUserGroups: [UserGroupDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUserGroups
        }

        // Fetch from Core Data and convert to Domain
        let userGroupDomains: [UserGroupDomain] = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "groupId == %@", groupId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]

            let userGroups = try self.context.fetch(request)

            // Convert to Domain models INSIDE context.perform
            return userGroups.map { $0.toDomain() }
        }

        // Cache the Domain models
        await CacheManager.shared.cacheData(userGroupDomains, for: cacheKey)

        return userGroupDomains
    }

    /// Get users in a specific group with caching
    /// ✅ REFACTORED: Accepts UUID, returns UserDomain array
    func getUsers(inGroupId groupId: UUID) async throws -> [UserDomain] {
        let cacheKey = "\(CacheKeys.usersInGroup).\(groupId.uuidString)"

        // Check cache first
        if let cachedUsers: [UserDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedUsers
        }

        // Fetch from Core Data and convert to Domain
        let userDomains: [UserDomain] = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "groupId == %@", groupId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
            request.relationshipKeyPathsForPrefetching = ["user"]

            let userGroups = try self.context.fetch(request)

            // Extract users and convert to Domain models INSIDE context.perform
            let users = userGroups.compactMap { $0.user }
            return users.map { $0.toDomain() }
        }

        // Cache the Domain models
        await CacheManager.shared.cacheData(userDomains, for: cacheKey)

        return userDomains
    }

    /// Get groups for a specific user with caching
    /// ✅ REFACTORED: Accepts UUID, returns GroupDomain array
    func getGroups(forUserId userId: UUID) async throws -> [GroupDomain] {
        let cacheKey = "\(CacheKeys.groupsForUser).\(userId.uuidString)"

        // Check cache first
        if let cachedGroups: [GroupDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedGroups
        }

        // Fetch from Core Data and convert to Domain
        let groupDomains: [GroupDomain] = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@", userId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \UserGroup.joinedAt, ascending: true)]
            request.relationshipKeyPathsForPrefetching = ["group"]

            let userGroups = try self.context.fetch(request)

            // Extract groups and convert to Domain models INSIDE context.perform
            let groups = userGroups.compactMap { $0.group }
            return groups.map { $0.toDomain() }
        }

        // Cache the Domain models
        await CacheManager.shared.cacheData(groupDomains, for: cacheKey)

        return groupDomains
    }

    /// Check if user is member of group with caching
    /// ✅ REFACTORED: Accepts UUIDs
    func isUserMember(userId: UUID, groupId: UUID) async throws -> Bool {
        let cacheKey = "\(CacheKeys.isMember).\(userId.uuidString).\(groupId.uuidString)"

        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }

        // Check in Core Data
        let isMember = try await context.perform {
            let request: NSFetchRequest<UserGroup> = UserGroup.fetchRequest()
            request.predicate = NSPredicate(format: "userId == %@ AND groupId == %@", userId as CVarArg, groupId as CVarArg)
            request.fetchLimit = 1

            let results = try self.context.fetch(request)
            return !results.isEmpty
        }

        // Cache the result
        await CacheManager.shared.cacheValidation(isMember, for: cacheKey)

        return isMember
    }

    // MARK: - Cache Invalidation

    private func invalidateAllCaches() async {
        await CacheManager.shared.clearDataCache(for: CacheKeys.userUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupUserGroups)
        await CacheManager.shared.clearDataCache(for: CacheKeys.usersInGroup)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupsForUser)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.isMember)
    }
}
