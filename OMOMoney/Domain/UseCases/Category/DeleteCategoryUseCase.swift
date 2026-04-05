//
//  DeleteCategoryUseCase.swift
//  OMOMoney
//
//  Created on 12/23/25.
//

import Foundation

/// Use case protocol for deleting a category
protocol DeleteCategoryUseCase {
    /// Delete a category by its ID
    func execute(categoryId: UUID) async throws
}

final class DefaultDeleteCategoryUseCase: DeleteCategoryUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute(categoryId: UUID) async throws {
        try await categoryRepository.deleteCategory(id: categoryId)
    }
}
