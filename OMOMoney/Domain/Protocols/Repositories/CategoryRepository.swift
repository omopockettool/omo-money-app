import Foundation

protocol CategoryRepository {
    func fetchCategories() async throws -> [SDCategory]
    func fetchCategory(id: UUID) async throws -> SDCategory?
    func fetchCategories(forGroupId groupId: UUID) async throws -> [SDCategory]
    func createCategory(
        name: String,
        color: String,
        icon: String,
        isDefault: Bool,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> SDCategory
    func updateCategory(_ category: SDCategory) async throws
    func deleteCategory(id: UUID) async throws
}
