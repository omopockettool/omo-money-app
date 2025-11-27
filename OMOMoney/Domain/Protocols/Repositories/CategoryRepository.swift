//
//  CategoryRepository.swift
//  OMOMoney
//
//  Created on 11/18/25.
//

import Foundation

/// Repository protocol for Category domain operations
/// Abstracts the data source implementation from business logic
protocol CategoryRepository {
    /// Fetch all categories
    /// - Returns: Array of CategoryDomain objects
    /// - Throws: Repository errors
    func fetchCategories() async throws -> [CategoryDomain]
    
    /// Fetch a specific category by ID
    /// - Parameter id: Category UUID
    /// - Returns: CategoryDomain object if found
    /// - Throws: Repository errors
    func fetchCategory(id: UUID) async throws -> CategoryDomain?
    
    /// Fetch categories for a specific group
    /// - Parameter groupId: Group UUID
    /// - Returns: Array of CategoryDomain objects
    /// - Throws: Repository errors
    func fetchCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain]
    
    /// Create a new category
    /// - Parameters:
    ///   - name: Category name
    ///   - color: Color hex string
    ///   - limit: Optional spending limit
    ///   - limitFrequency: Frequency of limit (monthly, weekly, etc.)
    ///   - groupId: Associated group ID
    /// - Returns: Created CategoryDomain object
    /// - Throws: Repository errors or validation errors
    func createCategory(
        name: String,
        color: String,
        limit: Decimal?,
        limitFrequency: String,
        groupId: UUID?
    ) async throws -> CategoryDomain
    
    /// Update an existing category
    /// - Parameter category: CategoryDomain object with updated values
    /// - Throws: Repository errors
    func updateCategory(_ category: CategoryDomain) async throws
    
    /// Delete a category by ID
    /// - Parameter id: Category UUID to delete
    /// - Throws: Repository errors
    func deleteCategory(id: UUID) async throws
}
