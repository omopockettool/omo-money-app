//
//  FetchItemsUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for fetching items
protocol FetchItemsUseCase {
    /// Fetch all items
    func execute() async throws -> [ItemDomain]
    /// Fetch a specific item by ID
    func execute(itemId: UUID) async throws -> ItemDomain?
    /// Fetch items for a specific item list
    func execute(forItemListId itemListId: UUID) async throws -> [ItemDomain]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute() async throws -> [ItemDomain] {
        return try await itemRepository.fetchItems()
    }

    func execute(itemId: UUID) async throws -> ItemDomain? {
        return try await itemRepository.fetchItem(id: itemId)
    }

    func execute(forItemListId itemListId: UUID) async throws -> [ItemDomain] {
        return try await itemRepository.fetchItems(forItemListId: itemListId)
    }
}
