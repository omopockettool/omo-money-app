//
//  DefaultUserGroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Default implementation of UserGroupRepository
/// Wraps UserGroupService and converts between Core Data and Domain models
final class DefaultUserGroupRepository: UserGroupRepository {
    
    // MARK: - Properties
    
    private let userGroupService: UserGroupServiceProtocol
    private let userService: UserServiceProtocol
    private let groupService: GroupServiceProtocol
    
    // MARK: - Initialization
    
    init(
        userGroupService: UserGroupServiceProtocol,
        userService: UserServiceProtocol,
        groupService: GroupServiceProtocol
    ) {
        self.userGroupService = userGroupService
        self.userService = userService
        self.groupService = groupService
    }
    
    // MARK: - UserGroupRepository Implementation
    
    func fetchUserGroups() async throws -> [UserGroupDomain] {
    // Note: In a real app, you might want to fetch all UserGroup entities
    // For now, this is not commonly used as we usually fetch by user or group
    fatalError("Not implemented")
    }
    
    func fetchUserGroup(id: UUID) async throws -> UserGroupDomain? {
        guard let userGroup = try await userGroupService.fetchUserGroup(by: id) else {
            return nil
        }
        return userGroup.toDomain()
    }
    
    func fetchUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain] {
        guard let user = try await userService.fetchUser(by: userId) else {
            throw RepositoryError.notFound
        }
        
        let userGroups = try await userGroupService.getUserGroups(for: user)
        return userGroups.map { $0.toDomain() }
    }
    
    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain] {
        guard let group = try await groupService.fetchGroup(by: groupId) else {
            throw RepositoryError.notFound
        }
        
        let userGroups = try await userGroupService.getUserGroups(for: group)
        return userGroups.map { $0.toDomain() }
    }
    
    func createUserGroup(
        userId: UUID,
        groupId: UUID,
        role: String
    ) async throws -> UserGroupDomain {
        // Fetch the user and group entities
        guard let user = try await userService.fetchUser(by: userId) else {
            throw RepositoryError.notFound
        }
        
        guard let group = try await groupService.fetchGroup(by: groupId) else {
            throw RepositoryError.notFound
        }
        
        // Create the user-group relationship
        let userGroup = try await userGroupService.createUserGroup(
            user: user,
            group: group,
            role: role
        )
        
        return userGroup.toDomain()
    }
    
    func updateUserGroup(_ userGroup: UserGroupDomain) async throws {
        guard let coreDataUserGroup = try await userGroupService.fetchUserGroup(by: userGroup.id) else {
            throw RepositoryError.notFound
        }
        
        try await userGroupService.updateUserGroup(
            coreDataUserGroup,
            role: userGroup.role
        )
    }
    
    func deleteUserGroup(id: UUID) async throws {
        guard let userGroup = try await userGroupService.fetchUserGroup(by: id) else {
            throw RepositoryError.notFound
        }
        
        try await userGroupService.deleteUserGroup(userGroup)
    }
    
    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws {
        // Fetch the user-group relationship
        guard let user = try await userService.fetchUser(by: userId) else {
            throw RepositoryError.notFound
        }
        
        let userGroups = try await userGroupService.getUserGroups(for: user)
        guard let userGroupToRemove = userGroups.first(where: { $0.groupId == groupId }) else {
            throw RepositoryError.notFound
        }
        
        try await userGroupService.deleteUserGroup(userGroupToRemove)
    }
}
