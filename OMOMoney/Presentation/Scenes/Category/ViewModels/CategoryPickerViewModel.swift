import Foundation

@MainActor

@Observable
final class CategoryPickerViewModel {

    // MARK: - Published Properties
    var categories: [SDCategory] = []
    var isLoading = false
    var errorMessage: String?

    // MARK: - Dependencies
    private let fetchCategoriesUseCase: FetchCategoriesUseCase

    // MARK: - Initialization

    init(fetchCategoriesUseCase: FetchCategoriesUseCase) {
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
    }

    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase())
    }

    // MARK: - Public Methods

    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
        } catch {
            errorMessage = "Error al cargar categorías: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func clearError() {
        errorMessage = nil
    }
}
