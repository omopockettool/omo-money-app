//
//  Group+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension Group {
    /// Converts Core Data Group entity to Domain model
    /// - Returns: GroupDomain object
    func toDomain() -> GroupDomain {
        return GroupDomain(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            currency: self.currency ?? "USD",
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt
        )
    }
    
    /// Updates Core Data Group entity from Domain model
    /// - Parameter domain: GroupDomain object with new values
    func update(from domain: GroupDomain) {
        self.name = domain.name
        self.currency = domain.currency
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension GroupDomain {
    /// Converts Domain model to Core Data Group entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: Group Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> Group {
        let group = Group(context: context)
        group.id = self.id
        group.name = self.name
        group.currency = self.currency
        group.createdAt = self.createdAt
        group.lastModifiedAt = self.lastModifiedAt
        return group
    }
}
