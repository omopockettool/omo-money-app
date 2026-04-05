//
//  SearchUsersUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for searching users
/// Encapsulates the business logic for user search
protocol SearchUsersUseCase {
    /// Execute the use case to search for users
    /// - Parameter query: Search query string
    /// - Returns: Array of matching UserDomain objects
    /// - Throws: Repository errors
    func execute(query: String) async throws -> [UserDomain]
}

/// Default implementation of SearchUsersUseCase
final class DefaultSearchUsersUseCase: SearchUsersUseCase {
    
    // MARK: - Properties
    
    private let userRepository: UserRepository
    
    // MARK: - Initialization
    
    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }
    
    // MARK: - Use Case Execution
    
    func execute(query: String) async throws -> [UserDomain] {
        // Business logic: Sanitize search query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            // Return all users if query is empty
            return try await userRepository.fetchUsers()
        }
        
        // Search through repository
        return try await userRepository.searchUsers(query: trimmedQuery)
    }
}
