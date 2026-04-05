import CoreData
import Foundation

/// Protocol for Item service operations
/// Enables dependency injection and testing
protocol ItemServiceProtocol {
    
    // MARK: - Item CRUD Operations
    
    /// Fetch item by ID
    func fetchItem(by id: UUID) async throws -> Item?
    
    /// Create a new item
    func createItem(description: String?, amount: NSDecimalNumber, quantity: Int32, itemListId: UUID, isPaid: Bool) async throws -> Item
    
    /// Update an existing item
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data object
    func updateItem(itemId: UUID, description: String?, amount: NSDecimalNumber?, quantity: Int32?) async throws
    
    /// Delete an item
    func deleteItem(_ item: Item) async throws
    
    /// Get items for a specific item list
    func getItems(for itemList: ItemList) async throws -> [ItemDomain]

    /// Get items for a specific group
    func getItems(for group: Group) async throws -> [ItemDomain]
    
    /// Calculate total amount for a specific item list
    func calculateTotalAmount(for itemList: ItemList) async throws -> NSDecimalNumber
    
    /// Calculate total amount for a specific group
    func calculateTotalAmount(for group: Group) async throws -> NSDecimalNumber

    /// Set isPaid on all items belonging to a specific item list
    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws
}
