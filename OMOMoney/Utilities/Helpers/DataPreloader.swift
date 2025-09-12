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
            ("Categories", preloadCategories),
            ("Payment Methods", preloadPaymentMethods)
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
    
    /// Preload users into cache
    private func preloadUsers() async {
        do {
            _ = try await userService.fetchUsers()
            _ = try await userService.getUsersCount()
        } catch {
            print("⚠️ Failed to preload users: \(error.localizedDescription)")
        }
    }
    
    /// Preload groups into cache
    private func preloadGroups() async {
        do {
            _ = try await groupService.fetchGroups()
            _ = try await groupService.getGroupsCount()
        } catch {
            print("⚠️ Failed to preload groups: \(error.localizedDescription)")
        }
    }
    
    /// Preload categories into cache
    private func preloadCategories() async {
        do {
            _ = try await categoryService.fetchCategories()
            _ = try await categoryService.getCategoriesCount()
        } catch {
            print("⚠️ Failed to preload categories: \(error.localizedDescription)")
        }
    }
    
    /// Preload payment methods into cache
    private func preloadPaymentMethods() async {
        do {
            _ = try await paymentMethodService.fetchPaymentMethods()
            _ = try await paymentMethodService.getPaymentMethodsCount()
        } catch {
            print("⚠️ Failed to preload payment methods: \(error.localizedDescription)")
        }
    }
    
    /// Preload data for specific group
    func preloadGroupData(_ group: Group) async {
        guard !isPreloading else { return }
        
        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Loading group data..."
        
        do {
            // Preload group-specific data
            _ = try await categoryService.getCategories(for: group)
            preloadingProgress = 0.25
            
            _ = try await paymentMethodService.getPaymentMethods(for: group)
            preloadingProgress = 0.5
            
            _ = try await groupService.getGroupMembersCount(group)
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
    func preloadMultipleGroupsData(_ groups: [Group]) async {
        guard !isPreloading else { return }
        
        isPreloading = true
        preloadingProgress = 0.0
        preloadingStatus = "Loading multiple groups data..."
        
        let progressIncrement = 1.0 / Double(groups.count)
        
        for (index, group) in groups.enumerated() {
            preloadingStatus = "Loading group \(index + 1) of \(groups.count)..."
            
            do {
                _ = try await categoryService.getCategories(for: group)
                _ = try await paymentMethodService.getPaymentMethods(for: group)
                _ = try await groupService.getGroupMembersCount(group)
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
