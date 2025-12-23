//
//  DefaultUserRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//  ✅ REFACTORED: Thin wrapper - Service returns Domain models directly
//

import Foundation

/// Default implementation of UserRepository
/// ✅ REFACTORED: Thin wrapper - Service returns Domain models directly
final class DefaultUserRepository: UserRepository {

    // MARK: - Properties

    private let userService: UserServiceProtocol

    // MARK: - Initialization

    init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    // MARK: - UserRepository Implementation

    func fetchUsers() async throws -> [UserDomain] {
        // Note: UserService doesn't have fetchAll, we'll need to get current user
        // For now, return array with current user if exists
        if let user = try await userService.getCurrentUser() {
            return [user]
        }
        return []
    }

    func fetchUser(id: UUID) async throws -> UserDomain? {
        // Simple passthrough - Service returns Domain model directly
        return try await userService.fetchUser(by: id)
    }

    func createUser(name: String, email: String) async throws -> UserDomain {
        // Simple passthrough - Service returns Domain model directly
        return try await userService.createUser(name: name, email: email)
    }

    func updateUser(_ user: UserDomain) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await userService.updateUser(
            userId: user.id,
            name: user.name,
            email: user.email
        )
    }

    func deleteUser(id: UUID) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await userService.deleteUser(userId: id)
    }

    func searchUsers(query: String) async throws -> [UserDomain] {
        // Get current user and filter by query
        if let user = try await userService.getCurrentUser() {
            if user.name.localizedCaseInsensitiveContains(query) ||
               user.email.localizedCaseInsensitiveContains(query) {
                return [user]
            }
        }
        return []
    }
}

// MARK: - Repository Errors
enum RepositoryError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "The requested item was not found"
        case .invalidData:
            return "The provided data is invalid"
        case .saveFailed:
            return "Failed to save the item"
        case .deleteFailed:
            return "Failed to delete the item"
        }
    }
}
