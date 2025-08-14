import Foundation
import CoreData

/// Protocol for UserGroup service operations
/// Enables dependency injection and testing
protocol UserGroupServiceProtocol {
    
    // MARK: - UserGroup CRUD Operations
    
    /// Fetch all user groups
    func fetchUserGroups() async throws -> [UserGroup]
    
    /// Fetch user group by ID
    func fetchUserGroup(by id: UUID) async throws -> UserGroup?
    
    /// Create a new user group relationship
    func createUserGroup(user: User, group: Group, role: String) async throws -> UserGroup
    
    /// Update an existing user group
    func updateUserGroup(_ userGroup: UserGroup, role: String?) async throws
    
    /// Delete a user group relationship
    func deleteUserGroup(_ userGroup: UserGroup) async throws
    
    /// Get user groups for a specific user
    func getUserGroups(for user: User) async throws -> [UserGroup]
    
    /// Get user groups for a specific group
    func getUserGroups(for group: Group) async throws -> [UserGroup]
    
    /// Get users in a specific group
    func getUsers(in group: Group) async throws -> [User]
    
    /// Get groups for a specific user
    func getGroups(for user: User) async throws -> [Group]
    
    /// Check if user is member of group
    func isUser(_ user: User, memberOf group: Group) async throws -> Bool
    
    /// Get user group count
    func getUserGroupsCount() async throws -> Int
}
