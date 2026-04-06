//
//  UpdateCategoryUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for updating a category
protocol UpdateCategoryUseCase {
    /// Update an existing category with the specified details
    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws
}

final class DefaultUpdateCategoryUseCase: UpdateCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(
        categoryId: UUID,
        name: String?,
        icon: String?,
        color: String?,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws {
        // Fetch the existing category to get current values
        guard let existingCategory = try await categoryRepository.fetchCategory(id: categoryId) else {
            throw RepositoryError.notFound
        }

        // Create updated category with merged values
        let updatedCategory = CategoryDomain(
            id: existingCategory.id,
            name: name ?? existingCategory.name,
            color: color ?? existingCategory.color,
            icon: icon ?? existingCategory.icon,
            isDefault: existingCategory.isDefault,
            limit: limit ?? existingCategory.limit,
            limitFrequency: limitFrequency ?? existingCategory.limitFrequency,
            groupId: existingCategory.groupId,
            createdAt: existingCategory.createdAt,
            lastModifiedAt: Date()
        )

        try await categoryRepository.updateCategory(updatedCategory)
    }
}
