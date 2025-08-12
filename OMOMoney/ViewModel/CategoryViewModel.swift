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
        
        // Store group ID for background operation
        guard let groupId = group.id else { return nil }
        
        // Perform creation in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch group in background context
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            
            do {
                let backgroundGroup = try self.context.fetch(groupRequest).first
                if let backgroundGroup = backgroundGroup {
                    let newCategory = Category(context: self.context)
                    newCategory.id = UUID()
                    newCategory.name = name
                    newCategory.color = color
                    newCategory.group = backgroundGroup
                    newCategory.createdAt = Date()
                    newCategory.lastModifiedAt = Date()
                    
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchCategories()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to create category: \(error.localizedDescription)"
                    print("Error creating category: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return nil // Will be updated via async callback
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
        
        // Store category ID for background operation
        guard let categoryId = category.id else { return false }
        
        // Perform update in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch category in background context
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            
            do {
                let backgroundCategory = try self.context.fetch(request).first
                if let backgroundCategory = backgroundCategory {
                    if let name = name {
                        backgroundCategory.name = name
                    }
                    
                    if let color = color {
                        backgroundCategory.color = color
                    }
                    
                    backgroundCategory.lastModifiedAt = Date()
                    
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchCategories()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to update category: \(error.localizedDescription)"
                    print("Error updating category: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
    }
    
    /// Delete a category
    /// - Parameter category: The category to delete
    /// - Returns: True if deletion was successful
    func deleteCategory(_ category: Category) -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Store category ID for background operation
        guard let categoryId = category.id else { return false }
        
        // Perform deletion in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch category in background context
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            
            do {
                let backgroundCategory = try self.context.fetch(request).first
                if let backgroundCategory = backgroundCategory {
                    self.context.delete(backgroundCategory)
                    try self.context.save()
                    
                    // Update UI on main thread
                    Task { @MainActor in
                        self.fetchCategories()
                        self.isLoading = false
                    }
                }
            } catch {
                Task { @MainActor in
                    self.context.rollback()
                    self.errorMessage = "Failed to delete category: \(error.localizedDescription)"
                    print("Error deleting category: \(error)")
                    self.isLoading = false
                }
            }
        }
        
        return true
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
