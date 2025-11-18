//
//  GroupRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for Group domain operations
/// Abstracts the data source implementation from business logic
protocol GroupRepository {
    /// Fetch a specific group by ID
    /// - Parameter id: Group UUID
    /// - Returns: GroupDomain object if found
    /// - Throws: Repository errors
    func fetchGroup(id: UUID) async throws -> GroupDomain?
    
    /// Create a new group
    /// - Parameters:
    ///   - name: Group name
    ///   - currency: Currency code (default: USD)
    /// - Returns: Created GroupDomain object
    /// - Throws: Repository errors or validation errors
    func createGroup(name: String, currency: String) async throws -> GroupDomain
    
    /// Update an existing group
    /// - Parameter group: GroupDomain object with updated values
    /// - Throws: Repository errors
    func updateGroup(_ group: GroupDomain) async throws
    
    /// Delete a group by ID
    /// - Parameter id: Group UUID to delete
    /// - Throws: Repository errors
    func deleteGroup(id: UUID) async throws
    
    /// Fetch groups for a specific user
    /// - Parameter userId: User UUID
    /// - Returns: Array of GroupDomain objects
    /// - Throws: Repository errors
    func fetchGroups(forUserId userId: UUID) async throws -> [GroupDomain]
}
