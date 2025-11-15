//
//  DashboardViewModel.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject, DashboardUpdateProtocol {
    
    // MARK: - Published Properties
    @Published var itemLists: [ItemList] = [] {
        didSet {
            // Update cached current month items whenever itemLists changes
            updateCurrentMonthCache()
        }
    }
    @Published var currentMonthItemLists: [ItemList] = []  // ✅ Cached version
    @Published var totalSpent: Double = 0.0
    @Published var isLoading = false
    @Published var isRefreshing = false  // ✅ Separate state for pull-to-refresh (doesn't affect other components)
    @Published var errorMessage: String?
    @Published var currentGroup: Group?
    @Published var currentUser: User?
    
    // MARK: - Services
    private let itemListService: ItemListServiceProtocol
    private let userService: UserServiceProtocol
    private let groupService: GroupServiceProtocol
    private let userGroupService: UserGroupServiceProtocol
    
    // MARK: - Cache
    // Note: Cache is managed by Service layer (ItemListService)
    // ViewModel only updates service cache for incremental changes
    private let cacheManager = CacheManager.shared
    
    // MARK: - Initialization
    init(itemListService: ItemListServiceProtocol,
         userService: UserServiceProtocol,
         groupService: GroupServiceProtocol,
         userGroupService: UserGroupServiceProtocol) {
        self.itemListService = itemListService
        self.userService = userService
        self.groupService = groupService
        self.userGroupService = userGroupService
        
        // Listen for Core Data context changes
        setupCoreDataNotifications()
    }
    
    // MARK: - Core Data Notifications
    private func setupCoreDataNotifications() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // 🎯 INCREMENTAL UPDATE: Handle ItemList insertions incrementally
            if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                let insertedItemLists = insertedObjects.compactMap { $0 as? ItemList }
                
                if !insertedItemLists.isEmpty {
                    print("📢 DashboardViewModel: Detected \(insertedItemLists.count) new ItemList insertion(s)")
                    
                    Task { @MainActor in
                        // Add each new ItemList incrementally (no DB query)
                        for itemList in insertedItemLists {
                            // Skip if already in our list (prevents duplicates)
                            guard !self.itemLists.contains(where: { $0.objectID == itemList.objectID }) else {
                                print("⚠️ DashboardViewModel: ItemList already in list, skipping duplicate add")
                                continue
                            }
                            
                            print("⚡️ DashboardViewModel: Adding ItemList incrementally: '\(itemList.itemListDescription ?? "Unknown")'")
                            await self.addItemList(itemList)
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Load initial dashboard data
    func loadDashboardData() async {
        print("🔄 DashboardViewModel: loadDashboardData() starting...")
        
        // Delay mínimo para mostrar el splash screen (mejor UX para branding)
        let startTime = Date()
        
        // Update UI on main thread
        await MainActor.run {
            print("🔄 DashboardViewModel: Setting isLoading = true")
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Get current user (background thread)
            print("🔄 DashboardViewModel: Getting current user...")
            guard let user = try await userService.getCurrentUser() else {
                print("❌ DashboardViewModel: No user found")
                await MainActor.run {
                    errorMessage = "No user found. Please create a user first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found user: \(user.name ?? "Unknown")")
            
            // 2. Get user's groups (background thread)
            print("🔄 DashboardViewModel: Getting user groups...")
            let userGroups = try await userGroupService.getGroups(for: user)
            guard let group = userGroups.first else {
                print("❌ DashboardViewModel: No groups found")
                await MainActor.run {
                    errorMessage = "No groups found. Please create a group first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found group: \(group.name ?? "Unknown")")
            
            // 3. Load ItemLists for the group (background thread)
            print("🔄 DashboardViewModel: Getting ItemLists for group...")
            let groupItemLists = try await itemListService.getItemLists(for: group)
            let sortedItemLists = groupItemLists.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
            print("✅ DashboardViewModel: Found \(groupItemLists.count) ItemLists")
            print("📋 DashboardViewModel: ItemList descriptions: \(groupItemLists.map { $0.itemListDescription ?? "No desc" })")
            
            // Calcular tiempo transcurrido y esperar si fue muy rápido
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 1.0 // 1 segundo mínimo
            
            if elapsed < minimumDisplayTime {
                try? await Task.sleep(nanoseconds: UInt64((minimumDisplayTime - elapsed) * 1_000_000_000))
            }
            
            // 4. Update UI on main thread
            await MainActor.run {
                print("🔄 DashboardViewModel: Updating UI with new data...")
                print("   - Current itemLists count before: \(itemLists.count)")
                print("   - New itemLists count: \(sortedItemLists.count)")
                
                currentUser = user
                currentGroup = group
                itemLists = sortedItemLists
                
                print("   - itemLists count after assignment: \(itemLists.count)")
                print("   - itemLists descriptions after: \(itemLists.map { $0.itemListDescription ?? "No desc" })")
                
                // Calculate total spent
                calculateTotalSpent()
                
                isLoading = false
                print("✅ DashboardViewModel: UI update completed, isLoading = false")
                
                // Force UI refresh
                objectWillChange.send()
                print("🔄 DashboardViewModel: objectWillChange.send() called")
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Error loading dashboard data: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Refresh dashboard data with smooth, native iOS behavior
    /// ✅ Only affects the list, not other components
    /// ✅ Uses incremental update - only changes data if different
    /// ✅ Smooth animation - no black flicker
    func refreshData() async {
        print("🔄 DashboardViewModel: refreshData() - SMOOTH NATIVE REFRESH")
        
        // Use separate isRefreshing state (won't trigger view rebuild)
        await MainActor.run {
            isRefreshing = true
        }
        
        do {
            guard let group = currentGroup else {
                print("⚠️ DashboardViewModel: No current group, skipping refresh")
                await MainActor.run { isRefreshing = false }
                return
            }
            
            // Fetch latest data from Core Data (background thread)
            print("🔍 DashboardViewModel: Fetching latest ItemLists...")
            let fetchedItemLists = try await itemListService.getItemLists(for: group)
            
            // Get current state
            let currentItemLists = await MainActor.run { itemLists }
            
            print("� DashboardViewModel: Current count: \(currentItemLists.count), Fetched count: \(fetchedItemLists.count)")
            
            // Check if data actually changed
            let currentIDs = Set(currentItemLists.map { $0.objectID })
            let fetchedIDs = Set(fetchedItemLists.map { $0.objectID })
            
            if currentIDs != fetchedIDs || currentItemLists.count != fetchedItemLists.count {
                print("✅ DashboardViewModel: [BACKGROUND] Data changed, processing...")
                
                // 🔥 BACKGROUND THREAD: Sort items (HEAVY)
                let sortedItemLists = fetchedItemLists.sorted { 
                    ($0.date ?? Date()) > ($1.date ?? Date()) 
                }
                
                // ℹ️ NO CACHE UPDATE: Service layer already cached the fetched data
                print("💡 DashboardViewModel: Service layer manages cache (single source of truth)")
                
                // ⚡️ MAIN THREAD: ONLY UI update with animation
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        itemLists = sortedItemLists
                    }
                    calculateTotalSpent()
                    print("✅ DashboardViewModel: UI updated with \(sortedItemLists.count) items")
                }
            } else {
                print("ℹ️ DashboardViewModel: No changes detected, skipping UI update")
            }
            
            // Small delay for smooth animation completion
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
            
            await MainActor.run {
                isRefreshing = false
                print("✅ DashboardViewModel: Refresh completed smoothly")
            }
            
        } catch {
            print("❌ DashboardViewModel: Error during refresh: \(error.localizedDescription)")
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    /// Load dashboard data using cache optimization
    func loadDashboardDataOptimized() async {
        print("🔄 DashboardViewModel: loadDashboardDataOptimized() starting...")
        
        // Update UI on main thread
        await MainActor.run {
            print("🔄 DashboardViewModel: Setting isLoading = true")
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Get current user (background thread)
            print("🔄 DashboardViewModel: Getting current user...")
            guard let user = try await userService.getCurrentUser() else {
                print("❌ DashboardViewModel: No user found")
                await MainActor.run {
                    errorMessage = "No user found. Please create a user first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found user: \(user.name ?? "Unknown")")
            
            // 2. Get user's groups (background thread)
            print("🔄 DashboardViewModel: Getting user groups...")
            let userGroups = try await userGroupService.getGroups(for: user)
            guard let group = userGroups.first else {
                print("❌ DashboardViewModel: No groups found")
                await MainActor.run {
                    errorMessage = "No groups found. Please create a group first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found group: \(group.name ?? "Unknown")")
            
            // 3. Update user and group first
            await MainActor.run {
                currentUser = user
                currentGroup = group
            }
            
            // 4. Load ItemLists (Service handles caching internally)
            print("� DashboardViewModel: Loading ItemLists (Service layer manages cache)...")
            let groupItemLists = try await itemListService.getItemLists(for: group)
            let sortedItemLists = groupItemLists.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
            
            print("✅ DashboardViewModel: Loaded \(groupItemLists.count) ItemLists")
            
            await MainActor.run {
                itemLists = sortedItemLists
                calculateTotalSpent()
                isLoading = false
                print("✅ DashboardViewModel: UI updated")
                print("📊 DashboardViewModel: Displaying \(itemLists.count) total items")
                print("💰 DashboardViewModel: Total spent: \(formattedTotalSpent)")
            }
            
        } catch {
            print("❌ DashboardViewModel: Error: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error loading dashboard data: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Load dashboard data optimized for massive datasets (500+ items)
    func loadDashboardDataMassive(limit: Int = 100) async {
        print("🚀 DashboardViewModel: loadDashboardDataMassive() starting with limit: \(limit)")
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // 1. Get current user and group
            guard let user = try await userService.getCurrentUser(),
                  let userGroups = try? await userGroupService.getGroups(for: user),
                  let group = userGroups.first else {
                await MainActor.run {
                    errorMessage = "User or group not found"
                    isLoading = false
                }
                return
            }
            
            // 2. Update context
            await MainActor.run {
                currentUser = user
                currentGroup = group
            }
            
            // 3. Check cache with timestamp validation
            let cacheKey = "dashboard_items_massive_\(group.id?.uuidString ?? "unknown")"
            let cacheTimestampKey = "\(cacheKey)_timestamp"
            
            if let cachedItemLists: [ItemList] = cacheManager.getCachedData(for: cacheKey),
               let timestamp: Date = cacheManager.getCachedData(for: cacheTimestampKey) {
                
                // Check if cache is still fresh (10 minutes for massive data)
                let cacheAge = Date().timeIntervalSince(timestamp)
                if cacheAge < 600 { // 10 minutes
                    print("🟢 DashboardViewModel: Using FRESH massive cache (\(cachedItemLists.count) items, age: \(Int(cacheAge))s)")
                    
                    await MainActor.run {
                        itemLists = cachedItemLists
                        calculateTotalSpent()
                        isLoading = false
                    }
                    return
                } else {
                    print("🟡 DashboardViewModel: Cache EXPIRED (age: \(Int(cacheAge))s), refreshing...")
                }
            }
            
            // 4. Load limited data from database
            print("🔄 DashboardViewModel: Loading RECENT \(limit) ItemLists from database...")
            let allItemLists = try await itemListService.getItemLists(for: group)
            
            // Sort by date and take most recent
            let recentItemLists = allItemLists
                .sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
                .prefix(limit)
                .map { $0 }
            
            print("🟡 DashboardViewModel: Loaded \(recentItemLists.count) recent ItemLists from \(allItemLists.count) total")
            
            // 5. Cache the limited data with timestamp
            cacheManager.cacheData(recentItemLists, for: cacheKey)
            cacheManager.cacheData(Date(), for: cacheTimestampKey)
            
            await MainActor.run {
                itemLists = recentItemLists
                calculateTotalSpent()
                isLoading = false
                print("✅ DashboardViewModel: UI updated with recent items only")
            }
            
        } catch {
            print("❌ DashboardViewModel: Error in massive load: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = "Error loading dashboard: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Add a new expense - triggers navigation to AddItemListView
    func addExpense() {
        // Navigation will be handled by the view using navigationPath
        print("Add expense tapped - navigating to AddItemListView")
    }
    
    /// Generate test data (temporary - triggered by gear button)
    func openSettings() {
        print("🔧 DashboardViewModel: Generating test data...")
        print("🏠 DashboardViewModel: Active group - ID: \(currentGroup?.id?.uuidString ?? "nil"), Name: '\(currentGroup?.name ?? "No Group")'")
        
        Task {
            do {
                // Get the context from one of the services
                guard let context = (itemListService as? ItemListService)?.context else {
                    print("❌ DashboardViewModel: Could not get Core Data context")
                    return
                }
                
                let generator = TestDataGenerator(context: context)
                
                // Generate 200 ItemLists with 2 items each = 400 total items
                // Pass the currentGroup to ensure data is created for the correct group
                try await generator.generateMassiveTestData(itemListCount: 200, itemsPerList: 2, targetGroup: currentGroup)
                
                print("✅ DashboardViewModel: Test data generation completed!")
                
                // Refresh the dashboard to show new data
                await refreshData()
                
            } catch {
                print("❌ DashboardViewModel: Error generating test data: \(error)")
            }
        }
    }
    
    /// Add new ItemList to the dashboard using cache optimization
    func addItemList(_ itemList: ItemList) async {
        let itemListDesc = itemList.itemListDescription ?? "No description"
        print("\n🟢 ============================================")
        print("� [ADD] Adding ItemList: '\(itemListDesc)'")
        print("🟢 ============================================")
        
        // Background validation
        guard isItemListInCurrentContext(itemList) else {
            print("⚠️ [ADD] ItemList doesn't belong to current context, skipping")
            return
        }
        
        // Get current state
        let (currentItemLists, groupId) = await MainActor.run { 
            (itemLists, currentGroup?.id?.uuidString)
        }
        
        print("📊 [ADD] Current count BEFORE add: \(currentItemLists.count)")
        
        // Check for duplicates
        if currentItemLists.contains(where: { $0.objectID == itemList.objectID }) {
            print("⚠️ [ADD] ItemList already exists in dashboard")
            return
        }
        
        // Calculate insert position (sorted by date)
        let sortedItemLists = (currentItemLists + [itemList]).sorted { 
            ($0.date ?? Date()) > ($1.date ?? Date()) 
        }
        
        print("📊 [ADD] New count AFTER add: \(sortedItemLists.count)")
        
        // 🎯 UPDATE SERVICE CACHE: Single source of truth
        // The Service layer owns the cache, ViewModel just updates it
        if let groupId = groupId {
            let serviceCacheKey = "ItemListService.groupItemLists.\(groupId)"
            let timestampKey = "\(serviceCacheKey).timestamp"
            print("🔑 [ADD] Cache key: \(serviceCacheKey)")
            cacheManager.cacheData(sortedItemLists, for: serviceCacheKey)
            cacheManager.cacheData(Date(), for: timestampKey) // Update timestamp to keep cache fresh
            print("✅ [ADD] Service cache UPDATED with \(sortedItemLists.count) items")
            print("💾 [ADD] Cache now contains:")
            for (index, item) in sortedItemLists.prefix(3).enumerated() {
                print("   \(index + 1). \(item.itemListDescription ?? "No desc") - ID: \(item.objectID)")
            }
            if sortedItemLists.count > 3 {
                print("   ... and \(sortedItemLists.count - 3) more")
            }
        }
        
        // Update UI on main thread
        await MainActor.run {
            itemLists = sortedItemLists
            updateTotalSpentForItemList(itemList, operation: .add)
            
            print("✅ [ADD] ItemList added successfully to UI")
            print("📊 [ADD] UI now shows \(itemLists.count) items")
            print("[TOTAL] [ADD] New total spent: \(formattedTotalSpent)")
            
            // Force UI refresh
            objectWillChange.send()
        }
        print("🟢 [ADD] Operation complete\n")
    }
    
    /// Remove ItemList from the dashboard using cache optimization
    func removeItemList(_ itemList: ItemList) async {
        let itemListDesc = itemList.itemListDescription ?? "Unknown"
        print("➖ DashboardViewModel: Removing ItemList from dashboard with INCREMENTAL cache...")
        print("🔍 DashboardViewModel: Removing: '\(itemListDesc)'")
        
        // Get current state
        let (currentItemLists, groupId) = await MainActor.run { 
            (itemLists, currentGroup?.id?.uuidString)
        }
        
        print("📊 DashboardViewModel: Current itemLists count BEFORE remove: \(currentItemLists.count)")
        
        guard let index = currentItemLists.firstIndex(where: { $0.objectID == itemList.objectID }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }
        
        print("🎯 DashboardViewModel: Found ItemList at index \(index)")
        
        // Create updated list
        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)
        
        print("📊 DashboardViewModel: New itemLists count AFTER remove: \(updatedItemLists.count)")
        
        // 🎯 UPDATE SERVICE CACHE: Single source of truth
        // The Service layer owns the cache, ViewModel just updates it
        if let groupId = groupId {
            let serviceCacheKey = "ItemListService.groupItemLists.\(groupId)"
            let timestampKey = "\(serviceCacheKey).timestamp"
            cacheManager.cacheData(updatedItemLists, for: serviceCacheKey)
            cacheManager.cacheData(Date(), for: timestampKey) // Update timestamp to keep cache fresh
            print("✅ DashboardViewModel: Service cache updated (single source of truth)")
            print("💡 DashboardViewModel: Cache now contains \(updatedItemLists.count) items")
        }
        
        // Update UI on main thread
        await MainActor.run {
            updateTotalSpentForItemList(itemList, operation: .remove)
            itemLists = updatedItemLists
            
            print("✅ DashboardViewModel: ItemList removed successfully")
            print("📊 DashboardViewModel: UI now shows \(itemLists.count) items")
            print("[TOTAL] DashboardViewModel: New total spent: \(formattedTotalSpent)")
            
            objectWillChange.send()
        }
    }
    
    /// Delete an ItemList (swipe-to-delete action)
    func deleteItemList(_ itemList: ItemList) async {
        let itemListDesc = itemList.itemListDescription ?? "Unknown"
        print("🗑️ DashboardViewModel: deleteItemList() called for: \(itemListDesc)")
        
        do {
            // 1. Remove from UI immediately with animation (optimistic update)
            print("⚡️ DashboardViewModel: Optimistic update - removing from UI and cache")
            await removeItemList(itemList)
            
            // 2. Delete from Core Data in background
            print("🔄 DashboardViewModel: Deleting from Core Data...")
            try await itemListService.deleteItemList(itemList)
            print("✅ DashboardViewModel: ItemList deleted from Core Data successfully")
            
            // 🎯 INCREMENTAL CACHE: NO clearCache() needed!
            // Cache was already updated in removeItemList()
            print("💡 DashboardViewModel: Cache already updated incrementally - no refresh needed")
            print("📊 DashboardViewModel: Current itemLists count: \(await itemLists.count)")
            
        } catch {
            print("❌ DashboardViewModel: Error deleting ItemList: \(error.localizedDescription)")
            
            // Rollback UI change by reloading data
            await MainActor.run {
                errorMessage = "Error al eliminar el gasto: \(error.localizedDescription)"
            }
            
            // Reload to restore correct state
            print("🔄 DashboardViewModel: Rolling back - reloading from database")
            await loadDashboardDataOptimized()
        }
    }
    
    /// Update specific ItemList in the dashboard using cache optimization
    func updateItemList(_ itemList: ItemList) async {
        print("✏️ DashboardViewModel: Updating ItemList in dashboard with cache optimization...")
        
        // Get current state
        let (currentItemLists, groupId) = await MainActor.run { 
            (itemLists, currentGroup?.id?.uuidString)
        }
        
        guard let index = currentItemLists.firstIndex(where: { $0.objectID == itemList.objectID }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }
        
        let oldItemList = currentItemLists[index]
        
        // Create updated list
        var updatedItemLists = currentItemLists
        updatedItemLists[index] = itemList
        
        // Re-sort if dates changed
        updatedItemLists = updatedItemLists.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        
        // Update cache
        if let groupId = groupId {
            let cacheKey = "dashboard_items_\(groupId)"
            cacheManager.cacheData(updatedItemLists, for: cacheKey)
            print("✅ DashboardViewModel: Cache updated after ItemList update")
        }
        
        // Update UI on main thread
        await MainActor.run {
            // Update total spent (remove old, add new)
            updateTotalSpentForItemList(oldItemList, operation: .remove)
            updateTotalSpentForItemList(itemList, operation: .add)
            
            itemLists = updatedItemLists
            
            print("✅ DashboardViewModel: ItemList updated successfully")
            objectWillChange.send()
        }
    }
    
    /// Refresh data after ItemList creation (fallback for complex cases)
    func refreshAfterItemListCreation() async {
        print("🔄 DashboardViewModel: Refreshing after ItemList creation...")
        await loadDashboardDataOptimized()
    }
    
    /// Clear cache for current group
    func clearCache() async {
        let groupIdString = await MainActor.run { currentGroup?.id?.uuidString }
        guard let groupId = groupIdString else { return }
        let cacheKey = "dashboard_items_\(groupId)"
        cacheManager.clearDataCache(for: cacheKey)
        print("🗂️ DashboardViewModel: Cache cleared for group \(groupId)")
    }
    
    /// Force refresh by clearing cache and reloading
    func forceRefresh() async {
        await clearCache()
        await loadDashboardDataOptimized()
        print("🔄 DashboardViewModel: Force refresh completed")
    }
    
    // MARK: - Private Methods
    
    /// Update total spent for a specific ItemList (incremental calculation)
    private func updateTotalSpentForItemList(_ itemList: ItemList, operation: TotalSpentOperation) {
        let itemsArray = itemList.items?.allObjects as? [Item] ?? []
        let itemListTotal = itemsArray.reduce(0.0) { itemTotal, item in
            let amount = item.amount as Decimal? ?? 0
            let quantity = Decimal(item.quantity)
            let itemValue = NSDecimalNumber(decimal: amount * quantity).doubleValue
            
            // Protect against NaN or infinite values
            guard itemValue.isFinite else {
                print("⚠️ DashboardViewModel: Invalid item value in incremental update, skipping")
                return itemTotal
            }
            
            return itemTotal + itemValue
        }
        
        // Protect against NaN
        guard itemListTotal.isFinite else {
            print("⚠️ DashboardViewModel: Invalid itemList total in incremental update, skipping")
            return
        }
        
        switch operation {
        case .add:
            totalSpent += itemListTotal
        case .remove:
            totalSpent -= itemListTotal
        }
        
        // Ensure totalSpent is valid and non-negative
        if !totalSpent.isFinite {
            print("❌ DashboardViewModel: Total spent became NaN/Infinite, recalculating from scratch")
            calculateTotalSpent()
        } else {
            totalSpent = max(0, totalSpent)
        }
    }
    
    /// Verify if an ItemList belongs to the current dashboard context
    private func isItemListInCurrentContext(_ itemList: ItemList) -> Bool {
        // Check if ItemList belongs to current group
        guard let currentGroupId = currentGroup?.id,
              let itemListGroupId = itemList.group?.id else {
            return false
        }
        
        return currentGroupId == itemListGroupId
    }
    
    /// Calculate total spent amount from all ItemLists (full recalculation)
    private func calculateTotalSpent() {
        let newTotal = itemLists.reduce(0.0) { total, itemList in
            let itemsArray = itemList.items?.allObjects as? [Item] ?? []
            let itemListTotal = itemsArray.reduce(0.0) { itemTotal, item in
                let amount = item.amount as Decimal? ?? 0
                let quantity = Decimal(item.quantity)
                let itemValue = NSDecimalNumber(decimal: amount * quantity).doubleValue
                
                // Protect against NaN or infinite values
                guard itemValue.isFinite else {
                    print("⚠️ DashboardViewModel: Invalid item value detected (NaN/Infinite), skipping")
                    return itemTotal
                }
                
                return itemTotal + itemValue
            }
            
            // Protect against NaN or infinite values
            guard itemListTotal.isFinite else {
                print("⚠️ DashboardViewModel: Invalid itemList total detected (NaN/Infinite), skipping")
                return total
            }
            
            return total + itemListTotal
        }
        
        // Final protection against NaN
        if newTotal.isFinite {
            totalSpent = max(0, newTotal)  // Ensure non-negative
        } else {
            print("❌ DashboardViewModel: Total spent calculation resulted in NaN/Infinite, setting to 0")
            totalSpent = 0.0
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get formatted total spent string
    var formattedTotalSpent: String {
        // Protect against NaN before formatting
        guard totalSpent.isFinite else {
            print("❌ DashboardViewModel: formattedTotalSpent called with NaN/Infinite value!")
            return "€0.00"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currentGroup?.currency ?? "EUR"
        formatter.locale = Locale(identifier: "es_ES") // Spanish locale for Euro formatting
        
        let formattedValue = formatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
        
        // Debug: Verify the formatted string is valid
        if formattedValue.contains("�") || formattedValue.contains("NaN") {
            print("⚠️ DashboardViewModel: Formatted value contains invalid characters: \(formattedValue)")
        }
        
        return formattedValue
    }
    
    /// Get recent ItemLists (last 10)
    var recentItemLists: [ItemList] {
        return Array(itemLists.prefix(10))
    }
    
    /// Update cached current month ItemLists
    /// ✅ Called automatically when itemLists changes (via didSet)
    private func updateCurrentMonthCache() {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = itemLists.filter { itemList in
            guard let itemListDate = itemList.date else { return false }
            return calendar.isDate(itemListDate, equalTo: now, toGranularity: .month)
        }
        
        // Only update if different to avoid unnecessary redraws
        if currentMonthItemLists.count != filtered.count {
            print("🗓️ DashboardViewModel: Updating current month cache")
            print("   - Total ItemLists: \(itemLists.count)")
            print("   - Current month ItemLists: \(filtered.count)")
            currentMonthItemLists = filtered
        }
    }
    
    /// Format date for display
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown Date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
    
    /// Get display amount for an ItemList
    func getItemListTotal(_ itemList: ItemList) -> Double {
        let itemsArray = itemList.items?.allObjects as? [Item] ?? []
        let total = itemsArray.reduce(0.0) { total, item in
            let amount = item.amount?.doubleValue ?? 0.0
            let quantity = Double(item.quantity)
            let itemValue = amount * quantity
            
            // Detect NaN at item level
            guard itemValue.isFinite else {
                print("❌ DashboardViewModel: getItemListTotal - Invalid item value detected!")
                print("   Item: \(item.itemDescription ?? "Unknown"), Amount: \(amount), Quantity: \(quantity)")
                return total
            }
            
            return total + itemValue
        }
        
        // Detect NaN at total level
        guard total.isFinite else {
            print("❌ DashboardViewModel: getItemListTotal - Total is NaN for ItemList: \(itemList.itemListDescription ?? "Unknown")")
            return 0.0
        }
        
        return total
    }
    
    /// Get formatted amount for an ItemList
    func getFormattedItemListTotal(_ itemList: ItemList) -> String {
        let total = getItemListTotal(itemList)
        
        // Extra protection
        guard total.isFinite else {
            print("❌ DashboardViewModel: getFormattedItemListTotal - Attempted to format NaN!")
            return "€0.00"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currentGroup?.currency ?? "EUR"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: NSNumber(value: total)) ?? "€0.00"
    }
}

// MARK: - Supporting Types

private enum TotalSpentOperation {
    case add
    case remove
}