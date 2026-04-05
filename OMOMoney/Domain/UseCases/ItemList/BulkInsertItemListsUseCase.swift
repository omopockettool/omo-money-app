//
//  BulkInsertItemListsUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for bulk inserting item lists
protocol BulkInsertItemListsUseCase {
    /// Execute the use case to insert multiple item lists efficiently
    /// - Parameter itemLists: Array of ItemListDomain objects to insert
    /// - Returns: Array of inserted ItemListDomain objects
    /// - Throws: Repository or validation errors
    func execute(_ itemLists: [ItemListDomain]) async throws -> [ItemListDomain]
}

final class DefaultBulkInsertItemListsUseCase: BulkInsertItemListsUseCase {
    private let itemListRepository: ItemListRepository
    
    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }
    
    func execute(_ itemLists: [ItemListDomain]) async throws -> [ItemListDomain] {
        return try await itemListRepository.bulkInsertItemLists(itemLists)
    }
}
