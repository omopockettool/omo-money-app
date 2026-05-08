import Foundation
import SwiftUI

/// ViewModel for creating the first user when app is newly installed
/// Uses Clean Architecture with Use Cases instead of direct Service calls
@MainActor

@Observable
class CreateFirstUserViewModel {
    enum SubmissionMode {
        case persist
        case simulate
    }
    
    // MARK: - Published Properties
    
    var name = ""
    var email = ""
    var isLoading = false
    var loadingMessage = ""
    var showError = false
    var errorMessage: String?
    var isSuccess = false
    
    // MARK: - Use Cases
    
    private let createUserUseCase: CreateUserUseCase
    private let createGroupUseCase: CreateGroupUseCase
    private let createUserGroupUseCase: CreateUserGroupUseCase
    private let submissionMode: SubmissionMode
    
    // MARK: - Initialization
    
    /// Initialize with Use Cases (Clean Architecture approach)
    init(
        createUserUseCase: CreateUserUseCase,
        createGroupUseCase: CreateGroupUseCase,
        createUserGroupUseCase: CreateUserGroupUseCase,
        submissionMode: SubmissionMode = .persist
    ) {
        self.createUserUseCase = createUserUseCase
        self.createGroupUseCase = createGroupUseCase
        self.createUserGroupUseCase = createUserGroupUseCase
        self.submissionMode = submissionMode
    }
    
    /// Convenience initializer using DI Container
    convenience init(submissionMode: SubmissionMode = .persist) {
        let appContainer = AppDIContainer.shared

        self.init(
            createUserUseCase: appContainer.makeCreateUserUseCase(),
            createGroupUseCase: appContainer.makeCreateGroupUseCase(),
            createUserGroupUseCase: appContainer.makeCreateUserGroupUseCase(),
            submissionMode: submissionMode
        )
    }
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@")
    }
    
    // MARK: - Public Methods
    
    /// Create the first user with personal group
    /// Uses Use Cases to execute business logic
    func createUser() async {
        guard isFormValid else { return }
        
        isLoading = true
        loadingMessage = "Creando usuario..."
        errorMessage = nil
        showError = false

        do {
            if submissionMode == .simulate {
                try await runSimulation()
                loadingMessage = "¡Listo!"
                isSuccess = true
                isLoading = false
                return
            }

            let userDomain = try await createUserUseCase.execute(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            loadingMessage = "Creando grupo personal..."
            let groupDomain = try await createGroupUseCase.execute(
                name: "Personal",
                currency: "USD"
            )

            loadingMessage = "Configurando categorías..."
            _ = try await createUserGroupUseCase.execute(
                userId: userDomain.id,
                groupId: groupDomain.id,
                role: "owner"
            )

            loadingMessage = "¡Listo!"
            isSuccess = true
            
        } catch let error as ValidationError {
            // Handle validation errors with localized messages
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            // Handle other errors
            errorMessage = LocalizationKey.RepositoryError.saveFailed.localized
            showError = true
        }
        
        isLoading = false
    }
    
    /// Clear form fields
    func clearForm() {
        name = ""
        email = ""
        errorMessage = nil
        showError = false
    }

    private func runSimulation() async throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { throw ValidationError.emptyName }
        guard !trimmedEmail.isEmpty else { throw ValidationError.emptyEmail }
        guard trimmedEmail.contains("@") else { throw ValidationError.invalidEmail }

        loadingMessage = "Simulando grupo personal..."
        try? await Task.sleep(for: .milliseconds(250))

        loadingMessage = "Simulando configuración inicial..."
        try? await Task.sleep(for: .milliseconds(250))
    }
}
