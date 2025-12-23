import CoreData
import Foundation

/// ViewModel for User detail functionality
/// Handles user detail display and group management
/// ✅ REFACTORED: Works with Domain models
@MainActor
class UserDetailViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var user: UserDomain?
    @Published var userGroups: [UserGroupDomain] = []
    @Published var groups: [GroupDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Services
    private let userService: any UserServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let groupService: any GroupServiceProtocol
    private let context: NSManagedObjectContext

    // MARK: - Initialization
    init(userService: any UserServiceProtocol, userGroupService: any UserGroupServiceProtocol, groupService: any GroupServiceProtocol, context: NSManagedObjectContext) {
        self.userService = userService
        self.userGroupService = userGroupService
        self.groupService = groupService
        self.context = context
    }

    // MARK: - Public Methods

    /// Load user details
    /// ✅ REFACTORED: Uses UserDomain
    func loadUser(by id: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            user = try await userService.fetchUser(by: id)
            if let currentUser = user {
                await loadUserGroups(forUserId: currentUser.id)
            }
        } catch {
            errorMessage = "Error loading user: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load user groups for a specific user
    /// ✅ REFACTORED: Uses Domain models
    func loadUserGroups(forUserId userId: UUID) async {
        do {
            userGroups = try await userGroupService.getUserGroups(forUserId: userId)

            // Load groups using userGroupService
            groups = try await userGroupService.getGroups(forUserId: userId)
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
        }
    }

    /// Update user information
    /// ✅ REFACTORED: Uses UUID parameter
    func updateUser(name: String? = nil, email: String? = nil) async -> Bool {
        guard let currentUser = user else { return false }

        isLoading = true
        errorMessage = nil

        do {
            try await userService.updateUser(userId: currentUser.id, name: name, email: email)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Create a new group for the user
    /// ✅ REFACTORED: Uses Domain models
    func createGroup(name: String, currency: String) async -> Bool {
        guard let currentUser = user else { return false }

        isLoading = true
        errorMessage = nil

        do {
            // Create the group (returns GroupDomain)
            let newGroup = try await groupService.createGroup(name: name, currency: currency)

            // Create the user-group relationship using UUIDs
            let userGroup = try await userGroupService.createUserGroup(
                userId: currentUser.id,
                groupId: newGroup.id,
                role: "owner"
            )

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
    /// ✅ REFACTORED: Uses Domain models
    func getGroupsCount() async -> Int {
        guard let user = user else { return 0 }

        do {
            let userGroups = try await userGroupService.getUserGroups(forUserId: user.id)
            return userGroups.count
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
