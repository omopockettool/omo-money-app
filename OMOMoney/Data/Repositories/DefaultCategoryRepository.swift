//
//  DefaultCategoryRepository.swift
//  OMOMoney
//
//  Created on 12/18/25.
//

import Foundation
import CoreData

final class DefaultCategoryRepository: CategoryRepository {
    private let categoryService: CategoryServiceProtocol
    private let context: NSManagedObjectContext

    init(categoryService: CategoryServiceProtocol, context: NSManagedObjectContext) {
        self.categoryService = categoryService
        self.context = context
    }

    func fetchCategories() async throws -> [CategoryDomain] {
        // Fetch all categories from Core Data on background thread
        let categories = try await context.perform {
            let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
            return try self.context.fetch(fetchRequest)
        }
        return categories.map { $0.toDomain() }
    }

    func fetchCategory(id: UUID) async throws -> CategoryDomain? {
        guard let category = try await categoryService.fetchCategory(by: id) else { return nil }
        return category.toDomain()
    }

    func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
        // ✅ Fetch the Group from Core Data on background thread
        let group = try await context.perform {
            let fetchRequest: NSFetchRequest<Group> = Group.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            fetchRequest.fetchLimit = 1
            return try self.context.fetch(fetchRequest).first
        }

        guard let group = group else {
            throw RepositoryError.notFound
        }

        // Get categories using service (already uses context.perform internally)
        let categories = try await categoryService.getCategories(for: group)
        return categories.map { $0.toDomain() }
    }

    func createCategory(
        name: String,
        color: String,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> CategoryDomain {
        guard let groupId = groupId else {
            throw NSError(domain: "DefaultCategoryRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "groupId is required"])
        }

        // ✅ Use service with groupId (proper Core Data context handling)
        let category = try await categoryService.createCategory(
            name: name,
            color: color,
            groupId: groupId,
            limit: limit,
            limitFrequency: limitFrequency
        )

        return category.toDomain()
    }

    func updateCategory(_ categoryDomain: CategoryDomain) async throws {
        // Fetch the Core Data Category entity
        guard let category = try await categoryService.fetchCategory(by: categoryDomain.id) else {
            throw RepositoryError.notFound
        }

        // Update using service
        try await categoryService.updateCategory(
            category,
            name: categoryDomain.name,
            color: categoryDomain.color,
            limit: categoryDomain.limit,
            limitFrequency: categoryDomain.limitFrequency
        )
    }

    func deleteCategory(id: UUID) async throws {
        // Fetch the Core Data Category entity
        guard let category = try await categoryService.fetchCategory(by: id) else {
            throw RepositoryError.notFound
        }

        // Delete using service
        try await categoryService.deleteCategory(category)
    }
}