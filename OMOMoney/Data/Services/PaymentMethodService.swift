import CoreData
import Foundation

/// Service class for PaymentMethod entity operations
/// Handles all CRUD operations for PaymentMethod with proper threading and caching
/// ✅ REFACTORED: Returns Domain models and accepts UUID parameters
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
    /// ✅ REFACTORED: Returns Domain model
    func fetchPaymentMethod(by id: UUID) async throws -> PaymentMethodDomain? {
        return try await context.perform {
            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false

            guard let paymentMethod = try self.context.fetch(request).first else {
                return nil
            }

            // Convert to Domain INSIDE context.perform
            return paymentMethod.toDomain()
        }
    }

    /// Create a new paymentMethod
    /// ✅ REFACTORED: Returns Domain model
    func createPaymentMethod(name: String, type: String, icon: String = "creditcard.fill", color: String = "#8E8E93", isActive: Bool, isDefault: Bool = false, groupId: UUID) async throws -> PaymentMethodDomain {
        let paymentMethodDomain = try await context.perform {
            let paymentMethod = PaymentMethod(context: self.context)
            paymentMethod.id = UUID()
            paymentMethod.name = name
            paymentMethod.type = type
            paymentMethod.icon = icon
            paymentMethod.color = color
            paymentMethod.isActive = isActive
            paymentMethod.isDefault = isDefault
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

            // Convert to Domain INSIDE context.perform
            return paymentMethod.toDomain()
        }

        try await save()

        // Invalidate relevant caches - specific to the group
        await invalidateCaches(forGroupId: groupId)

        return paymentMethodDomain
    }

    /// Update a paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter
    func updatePaymentMethod(paymentMethodId: UUID, name: String?, type: String?, isActive: Bool?) async throws {
        let groupId = try await context.perform {
            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", paymentMethodId as CVarArg)
            request.fetchLimit = 1

            guard let paymentMethod = try self.context.fetch(request).first else {
                throw NSError(domain: "PaymentMethodService", code: 404, userInfo: [NSLocalizedDescriptionKey: "PaymentMethod not found"])
            }

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

            return paymentMethod.group?.id
        }

        try await save()

        // Invalidate relevant caches - specific to the group
        if let groupId = groupId {
            await invalidateCaches(forGroupId: groupId)
        } else {
            await invalidateCaches() // Fallback if no group
        }
    }

    /// Delete a paymentMethod
    /// ✅ REFACTORED: Accepts UUID parameter
    func deletePaymentMethod(paymentMethodId: UUID) async throws {
        let groupId = try await context.perform {
            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", paymentMethodId as CVarArg)
            request.fetchLimit = 1

            guard let paymentMethod = try self.context.fetch(request).first else {
                throw NSError(domain: "PaymentMethodService", code: 404, userInfo: [NSLocalizedDescriptionKey: "PaymentMethod not found"])
            }

            let groupId = paymentMethod.group?.id
            self.context.delete(paymentMethod)
            return groupId
        }

        try await save()

        // Invalidate relevant caches - specific to the group
        if let groupId = groupId {
            await invalidateCaches(forGroupId: groupId)
        } else {
            await invalidateCaches() // Fallback if no group
        }
    }

    /// Get paymentMethods for a specific group with caching
    /// ✅ REFACTORED: Accepts UUID parameter and returns Domain models
    func getPaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        let cacheKey = "\(CacheKeys.groupPaymentMethods).\(groupId.uuidString)"

        // Check cache first (cache Domain models)
        if let cachedPaymentMethods: [PaymentMethodDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedPaymentMethods
        }

        // Fetch from Core Data
        let paymentMethodDomains: [PaymentMethodDomain] = try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                return []
            }

            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@", group)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
            request.returnsObjectsAsFaults = false

            let paymentMethods = try self.context.fetch(request)
            return paymentMethods.map { $0.toDomain() }
        }

        // Cache the result
        await CacheManager.shared.cacheData(paymentMethodDomains, for: cacheKey)

        return paymentMethodDomains
    }

    /// Get active paymentMethods for a specific group with caching
    /// ✅ REFACTORED: Accepts UUID parameter and returns Domain models
    func getActivePaymentMethods(forGroupId groupId: UUID) async throws -> [PaymentMethodDomain] {
        let cacheKey = "\(CacheKeys.activePaymentMethods).\(groupId.uuidString)"

        print("🔍 PaymentMethodService: Getting active payment methods for group '\(groupId)'")
        print("🔍 PaymentMethodService: Cache key: \(cacheKey)")

        // Check cache first (cache Domain models)
        if let cachedPaymentMethods: [PaymentMethodDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            print("🟢 PaymentMethodService: ✅ Payment methods found in CACHE (\(cachedPaymentMethods.count) items)")
            return cachedPaymentMethods
        }

        print("🔄 PaymentMethodService: Cache miss - fetching from Core Data...")

        // Fetch from Core Data
        let paymentMethodDomains: [PaymentMethodDomain] = try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                return []
            }

            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@ AND isActive == YES", group)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
            request.returnsObjectsAsFaults = false

            let paymentMethods = try self.context.fetch(request)
            return paymentMethods.map { $0.toDomain() }
        }

        // Cache the result
        await CacheManager.shared.cacheData(paymentMethodDomains, for: cacheKey)
        print("🟡 PaymentMethodService: ✅ Payment methods fetched from DATABASE and cached (\(paymentMethodDomains.count) items)")

        return paymentMethodDomains
    }

    /// Get paymentMethods count for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    func getPaymentMethodsCount(forGroupId groupId: UUID) async throws -> Int {
        return try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                return 0
            }

            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@", group)
            return try self.context.count(for: request)
        }
    }

    /// Toggle paymentMethod active status
    /// ✅ REFACTORED: Accepts UUID parameter
    func toggleActiveStatus(paymentMethodId: UUID) async throws {
        let groupId = try await context.perform {
            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", paymentMethodId as CVarArg)
            request.fetchLimit = 1

            guard let paymentMethod = try self.context.fetch(request).first else {
                throw NSError(domain: "PaymentMethodService", code: 404, userInfo: [NSLocalizedDescriptionKey: "PaymentMethod not found"])
            }

            paymentMethod.isActive.toggle()
            paymentMethod.lastModifiedAt = Date()
            return paymentMethod.group?.id
        }

        try await save()

        // Invalidate relevant caches
        if let groupId = groupId {
            await invalidateCaches(forGroupId: groupId)
        } else {
            await invalidateCaches() // Fallback if no group
        }
    }

    /// Get paymentMethods by type for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter and returns Domain models
    func getPaymentMethods(forGroupId groupId: UUID, type: String) async throws -> [PaymentMethodDomain] {
        let cacheKey = "\(CacheKeys.typePaymentMethods).\(groupId.uuidString).\(type)"

        // Check cache first (cache Domain models)
        if let cachedPaymentMethods: [PaymentMethodDomain] = await CacheManager.shared.getCachedData(for: cacheKey) {
            return cachedPaymentMethods
        }

        // Fetch from Core Data
        let paymentMethodDomains: [PaymentMethodDomain] = try await context.perform {
            let groupRequest: NSFetchRequest<Group> = Group.fetchRequest()
            groupRequest.predicate = NSPredicate(format: "id == %@", groupId as CVarArg)
            groupRequest.fetchLimit = 1

            guard let group = try self.context.fetch(groupRequest).first else {
                return []
            }

            let request: NSFetchRequest<PaymentMethod> = PaymentMethod.fetchRequest()
            request.predicate = NSPredicate(format: "group == %@ AND type == %@", group, type)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \PaymentMethod.name, ascending: true)]
            request.returnsObjectsAsFaults = false

            let paymentMethods = try self.context.fetch(request)
            return paymentMethods.map { $0.toDomain() }
        }

        // Cache the result
        await CacheManager.shared.cacheData(paymentMethodDomains, for: cacheKey)

        return paymentMethodDomains
    }

    // MARK: - Cache Management

    /// Invalidate caches for a specific group
    /// ✅ REFACTORED: Accepts UUID parameter
    private func invalidateCaches(forGroupId groupId: UUID) async {
        // Clear group-specific cache
        let groupCacheKey = "\(CacheKeys.groupPaymentMethods).\(groupId.uuidString)"
        let activeKey = "\(CacheKeys.activePaymentMethods).\(groupId.uuidString)"

        print("🧹 PaymentMethodService: Invalidating cache for group '\(groupId)'")
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
