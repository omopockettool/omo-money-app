//
//  CategoryViewModel.swift
//  OMOMoney
//
//  Created by Dennis Chicaiza A on 11/8/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class CategoryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Published array of categories for SwiftUI binding
    @Published var categories: [Category] = []
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error message for user feedback
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    /// Initialize with a managed object context
    /// - Parameter context: The Core Data context to use for operations
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchCategories()
    }
    
    // MARK: - CRUD Operations
    
    /// Fetch all categories from Core Data
    func fetchCategories() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            categories = try context.fetch(request)
        } catch {
            errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
            print("Error fetching categories: \(error)")
        }
        
        isLoading = false
    }
    
    /// Create a new category
    /// - Parameters:
    ///   - name: The category name
    ///   - color: The category color in hex format
    ///   - group: The group this category belongs to
    /// - Returns: The created category or nil if failed
    func createCategory(name: String, color: String = "#8E8E93", group: Group) -> Category? {
        isLoading = true
        errorMessage = nil
        
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.color = color
        newCategory.group = group
        newCategory.createdAt = Date()
        newCategory.lastModifiedAt = Date()
        
        do {
            try context.save()
            fetchCategories() // Refresh the list
            isLoading = false
            return newCategory
        } catch {
            context.rollback()
            errorMessage = "Failed to create category: \(error.localizedDescription)"
            print("Error creating category: \(error)")
            isLoading = false
            return nil
        }
    }
    
    /// Update an existing category
    /// - Parameters:
    ///   - category: The category to update
    ///   - name: New name (optional)
    ///   - color: New color (optional)
    /// - Returns: True if update was successful
    func updateCategory(_ category: Category, name: String? = nil, color: String? = nil) -> Bool {
        isLoading = true
        errorMessage = nil
        
        if let name = name {
            category.name = name
        }
        
        if let color = color {
            category.color = color
        }
        
        category.lastModifiedAt = Date()
        
        do {
            try context.save()
            fetchCategories() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to update category: \(error.localizedDescription)"
            print("Error updating category: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete a category
    /// - Parameter category: The category to delete
    /// - Returns: True if deletion was successful
    func deleteCategory(_ category: Category) -> Bool {
        isLoading = true
        errorMessage = nil
        
        context.delete(category)
        
        do {
            try context.save()
            fetchCategories() // Refresh the list
            isLoading = false
            return true
        } catch {
            context.rollback()
            errorMessage = "Failed to delete category: \(error.localizedDescription)"
            print("Error deleting category: \(error)")
            isLoading = false
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get categories for a specific group
    /// - Parameter group: The group to filter by
    /// - Returns: Array of categories in the group
    func categories(for group: Group) -> [Category] {
        return categories.filter { $0.group?.id == group.id }
    }
    
    /// Get category by ID
    /// - Parameter id: The category ID to search for
    /// - Returns: The category if found, nil otherwise
    func category(with id: UUID) -> Category? {
        return categories.first { $0.id == id }
    }
    
    /// Check if a category name already exists in a group
    /// - Parameters:
    ///   - name: The name to check
    ///   - group: The group to check in
    ///   - excludeCategory: Category to exclude from check (for updates)
    /// - Returns: True if name already exists
    func categoryNameExists(_ name: String, in group: Group, excluding excludeCategory: Category? = nil) -> Bool {
        return categories.contains { category in
            guard let categoryName = category.name else { return false }
            return category.group?.id == group.id &&
            categoryName.lowercased() == name.lowercased() &&
            category.id != excludeCategory?.id
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
