import CoreData
import Foundation

/// Service class for User entity operations
/// Handles all CRUD operations for User with proper threading and caching
class UserService: CoreDataService, UserServiceProtocol {
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let userExists = "UserService.userExists"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - User CRUD Operations
    
    /// Fetch user by ID
    func fetchUser(by id: UUID) async throws -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Get the current user (there should only be one in a personal app)
    func getCurrentUser() async throws -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.createdAt, ascending: true)]
        
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
        
        // Invalidate relevant cache itemLists
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
        
        // Invalidate relevant cache itemLists
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
    }
    
    /// Delete a user
    func deleteUser(_ user: User) async throws {
        await delete(user)
        try await save()
        
        // Invalidate relevant cache itemLists
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
    
    // MARK: - Batch Operations
    
    /// Bulk delete users by IDs for better performance
    func bulkDeleteUsers(userIds: [UUID]) async throws {
        let predicate = NSPredicate(format: "id IN %@", userIds)
        _ = try await batchDelete(User.self, predicate: predicate)
        
        // Clear relevant caches
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
    }
    
    /// Bulk update user active status
    func bulkUpdateUserStatus(userIds: [UUID], isActive: Bool) async throws {
        let predicate = NSPredicate(format: "id IN %@", userIds)
        let properties = ["lastModifiedAt": Date()]
        
        _ = try await batchUpdate(User.self, predicate: predicate, propertiesToUpdate: properties)
        
        // Note: No global cache to clear since users should be accessed through UserGroupService
    }
    
    /// Create multiple users efficiently
    func createUsers(_ userDataList: [(name: String, email: String?)]) async throws -> [User] {
        // For small batches, use regular creation for better control
        if userDataList.count <= 10 {
            var createdUsers: [User] = []
            for userData in userDataList {
                let user = try await createUser(name: userData.name, email: userData.email)
                createdUsers.append(user)
            }
            return createdUsers
        }
        
        // For larger batches, use bulk insert
        let objects: [[String: Any]] = userDataList.map { userData in
            return [
                "id": UUID(),
                "name": userData.name,
                "email": userData.email ?? "",
                "createdAt": Date(),
                "lastModifiedAt": Date()
            ]
        }
        
        try await bulkInsert(User.self, objects: objects)
        
        // Clear validation cache
        await CacheManager.shared.clearValidationCache(for: CacheKeys.userExists)
        
        // Return created users by fetching from context (bulk insert doesn't return objects)
        let request: NSFetchRequest<User> = User.fetchRequest()
        let names = userDataList.map { $0.name }
        request.predicate = NSPredicate(format: "name IN %@", names)
        return try await fetch(request)
    }
}
