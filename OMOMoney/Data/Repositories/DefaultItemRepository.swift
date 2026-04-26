import Foundation
import SwiftData

final class DefaultItemRepository: ItemRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItems(forItemListId itemListId: UUID) async throws -> [SDItem] {
        try await MainActor.run {
            let targetId = itemListId
            let descriptor = FetchDescriptor<SDItem>(
                predicate: #Predicate { $0.itemList?.id == targetId },
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    func createItem(
        description: String,
        amount: Decimal,
        quantity: Int32,
        itemListId: UUID?,
        isPaid: Bool
    ) async throws -> SDItem {
        try await MainActor.run {
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
            context.insert(item)
            try context.save()
            return item
        }
    }

    func updateItem(_ item: SDItem) async throws {
        try await MainActor.run {
            item.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deleteItem(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
            guard let item = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(item)
            try context.save()
        }
    }

    func setAllItemsPaid(forItemListId itemListId: UUID, isPaid: Bool) async throws {
        try await MainActor.run {
            let targetId = itemListId
            let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.itemList?.id == targetId })
            let items = try context.fetch(descriptor)
            items.forEach { $0.isPaid = isPaid }
            try context.save()
        }
    }

    func toggleItemPaid(id: UUID, isPaid: Bool) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDItem>(predicate: #Predicate { $0.id == targetId })
            guard let item = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            item.isPaid = isPaid
            try context.save()
        }
    }
}
