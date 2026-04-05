import Foundation

/// Protocol for Group service operations
/// Enables dependency injection and testing
/// ✅ REFACTORED: Returns Domain models, accepts UUID parameters (Clean Architecture)
protocol GroupServiceProtocol {

    // MARK: - Group CRUD Operations

    // NOTE: Use UserGroupService.getGroups(for userId: UUID) for dashboard group dropdown

    /// Fetch group by ID
    func fetchGroup(by id: UUID) async throws -> GroupDomain?

    /// Create a new group
    func createGroup(name: String, currency: String) async throws -> GroupDomain

    /// Update an existing group
    func updateGroup(groupId: UUID, name: String?, currency: String?) async throws

    /// Delete a group
    func deleteGroup(groupId: UUID) async throws

    /// Check if group exists by name
    func groupExists(withName name: String, excluding groupId: UUID?) async throws -> Bool

    // MARK: - Batch Operations

    /// Bulk delete groups by IDs for better performance
    func bulkDeleteGroups(groupIds: [UUID]) async throws

    /// Bulk update group currency
    func bulkUpdateGroupCurrency(groupIds: [UUID], currency: String) async throws

    /// Bulk update group status (if applicable)
    func bulkUpdateGroupStatus(groupIds: [UUID], isActive: Bool) async throws

    /// Create multiple groups efficiently
    func createGroups(_ groupDataList: [(name: String, currency: String)]) async throws -> [GroupDomain]

    /// Get groups count for specific currency
    func getGroupsCount(for currency: String) async throws -> Int

    /// Get group members count
    func getGroupMembersCount(groupId: UUID) async throws -> Int
}
