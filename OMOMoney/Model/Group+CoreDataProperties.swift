//
//  Group+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    // MARK: - Properties
    
    /// Unique identifier for the group
    @NSManaged public var id: UUID?
    
    /// Name of the group (default: "")
    @NSManaged public var name: String?
    
    /// Currency used by the group (default: "USD")
    @NSManaged public var currency: String?
    
    /// When the group was created
    @NSManaged public var createdAt: Date?
    
    /// When the group was last modified
    @NSManaged public var lastModifiedAt: Date?

    // MARK: - Relationships
    
    /// Entries in this group (to-many, inverse: group, delete rule: Cascade)
    /// When a group is deleted, all its entries are also deleted
    @NSManaged public var entries: Set<Entry>?
    
    /// Categories in this group (to-many, inverse: group, delete rule: Cascade)
    /// When a group is deleted, all its categories are also deleted
    @NSManaged public var categories: Set<Category>?
    
    /// User-group relationships (to-many, inverse: group, delete rule: Cascade)
    /// When a group is deleted, all its user-group relationships are also deleted
    @NSManaged public var userGroups: Set<UserGroup>?

}

// MARK: - Generated accessors for entries
extension Group {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: Entry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: Entry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

// MARK: - Generated accessors for categories
extension Group {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: Category)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: Category)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: - Generated accessors for userGroups
extension Group {

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
extension Group {
    
    /// Returns the group name or "Unnamed Group" if nil
    var displayName: String {
        return name?.isEmpty == false ? name! : "Unnamed Group"
    }
    
    /// Returns the currency or "USD" if nil
    var displayCurrency: String {
        return currency ?? "USD"
    }
    
    /// Returns true if the group has a name
    var hasName: Bool {
        return name?.isEmpty == false
    }
    
    /// Returns true if the group has entries
    var hasEntries: Bool {
        return entryCount > 0
    }
    
    /// Returns true if the group has categories
    var hasCategories: Bool {
        return categoryCount > 0
    }
    
    /// Returns true if the group has members
    var hasMembers: Bool {
        return memberCount > 0
    }
    
    /// Returns the group's total amount as a formatted string
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = displayCurrency
        return formatter.string(from: totalAmount) ?? "0.00"
    }
}
