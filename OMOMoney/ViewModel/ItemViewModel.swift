//
//  ItemViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class ItemViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of items for SwiftUI binding
    @Published var items: [Item] = []
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error message for user feedback
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    /// Initialize with a managed object context
    /// - Parameter context: The Core Data context to use for operations
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchItems()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all items from Core Data
    func fetchItems() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.createdAt, ascending: false)]
        
        do {
            items = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch items: \(error.localizedDescription)"
            print("Error fetching items: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new item
    /// - Parameters:
    ///   - description: The item description
    ///   - amount: The item amount
    ///   - quantity: The item quantity (defaults to 1)
    ///   - entry: The entry this item belongs to
    /// - Returns: The created item or nil if failed
    func createItem(description: String, amount: NSDecimalNumber, quantity: Int32 = 1, entry: Entry) -> Item? {
        isLoading = true
        errorMessage = nil
        
        let newItem = Item(context: context)
        newItem.id = UUID()
        newItem.itemDescription = description
        newItem.amount = amount
        newItem.quantity = quantity
        newItem.createdAt = Date()
        newItem.lastModifiedAt = Date()
        newItem.entry = entry
        
        do {
            try context.save()
            fetchItems() // Refresh the list
            isLoading = false
            return newItem
        } catch {
            context.rollback()
            errorMessage = "Failed to create item: \(error.localizedDescription)"
            print("Error creating item: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Update an existing item
    /// - Parameters:
    ///   - item: The item to update
    ///   - description: New description (optional)
    ///   - amount: New amount (optional)
    ///   - quantity: New quantity (optional)
    /// - Returns: True if update was successful
    func updateItem(_ item: Item, description: String? = nil, amount: NSDecimalNumber? = nil, quantity: Int32? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        if let description = description {
            item.itemDescription = description
        }
        
        if let amount = amount {
            item.amount = amount
        }
        
        if let quantity = quantity {
            item.quantity = quantity
        }
        
        item.lastModifiedAt = Date()
        
        do {
            try context.save()
            fetchItems() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update item: \(error.localizedDescription)"
            print("Error updating item: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete an item
    /// - Parameter item: The item to delete
    /// - Returns: True if deletion was successful
    func deleteItem(_ item: Item) -> Bool {
        isLoading = true
        errorMessage = nil
        
        context.delete(item)
        
        do {
            try context.save()
            fetchItems() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            print("Error deleting item: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get items for a specific entry
    /// - Parameter entry: The entry to filter by
    /// - Returns: Array of items in the entry
    func items(for entry: Entry) -> [Item] {
        return items.filter { $0.entry?.id == entry.id }
    }
    
    /// Get items for a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of items in the category
    func items(for category: Category) -> [Item] {
        return items.filter { $0.entry?.category?.id == category.id }
    }
    
    /// Get items for a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of items in the group
    func items(for group: Group) -> [Item] {
        return items.filter { $0.entry?.group?.id == group.id }
    }
    
    /// Get items with amount greater than specified value
    /// - Parameter amount: The minimum amount threshold
    /// - Returns: Array of items above the threshold
    func items(withAmountGreaterThan amount: NSDecimalNumber) -> [Item] {
        return items.filter { item in
            guard let itemAmount = item.amount else { return false }
            return itemAmount.compare(amount) == .orderedDescending
        }
    }
    
    /// Get items with quantity greater than specified value
    /// - Parameter quantity: The minimum quantity threshold
    /// - Returns: Array of items above the threshold
    func items(withQuantityGreaterThan quantity: Int32) -> [Item] {
        return items.filter { $0.quantity > quantity }
    }
    
    /// Get item by ID
    /// - Parameter id: The item ID to search for
    /// - Returns: The item if found, nil otherwise
    func item(with id: UUID) -> Item? {
        return items.first { $0.id == id }
    }
    
    /// Calculate total amount for a specific entry
    /// - Parameter entry: The entry to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for entry: Entry) -> NSDecimalNumber {
        let entryItems = items(for: entry)
        return entryItems.reduce(NSDecimalNumber.zero) { total, item in
            let itemAmount = item.amount ?? NSDecimalNumber.zero
            let itemQuantity = NSDecimalNumber(value: item.quantity)
            return total.adding(itemAmount.multiplying(by: itemQuantity))
        }
    }
    
    /// Calculate total amount for a specific category
    /// - Parameter category: The category to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for category: Category) -> NSDecimalNumber {
        let categoryItems = items(for: category)
        return categoryItems.reduce(NSDecimalNumber.zero) { total, item in
            let itemAmount = item.amount ?? NSDecimalNumber.zero
            let itemQuantity = NSDecimalNumber(value: item.quantity)
            return total.adding(itemAmount.multiplying(by: itemQuantity))
        }
    }
    
    /// Calculate total amount for a specific group
    /// - Parameter group: The group to calculate total for
    /// - Returns: Total amount as NSDecimalNumber
    func totalAmount(for group: Group) -> NSDecimalNumber {
        let groupItems = items(for: group)
        return groupItems.reduce(NSDecimalNumber.zero) { total, item in
            let itemAmount = item.amount ?? NSDecimalNumber.zero
            let itemQuantity = NSDecimalNumber(value: item.quantity)
            return total.adding(itemAmount.multiplying(by: itemQuantity))
        }
    }
    
    /// Get items sorted by amount (highest first)
    /// - Returns: Array of items sorted by amount
    func itemsSortedByAmount() -> [Item] {
        return items.sorted { item1, item2 in
            let amount1 = item1.amount ?? NSDecimalNumber.zero
            let amount2 = item2.amount ?? NSDecimalNumber.zero
            return amount1.compare(amount2) == .orderedDescending
        }
    }
    
    /// Get items sorted by quantity (highest first)
    /// - Returns: Array of items sorted by quantity
    func itemsSortedByQuantity() -> [Item] {
        return items.sorted { $0.quantity > $1.quantity }
    }
    
    /// Get items sorted by creation date (newest first)
    /// - Returns: Array of items sorted by creation date
    func itemsSortedByCreationDate() -> [Item] {
        return items.sorted { item1, item2 in
            let date1 = item1.createdAt ?? Date.distantPast
            let date2 = item2.createdAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
