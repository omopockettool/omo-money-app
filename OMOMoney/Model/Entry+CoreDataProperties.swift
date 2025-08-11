//
//  Entry+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry")
    }

    // MARK: - Properties
    
    /// Unique identifier for the entry
    @NSManaged public var id: UUID?
    
    /// Description of the entry (default: "")
    @NSManaged public var entryDescription: String?
    
    /// Date when the expense occurred
    @NSManaged public var date: Date
    
    /// When the entry was created
    @NSManaged public var createdAt: Date?
    
    /// When the entry was last modified
    @NSManaged public var lastModifiedAt: Date?
    
    /// Category ID for the entry
    @NSManaged public var categoryId: UUID?
    
    /// Group ID for the entry
    @NSManaged public var groupId: UUID?

    // MARK: - Relationships
    
    /// Category this entry belongs to (to-one, inverse: entries, delete rule: Nullify)
    /// When a category is deleted, entries keep their categoryId but lose the relationship
    @NSManaged public var category: Category?
    
    /// Group this entry belongs to (to-one, inverse: entries, delete rule: Nullify)
    /// When a group is deleted, entries keep their groupId but lose the relationship
    @NSManaged public var group: Group?
    
    /// Items in this entry (to-many, inverse: entry, delete rule: Cascade)
    /// When an entry is deleted, all its items are also deleted
    @NSManaged public var items: Set<Item>?

}

// MARK: - Generated accessors for items
extension Entry {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

// MARK: - Computed Properties
extension Entry {
    
    /// Returns the entry description or "No description" if nil
    var displayDescription: String {
        return entryDescription?.isEmpty == false ? entryDescription! : "No description"
    }
    
    /// Returns the category name or "Uncategorized" if nil
    var categoryName: String {
        return category?.displayName ?? "Uncategorized"
    }
    
    /// Returns the group name or "Unknown Group" if nil
    var groupName: String {
        return group?.displayName ?? "Unknown Group"
    }
    
    /// Returns the number of items in this entry
    var itemCount: Int {
        return items?.count ?? 0
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
    
    /// Returns true if the entry has items
    var hasItems: Bool {
        return itemCount > 0
    }
    
    /// Returns true if the entry has a description
    var hasDescription: Bool {
        return entryDescription?.isEmpty == false
    }
}
