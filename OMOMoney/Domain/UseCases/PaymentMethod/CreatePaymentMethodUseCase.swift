//
//  CreatePaymentMethodUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for creating a payment method
protocol CreatePaymentMethodUseCase {
    /// Create a new payment method with the specified details
    func execute(
        name: String,
        type: String,
        isActive: Bool,
        groupId: UUID
    ) async throws -> PaymentMethodDomain
}

final class DefaultCreatePaymentMethodUseCase: CreatePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(
        name: String,
        type: String,
        isActive: Bool,
        groupId: UUID
    ) async throws -> PaymentMethodDomain {
        return try await paymentMethodRepository.createPaymentMethod(
            name: name,
            type: type,
            isActive: isActive,
            groupId: groupId
        )
    }
}
