import Foundation
import CoreData

/// Protocol for Item service operations
/// Enables dependency injection and testing
protocol ItemServiceProtocol {
    
    // MARK: - Item CRUD Operations
    
    /// Fetch all items
    func fetchItems() async throws -> [Item]
    
    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item?
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, entry: Entry) async throws -> Item
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws
    
    /// Get items for a specific entry
    func getItems(for entry: Entry) async throws -> [Item]
    
    /// Calculate total amount for a specific entry
    func calculateTotalAmount(for entry: Entry) async throws -> NSDecimalNumber
    
    /// Calculate total amount for a specific group
    func calculateTotalAmount(for group: Group) async throws -> NSDecimalNumber
    
    /// Get items count
    func getItemsCount() async throws -> Int
}
