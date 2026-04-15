import Foundation

/// ViewModel for Category picker functionality
/// ✅ CLEAN ARCHITECTURE: Uses Use Cases
@MainActor
final class CategoryPickerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var categories: [CategoryDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let fetchCategoriesUseCase: FetchCategoriesUseCase

    // MARK: - Initialization

    init(fetchCategoriesUseCase: FetchCategoriesUseCase) {
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
    }

    /// Convenience initializer using DI Container
    convenience init() {
        let appContainer = AppDIContainer.shared
        self.init(fetchCategoriesUseCase: appContainer.makeFetchCategoriesUseCase())
    }

    // MARK: - Public Methods

    /// Load categories for the specified group
    /// ✅ CLEAN ARCHITECTURE: Uses Use Case
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

    /// Clear any error messages
    func clearError() {
        errorMessage = nil
    }
}
