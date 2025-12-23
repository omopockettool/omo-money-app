import CoreData
import Foundation

/// ViewModel for Category list functionality
/// Handles category list display and management
/// ✅ REFACTORED: Works with Domain models and UUID parameters
@MainActor
class CategoryListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var categories: [CategoryDomain] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Services
    private let categoryService: CategoryService

    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.categoryService = CategoryService(context: context)
    }

    // MARK: - Public Methods

    /// Load categories for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func loadCategories(forGroupId groupId: UUID) async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await categoryService.getCategories(forGroupId: groupId)
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Create a new category
    /// ✅ REFACTORED: Accepts UUID parameter
    func createCategory(name: String, color: String? = nil, groupId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let newCategory = try await categoryService.createCategory(name: name, color: color, groupId: groupId, limit: nil, limitFrequency: nil)
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
    /// ✅ REFACTORED: Accepts Domain model
    func updateCategory(_ category: CategoryDomain, name: String? = nil, color: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await categoryService.updateCategory(categoryId: category.id, name: name, color: color, limit: nil, limitFrequency: nil)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating category: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    /// Delete a category
    /// ✅ REFACTORED: Accepts Domain model
    func deleteCategory(_ category: CategoryDomain) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await categoryService.deleteCategory(categoryId: category.id)
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
    /// ✅ REFACTORED: Accepts UUID parameter
    func categoryExists(withName name: String, inGroupId groupId: UUID? = nil, excluding categoryId: UUID? = nil) async -> Bool {
        do {
            return try await categoryService.categoryExists(withName: name, inGroupId: groupId, excluding: categoryId)
        } catch {
            errorMessage = "Error checking category name: \(error.localizedDescription)"
            return false
        }
    }

    /// Get categories count for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func getCategoriesCount(forGroupId groupId: UUID) async -> Int {
        do {
            return try await categoryService.getCategoriesCount(forGroupId: groupId)
        } catch {
            errorMessage = "Error getting categories count: \(error.localizedDescription)"
            return 0
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
