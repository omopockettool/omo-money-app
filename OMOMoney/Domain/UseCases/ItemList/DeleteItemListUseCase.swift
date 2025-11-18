//
//  DeleteItemListUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for deleting an item list
protocol DeleteItemListUseCase {
    /// Execute the use case to delete an item list by ID
    /// - Parameter id: ItemList UUID to delete
    /// - Throws: Repository or validation errors
    func execute(id: UUID) async throws
}

final class DefaultDeleteItemListUseCase: DeleteItemListUseCase {
    private let itemListRepository: ItemListRepository
    
    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }
    
    func execute(id: UUID) async throws {
        try await itemListRepository.deleteItemList(id: id)
    }
}
