//
//  ItemDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for Item
/// No Core Data dependencies - represents business logic
struct ItemDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let itemDescription: String
    let amount: Decimal
    let quantity: Int32
    let itemListId: UUID?
    let createdAt: Date
    let lastModifiedAt: Date?
    let isPaid: Bool

    init(
        id: UUID = UUID(),
        itemDescription: String = "",
        amount: Decimal = 0.0,
        quantity: Int32 = 1,
        itemListId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        isPaid: Bool = false
    ) {
        self.id = id
        self.itemDescription = itemDescription
        self.amount = amount
        self.quantity = quantity
        self.itemListId = itemListId
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
        self.isPaid = isPaid
    }
}

// MARK: - Computed Properties
extension ItemDomain {
    var totalAmount: Decimal {
        amount * Decimal(quantity)
    }
}

// MARK: - Validation
extension ItemDomain {
    var isValid: Bool {
        !itemDescription.isEmpty && amount > 0 && quantity > 0
    }
    
    func validate() throws {
        guard !itemDescription.isEmpty else {
            throw ValidationError.emptyItemDescription
        }
        
        guard amount > 0 else {
            throw ValidationError.invalidAmount
        }
    }
}

// MARK: - Test Mock
#if DEBUG
extension ItemDomain {
    static func mock(
        id: UUID = UUID(),
        itemDescription: String = "Test Item",
        amount: Decimal = 10.0,
        quantity: Int32 = 1,
        itemListId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil,
        isPaid: Bool = false
    ) -> ItemDomain {
        ItemDomain(
            id: id,
            itemDescription: itemDescription,
            amount: amount,
            quantity: quantity,
            itemListId: itemListId,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt,
            isPaid: isPaid
        )
    }
}
#endif
