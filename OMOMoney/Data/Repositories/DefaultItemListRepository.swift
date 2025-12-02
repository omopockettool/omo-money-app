//
//  DefaultItemListRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation
import CoreData

final class DefaultItemListRepository: ItemListRepository {
    private let itemListService: ItemListServiceProtocol
    private let context: NSManagedObjectContext

    init(itemListService: ItemListServiceProtocol, context: NSManagedObjectContext) {
        self.itemListService = itemListService
        self.context = context
    }
    
    func fetchItemLists() async throws -> [ItemListDomain] {
        // Fetch all ItemLists from Core Data
        let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        let itemLists = try context.fetch(fetchRequest)
        return itemLists.map { $0.toDomain() }
    }
    
    func fetchItemList(id: UUID) async throws -> ItemListDomain? {
        guard let itemList = try await itemListService.fetchItemList(by: id) else { return nil }
        return itemList.toDomain()
    }
    
    func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
        // Fetch the Group from Core Data
        let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)

        guard let group = try context.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        // Get item lists using service
        let itemLists = try await itemListService.getItemLists(for: group)
        return itemLists.map { $0.toDomain() }
    }
    
    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [ItemListDomain] {
        // Fetch ItemLists by category from Core Data
        let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category.id == %@", categoryId as CVarArg)
        let itemLists = try context.fetch(fetchRequest)
        return itemLists.map { $0.toDomain() }
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
        // Fetch the Core Data ItemList entity
        let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", itemList.id as CVarArg)

        guard let coreDataItemList = try context.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        // Update the entity
        coreDataItemList.itemListDescription = itemList.itemListDescription
        coreDataItemList.date = itemList.date
        coreDataItemList.lastModifiedAt = Date()

        // Save context
        try context.save()
    }
    
    func deleteItemList(id: UUID) async throws {
        // Fetch the ItemList from Core Data
        let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let itemList = try context.fetch(fetchRequest).first else {
            throw RepositoryError.notFound
        }

        // Delete using service
        try await itemListService.deleteItemList(itemList)
    }
    
    func bulkInsertItemLists(_ itemLists: [ItemListDomain]) async throws -> [ItemListDomain] {
        fatalError("bulkInsertItemLists(_:) not implemented. Add to ItemListServiceProtocol and implementation.")
    }
}
