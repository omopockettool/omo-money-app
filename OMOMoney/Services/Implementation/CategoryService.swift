import Foundation
import CoreData

/// Service class for Category entity operations
/// Handles all CRUD operations for Category with proper threading and caching
class CategoryService: CoreDataService, CategoryServiceProtocol {
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let allCategories = "CategoryService.allCategories"
        static let groupCategories = "CategoryService.groupCategories"
        static let categoryCount = "CategoryService.categoryCount"
        static let categoryExists = "CategoryService.categoryExists"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Category CRUD Operations
    
    /// Fetch all categories with caching
    func fetchCategories() async throws -> [Category] {
        // Check cache first
        if let cachedCategories: [Category] = await CacheManager.shared.getCachedData(for: CacheKeys.allCategories) {
            return cachedCategories
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        let categories = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(categories, for: CacheKeys.allCategories)
        
        return categories
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
    func createCategory(name: String, color: String?, group: Group) async throws -> Category {
        let category = try await context.perform {
            let category = Category(context: self.context)
            category.id = UUID()
            category.name = name
            category.color = color ?? "#007AFF"
            category.group = group
            category.createdAt = Date()
            
            try self.context.save()
            return category
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allCategories)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupCategories)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
        
        return category
    }
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String? = nil, color: String? = nil) async throws {
        try await context.perform {
            if let name = name {
                category.name = name
            }
            if let color = color {
                category.color = color
            }
            category.lastModifiedAt = Date()
            
            try self.context.save()
        }
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allCategories)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }
    
    /// Delete a category
    func deleteCategory(_ category: Category) async throws {
        await delete(category)
        try await save()
        
        // Invalidate relevant cache entries
        await CacheManager.shared.clearDataCache(for: CacheKeys.allCategories)
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupCategories)
        await CacheManager.shared.clearDataCache(for: CacheKeys.categoryCount)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }
    
    /// Get categories for a specific group with caching
    func getCategories(for group: Group) async throws -> [Category] {
        let cacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedCategories: [Category] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedCategories
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        let categories = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(categories, for: cacheKey)
        
        return categories
    }
    
    /// Check if category exists by name with caching
    func categoryExists(withName name: String, in group: Group? = nil, excluding categoryId: UUID? = nil) async throws -> Bool {
        let groupId = group?.id?.uuidString ?? "nil"
        let categoryIdStr = categoryId?.uuidString ?? "nil"
        let cacheKey = "\(CacheKeys.categoryExists).\(name).\(groupId).\(categoryIdStr)"
        
        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }
        
        // Check in Core Data
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
        let exists = count > 0
        
        // Cache the result
        await CacheManager.shared.cacheValidation(exists, for: cacheKey)
        
        return exists
    }
    
    /// Get categories count with caching
    func getCategoriesCount() async throws -> Int {
        // Check cache first
        if let cachedCount: Int = await CacheManager.shared.getCachedData(for: CacheKeys.categoryCount) {
            return cachedCount
        }
        
        // Get from Core Data
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        let count = try await count(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(count, for: CacheKeys.categoryCount)
        
        return count
    }
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
}
