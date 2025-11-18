//
//  FetchGroupsUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for fetching groups
/// Encapsulates the business logic for retrieving group data
protocol FetchGroupsUseCase {
    /// Execute the use case to fetch all groups
    /// - Returns: Array of GroupDomain objects
    /// - Throws: Repository or domain errors
    func execute() async throws -> [GroupDomain]
    
    /// Execute the use case to fetch groups for a specific user
    /// - Parameter userId: User UUID
    /// - Returns: Array of GroupDomain objects
    /// - Throws: Repository or domain errors
    func execute(forUserId userId: UUID) async throws -> [GroupDomain]
}

/// Default implementation of FetchGroupsUseCase
final class DefaultFetchGroupsUseCase: FetchGroupsUseCase {
    
    // MARK: - Properties
    
    private let groupRepository: GroupRepository
    
    // MARK: - Initialization
    
    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute() async throws -> [GroupDomain] {
        // Business logic: Fetch and validate groups
        let groups = try await groupRepository.fetchGroups()
        
        // Filter out invalid groups (optional business rule)
        return groups.filter { $0.isValid }
    }
    
    func execute(forUserId userId: UUID) async throws -> [GroupDomain] {
        // Business logic: Fetch groups for specific user
        let groups = try await groupRepository.fetchGroups(forUserId: userId)
        
        // Filter out invalid groups
        return groups.filter { $0.isValid }
    }
}
