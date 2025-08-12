import Foundation
import CoreData

/// Service class for Category entity operations
/// Handles all CRUD operations for Category with proper threading
@MainActor
class CategoryService: CoreDataService {
    
    // MARK: - Category CRUD Operations
    
    /// Fetch all categories
    func fetchCategories() async throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return try await fetch(request)
    }
    
    /// Fetch category by ID
    func fetchCategory(by id: UUID) async throws -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new category
    func createCategory(name: String, color: String? = nil, group: Group? = nil) async throws -> Category {
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                let category = Category(context: self.context)
                category.id = UUID()
                category.name = name
                category.color = color ?? "#007AFF"
                category.group = group
                category.createdAt = Date()
                
                do {
                    try self.context.save()
                    continuation.resume(returning: category)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String? = nil, color: String? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                if let name = name {
                    category.name = name
                }
                if let color = color {
                    category.color = color
                }
                category.lastModifiedAt = Date()
                
                do {
                    try self.context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Delete a category
    func deleteCategory(_ category: Category) async throws {
        try await delete(category)
        try await save()
    }
    
    /// Get categories for a specific group
    func getCategories(for group: Group) async throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return try await fetch(request)
    }
    
    /// Check if category exists by name
    func categoryExists(withName name: String, in group: Group? = nil, excluding categoryId: UUID? = nil) async throws -> Bool {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        
        var predicates: [NSPredicate] = [NSPredicate(format: "name == %@", name)]
        
        if let group = group {
            predicates.append(NSPredicate(format: "group == %@", group))
        }
        
        if let categoryId = categoryId {
            predicates.append(NSPredicate(format: "id != %@", categoryId as CVarArg))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        let count = try await count(request)
        return count > 0
    }
    
    /// Get categories count
    func getCategoriesCount() async throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        return try await count(request)
    }
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
    
    /// Get default categories (system categories)
    func getDefaultCategories() async throws -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        return try await fetch(request)
    }
}
