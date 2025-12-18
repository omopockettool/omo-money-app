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
        print("🔶 [REPO-FETCH] ========================================")
        print("🔶 [REPO-FETCH] Repository fetching items for ItemList ID: \(itemListId.uuidString)")
        print("🔶 [REPO-FETCH] Fetching ItemList entity from Core Data...")

        // Fetch ItemList first on background thread
        let itemList = try await context.perform {
            let fetchRequest: NSFetchRequest<ItemList> = ItemList.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", itemListId as CVarArg)
            return try self.context.fetch(fetchRequest).first
        }

        guard let itemList = itemList else {
            print("❌ [REPO-FETCH] ERROR - ItemList not found")
            print("🔶 [REPO-FETCH] ========================================")
            throw RepositoryError.notFound
        }

        print("✅ [REPO-FETCH] ItemList found: '\(itemList.itemListDescription ?? "nil")'")
        print("🔶 [REPO-FETCH] Calling itemService.getItems()...")

        // Get items using service (already uses context.perform internally)
        let items = try await itemService.getItems(for: itemList)

        print("✅ [REPO-FETCH] Service returned \(items.count) Core Data items")
        print("🔶 [REPO-FETCH] Converting to Domain models...")

        let domainItems = items.map { $0.toDomain() }

        print("✅ [REPO-FETCH] Converted to \(domainItems.count) Domain models")
        print("🔶 [REPO-FETCH] ========================================")

        return domainItems
    }

    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?
    ) async throws -> ItemDomain {
        guard let itemListId = itemListId else {
            throw ValidationError.invalidItemList
        }

        // ✅ SIMPLE FIX: Pass itemListId directly - Service will fetch ItemList in its own context
        let item = try await itemService.createItem(
            description: description,
            amount: NSDecimalNumber(decimal: amount),
            quantity: quantity,
            itemListId: itemListId
        )

        return item.toDomain()
    }

    func updateItem(_ item: ItemDomain) async throws {
        // Fetch the Core Data item
        guard let coreDataItem = try await itemService.fetchItem(by: item.id) else {
            throw RepositoryError.notFound
        }

        // Update using service
        try await itemService.updateItem(
            coreDataItem,
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
}
