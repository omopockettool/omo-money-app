import CoreData
import Foundation

/// Service class for User entity operations
/// Handles all CRUD operations for User with proper threading and caching
/// ✅ REFACTORED: Returns Domain models, converts to Domain inside context.perform
class UserService: CoreDataService, UserServiceProtocol {

    // MARK: - Cache Keys
    private enum CacheKeys {
        static let userExists = "UserService.userExists"
        static let currentUser = "UserService.currentUser"
    }

    // MARK: - Initialization

    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }

    // MARK: - User CRUD Operations

    /// Fetch user by ID
    /// ✅ REFACTORED: Returns Domain model
    func fetchUser(by id: UUID) async throws -> UserDomain? {
        return try await context.perform {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false

            guard let user = try self.context.fetch(request).first else {
                return nil
            }

            // Convert to Domain INSIDE context.perform
            return user.toDomain()
        }
    }

    /// Get the current user (there should only be one in a personal app)
    /// ✅ REFACTORED: Returns Domain model with caching
    func getCurrentUser() async throws -> UserDomain? {
        // Check cache first
        if let cachedUser: UserDomain = await CacheManager.shared.getCachedData(for: CacheKeys.currentUser) {
            return cachedUser
        }

        let userDomain: UserDomain? = try await context.perform {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(keyPath: \User.createdAt, ascending: true)]
            request.returnsObjectsAsFaults = false

            guard let user = try self.context.fetch(request).first else {
                return nil
            }

            // Convert to Domain INSIDE context.perform
            return user.toDomain()
        }

        // Cache the result
        if let userDomain = userDomain {
            await CacheManager.shared.cacheData(userDomain, for: CacheKeys.currentUser)
        }

        return userDomain
    }
    
    /// Create a new user
    /// ✅ REFACTORED: Returns Domain model
    func createUser(name: String, email: String? = nil) async throws -> UserDomain {
        let userDomain = try await context.perform {
            let user = User(context: self.context)
            user.id = UUID()
            user.name = name
            user.email = email
            user.createdAt = Date()

            try self.context.save()

            // Convert to Domain INSIDE context.perform
            return user.toDomain()
        }

        // Invalidate relevant caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currentUser)

        return userDomain
    }

    
    /// Update an existing user
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func updateUser(userId: UUID, name: String? = nil, email: String? = nil) async throws {
        try await context.perform {
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            guard let user = try self.context.fetch(userRequest).first else {
                throw RepositoryError.notFound
            }

            if let name = name {
                user.name = name
            }
            if let email = email {
                user.email = email
            }
            user.lastModifiedAt = Date()

            try self.context.save()
        }

        // Invalidate relevant caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currentUser)
    }

    /// Delete a user
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func deleteUser(userId: UUID) async throws {
        try await context.perform {
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            guard let user = try self.context.fetch(userRequest).first else {
                throw RepositoryError.notFound
            }

            self.context.delete(user)
            try self.context.save()
        }

        // Invalidate relevant caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currentUser)
    }
    
    /// Check if user exists by name with caching
    func userExists(withName name: String, excluding userId: UUID? = nil) async throws -> Bool {
        let cacheKey = "\(CacheKeys.userExists).\(name).\(userId?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }
        
        // Check in Core Data
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "name == %@ AND id != %@", name, userId as CVarArg)
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
    
    /// Bulk delete users by IDs for better performance
    func bulkDeleteUsers(userIds: [UUID]) async throws {
        let predicate = NSPredicate(format: "id IN %@", userIds)
        _ = try await batchDelete(User.self, predicate: predicate)

        // Clear relevant caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currentUser)
    }
    
    /// Bulk update user active status
    func bulkUpdateUserStatus(userIds: [UUID], isActive: Bool) async throws {
        let predicate = NSPredicate(format: "id IN %@", userIds)
        let properties = ["lastModifiedAt": Date()]
        
        _ = try await batchUpdate(User.self, predicate: predicate, propertiesToUpdate: properties)
        
        // Note: No global cache to clear since users should be accessed through UserGroupService
    }
    
    /// Create multiple users efficiently
    /// ✅ REFACTORED: Returns Domain models
    func createUsers(_ userDataList: [(name: String, email: String?)]) async throws -> [UserDomain] {
        // For small batches, use regular creation for better control
        if userDataList.count <= 10 {
            var createdUsers: [UserDomain] = []
            for userData in userDataList {
                let userDomain = try await createUser(name: userData.name, email: userData.email)
                createdUsers.append(userDomain)
            }
            return createdUsers
        }

        // For larger batches, use bulk insert
        let userIds = try await context.perform {
            var userIds: [UUID] = []
            for userData in userDataList {
                let user = User(context: self.context)
                let userId = UUID()
                user.id = userId
                user.name = userData.name
                user.email = userData.email
                user.createdAt = Date()
                userIds.append(userId)
            }
            try self.context.save()
            return userIds
        }

        // Clear caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        await CacheManager.shared.clearDataCache(for: CacheKeys.currentUser)

        // Fetch created users as Domain models
        return try await context.perform {
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", userIds)
            request.returnsObjectsAsFaults = false

            let users = try self.context.fetch(request)
            return users.map { $0.toDomain() }
        }
    }
}
