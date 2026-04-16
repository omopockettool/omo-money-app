import Foundation
import SwiftData

final class DefaultItemListRepository: ItemListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItemLists() async throws -> [SDItemList] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDItemList>(
                sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    func fetchItemList(id: UUID) async throws -> SDItemList? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first
        }
    }

    func fetchItemLists(forGroupId groupId: UUID) async throws -> [SDItemList] {
        try await MainActor.run {
            let targetGroupId = groupId
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.group?.id == targetGroupId },
                sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [SDItemList] {
        try await MainActor.run {
            let targetCategoryId = categoryId
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.category?.id == targetCategoryId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    func fetchItemLists(from startDate: Date, to endDate: Date) async throws -> [SDItemList] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return try context.fetch(descriptor)
        }
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> SDItemList {
        try await MainActor.run {
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
    }

    func updateItemList(_ itemList: SDItemList) async throws {
        try await MainActor.run {
            itemList.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deleteItemList(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
            guard let itemList = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(itemList)
            try context.save()
        }
    }
}
