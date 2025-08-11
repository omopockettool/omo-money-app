//
//  UserGroup+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension UserGroup {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserGroup> {
        return NSFetchRequest<UserGroup>(entityName: "UserGroup")
    }

    // MARK: - Properties
    
    /// Unique identifier for the user-group relationship
    @NSManaged public var id: UUID?
    
    /// Role of the user in the group (default: "owner")
    @NSManaged public var role: String?
    
    /// When the user joined the group
    @NSManaged public var joinedAt: Date?
    
    /// User ID for the relationship
    @NSManaged public var userId: UUID?
    
    /// Group ID for the relationship
    @NSManaged public var groupId: UUID?

    // MARK: - Relationships
    
    /// User in this relationship (to-one, inverse: userGroups, delete rule: Cascade)
    /// When a user is deleted, all their user-group relationships are also deleted
    @NSManaged public var user: User?
    
    /// Group in this relationship (to-one, inverse: userGroups, delete rule: Cascade)
    /// When a group is deleted, all its user-group relationships are also deleted
    @NSManaged public var group: Group?

}

// MARK: - Computed Properties
extension UserGroup {
    
    /// Returns the role or "owner" if nil
    var displayRole: String {
        return role ?? "owner"
    }
    
    /// Returns true if the relationship has a user
    var hasUser: Bool {
        return user != nil
    }
    
    /// Returns true if the relationship has a group
    var hasGroup: Bool {
        return group != nil
    }
    
    /// Returns true if the relationship is valid (has both user and group)
    var isValid: Bool {
        return hasUser && hasGroup
    }
    
    /// Returns the user ID or nil if no user
    var displayUserId: UUID? {
        return user?.id
    }
    
    /// Returns the group ID or nil if no group
    var displayGroupId: UUID? {
        return group?.id
    }
    
    /// Returns true if the user can manage the group
    var canManageGroup: Bool {
        return isOwner || role == "admin"
    }
    
    /// Returns true if the user can invite others to the group
    var canInviteUsers: Bool {
        return isOwner || role == "admin"
    }
    
    /// Returns true if the user can remove others from the group
    var canRemoveUsers: Bool {
        return isOwner
    }
    
    /// Returns true if the user can edit group settings
    var canEditGroupSettings: Bool {
        return isOwner
    }
    
    /// Returns true if the user can delete the group
    var canDeleteGroup: Bool {
        return isOwner
    }
    
    /// Returns true if the user can add/edit categories
    var canManageCategories: Bool {
        return isAdmin
    }
    
    /// Returns true if the user can add/edit entries
    var canManageEntries: Bool {
        return isAdmin
    }
    
    /// Returns true if the user can only view data
    var canOnlyView: Bool {
        return role == "viewer"
    }
}
