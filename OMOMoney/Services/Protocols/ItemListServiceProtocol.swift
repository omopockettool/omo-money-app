import CoreData
import Foundation

/// Protocol for ItemList service operations
/// Enables dependency injection and testing
protocol ItemListServiceProtocol {
    
    // MARK: - ItemList CRUD Operations
    
    /// Fetch all itemLists
    func fetchItemLists() async throws -> [ItemList]
    
    /// Fetch itemList by ID
    func fetchItemList(by id: UUID) async throws -> ItemList?
    
    /// Create a new itemList
    func createItemList(description: String?, date: Date, categoryId: UUID, groupId: UUID) async throws -> ItemList
    
    /// Update an existing itemList
    func updateItemList(_ itemList: ItemList, description: String?, date: Date?, categoryId: UUID) async throws
    
    /// Delete an itemList
    func deleteItemList(_ itemList: ItemList) async throws
    
    /// Get itemLists for a specific group
    func getItemLists(for group: Group) async throws -> [ItemList]
    
    /// Get itemLists for a specific category
    func getItemLists(for category: Category) async throws -> [ItemList]
    
    /// Get itemLists within a date range
    func getItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemList]
    
    /// Get itemLists count
    func getItemListsCount() async throws -> Int
}
