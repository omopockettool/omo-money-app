import Foundation

/// ViewModel for adding and editing PaymentMethod
/// Handles payment method creation and modification forms
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor

@Observable
class AddPaymentMethodViewModel {

    // MARK: - Published Properties
    var name = ""
    var type = ""
    var isActive = true
    var isLoading = false
    var errorMessage: String?
    var validationErrors: [String: String] = [:]

    // MARK: - Private Properties
    private let createPaymentMethodUseCase: CreatePaymentMethodUseCase
    private let updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    private var editingPaymentMethodId: UUID?
    private var targetGroupId: UUID?

    // MARK: - Computed Properties
    var isEditing: Bool {
        return editingPaymentMethodId != nil
    }

    var title: String {
        return isEditing ? "Edit Payment Method" : "Add Payment Method"
    }

    var submitButtonTitle: String {
        return isEditing ? "Update" : "Create"
    }

    // MARK: - Initialization
    init(
        createPaymentMethodUseCase: CreatePaymentMethodUseCase,
        updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    ) {
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createPaymentMethodUseCase: appContainer.makeCreatePaymentMethodUseCase(),
            updatePaymentMethodUseCase: appContainer.makeUpdatePaymentMethodUseCase()
        )
    }

    // MARK: - Public Methods

    /// Configure for creating a new payment method
    /// ✅ REFACTORED: Accepts UUID parameter
    func configureForCreation(groupId: UUID) {
        self.targetGroupId = groupId
        self.editingPaymentMethodId = nil
        resetForm()
    }

    /// Configure for editing an existing payment method
    /// ✅ REFACTORED: Accepts Domain model
    func configureForEditing(_ paymentMethod: PaymentMethodDomain) {
        self.editingPaymentMethodId = paymentMethod.id
        self.targetGroupId = paymentMethod.groupId
        populateForm(with: paymentMethod)
    }

    /// Submit the form (create or update)
    /// ✅ CLEAN ARCHITECTURE: Uses Use Cases
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
    /// ✅ REFACTORED: Accepts Domain model
    private func populateForm(with paymentMethod: PaymentMethodDomain) {
        name = paymentMethod.name
        type = paymentMethod.type
        isActive = paymentMethod.isActive
    }

    /// Create a new payment method
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    private func createPaymentMethod() async -> Bool {
        guard let groupId = targetGroupId else {
            errorMessage = "Invalid group"
            return false
        }

        do {
            _ = try await createPaymentMethodUseCase.execute(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                icon: "creditcard.fill",
                color: "#6C63FF",
                isActive: isActive,
                isDefault: false,
                groupId: groupId
            )
            return true
        } catch {
            errorMessage = "Error creating payment method: \(error.localizedDescription)"
            return false
        }
    }

    /// Update existing payment method
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    private func updatePaymentMethod() async -> Bool {
        guard let paymentMethodId = editingPaymentMethodId,
              let groupId = targetGroupId else {
            errorMessage = "No payment method to update"
            return false
        }

        do {
            // Create updated domain model
            let updatedMethod = PaymentMethodDomain(
                id: paymentMethodId,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type.trimmingCharacters(in: .whitespacesAndNewlines),
                isActive: isActive,
                groupId: groupId,
                createdAt: Date(), // Note: This should ideally preserve original createdAt
                lastModifiedAt: Date()
            )

            try await updatePaymentMethodUseCase.execute(updatedMethod)
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
