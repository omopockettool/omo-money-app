import Foundation

protocol CreateCategoryUseCase {
    func execute(
        name: String,
        color: String?,
        icon: String,
        isDefault: Bool,
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
        isDefault: Bool = false,
        groupId: UUID,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws -> SDCategory {
        return try await categoryRepository.createCategory(
            name: name,
            color: color ?? "#CCCCCC",
            icon: icon,
            isDefault: isDefault,
            limit: limit,
            limitFrequency: limitFrequency ?? "monthly",
            groupId: groupId
        )
    }
}
