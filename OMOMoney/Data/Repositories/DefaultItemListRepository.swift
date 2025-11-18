//
//  DefaultItemListRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

final class DefaultItemListRepository: ItemListRepository {
    private let itemListService: ItemListServiceProtocol
    
    init(itemListService: ItemListServiceProtocol) {
        self.itemListService = itemListService
    }
    
    func fetchItemLists() async throws -> [ItemListDomain] {
        // This implementation assumes you want all item lists for all groups or users.
        // You may want to adjust this logic based on your app's needs.
        // For now, we'll throw a fatalError to force explicit usage.
        fatalError("fetchItemLists() is not implemented. Use fetchItemLists(forGroupId:) or fetchItemLists(forCategoryId:) or implement as needed.")
    }
    
    func fetchItemList(id: UUID) async throws -> ItemListDomain? {
        guard let itemList = try await itemListService.fetchItemList(by: id) else { return nil }
        return itemList.toDomain()
    }
    
    func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
        // You need to fetch the Group object by groupId. This requires a context or a service method.
        // For now, we'll throw a fatalError to force explicit usage.
        fatalError("fetchItemLists(forGroupId:) requires fetching Group by ID. Use getItemLists(for:) with a Group instance.")
    }
    
    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [ItemListDomain] {
        // You need to fetch the Category object by categoryId. This requires a context or a service method.
        // For now, we'll throw a fatalError to force explicit usage.
        fatalError("fetchItemLists(forCategoryId:) requires fetching Category by ID. Use getItemLists(for:) with a Category instance.")
    }
    
    func fetchItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain] {
        let itemLists = try await itemListService.getItemLists(from: startDate, to: endDate)
        return itemLists.map { $0.toDomain() }
    }
    
    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain {
        // The protocol expects non-optional values, so we need to handle nils.
        guard let categoryId = categoryId, let groupId = groupId else {
            throw NSError(domain: "DefaultItemListRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "categoryId and groupId are required"])
        }
        let itemList = try await itemListService.createItemList(
            description: description,
            date: date,
            categoryId: categoryId,
            groupId: groupId,
            paymentMethodId: paymentMethodId
        )
        return itemList.toDomain()
    }
    
    func updateItemList(_ itemList: ItemListDomain) async throws {
        // You need to fetch the ItemList object and update it. This requires a context or a service method.
        fatalError("updateItemList(_:) requires mapping ItemListDomain to ItemList. Implement as needed.")
    }
    
    func deleteItemList(id: UUID) async throws {
        // You need to fetch the ItemList object by id. This requires a context or a service method.
        fatalError("deleteItemList(id:) requires fetching ItemList by ID. Implement as needed.")
    }
    
    func bulkInsertItemLists(_ itemLists: [ItemListDomain]) async throws -> [ItemListDomain] {
        fatalError("bulkInsertItemLists(_:) not implemented. Add to ItemListServiceProtocol and implementation.")
    }
}
