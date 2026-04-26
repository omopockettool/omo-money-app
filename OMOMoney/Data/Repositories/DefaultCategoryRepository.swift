import Foundation
import SwiftData

@MainActor
final class DefaultCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCategory(id: UUID) async throws -> SDCategory? {
        let targetId = id
        let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
        return try context.fetch(descriptor).first
    }

    func fetchCategories(forGroupId groupId: UUID) async throws -> [SDCategory] {
        let targetGroupId = groupId
        let descriptor = FetchDescriptor<SDCategory>(
            predicate: #Predicate { $0.group?.id == targetGroupId },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func createCategory(
        name: String,
        color: String,
        icon: String,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> SDCategory {
        let category = SDCategory(
            name: name,
            color: color,
            icon: icon,
            limit: limit.map { Double(truncating: $0 as NSDecimalNumber) },
            limitFrequency: limitFrequency
        )
        if let groupId {
            let targetId = groupId
            let descriptor = FetchDescriptor<SDGroup>(predicate: #Predicate { $0.id == targetId })
            category.group = try context.fetch(descriptor).first
        }
        context.insert(category)
        try context.save()
        return category
    }

    func updateCategory(_ category: SDCategory) async throws {
        category.lastModifiedAt = Date()
        try context.save()
    }

    func deleteCategory(id: UUID) async throws {
        let targetId = id
        let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
        guard let category = try context.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        context.delete(category)
        try context.save()
    }
}
