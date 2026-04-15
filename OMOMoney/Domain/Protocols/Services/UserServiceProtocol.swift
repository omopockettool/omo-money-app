import Foundation

/// Protocol for User service operations
/// Enables dependency injection and testing
/// ✅ REFACTORED: Returns Domain models, accepts UUID parameters (Clean Architecture)
protocol UserServiceProtocol {

    // MARK: - User CRUD Operations

    /// Fetch user by ID
    func fetchUser(by id: UUID) async throws -> UserDomain?

    /// Get the current user (there should only be one in a personal app)
    func getCurrentUser() async throws -> UserDomain?

    /// Create a new user
    func createUser(name: String, email: String?) async throws -> UserDomain

    /// Update an existing user
    func updateUser(userId: UUID, name: String?, email: String?) async throws

    /// Delete a user
    func deleteUser(userId: UUID) async throws

    /// Check if user exists by name
    func userExists(withName name: String, excluding userId: UUID?) async throws -> Bool

}
