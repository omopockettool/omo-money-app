//
//  DeleteGroupUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for deleting a group
/// Encapsulates the business logic for group deletion
protocol DeleteGroupUseCase {
    /// Execute the use case to delete a group
    /// - Parameter groupId: UUID of the group to delete
    /// - Throws: Repository errors
    func execute(groupId: UUID) async throws
}

/// Default implementation of DeleteGroupUseCase
final class DefaultDeleteGroupUseCase: DeleteGroupUseCase {
    
    // MARK: - Properties
    
    private let groupRepository: GroupRepository
    
    // MARK: - Initialization
    
    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(groupId: UUID) async throws {
        // Business logic: Could add checks here
        // e.g., verify group exists, check if group has members, etc.
        
        // Delete group through repository
        try await groupRepository.deleteGroup(id: groupId)
    }
}
