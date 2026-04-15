import Foundation
import SwiftData

final class DefaultItemListRepository: ItemListRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchItemLists() async throws -> [ItemListDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDItemList>(
                sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchItemList(id: UUID) async throws -> ItemListDomain? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first?.toDomain()
        }
    }

    func fetchItemLists(forGroupId groupId: UUID) async throws -> [ItemListDomain] {
        try await MainActor.run {
            let targetGroupId = groupId
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.group?.id == targetGroupId },
                sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchItemLists(forCategoryId categoryId: UUID) async throws -> [ItemListDomain] {
        try await MainActor.run {
            let targetCategoryId = categoryId
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.category?.id == targetCategoryId },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchItemLists(from startDate: Date, to endDate: Date) async throws -> [ItemListDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDItemList>(
                predicate: #Predicate { $0.date >= startDate && $0.date <= endDate },
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func createItemList(
        description: String,
        date: Date,
        categoryId: UUID?,
        paymentMethodId: UUID?,
        groupId: UUID?
    ) async throws -> ItemListDomain {
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
            return itemList.toDomain()
        }
    }

    func updateItemList(_ itemList: ItemListDomain) async throws {
        try await MainActor.run {
            let targetId = itemList.id
            let descriptor = FetchDescriptor<SDItemList>(predicate: #Predicate { $0.id == targetId })
            guard let existing = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            existing.itemListDescription = itemList.itemListDescription
            existing.date = itemList.date
            existing.lastModifiedAt = Date()

            if let categoryId = itemList.categoryId {
                let catId = categoryId
                let catDescriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == catId })
                existing.category = try context.fetch(catDescriptor).first
            }
            if let pmId = itemList.paymentMethodId {
                let targetPmId = pmId
                let pmDescriptor = FetchDescriptor<SDPaymentMethod>(predicate: #Predicate { $0.id == targetPmId })
                existing.paymentMethod = try context.fetch(pmDescriptor).first
            } else {
                existing.paymentMethod = nil
            }

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

// MARK: - Domain mapping
private extension SDItemList {
    func toDomain() -> ItemListDomain {
        ItemListDomain(
            id: id,
            itemListDescription: itemListDescription,
            date: date,
            categoryId: category?.id,
            paymentMethodId: paymentMethod?.id,
            groupId: group?.id,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
