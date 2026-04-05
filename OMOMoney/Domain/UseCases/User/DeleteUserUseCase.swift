//
//  DeleteUserUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for deleting a user
/// Encapsulates the business logic for user deletion
protocol DeleteUserUseCase {
    /// Execute the use case to delete a user
    /// - Parameter userId: UUID of the user to delete
    /// - Throws: Repository errors
    func execute(userId: UUID) async throws
}

/// Default implementation of DeleteUserUseCase
final class DefaultDeleteUserUseCase: DeleteUserUseCase {
    
    // MARK: - Properties
    
    private let userRepository: UserRepository
    
    // MARK: - Initialization
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(userId: UUID) async throws {
        // Business logic: Could add checks here
        // e.g., verify user exists, check if user has dependencies, etc.
        
        // Delete user through repository
        try await userRepository.deleteUser(id: userId)
    }
}
