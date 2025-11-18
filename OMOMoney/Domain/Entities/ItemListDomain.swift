//
//  ItemListDomain.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Pure Swift domain model for ItemList (Entry/Transaction)
/// No Core Data dependencies - represents business logic
struct ItemListDomain: Identifiable, Equatable, Hashable {
    let id: UUID
    let itemListDescription: String
    let date: Date
    let categoryId: UUID?
    let paymentMethodId: UUID?
    let groupId: UUID?
    let createdAt: Date
    let lastModifiedAt: Date?
    
    init(
        id: UUID = UUID(),
        itemListDescription: String = "",
        date: Date = Date(),
        categoryId: UUID? = nil,
        paymentMethodId: UUID? = nil,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) {
        self.id = id
        self.itemListDescription = itemListDescription
        self.date = date
        self.categoryId = categoryId
        self.paymentMethodId = paymentMethodId
        self.groupId = groupId
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }
}

// MARK: - Validation
extension ItemListDomain {
    var isValid: Bool {
        true // ItemList description can be empty
    }
}

// MARK: - Test Mock
#if DEBUG
extension ItemListDomain {
    static func mock(
        id: UUID = UUID(),
        itemListDescription: String = "Shopping",
        date: Date = Date(),
        categoryId: UUID? = nil,
        paymentMethodId: UUID? = nil,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastModifiedAt: Date? = nil
    ) -> ItemListDomain {
        ItemListDomain(
            id: id,
            itemListDescription: itemListDescription,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
#endif
