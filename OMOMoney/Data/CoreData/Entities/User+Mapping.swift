//
//  User+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension User {
    /// Converts Core Data User entity to Domain model
    /// - Returns: UserDomain object
    func toDomain() -> UserDomain {
        return UserDomain(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            email: self.email ?? "",
            createdAt: self.createdAt ?? Date(),
            lastModifiedAt: self.lastModifiedAt
        )
    }
    
    /// Updates Core Data User entity from Domain model
    /// - Parameter domain: UserDomain object with new values
    func update(from domain: UserDomain) {
        self.name = domain.name
        self.email = domain.email
        self.lastModifiedAt = Date()
    }
}

// MARK: - Domain to Core Data Mapping
extension UserDomain {
    /// Converts Domain model to Core Data User entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: User Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> User {
        let user = User(context: context)
        user.id = self.id
        user.name = self.name
        user.email = self.email
        user.createdAt = self.createdAt
        user.lastModifiedAt = self.lastModifiedAt
        return user
    }
}
