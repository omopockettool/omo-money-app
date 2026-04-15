import CoreData
import Foundation

// MARK: - Type Aliases for Core Data Entities
// During SwiftData migration, explicitly reference Core Data NSManagedObject subclasses
// These will be removed in Phase 3 when Core Data is fully deprecated

/// Protocol for ItemList service operations
/// Enables dependency injection and testing
/// ⚠️ MIGRATION NOTE: Uses Core Data entities - will be deprecated in Phase 3
protocol ItemListServiceProtocol {
    
    // MARK: - ItemList CRUD Operations
    
    /// Fetch itemList by ID
    /// - Parameter id: UUID of the itemList
    /// - Returns: Core Data ItemList entity (NSManagedObject subclass)
    func fetchItemList(by id: UUID) async throws -> ItemList?
    
    /// Create a new itemList
    /// - Returns: Core Data ItemList entity (NSManagedObject subclass)
    func createItemList(description: String?, date: Date, categoryId: UUID, groupId: UUID, paymentMethodId: UUID?) async throws -> ItemList
    
    /// Update an existing itemList
    /// - Parameter itemList: Core Data ItemList entity to update
    func updateItemList(_ itemList: ItemList, description: String?, date: Date?, categoryId: UUID, paymentMethodId: UUID?) async throws
    
    /// Delete an itemList
    /// - Parameter itemList: Core Data ItemList entity to delete
    func deleteItemList(_ itemList: ItemList) async throws
    
    /// Get itemLists for a specific group
    /// - Parameter group: Core Data Group entity
    /// - Returns: Array of ItemListDomain models
    func getItemLists(for group: Group) async throws -> [ItemListDomain]

    /// Get itemLists for a specific user across all their groups
    /// - Parameter user: Core Data User entity
    /// - Returns: Array of ItemListDomain models
    func getItemLists(for user: User) async throws -> [ItemListDomain]

    /// Get itemLists for a specific category
    /// - Parameter category: Core Data Category entity
    /// - Returns: Array of ItemListDomain models
    func getItemLists(for category: Category) async throws -> [ItemListDomain]

    /// Get itemLists within a date range
    /// - Returns: Array of ItemListDomain models
    func getItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain]
    
    /// Get itemLists count for a specific group
    /// - Parameter group: Core Data Group entity
    /// - Returns: Count of item lists
    func getItemListsCount(for group: Group) async throws -> Int
    
    /// Get itemLists count for a specific user across all their groups
    /// - Parameter user: Core Data User entity
    /// - Returns: Count of item lists
    func getItemListsCount(for user: User) async throws -> Int

}

