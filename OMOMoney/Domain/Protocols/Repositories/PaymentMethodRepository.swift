import Foundation

@MainActor
protocol PaymentMethodRepository {
    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [SDPaymentMethod]
    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        groupId: UUID?
    ) async throws -> SDPaymentMethod
    func updatePaymentMethod(_ paymentMethod: SDPaymentMethod) async throws
    func deletePaymentMethod(id: UUID) async throws
}
