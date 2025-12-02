//
//  GetCurrentUserUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for getting the current user
protocol GetCurrentUserUseCase {
    /// Execute the use case to get the current user
    /// - Returns: UserDomain object if found
    /// - Throws: Repository errors
    func execute() async throws -> UserDomain?
}

final class DefaultGetCurrentUserUseCase: GetCurrentUserUseCase {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func execute() async throws -> UserDomain? {
        // Business logic: Get all users and return the first one
        // In a real app, this would check authentication state
        let users = try await userRepository.fetchUsers()
        return users.first
    }
}
