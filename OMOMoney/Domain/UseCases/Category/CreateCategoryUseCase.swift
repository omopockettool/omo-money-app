//
//  CreateCategoryUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for creating a category
protocol CreateCategoryUseCase {
    /// Create a new category with the specified details
    func execute(
        name: String,
        color: String?,
        icon: String,
        isDefault: Bool,
        groupId: UUID,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws -> CategoryDomain
}

final class DefaultCreateCategoryUseCase: CreateCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(
        name: String,
        color: String?,
        icon: String = "tag.fill",
        isDefault: Bool = false,
        groupId: UUID,
        limit: Decimal?,
        limitFrequency: String?
    ) async throws -> CategoryDomain {
        return try await categoryRepository.createCategory(
            name: name,
            color: color ?? "#CCCCCC",
            icon: icon,
            isDefault: isDefault,
            limit: limit,
            limitFrequency: limitFrequency ?? "monthly",
            groupId: groupId
        )
    }
}
