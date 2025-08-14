import CoreData
import Foundation

/// ViewModel for creating new users
/// Handles user creation form and validation
@MainActor
class CreateUserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigateBack = false
    
    // MARK: - Services
    private let userService: any UserServiceProtocol
    
    // MARK: - Initialization
    init(userService: any UserServiceProtocol) {
        self.userService = userService
    }
    
    // MARK: - Public Methods
    
    /// Create a new user
    func createUser() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Name is required"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if user name already exists
            let exists = try await userService.userExists(withName: name.trimmingCharacters(in: .whitespacesAndNewlines), excluding: nil)
            if exists {
                errorMessage = "A user with this name already exists"
                isLoading = false
                return
            }
            
            // Create the user
            let emailToUse = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
            _ = try await userService.createUser(name: name.trimmingCharacters(in: .whitespacesAndNewlines), email: emailToUse)
            
            isLoading = false
            shouldNavigateBack = true
        } catch {
            errorMessage = "Error creating user: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Validate user input
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
