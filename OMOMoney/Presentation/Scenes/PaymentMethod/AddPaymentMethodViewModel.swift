import CoreData
import Foundation

/// ViewModel for adding and editing PaymentMethod
/// Handles payment method creation and modification forms
@MainActor
class AddPaymentMethodViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var name = ""
    @Published var type = ""
    @Published var isActive = true
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var validationErrors: [String: String] = [:]
    
    // MARK: - Private Properties
    private let paymentMethodService: any PaymentMethodServiceProtocol
    private var editingPaymentMethod: PaymentMethod?
    private var targetGroup: Group?
    
    // MARK: - Computed Properties
    var isEditing: Bool {
        return editingPaymentMethod != nil
    }
    
    var title: String {
        return isEditing ? "Edit Payment Method" : "Add Payment Method"
    }
    
    var submitButtonTitle: String {
        return isEditing ? "Update" : "Create"
    }
    
    // MARK: - Initialization
    init(paymentMethodService: any PaymentMethodServiceProtocol) {
        self.paymentMethodService = paymentMethodService
    }
    
    // MARK: - Public Methods
    
    /// Configure for creating a new payment method
    func configureForCreation(group: Group) {
        self.targetGroup = group
        self.editingPaymentMethod = nil
        resetForm()
    }
    
    /// Configure for editing an existing payment method
    func configureForEditing(_ paymentMethod: PaymentMethod) {
        self.editingPaymentMethod = paymentMethod
        self.targetGroup = paymentMethod.group
        populateForm(with: paymentMethod)
    }
    
    /// Submit the form (create or update)
    func submit() async -> Bool {
        clearValidationErrors()
        
        guard validateForm() else {
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        let success: Bool
        if isEditing {
            success = await updatePaymentMethod()
        } else {
            success = await createPaymentMethod()
        }
        
        isLoading = false
        return success
    }
    
    /// Reset the form to initial state
    func resetForm() {
        name = ""
        type = ""
        isActive = true
        clearValidationErrors()
        clearError()
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Clear validation errors
    func clearValidationErrors() {
        validationErrors.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Populate form with existing payment method data
    private func populateForm(with paymentMethod: PaymentMethod) {
        name = paymentMethod.name ?? ""
        type = paymentMethod.type ?? ""
        isActive = paymentMethod.isActive
    }
    
    /// Create a new payment method
    private func createPaymentMethod() async -> Bool {
        guard let targetGroup = targetGroup,
              let groupId = targetGroup.id else {
            errorMessage = "Invalid group"
            return false
        }
        
        do {
            _ = try await paymentMethodService.createPaymentMethod(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: isActive,
                groupId: groupId
            )
            return true
        } catch {
            errorMessage = "Error creating payment method: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Update existing payment method
    private func updatePaymentMethod() async -> Bool {
        guard let editingPaymentMethod = editingPaymentMethod else {
            errorMessage = "No payment method to update"
            return false
        }
        
        do {
            try await paymentMethodService.updatePaymentMethod(
                editingPaymentMethod,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: isActive
            )
            return true
        } catch {
            errorMessage = "Error updating payment method: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Validate the form
    private func validateForm() -> Bool {
        var isValid = true
        
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            validationErrors["name"] = "Name is required"
            isValid = false
        } else if trimmedName.count < 2 {
            validationErrors["name"] = "Name must be at least 2 characters"
            isValid = false
        } else if trimmedName.count > 50 {
            validationErrors["name"] = "Name must be less than 50 characters"
            isValid = false
        }
        
        // Validate type
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedType.isEmpty {
            validationErrors["type"] = "Type is required"
            isValid = false
        } else if trimmedType.count < 2 {
            validationErrors["type"] = "Type must be at least 2 characters"
            isValid = false
        } else if trimmedType.count > 30 {
            validationErrors["type"] = "Type must be less than 30 characters"
            isValid = false
        }
        
        return isValid
    }
    
    // MARK: - Validation Helpers
    
    /// Check if name field has validation error
    func hasNameError() -> Bool {
        return validationErrors["name"] != nil
    }
    
    /// Get name validation error message
    func getNameError() -> String? {
        return validationErrors["name"]
    }
    
    /// Check if type field has validation error
    func hasTypeError() -> Bool {
        return validationErrors["type"] != nil
    }
    
    /// Get type validation error message
    func getTypeError() -> String? {
        return validationErrors["type"]
    }
    
    /// Check if form is valid for submission
    var canSubmit: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !trimmedName.isEmpty && 
               !trimmedType.isEmpty && 
               !isLoading
    }
    
    // MARK: - Common Payment Method Types
    
    /// Get common payment method types for quick selection
    var commonTypes: [String] {
        return [
            "Credit Card",
            "Debit Card", 
            "Cash",
            "Bank Transfer",
            "Digital Wallet",
            "Check",
            "Gift Card",
            "Other"
        ]
    }
    
    /// Set type from common types
    func setType(_ selectedType: String) {
        type = selectedType
    }
}
