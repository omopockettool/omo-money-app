import CoreData
import Foundation

/// ViewModel for User detail functionality
/// Handles user detail display and group management
@MainActor
class UserDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var user: User?
    @Published var userGroups: [UserGroup] = []
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let userService: any UserServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let groupService: any GroupServiceProtocol
    
    // MARK: - Initialization
    init(userService: any UserServiceProtocol, userGroupService: any UserGroupServiceProtocol, groupService: any GroupServiceProtocol) {
        self.userService = userService
        self.userGroupService = userGroupService
        self.groupService = groupService
    }
    
    // MARK: - Public Methods
    
    /// Load user details
    func loadUser(by id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.fetchUser(by: id)
            if let currentUser = user {
                await loadUserGroups(for: currentUser)
            }
        } catch {
            errorMessage = "Error loading user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load user groups for a specific user
    func loadUserGroups(for user: User) async {
        do {
            userGroups = try await userGroupService.getUserGroups(for: user)
            groups = userGroups.compactMap { $0.group }
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
        }
    }
    
    /// Update user information
    func updateUser(name: String? = nil, email: String? = nil) async -> Bool {
        guard let currentUser = user else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await userService.updateUser(currentUser, name: name, email: email)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Create a new group for the user
    func createGroup(name: String, currency: String) async -> Bool {
        guard let currentUser = user else { return false }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create the group
            let newGroup = try await groupService.createGroup(name: name, currency: currency)
            
            // Create the user-group relationship
            let userGroup = try await userGroupService.createUserGroup(user: currentUser, group: newGroup, role: "owner")
            
            // Update local state
            userGroups.append(userGroup)
            groups.append(newGroup)
            
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating group: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Check if group name exists
    func groupExists(withName name: String) async -> Bool {
        do {
            return try await groupService.groupExists(withName: name, excluding: nil)
        } catch {
            errorMessage = "Error checking group name: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Get groups count for the user
    func getGroupsCount() async -> Int {
        guard user != nil else { return 0 }
        
        do {
            return try await userGroupService.getUserGroupsCount()
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
