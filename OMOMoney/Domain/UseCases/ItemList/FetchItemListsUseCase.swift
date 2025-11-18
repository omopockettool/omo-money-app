//
//  FetchItemListsUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for fetching item lists
protocol FetchItemListsUseCase {
    /// Fetch all item lists
    func execute() async throws -> [ItemListDomain]
    /// Fetch item lists for a specific group
    func execute(forGroupId groupId: UUID) async throws -> [ItemListDomain]
    /// Fetch item lists for a specific category
    func execute(forCategoryId categoryId: UUID) async throws -> [ItemListDomain]
    /// Fetch item lists within a date range
    func execute(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain]
}

final class DefaultFetchItemListsUseCase: FetchItemListsUseCase {
    private let itemListRepository: ItemListRepository
    
    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }
    
    func execute() async throws -> [ItemListDomain] {
        return try await itemListRepository.fetchItemLists()
    }
    
    func execute(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
        return try await itemListRepository.fetchItemLists(forGroupId: groupId)
    }
    
    func execute(forCategoryId categoryId: UUID) async throws -> [ItemListDomain] {
        return try await itemListRepository.fetchItemLists(forCategoryId: categoryId)
    }
    
    func execute(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain] {
        return try await itemListRepository.fetchItemLists(from: startDate, to: endDate)
    }
}
