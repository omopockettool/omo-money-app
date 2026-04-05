//
//  FetchGroupsForUserUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for fetching groups for a user
protocol FetchGroupsForUserUseCase {
    /// Execute the use case to fetch groups for a specific user
    /// - Parameter userId: User UUID
    /// - Returns: Array of GroupDomain objects
    /// - Throws: Repository errors
    func execute(userId: UUID) async throws -> [GroupDomain]
}

final class DefaultFetchGroupsForUserUseCase: FetchGroupsForUserUseCase {
    private let groupRepository: GroupRepository

    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }

    func execute(userId: UUID) async throws -> [GroupDomain] {
        // Business logic: Fetch groups for the user
        return try await groupRepository.fetchGroups(forUserId: userId)
    }
}
