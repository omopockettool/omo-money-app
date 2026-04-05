//
//  UpdateUserUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for updating an existing user
/// Encapsulates the business logic for user updates with validation
protocol UpdateUserUseCase {
    /// Execute the use case to update a user
    /// - Parameter user: UserDomain object with updated values
    /// - Throws: ValidationError or repository errors
    func execute(user: UserDomain) async throws
}

/// Default implementation of UpdateUserUseCase
final class DefaultUpdateUserUseCase: UpdateUserUseCase {
    
    // MARK: - Properties
    
    private let userRepository: UserRepository
    
    // MARK: - Initialization
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(user: UserDomain) async throws {
        // Business validation logic
        try user.validate()
        
        // Update user through repository
        try await userRepository.updateUser(user)
    }
}
