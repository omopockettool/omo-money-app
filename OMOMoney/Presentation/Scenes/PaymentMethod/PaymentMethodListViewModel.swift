import Foundation

/// ViewModel for PaymentMethod list functionality
/// Handles paymentMethod list display and management
/// ✅ REFACTORED: Uses Domain models
@MainActor
class PaymentMethodListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var paymentMethods: [PaymentMethodDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Services
    private let paymentMethodService: any PaymentMethodServiceProtocol

    // MARK: - Initialization
    init(paymentMethodService: any PaymentMethodServiceProtocol) {
        self.paymentMethodService = paymentMethodService
    }
    
    // MARK: - Public Methods

    /// Load paymentMethods for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func loadPaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await paymentMethodService.getPaymentMethods(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load only active paymentMethods for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func loadActivePaymentMethods(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await paymentMethodService.getActivePaymentMethods(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading active paymentMethods: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Load paymentMethods by type for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func loadPaymentMethods(forGroupId groupId: UUID, type: String) async {
        isLoading = true
        errorMessage = nil

        do {
            paymentMethods = try await paymentMethodService.getPaymentMethods(forGroupId: groupId, type: type)
        } catch {
            errorMessage = "Error loading paymentMethods by type: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create a new paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter
    func createPaymentMethod(name: String, type: String, isActive: Bool = true, groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newPaymentMethod = try await paymentMethodService.createPaymentMethod(
                name: name,
                type: type,
                isActive: isActive,
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
    
    /// Update an existing paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter and works with Domain models
    func updatePaymentMethod(paymentMethodId: UUID, name: String? = nil, type: String? = nil, isActive: Bool? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await paymentMethodService.updatePaymentMethod(paymentMethodId: paymentMethodId, name: name, type: type, isActive: isActive)

            // Update local array - reconstruct the domain model with updated values
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethodId }) {
                let current = paymentMethods[index]
                paymentMethods[index] = PaymentMethodDomain(
                    id: current.id,
                    name: name ?? current.name,
                    type: type ?? current.type,
                    isActive: isActive ?? current.isActive,
                    groupId: current.groupId,
                    createdAt: current.createdAt,
                    lastModifiedAt: Date()
                )
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Delete a paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter
    func deletePaymentMethod(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await paymentMethodService.deletePaymentMethod(paymentMethodId: paymentMethodId)
            paymentMethods.removeAll { $0.id == paymentMethodId }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting paymentMethod: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Toggle active status of a paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter
    func toggleActiveStatus(paymentMethodId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await paymentMethodService.toggleActiveStatus(paymentMethodId: paymentMethodId)

            // Update local array - reconstruct the domain model with toggled status
            if let index = paymentMethods.firstIndex(where: { $0.id == paymentMethodId }) {
                let current = paymentMethods[index]
                paymentMethods[index] = PaymentMethodDomain(
                    id: current.id,
                    name: current.name,
                    type: current.type,
                    isActive: !current.isActive,
                    groupId: current.groupId,
                    createdAt: current.createdAt,
                    lastModifiedAt: Date()
                )
            }

            isLoading = false
            return true
        } catch {
            errorMessage = "Error toggling paymentMethod status: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Get paymentMethods count for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func getPaymentMethodsCount(forGroupId groupId: UUID) async -> Int {
        do {
            return try await paymentMethodService.getPaymentMethodsCount(forGroupId: groupId)
        } catch {
            errorMessage = "Error getting paymentMethods count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Computed Properties

    /// Get active paymentMethods only
    var activePaymentMethods: [PaymentMethodDomain] {
        return paymentMethods.filter { $0.isActive }
    }

    /// Get inactive paymentMethods only
    var inactivePaymentMethods: [PaymentMethodDomain] {
        return paymentMethods.filter { !$0.isActive }
    }

    /// Get paymentMethods grouped by type
    var paymentMethodsByType: [String: [PaymentMethodDomain]] {
        return Dictionary(grouping: paymentMethods) { $0.type }
    }
}
