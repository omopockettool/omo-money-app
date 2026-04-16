import Foundation

/// ViewModel for editing existing users
/// Handles user editing form and validation
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
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
    private let user: UserDomain
    private let updateUserUseCase: UpdateUserUseCase

    // MARK: - Initialization
    init(user: UserDomain, updateUserUseCase: UpdateUserUseCase) {
        self.user = user
        self.updateUserUseCase = updateUserUseCase

        // Initialize form with current values
        self.name = user.name
        self.email = user.email
    }

    /// Convenience initializer using DI Container
    convenience init(user: UserDomain) {
        let appContainer = AppDIContainer.shared
        self.init(
            user: user,
            updateUserUseCase: appContainer.makeUpdateUserUseCase()
        )
    }

    // MARK: - Public Methods

    /// Update the user
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func updateUser() async {
        guard validateInput() else { return }

        // Additional async validation for name duplicates
        guard await validateNameAsync() else { return }

        isLoading = true
        errorMessage = nil

        do {
            let nameToUse = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let emailToUse = email.trimmingCharacters(in: .whitespacesAndNewlines)

            // Create updated UserDomain with all fields
            let updatedUser = UserDomain(
                id: user.id,
                name: nameToUse,
                email: emailToUse,
                createdAt: user.createdAt,
                lastModifiedAt: Date()
            )

            try await updateUserUseCase.execute(user: updatedUser)

            isLoading = false
            shouldNavigateBack = true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
            isLoading = false
        }
    }

    /// Validate user input (synchronous validation only)
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

        // Validate email if provided
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

    /// Validate user name asynchronously (check for duplicates)
    /// ⚠️ TODO: Create UserExistsUseCase to avoid needing validation logic here
    func validateNameAsync() async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let originalName = user.name

        // Only check if name actually changed
        if trimmedName != originalName {
            // This would need a UserExistsUseCase
            // For now, we'll skip the duplicate check to maintain clean architecture
            // The Service layer will catch it if there's a duplicate
        }

        return true
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    /// Reset form to original values
    func resetForm() {
        name = user.name
        email = user.email
        errorMessage = nil
    }
}
