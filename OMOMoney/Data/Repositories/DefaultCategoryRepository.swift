//
//  DefaultCategoryRepository.swift
//  OMOMoney
//
//  Created on 12/18/25.
//  ✅ REFACTORED: Thin wrapper - Service returns Domain models directly
//

import Foundation

final class DefaultCategoryRepository: CategoryRepository {
    private let categoryService: CategoryServiceProtocol

    init(categoryService: CategoryServiceProtocol) {
        self.categoryService = categoryService
    }

    func fetchCategories() async throws -> [CategoryDomain] {
        // TODO: Need a CategoryService method to fetch all categories
        // For now, this will need to be updated when we add that method
        throw RepositoryError.notFound
    }

    func fetchCategory(id: UUID) async throws -> CategoryDomain? {
        // Simple passthrough - Service returns Domain model directly
        return try await categoryService.fetchCategory(by: id)
    }

    func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
        // Simple passthrough - Service returns Domain models directly
        return try await categoryService.getCategories(forGroupId: groupId)
    }

    func createCategory(
        name: String,
        color: String,
        icon: String,
        isDefault: Bool,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> CategoryDomain {
        guard let groupId = groupId else {
            throw NSError(domain: "DefaultCategoryRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "groupId is required"])
        }

        // Simple passthrough - Service returns Domain model directly
        return try await categoryService.createCategory(
            name: name,
            color: color,
            icon: icon,
            isDefault: isDefault,
            groupId: groupId,
            limit: limit,
            limitFrequency: limitFrequency
        )
    }

    func updateCategory(_ categoryDomain: CategoryDomain) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await categoryService.updateCategory(
            categoryId: categoryDomain.id,
            name: categoryDomain.name,
            icon: categoryDomain.icon,
            color: categoryDomain.color,
            limit: categoryDomain.limit,
            limitFrequency: categoryDomain.limitFrequency
        )
    }

    func deleteCategory(id: UUID) async throws {
        // Simple passthrough - Service accepts UUID parameter
        try await categoryService.deleteCategory(categoryId: id)
    }
}