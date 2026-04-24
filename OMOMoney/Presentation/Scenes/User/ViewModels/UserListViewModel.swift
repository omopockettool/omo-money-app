import Foundation
import SwiftUI

@MainActor

@Observable
class UserListViewModel {

    // MARK: - Published Properties
    var users: [SDUser] = []
    var isLoading = false
    var errorMessage: String?
    var hasMoreUsers = false
    var currentPage = 0

    // MARK: - Private Properties
    private let pageSize = 20
    private var allUsers: [SDUser] = []

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

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createUserUseCase: appContainer.makeCreateUserUseCase(),
            deleteUserUseCase: appContainer.makeDeleteUserUseCase()
        )
    }

    // MARK: - Public Methods

    func loadUsers() async {
        isLoading = true
        errorMessage = nil

        allUsers = []
        users = []
        hasMoreUsers = false
        errorMessage = "Users should be loaded through UserGroupService based on current user's groups"

        isLoading = false
    }

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

    func resetPagination() async {
        currentPage = 0
        users = Array(allUsers.prefix(pageSize))
        hasMoreUsers = allUsers.count > pageSize
    }

    func createUser(name: String, email: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let emailToUse = email ?? ""
            let newUser = try await createUserUseCase.execute(name: name, email: emailToUse)
            allUsers.append(newUser)
            allUsers.sort { $0.name < $1.name }

            await resetPagination()

            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating user: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    func deleteUser(_ user: SDUser) async -> Bool {
        withAnimation {
            allUsers.removeAll { $0.id == user.id }
            users.removeAll { $0.id == user.id }
        }
        do {
            try await deleteUserUseCase.execute(userId: user.id)
            if users.isEmpty && hasMoreUsers { await loadMoreUsers() }
            return true
        } catch {
            withAnimation {
                allUsers.append(user)
                users.append(user)
            }
            errorMessage = "Error deleting user: \(error.localizedDescription)"
            return false
        }
    }

    func userExists(withName name: String, excluding userId: UUID? = nil) async -> Bool {
        return false
    }

    func clearError() {
        errorMessage = nil
    }
}
