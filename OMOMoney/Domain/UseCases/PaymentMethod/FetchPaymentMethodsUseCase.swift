//
//  FetchPaymentMethodsUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for fetching payment methods
protocol FetchPaymentMethodsUseCase {
    /// Fetch a single payment method by ID
    func execute(paymentMethodId: UUID) async throws -> PaymentMethodDomain?
    /// Fetch all payment methods for a specific group
    func execute(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain]
    /// Fetch only active payment methods for a specific group
    func executeActive(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain]
}

final class DefaultFetchPaymentMethodsUseCase: FetchPaymentMethodsUseCase {
    private let paymentMethodRepository: PaymentMethodRepository

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
    }

    func execute(paymentMethodId: UUID) async throws -> PaymentMethodDomain? {
        return try await paymentMethodRepository.fetchPaymentMethod(id: paymentMethodId)
    }

    func execute(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        return try await paymentMethodRepository.fetchPaymentMethods(forGroupId: groupId)
    }

    func executeActive(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        // Fetch all payment methods for the group, then filter active ones
        let allPaymentMethods = try await paymentMethodRepository.fetchPaymentMethods(forGroupId: groupId)
        return allPaymentMethods.filter { $0.isActive }
    }
}
