import Foundation

protocol CreateCategoryUseCase {
    func execute(
        name: String,
        color: String?,
        icon: String,
        groupId: UUID,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws -> SDCategory
}

final class DefaultCreateCategoryUseCase: CreateCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(
        name: String,
        color: String?,
        icon: String = "tag.fill",
        groupId: UUID,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws -> SDCategory {
        return try await categoryRepository.createCategory(
            name: name,
            color: color ?? "#CCCCCC",
            icon: icon,
            limit: limit,
            limitFrequency: limitFrequency ?? "monthly",
            groupId: groupId
        )
    }
}
