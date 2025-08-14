import Foundation
import CoreData

/// Protocol for Category service operations
/// Enables dependency injection and testing
protocol CategoryServiceProtocol {
    
    // MARK: - Category CRUD Operations
    
    /// Fetch all categories
    func fetchCategories() async throws -> [Category]
    
    /// Fetch category by ID
    func fetchCategory(by id: UUID) async throws -> Category?
    
    /// Create a new category
    func createCategory(name: String, color: String?, group: Group) async throws -> Category
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String?, color: String?) async throws
    
    /// Delete a category
    func deleteCategory(_ category: Category) async throws
    
    /// Get categories for a specific group
    func getCategories(for group: Group) async throws -> [Category]
    
    /// Check if category exists by name
    func categoryExists(withName name: String, in group: Group?, excluding categoryId: UUID?) async throws -> Bool
    
    /// Get categories count
    func getCategoriesCount() async throws -> Int
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async throws -> Int
}
