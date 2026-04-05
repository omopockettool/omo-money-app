import Foundation

/// Protocol for PaymentMethod service operations
/// Enables dependency injection and testing
/// ✅ REFACTORED: Returns Domain models and accepts UUID parameters
protocol PaymentMethodServiceProtocol {

    // MARK: - PaymentMethod CRUD Operations

    /// Fetch paymentMethod by ID
    func fetchPaymentMethod(by id: UUID) async throws -> PaymentMethodDomain?

    /// Create a new paymentMethod
    func createPaymentMethod(name: String, type: String, icon: String, color: String, isActive: Bool, isDefault: Bool, groupId: UUID) async throws -> PaymentMethodDomain

    /// Update an existing paymentMethod
    func updatePaymentMethod(paymentMethodId: UUID, name: String?, type: String?, isActive: Bool?) async throws

    /// Delete a paymentMethod
    func deletePaymentMethod(paymentMethodId: UUID) async throws

    /// Get paymentMethods for a specific group
    func getPaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain]

    /// Get active paymentMethods for a specific group
    func getActivePaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain]

    /// Get paymentMethods count for a specific group
    func getPaymentMethodsCount(forGroupId groupId: UUID) async throws -> Int

    /// Toggle paymentMethod active status
    func toggleActiveStatus(paymentMethodId: UUID) async throws

    /// Get paymentMethods by type
    func getPaymentMethods(forGroupId groupId: UUID, type: String) async throws -> [PaymentMethodDomain]
}
