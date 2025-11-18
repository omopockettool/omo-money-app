//
//  DefaultUserRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Default implementation of UserRepository
/// Wraps UserService and converts between Core Data and Domain models
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
            return [user.toDomain()]
        }
        return []
    }
    
    func fetchUser(id: UUID) async throws -> UserDomain? {
        guard let user = try await userService.fetchUser(by: id) else {
            return nil
        }
        return user.toDomain()
    }
    
    func createUser(name: String, email: String) async throws -> UserDomain {
        let user = try await userService.createUser(name: name, email: email)
        return user.toDomain()
    }
    
    func updateUser(_ user: UserDomain) async throws {
        guard let coreDataUser = try await userService.fetchUser(by: user.id) else {
            throw RepositoryError.notFound
        }
        
        try await userService.updateUser(
            coreDataUser,
            name: user.name,
            email: user.email
        )
    }
    
    func deleteUser(id: UUID) async throws {
        guard let user = try await userService.fetchUser(by: id) else {
            throw RepositoryError.notFound
        }
        
        try await userService.deleteUser(user)
    }
    
    func searchUsers(query: String) async throws -> [UserDomain] {
        // Get current user and filter by query
        if let user = try await userService.getCurrentUser() {
            let domain = user.toDomain()
            if domain.name.localizedCaseInsensitiveContains(query) ||
               domain.email.localizedCaseInsensitiveContains(query) {
                return [domain]
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
