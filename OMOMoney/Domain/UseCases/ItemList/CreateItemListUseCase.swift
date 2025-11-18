//
//  CreateItemListUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for creating a new item list
protocol CreateItemListUseCase {
    /// Execute the use case to create a new item list
    /// - Parameters:
    ///   - description: Item list description
    ///   - date: Date of the transaction
    ///   - categoryId: Associated category ID
    ///   - paymentMethodId: Associated payment method ID
    ///   - groupId: Associated group ID
    /// - Returns: Created ItemListDomain object
    /// - Throws: Repository or validation errors
    func execute(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain
}

/// Default implementation of CreateItemListUseCase
final class DefaultCreateItemListUseCase: CreateItemListUseCase {
    private let itemListRepository: ItemListRepository
    
    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }
    
    func execute(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain {
        // Add any business validation here if needed
        return try await itemListRepository.createItemList(
            description: description,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId
        )
    }
}
