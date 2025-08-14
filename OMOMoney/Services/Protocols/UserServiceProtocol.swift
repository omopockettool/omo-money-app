import CoreData
import Foundation

/// Protocol for User service operations
/// Enables dependency injection and testing
protocol UserServiceProtocol {
    
    // MARK: - User CRUD Operations
    
    /// Fetch all users
    func fetchUsers() async throws -> [User]
    
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
    
    /// Get users count
    func getUsersCount() async throws -> Int
}
