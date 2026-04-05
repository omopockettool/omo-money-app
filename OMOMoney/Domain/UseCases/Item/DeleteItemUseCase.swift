//
//  DeleteItemUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for deleting items
protocol DeleteItemUseCase {
    /// Execute the use case to delete an item by ID
    /// - Parameter id: Item UUID to delete
    /// - Throws: Repository errors
    func execute(id: UUID) async throws
}

final class DefaultDeleteItemUseCase: DeleteItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(id: UUID) async throws {
        // Business logic: Delete the item
        try await itemRepository.deleteItem(id: id)
    }
}
