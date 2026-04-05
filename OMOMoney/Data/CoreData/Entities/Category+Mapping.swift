//
//  Category+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension Category {
    /// Converts Core Data Category entity to Domain model
    /// - Returns: CategoryDomain object
    func toDomain() -> CategoryDomain {
        return CategoryDomain(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            color: self.color ?? "#8E8E93",
            icon: self.icon ?? "tag.fill",
            isDefault: self.isDefault,
            limit: self.limit as Decimal?,
            limitFrequency: self.limitFrequency ?? "monthly",
            groupId: self.group?.id,
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt
        )
    }

    /// Updates Core Data Category entity from Domain model
    /// - Parameter domain: CategoryDomain object with new values
    func update(from domain: CategoryDomain) {
        self.name = domain.name
        self.color = domain.color
        self.icon = domain.icon
        self.isDefault = domain.isDefault
        self.limit = domain.limit as NSDecimalNumber?
        self.limitFrequency = domain.limitFrequency
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension CategoryDomain {
    /// Converts Domain model to Core Data Category entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: Category Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> Category {
        let category = Category(context: context)
        category.id = self.id
        category.name = self.name
        category.color = self.color
        category.icon = self.icon
        category.isDefault = self.isDefault
        category.limit = self.limit as NSDecimalNumber?
        category.limitFrequency = self.limitFrequency
        category.createdAt = self.createdAt
        category.lastModifiedAt = self.lastModifiedAt
        return category
    }
}
