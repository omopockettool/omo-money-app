//
//  CreateUserGroupUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for creating user-group relationships
/// Encapsulates the business logic for associating users with groups
protocol CreateUserGroupUseCase {
    /// Execute the use case to create a user-group relationship
    /// - Parameters:
    ///   - userId: User UUID
    ///   - groupId: Group UUID
    ///   - role: User's role in the group (default: "member")
    /// - Returns: Created UserGroupDomain object
    /// - Throws: Repository or validation errors
    func execute(userId: UUID, groupId: UUID, role: String) async throws -> UserGroupDomain
}

/// Default implementation of CreateUserGroupUseCase
final class DefaultCreateUserGroupUseCase: CreateUserGroupUseCase {
    
    // MARK: - Properties
    
    private let userGroupRepository: UserGroupRepository
    
    // MARK: - Initialization
    
    init(userGroupRepository: UserGroupRepository) {
        self.userGroupRepository = userGroupRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(userId: UUID, groupId: UUID, role: String = "member") async throws -> UserGroupDomain {
        // Business logic: Validate and create user-group relationship
        let trimmedRole = role.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedRole.isEmpty else {
            throw ValidationError.invalidRole
        }
        
        // Create the user-group relationship
        let userGroup = try await userGroupRepository.createUserGroup(
            userId: userId,
            groupId: groupId,
            role: trimmedRole
        )
        
        return userGroup
    }
}
