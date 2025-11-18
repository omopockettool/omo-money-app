//
//  UpdateItemListUseCase.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Use case protocol for updating an item list
protocol UpdateItemListUseCase {
    /// Execute the use case to update an item list
    /// - Parameter itemList: ItemListDomain object with updated values
    /// - Throws: Repository or validation errors
    func execute(_ itemList: ItemListDomain) async throws
}

final class DefaultUpdateItemListUseCase: UpdateItemListUseCase {
    private let itemListRepository: ItemListRepository
    
    init(itemListRepository: ItemListRepository) {
        self.itemListRepository = itemListRepository
    }
    
    func execute(_ itemList: ItemListDomain) async throws {
        try await itemListRepository.updateItemList(itemList)
    }
}
