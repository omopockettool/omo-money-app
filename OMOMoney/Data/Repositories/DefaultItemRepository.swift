//
//  DefaultItemRepository.swift
//  OMOMoney
//
//  Created on 11/29/25.
//

import Foundation
import CoreData

final class DefaultItemRepository: ItemRepository {
    private let itemService: ItemServiceProtocol
    private let context: NSManagedObjectContext

    init(itemService: ItemServiceProtocol, context: NSManagedObjectContext) {
        self.itemService = itemService
        self.context = context
    }

    func fetchItems() async throws -> [ItemDomain] {
        // Fetch all items from the service
        // Since there's no service method for this, we'll throw for now
        fatalError("fetchItems() not implemented - use fetchItems(forItemListId:) instead")
    }

    func fetchItem(id: UUID) async throws -> ItemDomain? {
        guard let item = try await itemService.fetchItem(by: id) else {
            return nil
        }
        return item.toDomain()
    }

    func fetchItems(forItemListId itemListId: UUID) async throws -> [ItemDomain] {
        let itemList = try await context.perform {
            let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", itemListId as CVarArg)
            fetchRequest.fetchLimit = 1
            guard let itemList = try self.context.fetch(fetchRequest).first else {
                throw RepositoryError.notFound
            }
            return itemList
        }
        // Service handles caching and domain conversion
        return try await itemService.getItems(for: itemList)
    }

    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool = false
    ) async throws -> ItemDomain {
        guard let itemListId = itemListId else {
            throw ValidationError.invalidItemList
        }

        let item = try await itemService.createItem(
            description: description,
            amount: NSDecimalNumber(decimal: amount),
            quantity: quantity,
            itemListId: itemListId,
            isPaid: isPaid
        )

        return item.toDomain()
    }

    func updateItem(_ item: ItemDomain) async throws {
        // ✅ CRITICAL FIX: Pass UUID instead of Core Data object to avoid thread boundary issues
        // The service will fetch the item inside its own context.perform block
        try await itemService.updateItem(
            itemId: item.id,
            description: item.itemDescription,
            amount: NSDecimalNumber(decimal: item.amount),
            quantity: item.quantity
        )
    }

    func deleteItem(id: UUID) async throws {
        // Fetch the Core Data item
        guard let item = try await itemService.fetchItem(by: id) else {
            throw RepositoryError.notFound
        }

        // Delete using service
        try await itemService.deleteItem(item)
    }

    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws {
        try await itemService.setAllItemsPaid(forItemListId: itemListId, isPaid: isPaid)
    }

    func toggleItemPaid(id: UUID, isPaid: Bool) async throws {
        try await itemService.toggleItemPaid(itemId: id, isPaid: isPaid)
    }
}
