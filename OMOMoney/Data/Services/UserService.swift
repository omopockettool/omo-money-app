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
    
}
