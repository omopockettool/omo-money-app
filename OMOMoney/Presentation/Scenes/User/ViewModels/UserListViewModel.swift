import Foundation

/// ViewModel for User list functionality
/// Handles user list display and management
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor

@Observable
class UserListViewModel {

    // MARK: - Published Properties
    var users: [UserDomain] = []
    var isLoading = false
    var errorMessage: String?
    var hasMoreUsers = false
    var currentPage = 0

    // MARK: - Private Properties
    private let pageSize = 20
    private var allUsers: [UserDomain] = []

    // MARK: - Use Cases
    private let createUserUseCase: CreateUserUseCase
    private let deleteUserUseCase: DeleteUserUseCase

    // MARK: - Initialization
    init(
        createUserUseCase: CreateUserUseCase,
        deleteUserUseCase: DeleteUserUseCase
    ) {
        self.createUserUseCase = createUserUseCase
        self.deleteUserUseCase = deleteUserUseCase
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createUserUseCase: appContainer.makeCreateUserUseCase(),
            deleteUserUseCase: appContainer.makeDeleteUserUseCase()
        )
    }

    // MARK: - Public Methods

    /// Load users for specific groups (users should be loaded through UserGroupService)
    func loadUsers() async {
        isLoading = true
        errorMessage = nil

        // Note: In a multi-user app, users should be loaded through UserGroupService
        // based on the current user's groups. This global fetch should be removed.
        allUsers = []
        users = []
        hasMoreUsers = false
        errorMessage = "Users should be loaded through UserGroupService based on current user's groups"

        isLoading = false
    }

    /// Load more users for pagination
    func loadMoreUsers() async {
        guard hasMoreUsers && !isLoading else { return }

        isLoading = true

        let nextPage = currentPage + 1
        let startIndex = nextPage * pageSize
        let endIndex = min(startIndex + pageSize, allUsers.count)

        if startIndex < allUsers.count {
            let newUsers = Array(allUsers[startIndex..<endIndex])
            users.append(contentsOf: newUsers)
            currentPage = nextPage
            hasMoreUsers = endIndex < allUsers.count
        }

        isLoading = false
    }

    /// Reset pagination and reload from beginning
    func resetPagination() async {
        currentPage = 0
        users = Array(allUsers.prefix(pageSize))
        hasMoreUsers = allUsers.count > pageSize
    }

    /// Create a new user
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func createUser(name: String, email: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let emailToUse = email ?? ""
            let newUser = try await createUserUseCase.execute(name: name, email: emailToUse)
            allUsers.append(newUser)
            allUsers.sort { $0.name < $1.name }

            // Reset pagination to show the new user
            await resetPagination()

            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Delete a user
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func deleteUser(_ user: UserDomain) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await deleteUserUseCase.execute(userId: user.id)
            allUsers.removeAll { $0.id == user.id }
            users.removeAll { $0.id == user.id }

            // Adjust pagination if needed
            if users.isEmpty && hasMoreUsers {
                await loadMoreUsers()
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Check if user name exists
    /// ⚠️ TODO: Create UserExistsUseCase to avoid needing direct Service access
    func userExists(withName name: String, excluding userId: UUID? = nil) async -> Bool {
        // This would need a dedicated Use Case or could be a computed property
        // For now, returning false to avoid breaking code
        return false
    }

    // Note: For users count, use UserGroupService.getUsers(in: group) and then .count
    // to ensure proper filtering by group context

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
