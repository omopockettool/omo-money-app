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
        // Fetch all ItemLists from Core Data on background thread
        let itemLists = try await context.perform {
            let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            return try self.context.fetch(fetchRequest)
        }
        return itemLists.map { $0.toDomain() }
    }
    
    func fetchItemList(id: UUID) async throws -> ItemListDomain? {
        guard let itemList = try await itemListService.fetchItemList(by: id) else { return nil }
        return itemList.toDomain()
    }
    
    func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
        // Fetch the Group from Core Data on background thread
        let group = try await context.perform {
            let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            return try self.context.fetch(fetchRequest).first
        }

        guard let group = group else {
            throw RepositoryError.notFound
        }

        // Get item lists using service — already returns [ItemListDomain]
        return try await itemListService.getItemLists(for: group)
    }
    
    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [ItemListDomain] {
        // Fetch ItemLists by category from Core Data on background thread
        let itemLists = try await context.perform {
            let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category.id == %@", categoryId as CVarArg)
            return try self.context.fetch(fetchRequest)
        }
        return itemLists.map { $0.toDomain() }
    }
    
    func fetchItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain] {
        return try await itemListService.getItemLists(from: startDate, to: endDate)
    }
    
    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain {
        print("🎬 [REPOSITORY] DefaultItemListRepository.createItemList()")
        print("   📋 Input Parameters:")
        print("      - Description: \(description)")
        print("      - Date: \(date)")
        print("      - Category ID: \(categoryId?.uuidString ?? "nil")")
        print("      - Payment Method ID: \(paymentMethodId?.uuidString ?? "nil")")
        print("      - Group ID: \(groupId?.uuidString ?? "nil")")

        // The protocol expects non-optional values, so we need to handle nils.
        guard let categoryId = categoryId, let groupId = groupId else {
            print("❌ [REPOSITORY] Validation failed: categoryId and groupId are required")
            throw NSError(domain: "DefaultItemListRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "categoryId and groupId are required"])
        }

        print("✅ [REPOSITORY] Validation passed: categoryId and groupId present")
        print("➡️ DefaultItemListRepository → ItemListService")

        let itemList = try await itemListService.createItemList(
            description: description,
            date: date,
            categoryId: categoryId,
            groupId: groupId,
            paymentMethodId: paymentMethodId
        )

        print("🔙 ItemListService → DefaultItemListRepository")
        print("   ✅ ItemList Core Data entity received: ID = \(itemList.id?.uuidString ?? "nil")")
        print("🔄 [REPOSITORY] Converting Core Data entity → Domain model (.toDomain())")

        let domainModel = itemList.toDomain()

        print("✅ [REPOSITORY] Conversion complete")
        print("   📋 Domain Model:")
        print("      - ID: \(domainModel.id)")
        print("      - Description: \(domainModel.itemListDescription)")
        print("      - Category ID: \(domainModel.categoryId?.uuidString ?? "nil")")
        print("      - Payment Method ID: \(domainModel.paymentMethodId?.uuidString ?? "nil")")
        print("      - Group ID: \(domainModel.groupId?.uuidString ?? "nil")")

        return domainModel
    }
    
    func updateItemList(_ itemList: ItemListDomain) async throws {
        guard let coreDataItemList = try await itemListService.fetchItemList(by: itemList.id) else {
            throw RepositoryError.notFound
        }
        guard let categoryId = itemList.categoryId else {
            throw RepositoryError.invalidData
        }
        // Route through service: handles category/paymentMethod fields + cache invalidation
        try await itemListService.updateItemList(
            coreDataItemList,
            description: itemList.itemListDescription,
            date: itemList.date,
            categoryId: categoryId,
            paymentMethodId: itemList.paymentMethodId
        )
    }
    
    func deleteItemList(id: UUID) async throws {
        // Fetch the ItemList from Core Data on background thread
        let itemList = try await context.perform {
            let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self.context.fetch(fetchRequest).first
        }

        guard let itemList = itemList else {
            throw RepositoryError.notFound
        }

        // Delete using service (already uses context.perform internally)
        try await itemListService.deleteItemList(itemList)
    }
    
}
