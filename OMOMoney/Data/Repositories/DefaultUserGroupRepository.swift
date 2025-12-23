//
//  DefaultUserGroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//  ⚠️ TEMPORARY: UserGroupService still uses Core Data entities
//

import CoreData
import Foundation

/// Default implementation of UserGroupRepository
/// Wraps UserGroupService and converts between Core Data and Domain models
/// ⚠️ TEMPORARY: Needs context until UserGroupService is refactored
final class DefaultUserGroupRepository: UserGroupRepository {

    // MARK: - Properties

    private let userGroupService: UserGroupServiceProtocol
    private let userService: UserServiceProtocol
    private let groupService: GroupServiceProtocol
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(
        userGroupService: UserGroupServiceProtocol,
        userService: UserServiceProtocol,
        groupService: GroupServiceProtocol,
        context: NSManagedObjectContext
    ) {
        self.userGroupService = userGroupService
        self.userService = userService
        self.groupService = groupService
        self.context = context
    }
    
    // MARK: - UserGroupRepository Implementation
    
    func fetchUserGroups() async throws -> [UserGroupDomain] {
    // Note: In a real app, you might want to fetch all UserGroup entities
    // For now, this is not commonly used as we usually fetch by user or group
    fatalError("Not implemented")
    }
    
    func fetchUserGroup(id: UUID) async throws -> UserGroupDomain? {
        // ✅ Service already returns UserGroupDomain
        return try await userGroupService.fetchUserGroup(by: id)
    }
    
    func fetchUserGroups(forUserId userId: UUID) async throws -> [UserGroupDomain] {
        // ✅ Service already accepts UUID and returns Domain models
        return try await userGroupService.getUserGroups(forUserId: userId)
    }
    
    func fetchUserGroups(forGroupId groupId: UUID) async throws -> [UserGroupDomain] {
        // ✅ Service already accepts UUID and returns Domain models
        return try await userGroupService.getUserGroups(forGroupId: groupId)
    }
    
    func createUserGroup(
        userId: UUID,
        groupId: UUID,
        role: String
    ) async throws -> UserGroupDomain {
        // ✅ Service already accepts UUIDs and returns Domain model
        return try await userGroupService.createUserGroup(
            userId: userId,
            groupId: groupId,
            role: role
        )
    }
    
    func updateUserGroup(_ userGroup: UserGroupDomain) async throws {
        // ✅ Service accepts UUID parameter
        try await userGroupService.updateUserGroup(
            userGroupId: userGroup.id,
            role: userGroup.role
        )
    }

    func deleteUserGroup(id: UUID) async throws {
        // ✅ Service accepts UUID parameter
        try await userGroupService.deleteUserGroup(userGroupId: id)
    }
    
    func removeUser(_ userId: UUID, fromGroup groupId: UUID) async throws {
        // ✅ Service accepts UUIDs and returns Domain models
        let userGroups = try await userGroupService.getUserGroups(forUserId: userId)
        guard let userGroupToRemove = userGroups.first(where: { $0.groupId == groupId }) else {
            throw RepositoryError.notFound
        }

        try await userGroupService.deleteUserGroup(userGroupId: userGroupToRemove.id)
    }
}
