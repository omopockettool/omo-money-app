import Foundation

protocol CreatePaymentMethodUseCase {
    func execute(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        isDefault: Bool,
        groupId: UUID
    ) async throws -> SDPaymentMethod
}

final class DefaultCreatePaymentMethodUseCase: CreatePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(
        name: String,
        type: String,
        icon: String = "creditcard.fill",
        color: String = "#8E8E93",
        isActive: Bool,
        isDefault: Bool = false,
        groupId: UUID
    ) async throws -> SDPaymentMethod {
        return try await paymentMethodRepository.createPaymentMethod(
            name: name,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            isDefault: isDefault,
            groupId: groupId
        )
    }
}
