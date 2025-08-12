import Foundation
import CoreData

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
    
    /// Get groups count
    func getGroupsCount() async -> Int {
        do {
            return try await groupService.getGroupsCount()
        } catch {
            errorMessage = "Error getting groups count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
