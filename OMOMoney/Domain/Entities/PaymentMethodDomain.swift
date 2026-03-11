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
    let icon: String
    let color: String
    let isActive: Bool
    let isDefault: Bool
    let groupId: UUID?
    let createdAt: Date
    let lastModifiedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        type: String = "card",
        icon: String = "creditcard.fill",
        color: String = "#8E8E93",
        isActive: Bool = true,
        isDefault: Bool = false,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.isDefault = isDefault
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
        icon: String = "creditcard.fill",
        color: String = "#2196F3",
        isActive: Bool = true,
        isDefault: Bool = false,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> PaymentMethodDomain {
        PaymentMethodDomain(
            id: id,
            name: name,
            type: type,
            icon: icon,
            color: color,
            isActive: isActive,
            isDefault: isDefault,
            groupId: groupId,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
