import CoreData
import Foundation

/// Protocol for Item service operations
/// Enables dependency injection and testing
protocol ItemServiceProtocol {
    
    // MARK: - Item CRUD Operations
    
    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item?
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, itemListId: UUID) async throws -> Item
    
    /// Update an existing item
    func updateItem(_ item: Item, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws
    
    /// Get items for a specific item list
    func getItems(for itemList: ItemList) async throws -> [Item]
    
    /// Get items for a specific group
    func getItems(for group: Group) async throws -> [Item]
    
    /// Calculate total amount for a specific item list
    func calculateTotalAmount(for itemList: ItemList) async throws -> NSDecimalNumber
    
    /// Calculate total amount for a specific group
    func calculateTotalAmount(for group: Group) async throws -> NSDecimalNumber
}
