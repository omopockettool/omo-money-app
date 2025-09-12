import CoreData
import Foundation

/// Service class for PaymentMethod entity operations
/// Handles all CRUD operations for PaymentMethod with proper threading and caching
class PaymentMethodService: CoreDataService, PaymentMethodServiceProtocol {
    
    // MARK: - Cache Keys
    private enum CacheKeys {
        static let allPaymentMethods = "PaymentMethodService.allPaymentMethods"
        static let groupPaymentMethods = "PaymentMethodService.groupPaymentMethods"
        static let activePaymentMethods = "PaymentMethodService.activePaymentMethods"
        static let typePaymentMethods = "PaymentMethodService.typePaymentMethods"
    }
    
    // MARK: - Initialization
    
    override init(context: NSManagedObjectContext) {
        super.init(context: context)
    }
    
    // MARK: - PaymentMethod CRUD Operations
    
    /// Fetch all paymentMethods with caching
    func fetchPaymentMethods() async throws -> [PaymentMethod] {
        // Check cache first
        if let cachedPaymentMethods: [PaymentMethod] = await CacheManager.shared.getCachedData(for: CacheKeys.allPaymentMethods) {
            return cachedPaymentMethods
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
        let paymentMethods = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(paymentMethods, for: CacheKeys.allPaymentMethods)
        
        return paymentMethods
    }
    
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
        let paymentMethod = try await context.perform {
            let paymentMethod = PaymentMethod(context: self.context)
            paymentMethod.id = UUID()
            paymentMethod.name = name
            paymentMethod.type = type
            paymentMethod.isActive = isActive
            paymentMethod.createdAt = Date()
            paymentMethod.lastModifiedAt = Date()
            
            // Set group by ID
            if let group = try? self.context.fetch(NSFetchRequest<Group>(entityName: "Group")).first(where: { $0.id == groupId }) {
                paymentMethod.group = group
            }
            
            return paymentMethod
        }
        
        try await save()
        
        // Invalidate relevant caches
        await invalidateCaches()
        
        return paymentMethod
    }
    
    /// Update an existing paymentMethod
    func updatePaymentMethod(_ paymentMethod: PaymentMethod, name: String?, type: String?, isActive: Bool?) async throws {
        try await context.perform {
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
        
        // Invalidate relevant caches
        await invalidateCaches()
    }
    
    /// Delete a paymentMethod
    func deletePaymentMethod(_ paymentMethod: PaymentMethod) async throws {
        try await context.perform {
            self.context.delete(paymentMethod)
        }
        
        try await save()
        
        // Invalidate relevant caches
        await invalidateCaches()
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
        
        // Check cache first
        if let cachedPaymentMethods: [PaymentMethod] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedPaymentMethods
        }
        
        // Fetch from Core Data
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@ AND isActive == YES", group)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
        let paymentMethods = try await fetch(request)
        
        // Cache the result
        await CacheManager.shared.cacheData(paymentMethods, for: cacheKey)
        
        return paymentMethods
    }
    
    /// Get paymentMethods count
    func getPaymentMethodsCount() async throws -> Int {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        return try await count(request)
    }
    
    /// Get paymentMethods count for a specific group
    func getPaymentMethodsCount(for group: Group) async throws -> Int {
        let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
        request.predicate = NSPredicate(format: "group == %@", group)
        return try await count(request)
    }
    
    /// Toggle paymentMethod active status
    func toggleActiveStatus(_ paymentMethod: PaymentMethod) async throws {
        try await context.perform {
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
    
    /// Invalidate all caches related to paymentMethods
    private func invalidateCaches() async {
        await CacheManager.shared.removeData(for: CacheKeys.allPaymentMethods)
        
        // Invalidate all group-specific caches (we don't know which group was affected)
        let cacheManager = CacheManager.shared
        await cacheManager.removeDataWithPrefix(CacheKeys.groupPaymentMethods)
        await cacheManager.removeDataWithPrefix(CacheKeys.activePaymentMethods)
        await cacheManager.removeDataWithPrefix(CacheKeys.typePaymentMethods)
    }
}
