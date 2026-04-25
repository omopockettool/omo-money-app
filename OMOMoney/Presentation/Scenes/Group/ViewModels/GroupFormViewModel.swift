import Foundation

@MainActor
@Observable
final class GroupFormViewModel {

    var isLoading = false
    var errorMessage: String?

    private let createGroupUseCase: CreateGroupUseCase
    private let createUserGroupUseCase: CreateUserGroupUseCase
    private let updateGroupUseCase: UpdateGroupUseCase

    init(
        createGroupUseCase: CreateGroupUseCase,
        createUserGroupUseCase: CreateUserGroupUseCase,
        updateGroupUseCase: UpdateGroupUseCase
    ) {
        self.createGroupUseCase = createGroupUseCase
        self.createUserGroupUseCase = createUserGroupUseCase
        self.updateGroupUseCase = updateGroupUseCase
    }

    convenience init() {
        let container = AppDIContainer.shared
        self.init(
            createGroupUseCase: container.makeCreateGroupUseCase(),
            createUserGroupUseCase: container.makeCreateUserGroupUseCase(),
            updateGroupUseCase: container.makeUpdateGroupUseCase()
        )
    }

    /// Creates a new group and associates it with the user. Returns the created SDGroup on success.
    func create(name: String, currency: String, userId: UUID) async -> SDGroup? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let group = try await createGroupUseCase.execute(name: name, currency: currency)
            _ = try await createUserGroupUseCase.execute(userId: userId, groupId: group.id, role: "owner")
            return group
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Updates name and currency on an existing group. Returns true on success.
    func update(group: SDGroup, name: String, currency: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        group.name = name
        group.currency = currency
        group.lastModifiedAt = Date()
        do {
            try await updateGroupUseCase.execute(group: group)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
