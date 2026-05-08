import Foundation
import SwiftData

@MainActor
final class DefaultItemRepository: ItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItems(forItemListId itemListId: UUID) async throws -> [SDItem] {
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItem>(
            predicate: #Predicate { $0.itemList?.id == targetId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem {
        guard let itemListId else { throw ValidationError.invalidItemList }

        let item = SDItem(
            itemDescription: description,
            amount: Double(truncating: amount as NSDecimalNumber),
            quantity: Int(quantity),
            isPaid: isPaid
        )
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
        item.itemList = try context.fetch(descriptor).first
        item.itemList?.lastModifiedAt = Date()
        context.insert(item)
        try context.save()
        return item
    }

    func updateItem(_ item: SDItem) async throws {
        let modifiedAt = Date()
        item.lastModifiedAt = modifiedAt
        item.itemList?.lastModifiedAt = modifiedAt
        try context.save()
    }

    func deleteItem(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
        guard let item = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        item.itemList?.lastModifiedAt = Date()
        context.delete(item)
        try context.save()
    }

    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws {
        let targetId = itemListId
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.itemList?.id == targetId })
        let items = try context.fetch(descriptor)
        let modifiedAt = Date()
        items.forEach {
            $0.isPaid = isPaid
            $0.lastModifiedAt = modifiedAt
            $0.itemList?.lastModifiedAt = modifiedAt
        }
        try context.save()
    }

    func toggleItemPaid(id: UUID, isPaid: Bool) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
        guard let item = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        let modifiedAt = Date()
        item.isPaid = isPaid
        item.lastModifiedAt = modifiedAt
        item.itemList?.lastModifiedAt = modifiedAt
        try context.save()
    }
}
