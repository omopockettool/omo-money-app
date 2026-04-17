import Foundation

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
    private var editingPaymentMethod: SDPaymentMethod?
    private var targetGroupId: UUID?

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
    init(
        createPaymentMethodUseCase: CreatePaymentMethodUseCase,
        updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    ) {
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
    }

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            createPaymentMethodUseCase: appContainer.makeCreatePaymentMethodUseCase(),
            updatePaymentMethodUseCase: appContainer.makeUpdatePaymentMethodUseCase()
        )
    }

    // MARK: - Public Methods

    func configureForCreation(groupId: UUID) {
        self.targetGroupId = groupId
        self.editingPaymentMethod = nil
        resetForm()
    }

    func configureForEditing(_ paymentMethod: SDPaymentMethod) {
        self.editingPaymentMethod = paymentMethod
        self.targetGroupId = paymentMethod.group?.id
        populateForm(with: paymentMethod)
    }

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

    func resetForm() {
        name = ""
        type = ""
        isActive = true
        clearValidationErrors()
        clearError()
    }

    func clearError() {
        errorMessage = nil
    }

    func clearValidationErrors() {
        validationErrors.removeAll()
    }

    // MARK: - Private Methods

    private func populateForm(with paymentMethod: SDPaymentMethod) {
        name = paymentMethod.name
        type = paymentMethod.type
        isActive = paymentMethod.isActive
    }

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
                groupId: groupId
            )
            return true
        } catch {
            errorMessage = "Error creating payment method: \(error.localizedDescription)"
            return false
        }
    }

    private func updatePaymentMethod() async -> Bool {
        guard let pm = editingPaymentMethod else {
            errorMessage = "No payment method to update"
            return false
        }

        do {
            pm.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            pm.type = type.trimmingCharacters(in: .whitespacesAndNewlines)
            pm.isActive = isActive
            try await updatePaymentMethodUseCase.execute(pm)
            return true
        } catch {
            errorMessage = "Error updating payment method: \(error.localizedDescription)"
            return false
        }
    }

    private func validateForm() -> Bool {
        var isValid = true

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

    func hasNameError() -> Bool {
        return validationErrors["name"] != nil
    }

    func getNameError() -> String? {
        return validationErrors["name"]
    }

    func hasTypeError() -> Bool {
        return validationErrors["type"] != nil
    }

    func getTypeError() -> String? {
        return validationErrors["type"]
    }

    var canSubmit: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedType = type.trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmedName.isEmpty &&
               !trimmedType.isEmpty &&
               !isLoading
    }

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

    func setType(_ selectedType: String) {
        type = selectedType
    }
}
