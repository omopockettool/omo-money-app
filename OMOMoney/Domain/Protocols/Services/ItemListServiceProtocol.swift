import CoreData
import Foundation

/// Protocol for ItemList service operations
/// Enables dependency injection and testing
protocol ItemListServiceProtocol {
    
    // MARK: - ItemList CRUD Operations
    
    /// Fetch itemList by ID
    func fetchItemList(by id: UUID) async throws -> ItemList?
    
    /// Create a new itemList
    func createItemList(description: String?, date: Date, categoryId: UUID, groupId: UUID, paymentMethodId: UUID?) async throws -> ItemList
    
    /// Update an existing itemList
    func updateItemList(_ itemList: ItemList, description: String?, date: Date?, categoryId: UUID, paymentMethodId: UUID?) async throws
    
    /// Delete an itemList
    func deleteItemList(_ itemList: ItemList) async throws
    
    /// Get itemLists for a specific group
    func getItemLists(for group: Group) async throws -> [ItemListDomain]

    /// Get itemLists for a specific user across all their groups
    func getItemLists(for user: User) async throws -> [ItemListDomain]

    /// Get itemLists for a specific category
    func getItemLists(for category: Category) async throws -> [ItemListDomain]

    /// Get itemLists within a date range
    func getItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain]
    
    /// Get itemLists count for a specific group
    func getItemListsCount(for group: Group) async throws -> Int
    
    /// Get itemLists count for a specific user across all their groups
    func getItemListsCount(for user: User) async throws -> Int

}
