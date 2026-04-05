//
//  DeletePaymentMethodUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for deleting a payment method
protocol DeletePaymentMethodUseCase {
    /// Delete a payment method by its ID
    func execute(id: UUID) async throws
}

final class DefaultDeletePaymentMethodUseCase: DeletePaymentMethodUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(id: UUID) async throws {
        try await paymentMethodRepository.deletePaymentMethod(id: id)
    }
}
