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
        
        // Perform fetch in background
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
            
            do {
                let fetchedCategories = try self.context.fetch(request)
                
                // Update UI on main thread
                Task { @MainActor in
                    self.categories = fetchedCategories
                    self.isLoading = false
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = "Failed to fetch categories: \(error.localizedDescription)"
                    print("Error fetching categories: \(error)")
                    self.isLoading = false
                }
            }
        }
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
        // This is a heavy calculation, should be done in background
        return categories.filter { $0.group?.id == group.id }
    }
    
    /// Get categories for a specific group asynchronously
    /// - Parameter group: The group to filter by
    /// - Parameter completion: Callback with the filtered categories
    func categories(for group: Group, completion: @escaping ([Category]) -> Void) {
        // Use Core Data context to perform filtering in background
        context.perform {
            guard let groupId = group.id else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "group.id == %@", groupId as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
            
            do {
                let filteredCategories = try self.context.fetch(request)
                DispatchQueue.main.async {
                    completion(filteredCategories)
                }
            } catch {
                print("Error fetching categories for group: \(error)")
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }
    }
    
    /// Get category by ID
    /// - Parameter id: The category ID to search for
    /// - Returns: The category if found, nil otherwise
    func category(with id: UUID) -> Category? {
        // This is a heavy calculation, should be done in background
        return categories.first { $0.id == id }
    }
    
    /// Get category by ID asynchronously
    /// - Parameter id: The category ID to search for
    /// - Parameter completion: Callback with the category if found
    func category(with id: UUID, completion: @escaping (Category?) -> Void) {
        // Use Core Data context to perform search in background
        context.perform {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            
            do {
                let foundCategory = try self.context.fetch(request).first
                DispatchQueue.main.async {
                    completion(foundCategory)
                }
            } catch {
                print("Error fetching category by ID: \(error)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /// Check if a category name already exists in a group
    /// - Parameters:
    ///   - name: The name to check
    ///   - group: The group to check in
    ///   - excludeCategory: Category to exclude from check (for updates)
    /// - Returns: True if name already exists
    func categoryNameExists(_ name: String, in group: Group, excluding excludeCategory: Category? = nil) -> Bool {
        // This is a heavy calculation, should be done in background
        return categories.contains { category in
            guard let categoryName = category.name else { return false }
            return category.group?.id == group.id &&
            categoryName.lowercased() == name.lowercased() &&
            category.id != excludeCategory?.id
        }
    }
    
    /// Check if a category name already exists in a group asynchronously
    /// - Parameters:
    ///   - name: The name to check
    ///   - group: The group to check in
    ///   - excludeCategory: Category to exclude from check (for updates)
    /// - Parameter completion: Callback with the result
    func categoryNameExists(_ name: String, in group: Group, excluding excludeCategory: Category? = nil, completion: @escaping (Bool) -> Void) {
        // Use Core Data context to perform check in background
        context.perform {
            guard let groupId = group.id else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            var predicateFormat = "group.id == %@ AND name ==[c] %@"
            var predicateArgs: [CVarArg] = [groupId as CVarArg, name as CVarArg]
            
            if let excludeCategory = excludeCategory, let excludeId = excludeCategory.id {
                predicateFormat += " AND id != %@"
                predicateArgs.append(excludeId as CVarArg)
            }
            
            request.predicate = NSPredicate(format: predicateFormat, argumentArray: predicateArgs)
            request.fetchLimit = 1
            
            do {
                let existingCategory = try self.context.fetch(request).first
                let exists = existingCategory != nil
                
                DispatchQueue.main.async {
                    completion(exists)
                }
            } catch {
                print("Error checking category name existence: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
