import CoreData
import Foundation

/// ViewModel for Group list functionality
/// Handles group list display and management
@MainActor
class GroupListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let groupService: GroupService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.groupService = GroupService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all groups
    func loadGroups() async {
        isLoading = true
        errorMessage = nil
        
        do {
            groups = try await groupService.fetchGroups()
        } catch {
            errorMessage = "Error loading groups: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new group
    func createGroup(name: String, currency: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newGroup = try await groupService.createGroup(name: name, currency: currency)
            groups.append(newGroup)
            groups.sort { ($0.name ?? "") < ($1.name ?? "") }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating group: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete a group
    func deleteGroup(_ group: Group) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await groupService.deleteGroup(group)
            groups.removeAll { $0.id == group.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting group: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Check if group name exists
    func groupExists(withName name: String, excluding groupId: UUID? = nil) async -> Bool {
        do {
            return try await groupService.groupExists(withName: name, excluding: groupId)
        } catch {
            errorMessage = "Error checking group name: \(error.localizedDescription)"
            return false
        }
    }
    
    // NOTE: Use UserGroupService.getGroups(for: user) to get groups for a specific user
    // Groups count should be calculated from the filtered results
    
    // MARK: - Batch Operations
    
    /// Delete multiple groups at once
    func deleteSelectedGroups(_ selectedGroups: [Group]) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let groupIds = selectedGroups.compactMap { $0.id }
            try await groupService.bulkDeleteGroups(groupIds: groupIds)
            
            // Remove from local array
            groups.removeAll { group in
                selectedGroups.contains { $0.id == group.id }
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting groups: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update currency for multiple groups
    func updateCurrencyForGroups(_ selectedGroups: [Group], newCurrency: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let groupIds = selectedGroups.compactMap { $0.id }
            try await groupService.bulkUpdateGroupCurrency(groupIds: groupIds, currency: newCurrency)
            
            // Update local array
            for group in selectedGroups {
                if let index = groups.firstIndex(where: { $0.id == group.id }) {
                    groups[index].currency = newCurrency
                }
            }
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating currency: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Create multiple groups at once
    func createMultipleGroups(_ groupDataList: [(name: String, currency: String)]) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newGroups = try await groupService.createGroups(groupDataList)
            groups.append(contentsOf: newGroups)
            groups.sort { ($0.name ?? "") < ($1.name ?? "") }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating multiple groups: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Get groups count by currency
    func getGroupsCount(for currency: String) async -> Int {
        do {
            return try await groupService.getGroupsCount(for: currency)
        } catch {
            errorMessage = "Error getting groups count for currency: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Get member count for a specific group
    func getMemberCount(for group: Group) async -> Int {
        do {
            return try await groupService.getGroupMembersCount(group)
        } catch {
            errorMessage = "Error getting member count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Get groups by currency
    var groupsByCurrency: [String: [Group]] {
        return Dictionary(grouping: groups) { $0.currency ?? "Unknown" }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
