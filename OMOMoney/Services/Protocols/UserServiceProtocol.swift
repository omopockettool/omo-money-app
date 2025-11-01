import CoreData
import Foundation

/// Protocol for User service operations
/// Enables dependency injection and testing
protocol UserServiceProtocol {
    
    // MARK: - User CRUD Operations
    
    /// Fetch user by ID
    func fetchUser(by id: UUID) async throws -> User?
    
    /// Create a new user
    func createUser(name: String, email: String?) async throws -> User
    
    /// Update an existing user
    func updateUser(_ user: User, name: String?, email: String?) async throws
    
    /// Delete a user
    func deleteUser(_ user: User) async throws
    
    /// Check if user exists by name
    func userExists(withName name: String, excluding userId: UUID?) async throws -> Bool
    
    // MARK: - Batch Operations
    
    /// Bulk delete users by IDs for better performance
    func bulkDeleteUsers(userIds: [UUID]) async throws
    
    /// Bulk update user status
    func bulkUpdateUserStatus(userIds: [UUID], isActive: Bool) async throws
    
    /// Create multiple users efficiently
    func createUsers(_ userDataList: [(name: String, email: String?)]) async throws -> [User]
}
