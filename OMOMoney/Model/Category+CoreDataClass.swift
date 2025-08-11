//
//  Category+CoreDataClass.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData

@objc(Category)
public class Category: NSManagedObject, Identifiable {
    
    /// Convenience initializer for creating a new Category
    /// - Parameters:
    ///   - context: The managed object context
    ///   - name: The category name (defaults to empty string)
    ///   - color: The category color in hex format (defaults to "#8E8E93")
    ///   - group: The group this category belongs to
    convenience init(context: NSManagedObjectContext, name: String = "", color: String = "#8E8E93", group: Group) {
        self.init(context: context)
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        self.group = group
    }
    
    /// Updates the lastModifiedAt timestamp
    func updateTimestamp() {
        self.lastModifiedAt = Date()
    }
}
