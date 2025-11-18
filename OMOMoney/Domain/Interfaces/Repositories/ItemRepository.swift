//
//  ItemRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for Item domain operations
/// Abstracts the data source implementation from business logic
protocol ItemRepository {
    /// Fetch all items
    /// - Returns: Array of ItemDomain objects
    /// - Throws: Repository errors
    func fetchItems() async throws -> [ItemDomain]
    
    /// Fetch a specific item by ID
    /// - Parameter id: Item UUID
    /// - Returns: ItemDomain object if found
    /// - Throws: Repository errors
    func fetchItem(id: UUID) async throws -> ItemDomain?
    
    /// Fetch items for a specific item list
    /// - Parameter itemListId: ItemList UUID
    /// - Returns: Array of ItemDomain objects
    /// - Throws: Repository errors
    func fetchItems(forItemListId itemListId: UUID) async throws -> [ItemDomain]
    
    /// Create a new item
    /// - Parameters:
    ///   - description: Item description
    ///   - amount: Item amount
    ///   - quantity: Item quantity
    ///   - itemListId: Associated item list ID
    /// - Returns: Created ItemDomain object
    /// - Throws: Repository errors or validation errors
    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?
    ) async throws -> ItemDomain
    
    /// Update an existing item
    /// - Parameter item: ItemDomain object with updated values
    /// - Throws: Repository errors
    func updateItem(_ item: ItemDomain) async throws
    
    /// Delete an item by ID
    /// - Parameter id: Item UUID to delete
    /// - Throws: Repository errors
    func deleteItem(id: UUID) async throws
}
