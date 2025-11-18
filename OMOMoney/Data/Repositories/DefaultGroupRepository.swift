//
//  DefaultGroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Default implementation of GroupRepository
/// Wraps GroupService and converts between Core Data and Domain models
final class DefaultGroupRepository: GroupRepository {
    
    // MARK: - Properties
    
    private let groupService: GroupServiceProtocol
    
    // MARK: - Initialization
    
    init(groupService: GroupServiceProtocol) {
        self.groupService = groupService
    }
    
    // MARK: - GroupRepository Implementation
    
    func fetchGroups() async throws -> [GroupDomain] {
        let groups = try await groupService.fetchAllGroups()
        return groups.map { $0.toDomain() }
    }
    
    func fetchGroup(id: UUID) async throws -> GroupDomain? {
        guard let group = try await groupService.fetchGroup(by: id) else {
            return nil
        }
        return group.toDomain()
    }
    
    func createGroup(name: String, currency: String) async throws -> GroupDomain {
        let group = try await groupService.createGroup(name: name, currency: currency)
        return group.toDomain()
    }
    
    func updateGroup(_ group: GroupDomain) async throws {
        guard let coreDataGroup = try await groupService.fetchGroup(by: group.id) else {
            throw RepositoryError.notFound
        }
        
        try await groupService.updateGroup(
            coreDataGroup,
            name: group.name,
            currency: group.currency
        )
    }
    
    func deleteGroup(id: UUID) async throws {
        guard let group = try await groupService.fetchGroup(by: id) else {
            throw RepositoryError.notFound
        }
        
        try await groupService.deleteGroup(group)
    }
    
    func fetchGroups(forUserId userId: UUID) async throws -> [GroupDomain] {
        let groups = try await groupService.fetchGroups(forUserId: userId)
        return groups.map { $0.toDomain() }
    }
}
