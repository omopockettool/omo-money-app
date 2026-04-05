//
//  FetchUsersUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for fetching users
/// Encapsulates the business logic for retrieving user data
protocol FetchUsersUseCase {
    /// Execute the use case to fetch all users
    /// - Returns: Array of UserDomain objects
    /// - Throws: Repository or domain errors
    func execute() async throws -> [UserDomain]
}

/// Default implementation of FetchUsersUseCase
final class DefaultFetchUsersUseCase: FetchUsersUseCase {
    
    // MARK: - Properties
    
    private let userRepository: UserRepository
    
    // MARK: - Initialization
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute() async throws -> [UserDomain] {
        // Business logic: Fetch and validate users
        let users = try await userRepository.fetchUsers()
        
        // Filter out invalid users (optional business rule)
        return users.filter { $0.isValid }
    }
}
