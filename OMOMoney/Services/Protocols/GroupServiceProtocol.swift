import CoreData
import Foundation

/// Protocol for Group service operations
/// Enables dependency injection and testing
protocol GroupServiceProtocol {
    
    // MARK: - Group CRUD Operations
    
    /// Fetch all groups
    func fetchGroups() async throws -> [Group]
    
    /// Fetch group by ID
    func fetchGroup(by id: UUID) async throws -> Group?
    
    /// Create a new group
    func createGroup(name: String, currency: String) async throws -> Group
    
    /// Update an existing group
    func updateGroup(_ group: Group, name: String?, currency: String?) async throws
    
    /// Delete a group
    func deleteGroup(_ group: Group) async throws
    
    /// Check if group exists by name
    func groupExists(withName name: String, excluding groupId: UUID?) async throws -> Bool
    
    /// Get groups count
    func getGroupsCount() async throws -> Int
    
    // MARK: - Batch Operations
    
    /// Bulk delete groups by IDs for better performance
    func bulkDeleteGroups(groupIds: [UUID]) async throws
    
    /// Bulk update group currency
    func bulkUpdateGroupCurrency(groupIds: [UUID], currency: String) async throws
    
    /// Bulk update group status (if applicable)
    func bulkUpdateGroupStatus(groupIds: [UUID], isActive: Bool) async throws
    
    /// Create multiple groups efficiently
    func createGroups(_ groupDataList: [(name: String, currency: String)]) async throws -> [Group]
    
    /// Get groups count for specific currency
    func getGroupsCount(for currency: String) async throws -> Int
    
    /// Get group members count
    func getGroupMembersCount(_ group: Group) async throws -> Int
}
