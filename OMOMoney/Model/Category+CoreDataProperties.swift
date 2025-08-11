//
//  Category+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    // MARK: - Properties
    
    /// Unique identifier for the category
    @NSManaged public var id: UUID?
    
    /// Name of the category (default: "")
    @NSManaged public var name: String?
    
    /// Color of the category in hex format (default: "#8E8E93")
    @NSManaged public var color: String?
    
    /// When the category was created
    @NSManaged public var createdAt: Date?
    
    /// When the category was last modified
    @NSManaged public var lastModifiedAt: Date?

    // MARK: - Relationships
    
    /// Entries that use this category (to-many, inverse: category, delete rule: Nullify)
    /// When a category is deleted, entries keep their categoryId but lose the relationship
    @NSManaged public var entries: Set<Entry>?
    
    /// Group this category belongs to (to-one, inverse: categories, delete rule: Cascade)
    /// When a group is deleted, all its categories are also deleted
    @NSManaged public var group: Group?

}

// MARK: - Generated accessors for entries
extension Category {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: Entry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: Entry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

// MARK: - Computed Properties
extension Category {
    
    /// Returns the category name or "Unnamed Category" if nil
    var displayName: String {
        return name ?? "Unnamed Category"
    }
    
    /// Returns the color or default color if nil
    var displayColor: String {
        return color ?? "#8E8E93"
    }
    
    /// Returns the number of entries in this category
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
