//
//  UserRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for User domain operations
/// Abstracts the data source implementation from business logic
protocol UserRepository {
    /// Fetch all users
    /// - Returns: Array of UserDomain objects
    /// - Throws: Repository errors
    func fetchUsers() async throws -> [UserDomain]
    
    /// Fetch a specific user by ID
    /// - Parameter id: User UUID
    /// - Returns: UserDomain object if found
    /// - Throws: Repository errors
    func fetchUser(id: UUID) async throws -> UserDomain?
    
    /// Create a new user
    /// - Parameters:
    ///   - name: User name
    ///   - email: User email
    /// - Returns: Created UserDomain object
    /// - Throws: Repository errors or validation errors
    func createUser(name: String, email: String) async throws -> UserDomain
    
    /// Update an existing user
    /// - Parameter user: UserDomain object with updated values
    /// - Throws: Repository errors
    func updateUser(_ user: UserDomain) async throws
    
    /// Delete a user by ID
    /// - Parameter id: User UUID to delete
    /// - Throws: Repository errors
    func deleteUser(id: UUID) async throws
    
    /// Search users by name or email
    /// - Parameter query: Search string
    /// - Returns: Array of matching UserDomain objects
    /// - Throws: Repository errors
    func searchUsers(query: String) async throws -> [UserDomain]
}
