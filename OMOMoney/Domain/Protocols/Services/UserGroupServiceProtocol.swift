import Foundation

/// Protocol for UserGroup service operations
/// Enables dependency injection and testing
/// ✅ REFACTORED: Pure Domain Architecture - returns Domain models, accepts UUIDs
protocol UserGroupServiceProtocol {

    // MARK: - UserGroup CRUD Operations

    /// Fetch user group by ID
    /// - Returns: UserGroupDomain model
    func fetchUserGroup(by id: UUID) async throws -> UserGroupDomain?

    /// Create a new user group relationship
    /// - Parameters:
    ///   - userId: UUID of the user
    ///   - groupId: UUID of the group
    ///   - role: Role string (owner, admin, member)
    /// - Returns: UserGroupDomain model
    func createUserGroup(userId: UUID, groupId: UUID, role: String) async throws -> UserGroupDomain

    /// Update an existing user group
    /// - Parameters:
    ///   - userGroupId: UUID of the UserGroup to update
    ///   - role: New role (optional)
    func updateUserGroup(userGroupId: UUID, role: String?) async throws

    /// Delete a user group relationship
    /// - Parameter userGroupId: UUID of the UserGroup to delete
    func deleteUserGroup(userGroupId: UUID) async throws

    /// Get user groups for a specific user
    /// - Parameter userId: UUID of the user
    /// - Returns: Array of UserGroupDomain models
    func getUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain]

    /// Get user groups for a specific group
    /// - Parameter groupId: UUID of the group
    /// - Returns: Array of UserGroupDomain models
    func getUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain]

    /// Get users in a specific group
    /// - Parameter groupId: UUID of the group
    /// - Returns: Array of UserDomain models
    func getUsers(inGroupId groupId: UUID) async throws -> [UserDomain]

    /// Get groups for a specific user
    /// - Parameter userId: UUID of the user
    /// - Returns: Array of GroupDomain models
    func getGroups(forUserId userId: UUID) async throws -> [GroupDomain]

    /// Check if user is member of group
    /// - Parameters:
    ///   - userId: UUID of the user
    ///   - groupId: UUID of the group
    /// - Returns: Boolean indicating membership
    func isUserMember(userId: UUID, groupId: UUID) async throws -> Bool
}
