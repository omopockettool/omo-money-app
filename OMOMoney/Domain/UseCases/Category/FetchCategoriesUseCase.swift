import Foundation

protocol FetchCategoriesUseCase {
    func execute(forGroupId groupId: UUID) async throws -> [SDCategory]
}

final class DefaultFetchCategoriesUseCase: FetchCategoriesUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(forGroupId groupId: UUID) async throws -> [SDCategory] {
        return try await categoryRepository.fetchCategories(forGroupId: groupId)
    }
}
