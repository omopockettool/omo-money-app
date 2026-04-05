//
//  UpdateGroupUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for updating an existing group
/// Encapsulates the business logic for group updates with validation
protocol UpdateGroupUseCase {
    /// Execute the use case to update a group
    /// - Parameter group: GroupDomain object with updated values
    /// - Throws: ValidationError or repository errors
    func execute(group: GroupDomain) async throws
}

/// Default implementation of UpdateGroupUseCase
final class DefaultUpdateGroupUseCase: UpdateGroupUseCase {
    
    // MARK: - Properties
    
    private let groupRepository: GroupRepository
    
    // MARK: - Initialization
    
    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(group: GroupDomain) async throws {
        // Business validation logic
        try group.validate()
        
        // Update group through repository
        try await groupRepository.updateGroup(group)
    }
}
