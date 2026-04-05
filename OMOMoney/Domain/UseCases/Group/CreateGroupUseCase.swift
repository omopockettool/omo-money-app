//
//  CreateGroupUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for creating a new group
/// Encapsulates the business logic for group creation with validation
protocol CreateGroupUseCase {
    /// Execute the use case to create a new group
    /// - Parameters:
    ///   - name: Group name
    ///   - currency: Currency code (default: USD)
    /// - Returns: Created GroupDomain object
    /// - Throws: ValidationError or repository errors
    func execute(name: String, currency: String) async throws -> GroupDomain
}

/// Default implementation of CreateGroupUseCase
final class DefaultCreateGroupUseCase: CreateGroupUseCase {
    
    // MARK: - Properties
    
    private let groupRepository: GroupRepository
    
    // MARK: - Initialization
    
    init(groupRepository: GroupRepository) {
        self.groupRepository = groupRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(name: String, currency: String = "USD") async throws -> GroupDomain {
        // Business validation logic
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyGroupName
        }
        
        guard !trimmedCurrency.isEmpty else {
            throw ValidationError.invalidAmount
        }
        
        // Create group through repository
        let group = try await groupRepository.createGroup(
            name: trimmedName,
            currency: trimmedCurrency
        )
        
        return group
    }
}
