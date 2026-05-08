import Foundation

@MainActor
@Observable
final class UserProfileViewModel {
    var name: String
    var isLoading = false
    var errorMessage: String?

    private let user: SDUser
    private let updateUserUseCase: UpdateUserUseCase

    init(user: SDUser, updateUserUseCase: UpdateUserUseCase) {
        self.user = user
        self.updateUserUseCase = updateUserUseCase
        self.name = user.name
    }

    convenience init(user: SDUser) {
        let container = AppDIContainer.shared
        self.init(
            user: user,
            updateUserUseCase: container.makeUpdateUserUseCase()
        )
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }

    func save() async -> SDUser? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        user.name = trimmedName
        user.lastModifiedAt = Date()

        do {
            try await updateUserUseCase.execute(user: user)
            return user
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
