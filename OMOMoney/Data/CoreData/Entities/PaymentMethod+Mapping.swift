//
//  PaymentMethod+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension PaymentMethod {
    /// Converts Core Data PaymentMethod entity to Domain model
    /// - Returns: PaymentMethodDomain object
    func toDomain() -> PaymentMethodDomain {
        return PaymentMethodDomain(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            type: self.type ?? "card",
            icon: self.icon ?? "creditcard.fill",
            color: self.color ?? "#8E8E93",
            isActive: self.isActive,
            isDefault: self.isDefault,
            groupId: self.group?.id,
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt
        )
    }

    /// Updates Core Data PaymentMethod entity from Domain model
    /// - Parameter domain: PaymentMethodDomain object with new values
    func update(from domain: PaymentMethodDomain) {
        self.name = domain.name
        self.type = domain.type
        self.icon = domain.icon
        self.color = domain.color
        self.isActive = domain.isActive
        self.isDefault = domain.isDefault
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension PaymentMethodDomain {
    /// Converts Domain model to Core Data PaymentMethod entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: PaymentMethod Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> PaymentMethod {
        let paymentMethod = PaymentMethod(context: context)
        paymentMethod.id = self.id
        paymentMethod.name = self.name
        paymentMethod.type = self.type
        paymentMethod.icon = self.icon
        paymentMethod.color = self.color
        paymentMethod.isActive = self.isActive
        paymentMethod.isDefault = self.isDefault
        paymentMethod.createdAt = self.createdAt
        paymentMethod.lastModifiedAt = self.lastModifiedAt
        return paymentMethod
    }
}
