//
//  PaymentMethodDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for PaymentMethod
/// No Core Data dependencies - represents business logic
struct PaymentMethodDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let type: String
    let isActive: Bool
    let groupId: UUID?
    let createdAt: Date
    let lastModifiedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        type: String = "card",
        isActive: Bool = true,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isActive = isActive
        self.groupId = groupId
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

// MARK: - Validation
extension PaymentMethodDomain {
    var isValid: Bool {
        !name.isEmpty
    }
    
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyPaymentMethodName
        }
    }
}

// MARK: - Test Mock
#if DEBUG
extension PaymentMethodDomain {
    static func mock(
        id: UUID = UUID(),
        name: String = "Credit Card",
        type: String = "card",
        isActive: Bool = true,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> PaymentMethodDomain {
        PaymentMethodDomain(
            id: id,
            name: name,
            type: type,
            isActive: isActive,
            groupId: groupId,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
