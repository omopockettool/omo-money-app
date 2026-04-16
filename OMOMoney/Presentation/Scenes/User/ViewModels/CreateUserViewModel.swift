import Foundation

/// ViewModel for creating new users
/// Uses Clean Architecture with Use Cases instead of direct Service calls
@MainActor

@Observable
class CreateUserViewModel {
    
    // MARK: - Published Properties
    
    var name = ""
    var email = ""
    var isLoading = false
    var errorMessage: String?
    var shouldNavigateBack = false
    
    // MARK: - Use Cases
    
    private let createUserUseCase: CreateUserUseCase
    private let createGroupUseCase: CreateGroupUseCase
    
    // MARK: - Initialization
    
    /// Initialize with Use Cases (Clean Architecture approach)
    init(
        createUserUseCase: CreateUserUseCase,
        createGroupUseCase: CreateGroupUseCase
    ) {
        self.createUserUseCase = createUserUseCase
        self.createGroupUseCase = createGroupUseCase
    }
    
    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        let userSceneContainer = appContainer.makeUserSceneDIContainer()
        let groupSceneContainer = appContainer.makeGroupSceneDIContainer()
        
        self.init(
            createUserUseCase: userSceneContainer.makeCreateUserUseCase(),
            createGroupUseCase: groupSceneContainer.makeCreateGroupUseCase()
        )
    }
    
    // MARK: - Public Methods
    
    /// Create a new user with personal group
    /// Uses Use Cases to execute business logic with proper validation
    func createUser() async {
        // Validate input first
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Prepare email (optional field)
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalEmail = trimmedEmail.isEmpty ? "noemail@\(name.lowercased()).com" : trimmedEmail
            
            // Use Case 1: Create User (includes validation)
            let userDomain = try await createUserUseCase.execute(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: finalEmail
            )
            
            print("✅ User created: \(userDomain.name)")
            
            // Use Case 2: Create Personal Group for user
            let groupName = "\(userDomain.name) - Personal"
            let groupDomain = try await createGroupUseCase.execute(
                name: groupName,
                currency: AppConstants.defaultCurrency
            )
            
            print("✅ Personal group created: \(groupDomain.name)")
            
            // TODO: Link user to group when UserGroup Use Case is implemented
            
            isLoading = false
            shouldNavigateBack = true
            
        } catch let error as ValidationError {
            // Handle validation errors with localized messages
            errorMessage = error.localizedDescription
            isLoading = false
        } catch {
            // Handle other errors
            errorMessage = LocalizationKey.RepositoryError.saveFailed.localized
            isLoading = false
        }
    }
    
    /// Validate user input
    /// Returns true if validation passes, false otherwise (sets errorMessage)
    func validateInput() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = LocalizationKey.ValidationError.emptyName.localized
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
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEmail.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: trimmedEmail) {
                errorMessage = LocalizationKey.ValidationError.invalidEmail.localized
                return false
            }
        }
        
        errorMessage = nil
        return true
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Reset form
    func resetForm() {
        name = ""
        email = ""
        errorMessage = nil
        shouldNavigateBack = false
    }
}
