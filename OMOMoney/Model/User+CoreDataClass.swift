//
//  User+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(User)
public class User: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new User
    /// - Parameters:
    ///   - context: The managed object context
    ///   - name: The user name (defaults to empty string)
    ///   - email: The user email (required)
    convenience init(context: NSManagedObjectContext, name: String = "", email: String) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
        self.lastModifiedAt = Date()
    }
    
    /// Updates the lastModifiedAt timestamp
    func updateTimestamp() {
        self.lastModifiedAt = Date()
    }
    
    /// Returns the number of groups this user belongs to
    var groupCount: Int {
        return userGroups?.count ?? 0
    }
    
    /// Returns the groups this user belongs to
    var groups: [Group] {
        guard let userGroups = userGroups else { return [] }
        return userGroups.compactMap { $0.group }
    }
    
    /// Returns the user's role in a specific group
    /// - Parameter group: The group to check
    /// - Returns: The user's role or nil if not a member
    func role(in group: Group) -> String? {
        guard let userGroups = userGroups else { return nil }
        return userGroups.first { $0.group?.id == group.id }?.role
    }
    
    /// Returns true if the user is an owner in any group
    var isOwnerInAnyGroup: Bool {
        guard let userGroups = userGroups else { return false }
        return userGroups.contains { $0.role == "owner" }
    }
    
    /// Returns true if the user is an owner in a specific group
    /// - Parameter group: The group to check
    /// - Returns: True if user is owner
    func isOwner(in group: Group) -> Bool {
        return role(in: group) == "owner"
    }
    
    /// Returns formatted creation date
    var formattedCreatedDate: String {
        guard let date = createdAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Returns formatted last modified date
    var formattedModifiedDate: String {
        guard let date = lastModifiedAt else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
