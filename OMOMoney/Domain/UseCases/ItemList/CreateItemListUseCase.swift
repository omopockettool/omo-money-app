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
        print("🎬 [USE CASE] CreateItemListUseCase.execute()")
        print("   📋 Input Parameters:")
        print("      - Description: \(description)")
        print("      - Date: \(date)")
        print("      - Category ID: \(categoryId?.uuidString ?? "nil")")
        print("      - Payment Method ID: \(paymentMethodId?.uuidString ?? "nil")")
        print("      - Group ID: \(groupId?.uuidString ?? "nil")")
        print("➡️ CreateItemListUseCase → ItemListRepository")

        // Add any business validation here if needed
        let itemListDomain = try await itemListRepository.createItemList(
            description: description,
            date: date,
            categoryId: categoryId,
            paymentMethodId: paymentMethodId,
            groupId: groupId
        )

        print("🔙 ItemListRepository → CreateItemListUseCase")
        print("   ✅ ItemListDomain received: ID = \(itemListDomain.id)")
        print("   📋 Domain Model Details:")
        print("      - Description: \(itemListDomain.itemListDescription)")
        print("      - Category ID: \(itemListDomain.categoryId?.uuidString ?? "nil")")
        print("      - Payment Method ID: \(itemListDomain.paymentMethodId?.uuidString ?? "nil")")
        print("      - Group ID: \(itemListDomain.groupId?.uuidString ?? "nil")")

        return itemListDomain
    }
}
