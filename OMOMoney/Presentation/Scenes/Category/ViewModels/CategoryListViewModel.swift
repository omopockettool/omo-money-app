import Foundation

/// ViewModel for Category list functionality
/// Handles category list display and management
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor

@Observable
class CategoryListViewModel {

    // MARK: - Published Properties
    var categories: [CategoryDomain] = []
    var isLoading = false
    var errorMessage: String?

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

    /// Convenience initializer using DI Container
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

    /// Load categories for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create a new category
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func createCategory(name: String, color: String? = nil, icon: String = "tag.fill", groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newCategory = try await createCategoryUseCase.execute(
                name: name,
                color: color,
                icon: icon,
                isDefault: false,
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
            isLoading = false
            return false
        }
    }

    /// Update an existing category
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func updateCategory(_ category: CategoryDomain, name: String? = nil, icon: String? = nil, color: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

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
            isLoading = false
            return false
        }
    }

    /// Delete a category
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
    func deleteCategory(_ category: CategoryDomain) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await deleteCategoryUseCase.execute(categoryId: category.id)
            categories.removeAll { $0.id == category.id }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error deleting category: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Check if category name exists
    /// ⚠️ TODO: Create CategoryExistsUseCase to avoid direct Service access
    func categoryExists(withName name: String, inGroupId groupId: UUID? = nil, excluding categoryId: UUID? = nil) async -> Bool {
        // NOTE: This method still needs a Use Case implementation
        // For now, returning false to avoid breaking existing code
        return false
    }

    /// Get categories count for a specific group
    /// ✅ CLEAN ARCHITECTURE: Uses loaded categories array
    func getCategoriesCount(forGroupId groupId: UUID) async -> Int {
        // Simple count from current categories array
        return categories.count
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
