import Foundation
import SwiftUI

/// ViewModel for creating the first user when app is newly installed
/// Uses Clean Architecture with Use Cases instead of direct Service calls
@MainActor
class CreateFirstUserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isSuccess = false
    
    // MARK: - Use Cases
    
    private let createUserUseCase: CreateUserUseCase
    private let createGroupUseCase: CreateGroupUseCase
    private let createUserGroupUseCase: CreateUserGroupUseCase
    
    // MARK: - Initialization
    
    /// Initialize with Use Cases (Clean Architecture approach)
    init(
        createUserUseCase: CreateUserUseCase,
        createGroupUseCase: CreateGroupUseCase,
        createUserGroupUseCase: CreateUserGroupUseCase
    ) {
        self.createUserUseCase = createUserUseCase
        self.createGroupUseCase = createGroupUseCase
        self.createUserGroupUseCase = createUserGroupUseCase
    }
    
    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        let userSceneContainer = appContainer.makeUserSceneDIContainer()
        let groupSceneContainer = appContainer.makeGroupSceneDIContainer()
        
        self.init(
            createUserUseCase: userSceneContainer.makeCreateUserUseCase(),
            createGroupUseCase: groupSceneContainer.makeCreateGroupUseCase(),
            createUserGroupUseCase: userSceneContainer.makeCreateUserGroupUseCase()
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
        errorMessage = nil
        showError = false
        
        do {
            // Use Case 1: Create User (includes validation)
            let userDomain = try await createUserUseCase.execute(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            print("✅ User created: \(userDomain.name)")
            
            // Use Case 2: Create Personal Group
            let groupDomain = try await createGroupUseCase.execute(
                name: "Personal",
                currency: "USD"
            )
            
            print("✅ Personal group created: \(groupDomain.name)")
            
            // Use Case 3: Create UserGroup relationship
            _ = try await createUserGroupUseCase.execute(
                userId: userDomain.id,
                groupId: groupDomain.id,
                role: "owner"
            )
            
            print("✅ UserGroup relationship created: User '\(userDomain.name)' is owner of group '\(groupDomain.name)'")
            
            print("✅ First user setup completed successfully")
            isSuccess = true
            
        } catch let error as ValidationError {
            // Handle validation errors with localized messages
            print("❌ Validation error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            showError = true
        } catch {
            // Handle other errors
            print("❌ Error creating user: \(error.localizedDescription)")
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
}


