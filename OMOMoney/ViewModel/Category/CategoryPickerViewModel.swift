import Foundation
import CoreData

@MainActor
final class CategoryPickerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
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
    func loadCategories(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.getCategories(for: group)
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
