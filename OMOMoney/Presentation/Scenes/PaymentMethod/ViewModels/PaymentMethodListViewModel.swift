import Foundation

/// ViewModel for PaymentMethod list functionality
/// Handles payment method list display and management
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor

@Observable
class PaymentMethodListViewModel {

    // MARK: - Published Properties
    var paymentMethods: [PaymentMethodDomain] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Use Cases
    private let fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase
    private let createPaymentMethodUseCase: CreatePaymentMethodUseCase
    private let updatePaymentMethodUseCase: UpdatePaymentMethodUseCase
    private let deletePaymentMethodUseCase: DeletePaymentMethodUseCase

    // MARK: - Initialization
    init(
        fetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase,
        createPaymentMethodUseCase: CreatePaymentMethodUseCase,
        updatePaymentMethodUseCase: UpdatePaymentMethodUseCase,
        deletePaymentMethodUseCase: DeletePaymentMethodUseCase
    ) {
        self.fetchPaymentMethodsUseCase = fetchPaymentMethodsUseCase
        self.createPaymentMethodUseCase = createPaymentMethodUseCase
        self.updatePaymentMethodUseCase = updatePaymentMethodUseCase
        self.deletePaymentMethodUseCase = deletePaymentMethodUseCase
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            fetchPaymentMethodsUseCase: appContainer.makeFetchPaymentMethodsUseCase(),
            createPaymentMethodUseCase: appContainer.makeCreatePaymentMethodUseCase(),
            updatePaymentMethodUseCase: appContainer.makeUpdatePaymentMethodUseCase(),
            deletePaymentMethodUseCase: appContainer.makeDeletePaymentMethodUseCase()
        )
    }

    // MARK: - Public Methods

    /// Load payment methods for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func loadPaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load only active payment methods for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func loadActivePaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading active paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load payment methods by type for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case with client-side filtering
    func loadPaymentMethods(forGroupId groupId: UUID, type: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let allMethods = try await fetchPaymentMethodsUseCase.execute(forGroupId: groupId)
            paymentMethods = allMethods.filter { $0.type == type }
        } catch {
            errorMessage = "Error loading paymentMethods by type: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create a new payment method
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func createPaymentMethod(name: String, type: String, icon: String = "creditcard.fill", isActive: Bool = true, groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPaymentMethod = try await createPaymentMethodUseCase.execute(
                name: name,
                type: type,
                icon: icon,
                color: "#6C63FF",
                isActive: isActive,
                isDefault: false,
                groupId: groupId
            )
            paymentMethods.append(newPaymentMethod)
            paymentMethods.sort { $0.name < $1.name }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Update an existing payment method (used from form — takes existing domain as base)
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func updatePaymentMethod(_ existing: PaymentMethodDomain, name: String, type: String, icon: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedMethod = PaymentMethodDomain(
                id: existing.id,
                name: name,
                type: type,
                icon: icon,
                color: existing.color,
                isActive: existing.isActive,
                isDefault: existing.isDefault,
                groupId: existing.groupId,
                createdAt: existing.createdAt,
                lastModifiedAt: Date()
            )

            try await updatePaymentMethodUseCase.execute(updatedMethod)

            // Update local array if present
            if let index = paymentMethods.firstIndex(where: { $0.id == existing.id }) {
                paymentMethods[index] = updatedMethod
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Delete a payment method
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func deletePaymentMethod(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await deletePaymentMethodUseCase.execute(id: paymentMethodId)
            paymentMethods.removeAll { $0.id == paymentMethodId }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Toggle active status of a payment method
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func toggleActiveStatus(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            // Find current payment method
            guard let currentMethod = paymentMethods.first(where: { $0.id == paymentMethodId }) else {
                errorMessage = "Payment method not found"
                isLoading = false
                return false
            }

            // Create updated domain model with toggled status
            let updatedMethod = PaymentMethodDomain(
                id: currentMethod.id,
                name: currentMethod.name,
                type: currentMethod.type,
                isActive: !currentMethod.isActive,
                groupId: currentMethod.groupId,
                createdAt: currentMethod.createdAt,
                lastModifiedAt: Date()
            )

            try await updatePaymentMethodUseCase.execute(updatedMethod)

            // Update local array
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethodId }) {
                paymentMethods[index] = updatedMethod
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Error toggling paymentMethod status: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Get payment methods count for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses loaded payment methods array
    func getPaymentMethodsCount(forGroupId groupId: UUID) async -> Int {
        return paymentMethods.count
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Computed Properties

    /// Get active payment methods only
    var activePaymentMethods: [PaymentMethodDomain] {
        return paymentMethods.filter { $0.isActive }
    }

    /// Get inactive payment methods only
    var inactivePaymentMethods: [PaymentMethodDomain] {
        return paymentMethods.filter { !$0.isActive }
    }

    /// Get payment methods grouped by type
    var paymentMethodsByType: [String: [PaymentMethodDomain]] {
        return Dictionary(grouping: paymentMethods) { $0.type }
    }
}
