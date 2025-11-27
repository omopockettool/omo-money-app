import CoreData
import Foundation

/// Service class for PaymentMethod entity operations
/// Handles all CRUD operations for PaymentMethod with proper threading and caching
class PaymentMethodService: CoreDataService, PaymentMethodServiceProtocol {
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let groupPaymentMethods = "PaymentMethodService.groupPaymentMethods"
        static let activePaymentMethods = "PaymentMethodService.activePaymentMethods"
        static let typePaymentMethods = "PaymentMethodService.typePaymentMethods"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - PaymentMethod CRUD Operations
    
    /// Fetch paymentMethod by ID
    func fetchPaymentMethod(by id: UUID) async throws -> PaymentMethod? {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        let results = try await fetch(request)
        return results.first
    }
    
    /// Create a new paymentMethod
    func createPaymentMethod(name: String, type: String, isActive: Bool, groupId: UUID) async throws -> PaymentMethod {
        let (paymentMethod, group) = try await context.perform {
            let paymentMethod = PaymentMethod(context: self.context)
            paymentMethod.id = UUID()
            paymentMethod.name = name
            paymentMethod.type = type
            paymentMethod.isActive = isActive
            paymentMethod.createdAt = Date()
            paymentMethod.lastModifiedAt = Date()
            
            // Set group by ID
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1
            
            let group = try self.context.fetch(groupRequest).first
            if let group = group {
                paymentMethod.group = group
            }
            
            return (paymentMethod, group)
        }
        
        try await save()
        
        // Invalidate relevant caches - specific to the group
        if let group = group {
            await invalidateCaches(for: group)
        } else {
            await invalidateCaches() // Fallback if group not found
        }
        
        return paymentMethod
    }
    
    /// Update a paymentMethod
    func updatePaymentMethod(_ paymentMethod: PaymentMethod, name: String?, type: String?, isActive: Bool?) async throws {
        await context.perform {
            if let name = name {
                paymentMethod.name = name
            }
            if let type = type {
                paymentMethod.type = type
            }
            if let isActive = isActive {
                paymentMethod.isActive = isActive
            }
            paymentMethod.lastModifiedAt = Date()
        }
        
        try await save()
        
        // Invalidate relevant caches - specific to the group
        if let group = paymentMethod.group {
            await invalidateCaches(for: group)
        } else {
            await invalidateCaches() // Fallback if no group
        }
    }
    
    /// Delete a paymentMethod
    func deletePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        // Get the group before deleting the payment method
        let group = paymentMethod.group
        
        await context.perform {
            self.context.delete(paymentMethod)
        }
        
        try await save()
        
        // Invalidate relevant caches - specific to the group
        if let group = group {
            await invalidateCaches(for: group)
        } else {
            await invalidateCaches() // Fallback if no group
        }
    }
    
    /// Get paymentMethods for a specific group with caching
    func getPaymentMethods(for group: Group) async throws -> [PaymentMethod] {
        let cacheKey = "\(CacheKeys.groupPaymentMethods).\(group.id?.uuidString ?? "nil")"
        
        // Check cache first
        if let cachedPaymentMethods: [PaymentMethod] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedPaymentMethods
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
        let paymentMethods = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(paymentMethods, for: cacheKey)
        
        return paymentMethods
    }
    
    /// Get active paymentMethods for a specific group with caching
    func getActivePaymentMethods(for group: Group) async throws -> [PaymentMethod] {
        let cacheKey = "\(CacheKeys.activePaymentMethods).\(group.id?.uuidString ?? "nil")"
        
        print("🔍 PaymentMethodService: Getting active payment methods for group '\(group.name ?? "Unknown")'")
        print("🔍 PaymentMethodService: Cache key: \(cacheKey)")
        
        // Check cache first
        if let cachedPaymentMethods: [PaymentMethod] = await CacheManager.shared.getCachedData(for: cacheKey) {
            print("🟢 PaymentMethodService: ✅ Payment methods found in CACHE (\(cachedPaymentMethods.count) items)")
            return cachedPaymentMethods
        }
        
        print("🔄 PaymentMethodService: Cache miss - fetching from Core Data...")
        
        // Fetch from Core Data
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@ AND isActive == YES", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
        let paymentMethods = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(paymentMethods, for: cacheKey)
        print("🟡 PaymentMethodService: ✅ Payment methods fetched from DATABASE and cached (\(paymentMethods.count) items)")
        
        return paymentMethods
    }
    
    /// Get paymentMethods count for a specific group
    func getPaymentMethodsCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
    
    /// Toggle paymentMethod active status
    func toggleActiveStatus(_ paymentMethod: PaymentMethod) async throws {
        await context.perform {
            paymentMethod.isActive.toggle()
            paymentMethod.lastModifiedAt = Date()
        }
        
        try await save()
        
        // Invalidate relevant caches
        await invalidateCaches()
    }
    
    /// Get paymentMethods by type for a specific group
    func getPaymentMethods(for group: Group, type: String) async throws -> [PaymentMethod] {
        let cacheKey = "\(CacheKeys.typePaymentMethods).\(group.id?.uuidString ?? "nil").\(type)"
        
        // Check cache first
        if let cachedPaymentMethods: [PaymentMethod] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedPaymentMethods
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@ AND type == %@", group, type)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
        let paymentMethods = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(paymentMethods, for: cacheKey)
        
        return paymentMethods
    }
    
    // MARK: - Cache Management
    
    /// Invalidate caches for a specific group
    private func invalidateCaches(for group: Group) async {
        // Clear group-specific cache
        let groupCacheKey = "\(CacheKeys.groupPaymentMethods).\(group.id?.uuidString ?? "nil")"
        let activeKey = "\(CacheKeys.activePaymentMethods).\(group.id?.uuidString ?? "nil")"
        
        print("🧹 PaymentMethodService: Invalidating cache for group '\(group.name ?? "Unknown")'")
        print("🧹 PaymentMethodService: Clearing cache keys:")
        print("   - Group payment methods: \(groupCacheKey)")
        print("   - Active payment methods: \(activeKey)")
        
        await CacheManager.shared.clearDataCache(for: groupCacheKey)
        await CacheManager.shared.clearDataCache(for: activeKey)
        
        // These are broader caches that still need to be cleared for now
        await CacheManager.shared.clearDataCache(for: CacheKeys.typePaymentMethods)
        print("✅ PaymentMethodService: Cache invalidated successfully")
    }
    
    /// Invalidate all caches related to paymentMethods (fallback method)
    private func invalidateCaches() async {
        // Clear group-specific caches
        await CacheManager.shared.clearDataCache(for: CacheKeys.groupPaymentMethods)
        await CacheManager.shared.clearDataCache(for: CacheKeys.activePaymentMethods)
        await CacheManager.shared.clearDataCache(for: CacheKeys.typePaymentMethods)
    }
}
