import Foundation
import SwiftUI

@MainActor

@Observable
class CategoryListViewModel {

    // MARK: - Published Properties
    var categories: [SDCategory] = []
    var isLoading = false
    var errorMessage: String?
    var showError = false

    // MARK: - Use Cases
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let createCategoryUseCase: CreateCategoryUseCase
    private let updateCategoryUseCase: UpdateCategoryUseCase
    private let deleteCategoryUseCase: DeleteCategoryUseCase

    // MARK: - Initialization
    init(
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        createCategoryUseCase: CreateCategoryUseCase,
        updateCategoryUseCase: UpdateCategoryUseCase,
        deleteCategoryUseCase: DeleteCategoryUseCase
    ) {
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.createCategoryUseCase = createCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
        self.deleteCategoryUseCase = deleteCategoryUseCase
    }

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(
            fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase(),
            createCategoryUseCase: appContainer.makeCreateCategoryUseCase(),
            updateCategoryUseCase: appContainer.makeUpdateCategoryUseCase(),
            deleteCategoryUseCase: appContainer.makeDeleteCategoryUseCase()
        )
    }

    // MARK: - Public Methods

    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
            showError = true
        }

        isLoading = false
    }

    func createCategory(name: String, color: String? = nil, icon: String = "tag.fill", groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            let newCategory = try await createCategoryUseCase.execute(
                name: name,
                color: color,
                icon: icon,
                groupId: groupId,
                limit: nil,
                limitFrequency: nil
            )
            categories.append(newCategory)
            categories.sort { $0.name < $1.name }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating category: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return false
        }
    }

    func updateCategory(_ category: SDCategory, name: String? = nil, icon: String? = nil, color: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        showError = false

        do {
            try await updateCategoryUseCase.execute(
                categoryId: category.id,
                name: name,
                icon: icon,
                color: color,
                limit: nil,
                limitFrequency: nil
            )
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating category: \(error.localizedDescription)"
            showError = true
            isLoading = false
            return false
        }
    }

    func deleteCategory(_ category: SDCategory) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            categories.removeAll { $0.id == category.id }
        }
        Task {
            do {
                try await deleteCategoryUseCase.execute(categoryId: category.id)
            } catch {
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    categories.append(category)
                }
                errorMessage = "Error deleting category: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    func categoryExists(withName name: String, inGroupId groupId: UUID? = nil, excluding categoryId: UUID? = nil) async -> Bool {
        return false
    }

    func getCategoriesCount(forGroupId groupId: UUID) async -> Int {
        return categories.count
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
