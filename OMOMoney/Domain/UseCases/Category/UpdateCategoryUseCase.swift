import Foundation

protocol UpdateCategoryUseCase {
    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws
}

final class DefaultUpdateCategoryUseCase: UpdateCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws {
        guard let category = try await categoryRepository.fetchCategory(id: categoryId) else {
            throw RepositoryError.notFound
        }
        if let name { category.name = name }
        if let icon { category.icon = icon }
        if let color { category.color = color }
        if let limit { category.limit = Double(truncating: limit as NSDecimalNumber) }
        if let limitFrequency { category.limitFrequency = limitFrequency }
        try await categoryRepository.updateCategory(category)
    }
}
