import Foundation

@MainActor

@Observable
class CategoryListViewModel {

    // MARK: - Published Properties
    var categories: [SDCategory] = []
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

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
        }

        isLoading = false
    }

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

    func updateCategory(_ category: SDCategory, name: String? = nil, icon: String? = nil, color: String? = nil) async -> Bool {
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

    func deleteCategory(_ category: SDCategory) async -> Bool {
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

    func categoryExists(withName name: String, inGroupId groupId: UUID? = nil, excluding categoryId: UUID? = nil) async -> Bool {
        return false
    }

    func getCategoriesCount(forGroupId groupId: UUID) async -> Int {
        return categories.count
    }

    func clearError() {
        errorMessage = nil
    }
}
