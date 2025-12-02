//
//  CreateItemUseCase.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation

/// Use case protocol for creating items
protocol CreateItemUseCase {
    /// Execute the use case to create a new item
    /// - Parameters:
    ///   - description: Item description
    ///   - amount: Item amount
    ///   - quantity: Item quantity
    ///   - itemListId: Associated item list ID
    /// - Returns: Created ItemDomain object
    /// - Throws: Repository or validation errors
    func execute(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?
    ) async throws -> ItemDomain
}

final class DefaultCreateItemUseCase: CreateItemUseCase {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func execute(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?
    ) async throws -> ItemDomain {
        // Business logic: Validate inputs
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedDescription.isEmpty else {
            throw ValidationError.invalidDescription
        }

        guard amount >= 0 else {
            throw ValidationError.invalidAmount
        }

        guard quantity > 0 else {
            throw ValidationError.invalidQuantity
        }

        // Create the item
        return try await itemRepository.createItem(
            description: trimmedDescription,
            amount: amount,
            quantity: quantity,
            itemListId: itemListId
        )
    }
}
