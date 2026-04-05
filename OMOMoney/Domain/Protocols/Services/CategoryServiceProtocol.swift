import Foundation

/// Protocol for Category service operations
/// Enables dependency injection and testing
/// ✅ REFACTORED: Returns Domain models, accepts UUID parameters (Clean Architecture)
protocol CategoryServiceProtocol {

    // MARK: - Category CRUD Operations

    /// Get categories for a specific user across all their groups
    func getCategories(forUserId userId: UUID) async throws -> [CategoryDomain]

    /// Fetch category by ID
    func fetchCategory(by id: UUID) async throws -> CategoryDomain?

    /// Create a new category
    func createCategory(name: String, color: String?, icon: String, isDefault: Bool, groupId: UUID, limit: Decimal?, limitFrequency: String?) async throws -> CategoryDomain

    /// Update an existing category
    func updateCategory(categoryId: UUID, name: String?, color: String?, limit: Decimal?, limitFrequency: String?) async throws

    /// Delete a category
    func deleteCategory(categoryId: UUID) async throws

    /// Get categories for a specific group
    func getCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain]

    /// Check if category exists by name
    func categoryExists(withName name: String, inGroupId groupId: UUID?, excluding categoryId: UUID?) async throws -> Bool

    /// Get categories count for a specific group
    func getCategoriesCount(forGroupId groupId: UUID) async throws -> Int

    /// Get categories count for a specific user across all their groups
    func getCategoriesCount(forUserId userId: UUID) async throws -> Int

    // MARK: - Budget & Limit Operations

    /// Get spending for a category within the specified frequency period
    func getSpending(forCategoryId categoryId: UUID, in period: DateInterval) async throws -> Decimal

    /// Check if category is over limit for the current period
    func isOverLimit(categoryId: UUID, currentDate: Date) async throws -> Bool

    /// Get remaining budget for a category in the current period
    func getRemainingBudget(forCategoryId categoryId: UUID, currentDate: Date) async throws -> Decimal

    /// Get budget status (percentage used) for a category
    func getBudgetStatus(forCategoryId categoryId: UUID, currentDate: Date) async throws -> Double
}
