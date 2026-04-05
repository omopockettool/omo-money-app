import Foundation
import CoreData

/// Data preloader for optimizing app launch performance
/// Preloads commonly accessed data into cache during app startup
@MainActor
class DataPreloader: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPreloading = false
    @Published var preloadingProgress: Double = 0.0
    @Published var preloadingStatus = "Ready"
    
    // MARK: - Services
    private let userService: any UserServiceProtocol
    private let groupService: any GroupServiceProtocol
    private let categoryService: any CategoryServiceProtocol
    private let paymentMethodService: any PaymentMethodServiceProtocol
    
    // MARK: - Initialization
    init(userService: any UserServiceProtocol, 
         groupService: any GroupServiceProtocol,
         categoryService: any CategoryServiceProtocol,
         paymentMethodService: any PaymentMethodServiceProtocol) {
        self.userService = userService
        self.groupService = groupService
        self.categoryService = categoryService
        self.paymentMethodService = paymentMethodService
    }
    
    // MARK: - Public Methods
    
    /// Preload common data during app launch
    func preloadCommonData() async {
        guard !isPreloading else { return }
        
        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Starting preload..."
        
        let tasks = [
            ("Users", preloadUsers),
            ("Groups", preloadGroups),
            ("Categories", preloadCategories)
        ]
        
        let progressIncrement = 1.0 / Double(tasks.count)
        
        for (name, task) in tasks {
            preloadingStatus = "Loading \(name)..."
            await task()
            preloadingProgress += progressIncrement
        }
        
        preloadingStatus = "Preload complete"
        isPreloading = false
        
        // Clean up any expired cache entries asynchronously
        await CacheManager.shared.cleanExpiredCacheAsync()
    }
    
    /// Preload critical data (users and groups) for faster startup
    func preloadCriticalData() async {
        guard !isPreloading else { return }
        
        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Loading critical data..."
        
        // Preload only essential data for faster startup
        await preloadUsers()
        preloadingProgress = 0.5
        
        await preloadGroups()
        preloadingProgress = 1.0
        
        preloadingStatus = "Ready"
        isPreloading = false
    }
    
    // MARK: - Private Methods
    
    /// Note: Users are accessed through UserGroupService.getUsers(in: group) for proper filtering
    private func preloadUsers() async {
        // Users should not be preloaded globally. They should be accessed 
        // through UserGroupService based on the current user's groups.
        print("ℹ️ User preloading skipped - users should be loaded per group context")
    }
    
    /// Preload groups into cache (Note: Groups should be loaded per user via UserGroupService)
    private func preloadGroups() async {
        // Groups are now loaded per user through UserGroupService.getGroups(for: user)
        // This function is kept for compatibility but does nothing
        print("ℹ️ Groups are loaded per user through UserGroupService")
    }
    
    /// Preload categories into cache
    /// Note: Categories should be loaded per group for proper filtering
    private func preloadCategories() async {
        // Categories are now loaded per group through CategoryService.getCategories(for: group)
        // This function is kept for compatibility but does nothing
        print("ℹ️ Categories are loaded per group through CategoryService")
    }
    
    /// Preload payment methods for a specific group into cache
    /// ✅ REFACTORED: Uses UUID parameter
    private func preloadPaymentMethods(for group: Group) async {
        guard let groupId = group.id else { return }
        do {
            _ = try await paymentMethodService.getPaymentMethods(forGroupId: groupId)
            _ = try await paymentMethodService.getPaymentMethodsCount(forGroupId: groupId)
        } catch {
            print("⚠️ Failed to preload payment methods: \(error.localizedDescription)")
        }
    }
    
    /// Preload data for specific group
    /// ✅ REFACTORED: Uses UUID parameter
    func preloadGroupData(_ group: Group) async {
        guard !isPreloading else { return }
        guard let groupId = group.id else { return }

        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Loading group data..."

        do {
            // Preload group-specific data
            _ = try await categoryService.getCategories(forGroupId: groupId)
            preloadingProgress = 0.25

            await preloadPaymentMethods(for: group)
            preloadingProgress = 0.5

            _ = try await groupService.getGroupMembersCount(groupId: groupId)
            preloadingProgress = 0.75

            // Preload group statistics
            if let currency = group.currency {
                _ = try await groupService.getGroupsCount(for: currency)
            }
            preloadingProgress = 1.0

            preloadingStatus = "Group data loaded"
        } catch {
            preloadingStatus = "Failed to load group data"
            print("⚠️ Failed to preload group data: \(error.localizedDescription)")
        }

        isPreloading = false
    }

    /// Preload data for multiple groups efficiently
    /// ✅ REFACTORED: Uses UUID parameters
    func preloadMultipleGroupsData(_ groups: [Group]) async {
        guard !isPreloading else { return }

        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Loading multiple groups data..."

        let progressIncrement = 1.0 / Double(groups.count)

        for (index, group) in groups.enumerated() {
            preloadingStatus = "Loading group \(index + 1) of \(groups.count)..."

            do {
                if let groupId = group.id {
                    _ = try await categoryService.getCategories(forGroupId: groupId)
                    _ = try await groupService.getGroupMembersCount(groupId: groupId)
                    _ = try await paymentMethodService.getPaymentMethods(forGroupId: groupId)
                }
            } catch {
                print("⚠️ Failed to preload data for group \(group.name ?? "Unknown"): \(error.localizedDescription)")
            }

            preloadingProgress += progressIncrement
        }

        preloadingStatus = "All groups data loaded"
        isPreloading = false
    }
    
    /// Clear all cached data and reload
    func refreshAllData() async {
        // Clear all caches
        CacheManager.shared.clearAllCaches()
        
        // Reload critical data
        await preloadCriticalData()
    }
}
