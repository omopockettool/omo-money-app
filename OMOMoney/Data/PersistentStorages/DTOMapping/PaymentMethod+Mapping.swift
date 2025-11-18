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
            isActive: self.isActive,
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
        self.isActive = domain.isActive
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
        paymentMethod.isActive = self.isActive
        paymentMethod.createdAt = self.createdAt
        paymentMethod.lastModifiedAt = self.lastModifiedAt
        return paymentMethod
    }
}
