//
//  UserGroup+Mapping.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

// MARK: - Core Data to Domain Mapping
extension UserGroup {
    /// Converts Core Data UserGroup entity to Domain model
    /// - Returns: UserGroupDomain object
    func toDomain() -> UserGroupDomain {
        return UserGroupDomain(
            id: self.id ?? UUID(),
            userId: self.userId ?? UUID(),
            groupId: self.groupId ?? UUID(),
            role: self.role ?? "owner",
            joinedAt: self.joinedAt ?? Date()
        )
    }
    
    /// Updates Core Data UserGroup entity from Domain model
    /// - Parameter domain: UserGroupDomain object with new values
    func update(from domain: UserGroupDomain) {
        self.userId = domain.userId
        self.groupId = domain.groupId
        self.role = domain.role
    }
}

// MARK: - Domain to Core Data Mapping
extension UserGroupDomain {
    /// Converts Domain model to Core Data UserGroup entity
    /// - Parameter context: NSManagedObjectContext for creating entity
    /// - Returns: UserGroup Core Data entity
    func toCoreData(context: NSManagedObjectContext) -> UserGroup {
        let userGroup = UserGroup(context: context)
        userGroup.id = self.id
        userGroup.userId = self.userId
        userGroup.groupId = self.groupId
        userGroup.role = self.role
        userGroup.joinedAt = self.joinedAt
        return userGroup
    }
}
