import Foundation

@MainActor
final class CategoryPickerViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var categories: [CategoryDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let categoryService: CategoryServiceProtocol

    // MARK: - Initialization

    init(categoryService: CategoryServiceProtocol) {
        self.categoryService = categoryService
    }

    // MARK: - Public Methods

    /// Load categories for the specified group
    /// ✅ REFACTORED: Accepts UUID parameter, returns Domain models
    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await categoryService.getCategories(forGroupId: groupId)
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
