import Foundation
import SwiftData

@MainActor
final class DefaultItemListRepository: ItemListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItemLists(forGroupId groupId: UUID) async throws -> [SDItemList] {
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDItemList>(
            predicate: #Predicate { $0.group?.id == targetGroupId },
            sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList {
        let itemList = SDItemList(itemListDescription: description, date: date)

        if let groupId {
            let targetId = groupId
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            itemList.group = try context.fetch(descriptor).first
        }
        if let categoryId {
            let targetId = categoryId
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
            itemList.category = try context.fetch(descriptor).first
        }
        if let paymentMethodId {
            let targetId = paymentMethodId
            let descriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetId })
            itemList.paymentMethod = try context.fetch(descriptor).first
        }

        context.insert(itemList)
        try context.save()
        return itemList
    }

    func updateItemList(_ itemList: SDItemList) async throws {
        itemList.lastModifiedAt = Date()
        try context.save()
    }

    func deleteItemList(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
        guard let itemList = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(itemList)
        try context.save()
    }
}
