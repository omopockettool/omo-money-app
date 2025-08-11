//
//  Group+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(Group)
public class Group: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new Group
    /// - Parameters:
    ///   - context: The managed object context
    ///   - name: The group name (defaults to empty string)
    ///   - currency: The group currency (defaults to "USD")
    convenience init(context: NSManagedObjectContext, name: String = "", currency: String = "USD") {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.currency = currency
        self.createdAt = Date()
        self.lastModifiedAt = Date()
    }
    
    /// Updates the lastModifiedAt timestamp
    func updateTimestamp() {
        self.lastModifiedAt = Date()
    }
    
    /// Returns the total amount spent in this group
    var totalAmount: NSDecimalNumber {
        guard let entries = entries else { return NSDecimalNumber.zero }
        return entries.reduce(NSDecimalNumber.zero) { total, entry in
            total.adding(entry.totalAmount)
        }
    }
    
    /// Returns the number of members in this group
    var memberCount: Int {
        return userGroups?.count ?? 0
    }
    
    /// Returns the number of categories in this group
    var categoryCount: Int {
        return categories?.count ?? 0
    }
    
    /// Returns the number of entries in this group
    var entryCount: Int {
        return entries?.count ?? 0
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
