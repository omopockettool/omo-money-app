//
//  Item+CoreDataProperties.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    // MARK: - Properties
    
    /// Unique identifier for the item
    @NSManaged public var id: UUID?
    
    /// Description of the item (default: "")
    @NSManaged public var itemDescription: String?
    
    /// Amount of the item (default: 0.0)
    @NSManaged public var amount: NSDecimalNumber?
    
    /// Quantity of the item (default: 1)
    @NSManaged public var quantity: Int32
    
    /// When the item was created
    @NSManaged public var createdAt: Date?
    
    /// When the item was last modified
    @NSManaged public var lastModifiedAt: Date?

    // MARK: - Relationships
    
    /// Entry this item belongs to (to-one, inverse: items, delete rule: Nullify)
    /// When an entry is deleted, items keep their entryId but lose the relationship
    @NSManaged public var entry: Entry?

}

// MARK: - Computed Properties
extension Item {
    
    /// Returns the item description or "No description" if nil
    var displayDescription: String {
        return itemDescription?.isEmpty == false ? itemDescription! : "No description"
    }
    
    /// Returns the amount or 0.0 if nil
    var displayAmount: NSDecimalNumber {
        return amount ?? NSDecimalNumber.zero
    }
    
    /// Returns the quantity as Int
    var displayQuantity: Int {
        return Int(quantity)
    }
    
    /// Returns true if the item has a description
    var hasDescription: Bool {
        return itemDescription?.isEmpty == false
    }
    
    /// Returns true if the item has an amount greater than 0
    var hasAmount: Bool {
        return (amount?.compare(NSDecimalNumber.zero) == .orderedDescending)
    }
    
    /// Returns true if the item quantity is greater than 1
    var hasMultipleQuantity: Bool {
        return quantity > 1
    }
    
    /// Returns the entry description or "Unknown Entry" if nil
    var entryDescription: String {
        return entry?.displayDescription ?? "Unknown Entry"
    }
    
    /// Returns the category name or "Uncategorized" if nil
    var categoryName: String {
        return entry?.categoryName ?? "Uncategorized"
    }
    
    /// Returns the group name or "Unknown Group" if nil
    var groupName: String {
        return entry?.groupName ?? "Unknown Group"
    }
    
    /// Returns the group currency or "USD" if nil
    var groupCurrency: String {
        return entry?.group?.displayCurrency ?? "USD"
    }
}
