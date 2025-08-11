//
//  Item+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(Item)
public class Item: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new Item
    /// - Parameters:
    ///   - context: The managed object context
    ///   - description: The item description (defaults to empty string)
    ///   - amount: The item amount (defaults to 0.0)
    ///   - quantity: The item quantity (defaults to 1)
    ///   - entry: The entry this item belongs to
    convenience init(context: NSManagedObjectContext, description: String = "", amount: NSDecimalNumber = NSDecimalNumber.zero, quantity: Int32 = 1, entry: Entry) {
        self.init(context: context)
        self.id = UUID()
        self.itemDescription = description
        self.amount = amount
        self.quantity = quantity
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        self.entry = entry
    }
    
    /// Updates the lastModifiedAt timestamp
    func updateTimestamp() {
        self.lastModifiedAt = Date()
    }
    
    /// Calculates the total amount for this item (amount * quantity)
    var totalAmount: NSDecimalNumber {
        let itemAmount = amount ?? NSDecimalNumber.zero
        let itemQuantity = NSDecimalNumber(value: quantity)
        return itemAmount.multiplying(by: itemQuantity)
    }
    
    /// Returns formatted amount string
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry?.group?.displayCurrency ?? "USD"
        return formatter.string(from: amount ?? NSDecimalNumber.zero) ?? "0.00"
    }
    
    /// Returns formatted total amount string
    var formattedTotalAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = entry?.group?.displayCurrency ?? "USD"
        return formatter.string(from: totalAmount) ?? "0.00"
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
