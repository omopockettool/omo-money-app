//
//  User+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    // MARK: - Properties
    
    /// Unique identifier for the user (optional)
    @NSManaged public var id: UUID?
    
    /// Name of the user (default: "")
    @NSManaged public var name: String?
    
    /// Email of the user (required)
    @NSManaged public var email: String
    
    /// When the user was created
    @NSManaged public var createdAt: Date?
    
    /// When the user was last modified
    @NSManaged public var lastModifiedAt: Date?

    // MARK: - Relationships
    
    /// User-group relationships (to-many, inverse: user, delete rule: Cascade)
    /// When a user is deleted, all their user-group relationships are also deleted
    @NSManaged public var userGroups: Set<UserGroup>?

}

// MARK: - Generated accessors for userGroups
extension User {

    @objc(addUserGroupsObject:)
    @NSManaged public func addToUserGroups(_ value: UserGroup)

    @objc(removeUserGroupsObject:)
    @NSManaged public func removeFromUserGroups(_ value: UserGroup)

    @objc(addUserGroups:)
    @NSManaged public func addToUserGroups(_ values: NSSet)

    @objc(removeUserGroups:)
    @NSManaged public func removeFromUserGroups(_ values: NSSet)

}

// MARK: - Computed Properties
extension User {
    
    /// Returns the user name or "Unnamed User" if nil
    var displayName: String {
        return name?.isEmpty == false ? name! : "Unnamed User"
    }
    
    /// Returns true if the user has a name
    var hasName: Bool {
        return name?.isEmpty == false
    }
    
    /// Returns true if the user belongs to any groups
    var belongsToGroups: Bool {
        return groupCount > 0
    }
    
    /// Returns true if the user is an owner
    var isOwner: Bool {
        return isOwnerInAnyGroup
    }
    
    /// Returns the user's primary group (first group they belong to)
    var primaryGroup: Group? {
        return groups.first
    }
    
    /// Returns the user's primary group name
    var primaryGroupName: String {
        return primaryGroup?.displayName ?? "No Group"
    }
    
    /// Returns the user's role in their primary group
    var primaryGroupRole: String {
        guard let primaryGroup = primaryGroup else { return "No Role" }
        return role(in: primaryGroup) ?? "Unknown Role"
    }
    
    /// Returns a list of group names the user belongs to
    var groupNames: [String] {
        return groups.map { $0.displayName }
    }
    
    /// Returns a list of roles the user has across all groups
    var roles: [String] {
        guard let userGroups = userGroups else { return [] }
        return userGroups.compactMap { $0.role }
    }
    
    /// Returns true if the user has admin privileges in any group
    var hasAdminPrivileges: Bool {
        return roles.contains { $0.lowercased() == "admin" || $0.lowercased() == "owner" }
    }
}
