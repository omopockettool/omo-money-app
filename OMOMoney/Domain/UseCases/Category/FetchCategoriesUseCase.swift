//
//  FetchCategoriesUseCase.swift
//  OMOMoney
//
//  Created on 12/18/25.
//

import Foundation

/// Use case protocol for fetching categories
protocol FetchCategoriesUseCase {
    /// Fetch all categories
    func execute() async throws -> [CategoryDomain]
    /// Fetch a single category by ID
    func execute(categoryId: UUID) async throws -> CategoryDomain?
    /// Fetch categories for a specific group
    func execute(forGroupId groupId: UUID) async throws -> [CategoryDomain]
}

final class DefaultFetchCategoriesUseCase: FetchCategoriesUseCase {
    private let categoryRepository: CategoryRepository

    init(categoryRepository: CategoryRepository) {
        self.categoryRepository = categoryRepository
    }

    func execute() async throws -> [CategoryDomain] {
        return try await categoryRepository.fetchCategories()
    }

    func execute(categoryId: UUID) async throws -> CategoryDomain? {
        return try await categoryRepository.fetchCategory(id: categoryId)
    }

    func execute(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
        return try await categoryRepository.fetchCategories(forGroupId: groupId)
    }
}