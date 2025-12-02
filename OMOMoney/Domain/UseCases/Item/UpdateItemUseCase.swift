//
//  UpdateItemUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for updating items
protocol UpdateItemUseCase {
    /// Execute the use case to update an existing item
    /// - Parameter item: ItemDomain object with updated values
    /// - Throws: Repository or validation errors
    func execute(_ item: ItemDomain) async throws
}

final class DefaultUpdateItemUseCase: UpdateItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(_ item: ItemDomain) async throws {
        // Business logic: Validate inputs
        let trimmedDescription = item.itemDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDescription.isEmpty else {
            throw ValidationError.invalidDescription
        }

        guard item.amount >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard item.quantity > 0 else {
            throw ValidationError.invalidQuantity
        }

        // Update the item
        try await itemRepository.updateItem(item)
    }
}
