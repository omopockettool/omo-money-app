import Foundation
import CoreData

/// ViewModel for creating new groups
/// Handles group creation form and validation
@MainActor
class CreateGroupViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var currency = "USD"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldNavigateBack = false
    
    // MARK: - Services
    private let groupService: GroupService
    
    // MARK: - Available Currencies
    let availableCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CHF", "CNY", "MXN", "BRL"]
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.groupService = GroupService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Create a new group
    func createGroup() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if group name already exists
            let exists = try await groupService.groupExists(withName: name.trimmingCharacters(in: .whitespacesAndNewlines))
            if exists {
                errorMessage = "A group with this name already exists"
                isLoading = false
                return
            }
            
            // Create the group
            _ = try await groupService.createGroup(name: name.trimmingCharacters(in: .whitespacesAndNewlines), currency: currency)
            
            isLoading = false
            shouldNavigateBack = true
        } catch {
            errorMessage = "Error creating group: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Validate group input
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
        shouldNavigateBack = false
    }
}
