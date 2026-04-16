import Foundation

@MainActor

@Observable
class EditUserViewModel {

    // MARK: - Published Properties
    var name = ""
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var shouldNavigateBack = false

    // MARK: - Computed Properties
    var userCreatedAt: Date? {
        return user.createdAt
    }

    var userLastModifiedAt: Date? {
        return user.lastModifiedAt
    }

    // MARK: - Private Properties
    private let user: SDUser
    private let updateUserUseCase: UpdateUserUseCase

    // MARK: - Initialization
    init(user: SDUser, updateUserUseCase: UpdateUserUseCase) {
        self.user = user
        self.updateUserUseCase = updateUserUseCase

        self.name = user.name
        self.email = user.email
    }

    convenience init(user: SDUser) {
        let appContainer = AppDIContainer.shared
        self.init(
            user: user,
            updateUserUseCase: appContainer.makeUpdateUserUseCase()
        )
    }

    // MARK: - Public Methods

    func updateUser() async {
        guard validateInput() else { return }
        guard await validateNameAsync() else { return }

        isLoading = true
        errorMessage = nil

        do {
            user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            user.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            try await updateUserUseCase.execute(user: user)

            isLoading = false
            shouldNavigateBack = true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func validateInput() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            errorMessage = "Name is required"
            return false
        }

        if trimmedName.count < 2 {
            errorMessage = "Name must be at least 2 characters long"
            return false
        }

        if trimmedName.count > 50 {
            errorMessage = "Name must be less than 50 characters"
            return false
        }

        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines)) {
                errorMessage = "Please enter a valid email address"
                return false
            }
        }

        errorMessage = nil
        return true
    }

    func validateNameAsync() async -> Bool {
        return true
    }

    func clearError() {
        errorMessage = nil
    }

    func resetForm() {
        name = user.name
        email = user.email
        errorMessage = nil
    }
}
