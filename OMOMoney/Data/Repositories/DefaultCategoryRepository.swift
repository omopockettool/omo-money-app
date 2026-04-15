import Foundation
import SwiftData

final class DefaultCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCategories() async throws -> [CategoryDomain] {
        try await MainActor.run {
            let descriptor = FetchDescriptor<SDCategory>()
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func fetchCategory(id: UUID) async throws -> CategoryDomain? {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
            return try context.fetch(descriptor).first?.toDomain()
        }
    }

    func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
        try await MainActor.run {
            let targetGroupId = groupId
            let descriptor = FetchDescriptor<SDCategory>(
                predicate: #Predicate { $0.group?.id == targetGroupId },
                sortBy: [SortDescriptor(\.name)]
            )
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    func createCategory(
        name: String,
        color: String,
        icon: String,
        isDefault: Bool,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> CategoryDomain {
        try await MainActor.run {
            let category = SDCategory(
                name: name,
                color: color,
                icon: icon,
                isDefault: isDefault,
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
            return category.toDomain()
        }
    }

    func updateCategory(_ category: CategoryDomain) async throws {
        try await MainActor.run {
            let targetId = category.id
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
            guard let existing = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            existing.name = category.name
            existing.color = category.color
            existing.icon = category.icon
            existing.limit = category.limit.map { Double(truncating: $0 as NSDecimalNumber) }
            existing.limitFrequency = category.limitFrequency
            existing.lastModifiedAt = Date()
            try context.save()
        }
    }

    func deleteCategory(id: UUID) async throws {
        try await MainActor.run {
            let targetId = id
            let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == targetId })
            guard let category = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(category)
            try context.save()
        }
    }
}

// MARK: - Domain mapping
private extension SDCategory {
    func toDomain() -> CategoryDomain {
        CategoryDomain(
            id: id,
            name: name,
            color: color,
            icon: icon,
            isDefault: isDefault,
            limit: limit.map { Decimal($0) },
            limitFrequency: limitFrequency,
            groupId: group?.id,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}
