import Foundation

protocol FetchCategoriesUseCase {
    func execute() async throws -> [SDCategory]
    func execute(categoryId: UUID) async throws -> SDCategory?
    func execute(forGroupId groupId: UUID) async throws -> [SDCategory]
}

final class DefaultFetchCategoriesUseCase: FetchCategoriesUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute() async throws -> [SDCategory] {
        return try await categoryRepository.fetchCategories()
    }

    func execute(categoryId: UUID) async throws -> SDCategory? {
        return try await categoryRepository.fetchCategory(id: categoryId)
    }

    func execute(forGroupId groupId: UUID) async throws -> [SDCategory] {
        return try await categoryRepository.fetchCategories(forGroupId: groupId)
    }
}
