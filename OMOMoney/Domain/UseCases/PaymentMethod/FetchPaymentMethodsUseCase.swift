import Foundation

protocol FetchPaymentMethodsUseCase {
    func execute(forGroupId groupId: UUID) async throws -> [SDPaymentMethod]
    func executeActive(forGroupId groupId: UUID) async throws -> [SDPaymentMethod]
}

final class DefaultFetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(forGroupId groupId: UUID) async throws -> [SDPaymentMethod] {
        return try await paymentMethodRepository.fetchPaymentMethods(forGroupId: groupId)
    }

    func executeActive(forGroupId groupId: UUID) async throws -> [SDPaymentMethod] {
        let all = try await paymentMethodRepository.fetchPaymentMethods(forGroupId: groupId)
        return all.filter { $0.isActive }
    }
}
