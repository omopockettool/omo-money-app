import CoreData
import Foundation

/// ViewModel for creating new groups
/// Handles group creation form and validation following strict MVVM architecture
@MainActor
class CreateGroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var currency = "USD"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var groupCreatedSuccessfully = false
    
    // MARK: - Available Currencies
    let availableCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]
    
    // MARK: - Private Properties
    private let user: User
    private let groupService: any GroupServiceProtocol
    private let userGroupService: any UserGroupServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    
    // MARK: - Initialization
    init(user: User, groupService: any GroupServiceProtocol, userGroupService: any UserGroupServiceProtocol, categoryService: any CategoryServiceProtocol) {
        self.user = user
        self.groupService = groupService
        self.userGroupService = userGroupService
        self.categoryService = categoryService
    }
    
    // MARK: - Public Methods
    
    /// Create a new group with proper validation and background operations
    func createGroup() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // ✅ BACKGROUND THREAD: Operaciones Core Data en background
            let newGroup = try await groupService.createGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines), currency: currency)
            
            // ✅ BACKGROUND THREAD: Crear relación usuario-grupo
            _ = try await userGroupService.createUserGroup(user: user, group: newGroup, role: "owner")
            
            // ✅ BACKGROUND THREAD: Crear categorías por defecto
            await createDefaultCategories(for: newGroup)
            
            // ✅ MAIN THREAD: Actualizar UI reactivamente
            groupCreatedSuccessfully = true
            
        } catch {
            errorMessage = "Error creating group: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Validate group input with proper error messages
    func validateInput() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            errorMessage = "Group name is required"
            return false
        }
        
        if trimmedName.count < 2 {
            errorMessage = "Group name must be at least 2 characters long"
            return false
        }
        
        if trimmedName.count > 50 {
            errorMessage = "Group name must be less than 50 characters"
            return false
        }
        
        if !availableCurrencies.contains(currency) {
            errorMessage = "Please select a valid currency"
            return false
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
        currency = "USD"
        errorMessage = nil
        groupCreatedSuccessfully = false
    }
    
    // MARK: - Private Methods
    
    /// Create default categories for a new group
    private func createDefaultCategories(for group: Group) async {
        let defaultCategories = [
            ("Comida", "#FF6B6B"),
            ("Transporte", "#4ECDC4"),
            ("Entretenimiento", "#45B7D1"),
            ("Compras", "#96CEB4"),
            ("Salud", "#FFEAA7"),
            ("Otros", "#8E8E93")
        ]
        
        for (categoryName, categoryColor) in defaultCategories {
            do {
                _ = try await categoryService.createCategory(name: categoryName, color: categoryColor, group: group)
            } catch {
                // Log error but don't fail group creation
                print("Warning: Failed to create category \(categoryName): \(error)")
            }
        }
    }
}
