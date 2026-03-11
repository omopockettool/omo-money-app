//
//  DefaultPaymentMethodRepository.swift
//  OMOMoney
//
//  Created on 12/23/25.
//  ✅ Clean Architecture: Thin wrapper - Service returns Domain models directly
//

import Foundation

final class DefaultPaymentMethodRepository: PaymentMethodRepository {
    private let paymentMethodService: PaymentMethodServiceProtocol

    init(paymentMethodService: PaymentMethodServiceProtocol) {
        self.paymentMethodService = paymentMethodService
    }

    func fetchPaymentMethods() async throws -> [PaymentMethodDomain] {
        // TODO: Need PaymentMethodService method to fetch all payment methods
        throw RepositoryError.notFound
    }

    func fetchPaymentMethod(id: UUID) async throws -> PaymentMethodDomain? {
        // Simple passthrough - Service returns Domain model directly
        return try await paymentMethodService.fetchPaymentMethod(by: id)
    }

    func fetchPaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        // Simple passthrough - Service returns Domain models directly
        return try await paymentMethodService.getPaymentMethods(forGroupId: groupId)
    }

    func fetchActivePaymentMethods() async throws -> [PaymentMethodDomain] {
        // TODO: Need to fetch active payment methods for all groups
        throw RepositoryError.notFound
    }

    func createPaymentMethod(
        name: String,
        type: String,
        icon: String,
        color: String,
        isActive: Bool,
        isDefault: Bool,
        groupId: UUID?
    ) async throws -> PaymentMethodDomain {
        guard let groupId = groupId else {
            throw NSError(domain: "DefaultPaymentMethodRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "groupId is required"])
        }

        // Simple passthrough - Service returns Domain model directly
        return try await paymentMethodService.createPaymentMethod(
            name: name,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            isDefault: isDefault,
            groupId: groupId
        )
    }

    func updatePaymentMethod(_ paymentMethod: PaymentMethodDomain) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await paymentMethodService.updatePaymentMethod(
            paymentMethodId: paymentMethod.id,
            name: paymentMethod.name,
            type: paymentMethod.type,
            isActive: paymentMethod.isActive
        )
    }

    func deletePaymentMethod(id: UUID) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await paymentMethodService.deletePaymentMethod(paymentMethodId: id)
    }
}
