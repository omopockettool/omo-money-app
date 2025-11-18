//
//  UserGroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for UserGroup domain operations
/// Abstracts the data source implementation from business logic
protocol UserGroupRepository {
    /// Fetch all user-group relationships
    /// - Returns: Array of UserGroupDomain objects
    /// - Throws: Repository errors
    func fetchUserGroups() async throws -> [UserGroupDomain]
    
    /// Fetch a specific user-group relationship by ID
    /// - Parameter id: UserGroup UUID
    /// - Returns: UserGroupDomain object if found
    /// - Throws: Repository errors
    func fetchUserGroup(id: UUID) async throws -> UserGroupDomain?
    
    /// Fetch user groups for a specific user
    /// - Parameter userId: User UUID
    /// - Returns: Array of UserGroupDomain objects
    /// - Throws: Repository errors
    func fetchUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain]
    
    /// Fetch user groups for a specific group
    /// - Parameter groupId: Group UUID
    /// - Returns: Array of UserGroupDomain objects
    /// - Throws: Repository errors
    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain]
    
    /// Create a new user-group relationship
    /// - Parameters:
    ///   - userId: User UUID
    ///   - groupId: Group UUID
    ///   - role: User role in the group
    /// - Returns: Created UserGroupDomain object
    /// - Throws: Repository errors
    func createUserGroup(
        userId: UUID,
        groupId: UUID,
        role: String
    ) async throws -> UserGroupDomain
    
    /// Update an existing user-group relationship
    /// - Parameter userGroup: UserGroupDomain object with updated values
    /// - Throws: Repository errors
    func updateUserGroup(_ userGroup: UserGroupDomain) async throws
    
    /// Delete a user-group relationship by ID
    /// - Parameter id: UserGroup UUID to delete
    /// - Throws: Repository errors
    func deleteUserGroup(id: UUID) async throws
    
    /// Remove a user from a group
    /// - Parameters:
    ///   - userId: User UUID
    ///   - groupId: Group UUID
    /// - Throws: Repository errors
    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws
}
