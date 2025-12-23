//
//  DefaultGroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//  ✅ REFACTORED: Thin wrapper - Service returns Domain models directly
//

import CoreData
import Foundation

/// Default implementation of GroupRepository
/// ✅ REFACTORED: Thin wrapper - Service returns Domain models directly
final class DefaultGroupRepository: GroupRepository {

    // MARK: - Properties

    private let groupService: GroupServiceProtocol
    private let userGroupService: UserGroupServiceProtocol
    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(
        groupService: GroupServiceProtocol,
        userGroupService: UserGroupServiceProtocol,
        context: NSManagedObjectContext
    ) {
        self.groupService = groupService
        self.userGroupService = userGroupService
        self.context = context
    }

    // MARK: - GroupRepository Implementation

    func fetchGroup(id: UUID) async throws -> GroupDomain? {
        // Simple passthrough - Service returns Domain model directly
        return try await groupService.fetchGroup(by: id)
    }

    func createGroup(name: String, currency: String) async throws -> GroupDomain {
        // Simple passthrough - Service returns Domain model directly
        return try await groupService.createGroup(name: name, currency: currency)
    }

    func updateGroup(_ group: GroupDomain) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await groupService.updateGroup(
            groupId: group.id,
            name: group.name,
            currency: group.currency
        )
    }

    func deleteGroup(id: UUID) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await groupService.deleteGroup(groupId: id)
    }

    func fetchGroups(forUserId userId: UUID) async throws -> [GroupDomain] {
        // ✅ REFACTORED: UserGroupService now accepts UUID and returns Domain models
        return try await userGroupService.getGroups(forUserId: userId)
    }
}
