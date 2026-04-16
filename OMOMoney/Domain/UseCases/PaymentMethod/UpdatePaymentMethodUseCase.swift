import Foundation

protocol UpdatePaymentMethodUseCase {
    func execute(_ paymentMethod: SDPaymentMethod) async throws
}

final class DefaultUpdatePaymentMethodUseCase: UpdatePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(_ paymentMethod: SDPaymentMethod) async throws {
        try await paymentMethodRepository.updatePaymentMethod(paymentMethod)
    }
}
