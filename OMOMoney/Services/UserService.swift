import Foundation
import CoreData

/// Service class for User entity operations
/// Handles all CRUD operations for User with proper threading
@MainActor
class UserService: CoreDataService {
    
    // MARK: - User CRUD Operations
    
    /// Fetch all users
    func fetchUsers() async throws -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        return try await fetch(request)
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
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let user = User(context: self.context)
                user.id = UUID()
                user.name = name
                user.email = email
                user.createdAt = Date()
                
                do {
                    try self.context.save()
                    continuation.resume(returning: user)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update an existing user
    func updateUser(_ user: User, name: String? = nil, email: String? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                if let name = name {
                    user.name = name
                }
                if let email = email {
                    user.email = email
                }
                user.lastModifiedAt = Date()
                
                do {
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete a user
    func deleteUser(_ user: User) async throws {
        try await delete(user)
        try await save()
    }
    
    /// Check if user exists by name
    func userExists(withName name: String, excluding userId: UUID? = nil) async throws -> Bool {
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        if let userId = userId {
            request.predicate = NSPredicate(format: "name == %@ AND id != %@", name, userId as CVarArg)
        } else {
            request.predicate = NSPredicate(format: "name == %@", name)
        }
        
        let count = try await count(request)
        return count > 0
    }
    
    /// Get users count
    func getUsersCount() async throws -> Int {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try await count(request)
    }
}
