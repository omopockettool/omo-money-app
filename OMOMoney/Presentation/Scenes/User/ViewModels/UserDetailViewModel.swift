import Foundation

@MainActor

@Observable
class UserDetailViewModel {

    // MARK: - Published Properties

    var user: SDUser?
    var userGroups: [SDUserGroup] = []
    var groups: [SDGroup] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Repositories

    private let userRepository: UserRepository
    private let userGroupRepository: UserGroupRepository
    private let groupRepository: GroupRepository

    // MARK: - Initialization

    init(
        userRepository: UserRepository,
        userGroupRepository: UserGroupRepository,
        groupRepository: GroupRepository
    ) {
        self.userRepository = userRepository
        self.userGroupRepository = userGroupRepository
        self.groupRepository = groupRepository
    }

    // MARK: - Public Methods

    func loadUser(by id: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            user = try await userRepository.fetchUser(id: id)
            if let currentUser = user {
                await loadUserGroups(forUserId: currentUser.id)
            }
        } catch {
            errorMessage = "Error loading user: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadUserGroups(forUserId userId: UUID) async {
        do {
            userGroups = try await userGroupRepository.fetchUserGroups(forUserId: userId)
            groups = try await groupRepository.fetchGroups(forUserId: userId)
        } catch {
            errorMessage = "Error loading user groups: \(error.localizedDescription)"
        }
    }

    func updateUser(name: String? = nil, email: String? = nil) async -> Bool {
        guard let currentUser = user else { return false }
        isLoading = true
        errorMessage = nil
        do {
            if let name { currentUser.name = name }
            if let email { currentUser.email = email }
            try await userRepository.updateUser(currentUser)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func createGroup(name: String, currency: String) async -> Bool {
        guard let currentUser = user else { return false }
        isLoading = true
        errorMessage = nil
        do {
            let newGroup = try await groupRepository.createGroup(name: name, currency: currency)
            let userGroup = try await userGroupRepository.createUserGroup(
                userId: currentUser.id,
                groupId: newGroup.id,
                role: "owner"
            )
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

    func groupExists(withName name: String) async -> Bool {
        guard let currentUser = user else { return false }
        do {
            let existing = try await groupRepository.fetchGroups(forUserId: currentUser.id)
            return existing.contains { $0.name.lowercased() == name.lowercased() }
        } catch {
            return false
        }
    }

    func getGroupsCount() async -> Int {
        guard let user else { return 0 }
        do {
            return try await userGroupRepository.fetchUserGroups(forUserId: user.id).count
        } catch {
            return 0
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
