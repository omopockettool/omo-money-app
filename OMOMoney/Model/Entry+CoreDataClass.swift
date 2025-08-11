//
//  Entry+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(Entry)
public class Entry: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new Entry
    /// - Parameters:
    ///   - context: The managed object context
    ///   - description: The entry description (defaults to empty string)
    ///   - date: The date of the entry
    ///   - category: The category this entry belongs to
    ///   - group: The group this entry belongs to
    convenience init(context: NSManagedObjectContext, description: String = "", date: Date, category: Category, group: Group) {
        self.init(context: context)
        self.id = UUID()
        self.entryDescription = description
        self.date = date
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        self.category = category
        self.group = group
    }
    
    /// Updates the lastModifiedAt timestamp
    func updateTimestamp() {
        self.lastModifiedAt = Date()
    }
    
    /// Calculates the total amount for this entry
    var totalAmount: NSDecimalNumber {
        guard let items = items else { return NSDecimalNumber.zero }
        return items.reduce(NSDecimalNumber.zero) { total, item in
            let itemAmount = item.amount ?? NSDecimalNumber.zero
            let quantity = NSDecimalNumber(value: item.quantity)
            return total.adding(itemAmount.multiplying(by: quantity))
        }
    }
    
    /// Returns formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Returns formatted time string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
