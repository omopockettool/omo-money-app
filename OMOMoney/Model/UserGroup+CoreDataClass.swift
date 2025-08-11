//
//  UserGroup+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(UserGroup)
public class UserGroup: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new UserGroup
    /// - Parameters:
    ///   - context: The managed object context
    ///   - user: The user in this relationship
    ///   - group: The group in this relationship
    ///   - role: The user's role in the group (defaults to "owner")
    convenience init(context: NSManagedObjectContext, user: User, group: Group, role: String = "owner") {
        self.init(context: context)
        self.id = UUID()
        self.user = user
        self.group = group
        self.role = role
        self.joinedAt = Date()
    }
    
    /// Returns the user's display name
    var userDisplayName: String {
        return user?.displayName ?? "Unknown User"
    }
    
    /// Returns the group's display name
    var groupDisplayName: String {
        return group?.displayName ?? "Unknown Group"
    }
    
    /// Returns the user's email
    var userEmail: String {
        return user?.email ?? "No Email"
    }
    
    /// Returns the group's currency
    var groupCurrency: String {
        return group?.displayCurrency ?? "USD"
    }
    
    /// Returns true if the user is an owner in this group
    var isOwner: Bool {
        return role == "owner"
    }
    
    /// Returns true if the user is an admin in this group
    var isAdmin: Bool {
        return role == "admin" || role == "owner"
    }
    
    /// Returns true if the user has write permissions in this group
    var hasWritePermissions: Bool {
        return isAdmin
    }
    
    /// Returns true if the user has read-only permissions in this group
    var isReadOnly: Bool {
        return role == "member" || role == "viewer"
    }
    
    /// Returns formatted joined date
    var formattedJoinedDate: String {
        guard let date = joinedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Returns the role display name
    var roleDisplayName: String {
        switch role?.lowercased() {
        case "owner":
            return "Owner"
        case "admin":
            return "Admin"
        case "member":
            return "Member"
        case "viewer":
            return "Viewer"
        default:
            return role ?? "Unknown"
        }
    }
    
    /// Returns the role priority for sorting (higher number = higher priority)
    var rolePriority: Int {
        switch role?.lowercased() {
        case "owner":
            return 4
        case "admin":
            return 3
        case "member":
            return 2
        case "viewer":
            return 1
        default:
            return 0
        }
    }
}
