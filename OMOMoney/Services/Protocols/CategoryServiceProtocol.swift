import CoreData
import Foundation

/// Protocol for Category service operations
/// Enables dependency injection and testing
protocol CategoryServiceProtocol {
    
    // MARK: - Category CRUD Operations
    
    /// Get categories for a specific user across all their groups
    func getCategories(for user: User) async throws -> [Category]
    
    /// Fetch category by ID
    func fetchCategory(by id: UUID) async throws -> Category?
    
    /// Create a new category
    func createCategory(name: String, color: String?, group: Group, limit: Decimal?, limitFrequency: String?) async throws -> Category
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String?, color: String?, limit: Decimal?, limitFrequency: String?) async throws
    
    /// Delete a category
    func deleteCategory(_ category: Category) async throws
    
    /// Get categories for a specific group
    func getCategories(for group: Group) async throws -> [Category]
    
    /// Check if category exists by name
    func categoryExists(withName name: String, in group: Group?, excluding categoryId: UUID?) async throws -> Bool
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async throws -> Int
    
    /// Get categories count for a specific user across all their groups
    func getCategoriesCount(for user: User) async throws -> Int
    
    // MARK: - Budget & Limit Operations
    
    /// Get spending for a category within the specified frequency period
    func getSpending(for category: Category, in period: DateInterval) async throws -> Decimal
    
    /// Check if category is over limit for the current period
    func isOverLimit(_ category: Category, currentDate: Date) async throws -> Bool
    
    /// Get remaining budget for a category in the current period
    func getRemainingBudget(for category: Category, currentDate: Date) async throws -> Decimal
    
    /// Get budget status (percentage used) for a category
    func getBudgetStatus(for category: Category, currentDate: Date) async throws -> Double
}
