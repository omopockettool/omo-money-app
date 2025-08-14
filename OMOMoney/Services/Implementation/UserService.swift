import CoreData
import Foundation

/// Service class for User entity operations
/// Handles all CRUD operations for User with proper threading and caching
class UserService: CoreDataService, UserServiceProtocol {
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let allUsers = "UserService.allUsers"
        static let userCount = "UserService.userCount"
        static let userExists = "UserService.userExists"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - User CRUD Operations
    
    /// Fetch all users with caching
    func fetchUsers() async throws -> [User] {
        // Check cache first
        if let cachedUsers: [User] = await CacheManager.shared.getCachedData(for: CacheKeys.allUsers) {
            return cachedUsers
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        let users = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(users, for: CacheKeys.allUsers)
        
        return users
    }
    
    /// Fetch user by ID
    func fetchUser(by id: UUID) async throws -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new user
    func createUser(name: String, email: String? = nil) async throws -> User {
        let user = try await context.perform {
            let user = User(context: self.context)
            user.id = UUID()
            user.name = name
            user.email = email
            user.createdAt = Date()
            
            try self.context.save()
            return user
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUsers)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        
        return user
    }
    
    /// Update an existing user
    func updateUser(_ user: User, name: String? = nil, email: String? = nil) async throws {
        try await context.perform {
            if let name = name {
                user.name = name
            }
            if let email = email {
                user.email = email
            }
            user.lastModifiedAt = Date()
            
            try self.context.save()
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUsers)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
    }
    
    /// Delete a user
    func deleteUser(_ user: User) async throws {
        await delete(user)
        try await save()
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allUsers)
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
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
    
    /// Get users count with caching
    func getUsersCount() async throws -> Int {
        // Check cache first
        if let cachedCount: Int = await CacheManager.shared.getCachedData(for: CacheKeys.userCount) {
            return cachedCount
        }
        
        // Get from Core Data
        let request: NSFetchRequest<User> = User.fetchRequest()
        let count = try await count(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(count, for: CacheKeys.userCount)
        
        return count
    }
}
