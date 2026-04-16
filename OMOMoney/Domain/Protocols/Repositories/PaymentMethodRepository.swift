import Foundation

protocol PaymentMethodRepository {
    func fetchPaymentMethods() async throws -> [SDPaymentMethod]
    func fetchPaymentMethod(id: UUID) async throws -> SDPaymentMethod?
    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [SDPaymentMethod]
    func fetchActivePaymentMethods() async throws -> [SDPaymentMethod]
    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        isDefault: Bool,
        groupId: UUID?
    ) async throws -> SDPaymentMethod
    func updatePaymentMethod(_ paymentMethod: SDPaymentMethod) async throws
    func deletePaymentMethod(id: UUID) async throws
}
