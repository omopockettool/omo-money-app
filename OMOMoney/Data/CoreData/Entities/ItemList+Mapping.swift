//
//  ItemList+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension ItemList {
    /// Converts Core Data ItemList entity to Domain model
    /// - Returns: ItemListDomain object
    func toDomain() -> ItemListDomain {
        return ItemListDomain(
            id: self.id ?? UUID(),
            itemListDescription: self.itemListDescription ?? "",
            date: self.date ?? Date(),
            categoryId: self.categoryId,
            paymentMethodId: self.paymentMethodId,
            groupId: self.groupId,
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt
        )
    }
    
    /// Updates Core Data ItemList entity from Domain model
    /// - Parameter domain: ItemListDomain object with new values
    func update(from domain: ItemListDomain) {
        self.itemListDescription = domain.itemListDescription
        self.date = domain.date
        self.categoryId = domain.categoryId
        self.paymentMethodId = domain.paymentMethodId
        self.groupId = domain.groupId
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension ItemListDomain {
    /// Converts Domain model to Core Data ItemList entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: ItemList Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> ItemList {
        let itemList = ItemList(context: context)
        itemList.id = self.id
        itemList.itemListDescription = self.itemListDescription
        itemList.date = self.date
        itemList.categoryId = self.categoryId
        itemList.paymentMethodId = self.paymentMethodId
        itemList.groupId = self.groupId
        itemList.createdAt = self.createdAt
        itemList.lastModifiedAt = self.lastModifiedAt
        return itemList
    }
}
