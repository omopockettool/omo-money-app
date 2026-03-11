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
    /// ✅ REFACTORED: Returns Domain models, accepts UUID parameter
    func getCategories(forUserId userId: UUID) async throws -> [CategoryDomain] {
        let cacheKey = "\(CacheKeys.userCategories).\(userId.uuidString)"

        // Check cache first (cache Domain models)
        if let cachedCategories: [CategoryDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedCategories
        }

        // Fetch from Core Data and convert to Domain inside context.perform
        let categoryDomains = try await context.perform {
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            guard let user = try self.context.fetch(userRequest).first else {
                throw RepositoryError.notFound
            }

            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
            request.returnsObjectsAsFaults = false

            let categories = try self.context.fetch(request)

            // Convert to Domain INSIDE context.perform
            return categories.map { $0.toDomain() }
        }

        // Cache Domain models
        await CacheManager.shared.cacheData(categoryDomains, for: cacheKey)

        return categoryDomains
    }

    /// Fetch category by ID
    /// ✅ REFACTORED: Returns Domain model
    func fetchCategory(by id: UUID) async throws -> CategoryDomain? {
        return try await context.perform {
            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false

            guard let category = try self.context.fetch(request).first else {
                return nil
            }

            // Convert to Domain INSIDE context.perform
            return category.toDomain()
        }
    }
    
    /// Create a new category
    /// ✅ REFACTORED: Returns Domain model
    func createCategory(name: String, color: String?, icon: String = "tag.fill", isDefault: Bool = false, groupId: UUID, limit: Decimal? = nil, limitFrequency: String? = nil) async throws -> CategoryDomain {
        let categoryDomain = try await context.perform {
            let category = Category(context: self.context)
            category.id = UUID()
            category.name = name
            category.color = color ?? "#007AFF"
            category.icon = icon
            category.isDefault = isDefault
            category.createdAt = Date()

            // Set budget limit and frequency if provided
            if let limit = limit {
                category.limit = NSDecimalNumber(decimal: limit)
            }
            if let limitFrequency = limitFrequency {
                category.limitFrequency = limitFrequency
            }

            // Fetch group fresh from Core Data inside context.perform
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            let group = try self.context.fetch(groupRequest).first
            if let group = group {
                category.group = group
            }

            try self.context.save()

            // Convert to Domain INSIDE context.perform
            return category.toDomain()
        }

        print("💾 CategoryService: Category '\(name)' saved to Core Data successfully")

        // Invalidate relevant cache itemLists - only for the specific group
        let groupCacheKey = "\(CacheKeys.groupCategories).\(groupId.uuidString)"
        print("🧹 CategoryService: Invalidating cache after creating category '\(name)'")
        print("🧹 CategoryService: Group cache key: \(groupCacheKey)")
        await CacheManager.shared.clearDataCache(for: groupCacheKey)

        // For user categories, we need to clear for all users in this group
        // This is more complex, so for now we keep the broad invalidation
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
        print("✅ CategoryService: Cache invalidated successfully")

        return categoryDomain
    }
    
    /// Update an existing category
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func updateCategory(categoryId: UUID, name: String? = nil, color: String? = nil, limit: Decimal? = nil, limitFrequency: String? = nil) async throws {
        let groupId = try await context.perform {
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            categoryRequest.fetchLimit = 1

            guard let category = try self.context.fetch(categoryRequest).first else {
                throw RepositoryError.notFound
            }

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

            return category.group?.id
        }

        // Invalidate relevant cache itemLists - only for the specific group
        if let groupId = groupId {
            let groupCacheKey = "\(CacheKeys.groupCategories).\(groupId.uuidString)"
            await CacheManager.shared.clearDataCache(for: groupCacheKey)
        }

        // For user categories, we need to clear for all users in this group
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }

    /// Delete a category
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func deleteCategory(categoryId: UUID) async throws {
        let groupId = try await context.perform {
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            categoryRequest.fetchLimit = 1

            guard let category = try self.context.fetch(categoryRequest).first else {
                throw RepositoryError.notFound
            }

            let groupId = category.group?.id

            self.context.delete(category)
            try self.context.save()

            return groupId
        }

        // Invalidate relevant cache itemLists - only for the specific group
        if let groupId = groupId {
            let groupCacheKey = "\(CacheKeys.groupCategories).\(groupId.uuidString)"
            await CacheManager.shared.clearDataCache(for: groupCacheKey)
        }

        // For user categories, we need to clear for all users in this group
        await CacheManager.shared.clearDataCache(for: CacheKeys.userCategories)
        await CacheManager.shared.clearValidationCache(for: CacheKeys.categoryExists)
    }
    
    /// Get categories for a specific group with caching
    /// ✅ REFACTORED: Returns Domain models, accepts UUID parameter
    func getCategories(forGroupId groupId: UUID) async throws -> [CategoryDomain] {
        let cacheKey = "\(CacheKeys.groupCategories).\(groupId.uuidString)"

        print("🔍 CategoryService: Getting categories for groupId '\(groupId.uuidString)'")
        print("🔍 CategoryService: Cache key: \(cacheKey)")

        // Check cache first (cache Domain models)
        if let cachedCategories: [CategoryDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            print("🟢 CategoryService: ✅ Categories found in CACHE (\(cachedCategories.count) items)")
            return cachedCategories
        }

        print("🔄 CategoryService: Cache miss - fetching from Core Data...")

        // Fetch from Core Data and convert to Domain inside context.perform
        let categoryDomains = try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                throw RepositoryError.notFound
            }

            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "group == %@", group)
            categoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
            categoryRequest.returnsObjectsAsFaults = false

            let categories = try self.context.fetch(categoryRequest)

            // Convert to Domain INSIDE context.perform
            return categories.map { $0.toDomain() }
        }

        // ✅ DEBUG: Log category details
        print("🟡 CategoryService: ✅ Categories fetched from DATABASE and cached (\(categoryDomains.count) items)")
        if categoryDomains.isEmpty {
            print("⚠️ CategoryService: WARNING - No categories found in Core Data for groupId '\(groupId.uuidString)'")
        } else {
            print("📋 CategoryService: Category names: \(categoryDomains.map { $0.name })")
        }

        // Cache Domain models
        await CacheManager.shared.cacheData(categoryDomains, for: cacheKey)

        return categoryDomains
    }
    
    /// Check if category exists by name with caching
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func categoryExists(withName name: String, inGroupId groupId: UUID? = nil, excluding categoryId: UUID? = nil) async throws -> Bool {
        let groupIdStr = groupId?.uuidString ?? "nil"
        let categoryIdStr = categoryId?.uuidString ?? "nil"
        let cacheKey = "\(CacheKeys.categoryExists).\(name).\(groupIdStr).\(categoryIdStr)"

        // Check cache first
        if let cachedResult = await CacheManager.shared.getCachedValidation(for: cacheKey) {
            return cachedResult
        }

        // Check in Core Data
        let exists = try await context.perform {
            let request: NSFetchRequest<Category> = Category.fetchRequest()

            var predicates: [NSPredicate] = [NSPredicate(format: "name == %@", name)]

            if let groupId = groupId {
                let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
                groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
                groupRequest.fetchLimit = 1

                if let group = try self.context.fetch(groupRequest).first {
                    predicates.append(NSPredicate(format: "group == %@", group))
                }
            }

            if let categoryId = categoryId {
                predicates.append(NSPredicate(format: "id != %@", categoryId as CVarArg))
            }

            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

            let results = try self.context.fetch(request)
            return !results.isEmpty
        }

        // Cache the result
        await CacheManager.shared.cacheValidation(exists, for: cacheKey)

        return exists
    }

    /// Get categories count for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getCategoriesCount(forGroupId groupId: UUID) async throws -> Int {
        return try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                throw RepositoryError.notFound
            }

            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@", group)

            return try self.context.count(for: request)
        }
    }

    /// Get categories count for a specific user across all their groups
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getCategoriesCount(forUserId userId: UUID) async throws -> Int {
        return try await context.perform {
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
            userRequest.fetchLimit = 1

            guard let user = try self.context.fetch(userRequest).first else {
                throw RepositoryError.notFound
            }

            let request: NSFetchRequest<Category> = Category.fetchRequest()
            request.predicate = NSPredicate(format: "group.userGroups.user == %@", user)

            return try self.context.count(for: request)
        }
    }
    
    // MARK: - Budget & Limit Operations

    /// Get spending for a category within the specified frequency period
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getSpending(forCategoryId categoryId: UUID, in period: DateInterval) async throws -> Decimal {
        return try await context.perform {
            let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
            categoryRequest.predicate = NSPredicate(format: "id == %@", categoryId as CVarArg)
            categoryRequest.fetchLimit = 1

            guard let category = try self.context.fetch(categoryRequest).first else {
                throw RepositoryError.notFound
            }

            let request: NSFetchRequest<Item> = Item.fetchRequest()
            request.predicate = NSPredicate(
                format: "itemList.category == %@ AND itemList.date >= %@ AND itemList.date <= %@",
                category,
                period.start as NSDate,
                period.end as NSDate
            )

            let items = try self.context.fetch(request)
            return items.reduce(0) { total, item in
                let itemAmount = (item.amount ?? NSDecimalNumber.zero).decimalValue
                let quantity = Decimal(item.quantity)
                return total + (itemAmount * quantity)
            }
        }
    }

    /// Check if category is over limit for the current period
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func isOverLimit(categoryId: UUID, currentDate: Date = Date()) async throws -> Bool {
        // Fetch category to get limit
        guard let category = try await fetchCategory(by: categoryId) else {
            return false
        }

        guard let limit = category.limit, limit > 0 else { return false }

        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(forCategoryId: categoryId, in: period)

        return spending > limit
    }

    /// Get remaining budget for a category in the current period
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getRemainingBudget(forCategoryId categoryId: UUID, currentDate: Date = Date()) async throws -> Decimal {
        // Fetch category to get limit
        guard let category = try await fetchCategory(by: categoryId) else {
            return 0
        }

        guard let limit = category.limit, limit > 0 else { return 0 }

        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(forCategoryId: categoryId, in: period)

        return max(0, limit - spending)
    }

    /// Get budget status (percentage used) for a category
    /// ✅ REFACTORED: Accepts UUID parameter instead of Core Data entity
    func getBudgetStatus(forCategoryId categoryId: UUID, currentDate: Date = Date()) async throws -> Double {
        // Fetch category to get limit
        guard let category = try await fetchCategory(by: categoryId) else {
            return 0.0
        }

        guard let limit = category.limit, limit > 0 else { return 0.0 }

        let period = getBudgetPeriod(for: category.limitFrequency, currentDate: currentDate)
        let spending = try await getSpending(forCategoryId: categoryId, in: period)

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
