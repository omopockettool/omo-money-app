//
//  ItemListRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for ItemList (Entry/Transaction) domain operations
/// Abstracts the data source implementation from business logic
protocol ItemListRepository {
    /// Fetch all item lists
    /// - Returns: Array of ItemListDomain objects
    /// - Throws: Repository errors
    func fetchItemLists() async throws -> [ItemListDomain]
    
    /// Fetch a specific item list by ID
    /// - Parameter id: ItemList UUID
    /// - Returns: ItemListDomain object if found
    /// - Throws: Repository errors
    func fetchItemList(id: UUID) async throws -> ItemListDomain?
    
    /// Fetch item lists for a specific group
    /// - Parameter groupId: Group UUID
    /// - Returns: Array of ItemListDomain objects
    /// - Throws: Repository errors
    func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain]
    
    /// Fetch item lists for a specific category
    /// - Parameter categoryId: Category UUID
    /// - Returns: Array of ItemListDomain objects
    /// - Throws: Repository errors
    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [ItemListDomain]
    
    /// Fetch item lists within a date range
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    /// - Returns: Array of ItemListDomain objects
    /// - Throws: Repository errors
    func fetchItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain]
    
    /// Create a new item list
    /// - Parameters:
    ///   - description: Item list description
    ///   - date: Date of the transaction
    ///   - categoryId: Associated category ID
    ///   - paymentMethodId: Associated payment method ID
    ///   - groupId: Associated group ID
    /// - Returns: Created ItemListDomain object
    /// - Throws: Repository errors
    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain
    
    /// Update an existing item list
    /// - Parameter itemList: ItemListDomain object with updated values
    /// - Throws: Repository errors
    func updateItemList(_ itemList: ItemListDomain) async throws
    
    /// Delete an item list by ID
    /// - Parameter id: ItemList UUID to delete
    /// - Throws: Repository errors
    func deleteItemList(id: UUID) async throws
}
