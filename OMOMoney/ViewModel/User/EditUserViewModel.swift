import Foundation
import CoreData

/// ViewModel for editing existing users
/// Handles user editing form and validation
@MainActor
class EditUserViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigateBack = false
    
    // MARK: - Computed Properties
    var userCreatedAt: Date? {
        return user.createdAt
    }
    
    var userLastModifiedAt: Date? {
        return user.lastModifiedAt
    }
    
    // MARK: - Private Properties
    private let user: User
    private let userService: any UserServiceProtocol
    
    // MARK: - Initialization
    init(user: User, userService: any UserServiceProtocol) {
        self.user = user
        self.userService = userService
        
        // Initialize form with current values
        self.name = user.name ?? ""
        self.email = user.email ?? ""
    }
    
    // MARK: - Public Methods
    
    /// Update the user
    func updateUser() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let nameToUse = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let emailToUse = email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            try await userService.updateUser(user, name: nameToUse, email: emailToUse)
            
            isLoading = false
            shouldNavigateBack = true
        } catch {
            errorMessage = "Error updating user: \(error.localizedDescription)"
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
        
        // Check if name changed and if new name already exists
        let originalName = user.name ?? ""
        
        if trimmedName != originalName {
            // Name changed, check if new name exists
            Task {
                let exists = try? await userService.userExists(withName: trimmedName, excluding: user.id)
                if exists == true {
                    await MainActor.run {
                        errorMessage = "A user with this name already exists"
                    }
                    return
                }
            }
        }
        
        errorMessage = nil
        return true
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Reset form to original values
    func resetForm() {
        name = user.name ?? ""
        email = user.email ?? ""
        errorMessage = nil
    }
}
