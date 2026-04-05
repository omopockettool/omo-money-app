//
//  UpdatePaymentMethodUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for updating a payment method
protocol UpdatePaymentMethodUseCase {
    /// Update an existing payment method with the specified details
    func execute(_ paymentMethod: PaymentMethodDomain) async throws
}

final class DefaultUpdatePaymentMethodUseCase: UpdatePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(_ paymentMethod: PaymentMethodDomain) async throws {
        try await paymentMethodRepository.updatePaymentMethod(paymentMethod)
    }
}
