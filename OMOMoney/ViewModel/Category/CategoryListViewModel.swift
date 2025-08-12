import Foundation
import CoreData

/// ViewModel for Category list functionality
/// Handles category list display and management
@MainActor
class CategoryListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    private let categoryService: CategoryService
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.categoryService = CategoryService(context: context)
    }
    
    // MARK: - Public Methods
    
    /// Load all categories
    func loadCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.fetchCategories()
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load categories for a specific group
    func loadCategories(for group: Group) async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.getCategories(for: group)
        } catch {
            errorMessage = "Error loading categories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Load default categories (system categories)
    func loadDefaultCategories() async {
        isLoading = true
        errorMessage = nil
        
        do {
            categories = try await categoryService.getDefaultCategories()
        } catch {
            errorMessage = "Error loading default categories: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Create a new category
    func createCategory(name: String, color: String? = nil, group: Group? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let newCategory = try await categoryService.createCategory(name: name, color: color, group: group)
            categories.append(newCategory)
            categories.sort { ($0.name ?? "") < ($1.name ?? "") }
            isLoading = false
            return true
        } catch {
            errorMessage = "Error creating category: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String? = nil, color: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await categoryService.updateCategory(category, name: name, color: color)
            isLoading = false
            return true
        } catch {
            errorMessage = "Error updating category: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Delete a category
    func deleteCategory(_ category: Category) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await categoryService.deleteCategory(category)
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
    func categoryExists(withName name: String, in group: Group? = nil, excluding categoryId: UUID? = nil) async -> Bool {
        do {
            return try await categoryService.categoryExists(withName: name, in: group, excluding: categoryId)
        } catch {
            errorMessage = "Error checking category name: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Get categories count
    func getCategoriesCount() async -> Int {
        do {
            return try await categoryService.getCategoriesCount()
        } catch {
            errorMessage = "Error getting categories count: \(error.localizedDescription)"
            return 0
        }
    }
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async -> Int {
        do {
            return try await categoryService.getCategoriesCount(for: group)
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
