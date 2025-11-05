import CoreData
import Foundation

/// Service class for Category entity operations
/// Handles all CRUD operations for Category with proper threading and caching
class CategoryService: CoreDataService, CategoryServiceProtocol {
    
    // MARK: - Cache Keys
    enum CacheKeys {
        static let groupCategories = "CategoryService.groupCategories"
        static let userCategories = "CategoryService.userCategories"
        static let categoryExists = "CategoryService.categoryExists"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - Category CRUD Operations
    
    /// Get categories for a specific user across all their groups with caching
    func getCategories(for user: User) async throws -> [Category] {
        let cacheKey = "\(CacheKeys.userCategories).\(user.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedCategories: [Category] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedCategories
        }
        
        // Fetch from Core Data through UserGroup relationship
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        let categories = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(categories, for: cacheKey)
        
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
    func createCategory(name: String, color: String?, group: Group, limit: Decimal? = nil, limitFrequency: String? = nil) async throws -> Category {
        let category = try await context.perform {
            let category = Category(context: self.context)
            category.id = UUID()
            category.name = name
            category.color = color ?? "#007AFF"
            category.group = group
            category.createdAt = Date()
            
            // Set budget limit and frequency if provided
            if let limit = limit {
                category.limit = NSDecimalNumber(decimal: limit)
            }
            if let limitFrequency = limitFrequency {
                category.limitFrequency = limitFrequency
            }
            
            try self.context.save()
            return category
        }
        
        // Invalidate relevant cache itemLists - only for the specific group
        let groupCacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"
        print("🧹 CategoryService: Invalidating cache after creating category '\(name)'")
        print("🧹 CategoryService: Group cache key: \(groupCacheKey)")
        await CacheManager.shared.clearDataCache(for: groupCacheKey)
        
        // For user categories, we need to clear for all users in this group
        // This is more complex, so for now we keep the broad invalidation
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
        print("✅ CategoryService: Cache invalidated successfully")
        
        return category
    }
    
    /// Update an existing category
    func updateCategory(_ category: Category, name: String? = nil, color: String? = nil, limit: Decimal? = nil, limitFrequency: String? = nil) async throws {
        try await context.perform {
            if let name = name {
                category.name = name
            }
            if let color = color {
                category.color = color
            }
            if let limit = limit {
                category.limit = NSDecimalNumber(decimal: limit)
            }
            if let limitFrequency = limitFrequency {
                category.limitFrequency = limitFrequency
            }
            category.lastModifiedAt = Date()
            
            try self.context.save()
        }
        
        // Invalidate relevant cache itemLists - only for the specific group
        if let group = category.group {
            let groupCacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"
            await CacheManager.shared.clearDataCache(for: groupCacheKey)
        }
        
        // For user categories, we need to clear for all users in this group
        // This is more complex, so for now we keep the broad invalidation
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }
    
    /// Delete a category
    func deleteCategory(_ category: Category) async throws {
        // Get the group before deleting the category
        let group = category.group
        
        await delete(category)
        try await save()
        
        // Invalidate relevant cache itemLists - only for the specific group
        if let group = group {
            let groupCacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"
            await CacheManager.shared.clearDataCache(for: groupCacheKey)
        }
        
        // For user categories, we need to clear for all users in this group
        // This is more complex, so for now we keep the broad invalidation
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }
    
    /// Get categories for a specific group with caching
    func getCategories(for group: Group) async throws -> [Category] {
        let cacheKey = "\(CacheKeys.groupCategories).\(group.id?.uuidString ?? "nil")"
        
        print("🔍 CategoryService: Getting categories for group '\(group.name ?? "Unknown")'")
        print("🔍 CategoryService: Cache key: \(cacheKey)")
        
        // Check cache first
        if let cachedCategories: [Category] = await CacheManager.shared.getCachedData(for: cacheKey) {
            print("🟢 CategoryService: ✅ Categories found in CACHE (\(cachedCategories.count) items)")
            return cachedCategories
        }
        
        print("🔄 CategoryService: Cache miss - fetching from Core Data...")
        
        // Fetch from Core Data
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        let categories = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(categories, for: cacheKey)
        print("🟡 CategoryService: ✅ Categories fetched from DATABASE and cached (\(categories.count) items)")
        
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
        
        let results = try await fetch(request)
        let exists = !results.isEmpty
        
        // Cache the result
        await CacheManager.shared.cacheValidation(exists, for: cacheKey)
        
        return exists
    }
    
    /// Get categories count for a specific group
    func getCategoriesCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
    
    /// Get categories count for a specific user across all their groups
    func getCategoriesCount(for user: User) async throws -> Int {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
        return try await count(request)
    }
    
    // MARK: - Budget & Limit Operations
    
    /// Get spending for a category within the specified frequency period
    func getSpending(for category: Category, in period: DateInterval) async throws -> Decimal {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        request.predicate = NSPredicate(
            format: "itemList.category == %@ AND itemList.date >= %@ AND itemList.date <= %@",
            category,
            period.start as NSDate,
            period.end as NSDate
        )
        
        let items = try await fetch(request)
        return items.reduce(0) { total, item in
            let itemAmount = (item.amount ?? NSDecimalNumber.zero).decimalValue
            let quantity = Decimal(item.quantity)
            return total + (itemAmount * quantity)
        }
    }
    
    /// Check if category is over limit for the current period
    func isOverLimit(_ category: Category, currentDate: Date = Date()) async throws -> Bool {
        guard let limit = category.limit, limit.decimalValue > 0 else { return false }
        
        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(for: category, in: period)
        
        return spending > limit.decimalValue
    }
    
    /// Get remaining budget for a category in the current period
    func getRemainingBudget(for category: Category, currentDate: Date = Date()) async throws -> Decimal {
        guard let limit = category.limit, limit.decimalValue > 0 else { return 0 }
        
        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(for: category, in: period)
        
        return max(0, limit.decimalValue - spending)
    }
    
    /// Get budget status (percentage used) for a category
    func getBudgetStatus(for category: Category, currentDate: Date = Date()) async throws -> Double {
        guard let limit = category.limit, limit.decimalValue > 0 else { return 0.0 }
        
        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(for: category, in: period)
        
        let limitDouble = Double(truncating: limit as NSNumber)
        guard limitDouble > 0 else { return 0.0 }
        let percentage = Double(truncating: spending as NSNumber) / limitDouble
        return min(1.0, max(0.0, percentage)) // Clamp between 0 and 1
    }
    
    // MARK: - Private Helper Methods
    
    /// Get the budget period based on frequency
    private func getBudgetPeriod(for frequency: String?, currentDate: Date) -> DateInterval {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        
        switch frequency?.lowercased() {
        case "daily":
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            return DateInterval(start: startOfDay, end: endOfDay)
            
        case "weekly":
            if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: currentDate) {
                return weekInterval
            }
            // Fallback to monthly if week calculation fails
            fallthrough
            
        case "yearly":
            if let yearInterval = calendar.dateInterval(of: .year, for: currentDate) {
                return yearInterval
            }
            // Fallback to monthly if year calculation fails
            fallthrough
            
        default: // "monthly" or any invalid frequency
            if let monthInterval = calendar.dateInterval(of: .month, for: currentDate) {
                return monthInterval
            }
            // Ultimate fallback to current day
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            return DateInterval(start: startOfDay, end: endOfDay)
        }
    }
    
    /// Invalidate category-related caches
    private func invalidateCache(for category: Category) async {
        let userId = (category.group?.userGroups?.allObjects as? [UserGroup])?.first?.user?.id?.uuidString ?? "nil"
        let groupId = category.group?.id?.uuidString ?? "nil"
        
        await CacheManager.shared.clearDataCache(for: "\(CacheKeys.userCategories).\(userId)")
        await CacheManager.shared.clearDataCache(for: "\(CacheKeys.groupCategories).\(groupId)")
    }
}
