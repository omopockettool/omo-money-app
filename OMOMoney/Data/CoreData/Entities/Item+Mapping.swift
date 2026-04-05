//
//  Item+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension Item {
    /// Converts Core Data Item entity to Domain model
    /// - Returns: ItemDomain object
    func toDomain() -> ItemDomain {
        return ItemDomain(
            id: self.id ?? UUID(),
            itemDescription: self.itemDescription ?? "",
            amount: self.amount as Decimal? ?? 0.0,
            quantity: self.quantity,
            itemListId: self.itemList?.id,
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt,
            isPaid: self.isPaid
        )
    }
    
    /// Updates Core Data Item entity from Domain model
    /// - Parameter domain: ItemDomain object with new values
    func update(from domain: ItemDomain) {
        self.itemDescription = domain.itemDescription
        self.amount = domain.amount as NSDecimalNumber
        self.quantity = domain.quantity
        self.isPaid = domain.isPaid
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension ItemDomain {
    /// Converts Domain model to Core Data Item entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: Item Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> Item {
        let item = Item(context: context)
        item.id = self.id
        item.itemDescription = self.itemDescription
        item.amount = self.amount as NSDecimalNumber
        item.quantity = self.quantity
        item.isPaid = self.isPaid
        item.createdAt = self.createdAt
        item.lastModifiedAt = self.lastModifiedAt
        return item
    }
}
