//
//  CreateUserUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for creating a new user
/// Encapsulates the business logic for user creation with validation
protocol CreateUserUseCase {
    /// Execute the use case to create a new user
    /// - Parameters:
    ///   - name: User name
    ///   - email: User email
    /// - Returns: Created UserDomain object
    /// - Throws: ValidationError or repository errors
    func execute(name: String, email: String) async throws -> UserDomain
}

/// Default implementation of CreateUserUseCase
final class DefaultCreateUserUseCase: CreateUserUseCase {
    
    // MARK: - Properties
    
    private let userRepository: UserRepository
    
    // MARK: - Initialization
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(name: String, email: String) async throws -> UserDomain {
        // Business validation logic
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyName
        }
        
        guard !trimmedEmail.isEmpty else {
            throw ValidationError.emptyEmail
        }
        
        guard trimmedEmail.contains("@") else {
            throw ValidationError.invalidEmail
        }
        
        // Create user through repository
        let user = try await userRepository.createUser(
            name: trimmedName,
            email: trimmedEmail
        )
        
        return user
    }
}
