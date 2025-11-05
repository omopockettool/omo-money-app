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
    @Published var itemLists: [ItemList] = []
    @Published var totalSpent: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentGroup: Group?
    @Published var currentUser: User?
    
    // MARK: - Services
    private let itemListService: ItemListServiceProtocol
    private let userService: UserServiceProtocol
    private let groupService: GroupServiceProtocol
    private let userGroupService: UserGroupServiceProtocol
    
    // MARK: - Cache
    private let cacheManager = CacheManager.shared
    private var cacheKey: String {
        guard let groupId = currentGroup?.id?.uuidString else { return "dashboard_items_unknown" }
        return "dashboard_items_\(groupId)"
    }
    
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
            
            // Check if the notification contains ItemList changes
            if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
               insertedObjects.contains(where: { $0 is ItemList }) {
                print("📢 DashboardViewModel: Detected new ItemList insertion, refreshing data")
                Task {
                    await self.refreshData()
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
    
    /// Refresh dashboard data by clearing cache and reloading
    func refreshData() async {
        print("🔄 DashboardViewModel: refreshData() called")
        // Clear cache to ensure fresh data
        await clearCache()
        await loadDashboardDataOptimized()
        print("✅ DashboardViewModel: refreshData() completed")
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
            
            // 4. Try to get ItemLists from cache first
            let cacheKey = "dashboard_items_\(group.id?.uuidString ?? "unknown")"
            
            if let cachedItemLists: [ItemList] = cacheManager.getCachedData(for: cacheKey) {
                print("✅ DashboardViewModel: Using cached ItemLists (\(cachedItemLists.count) items)")
                
                // 🔍 DEBUG: Print ALL dates from CACHED ItemLists
                print("🗓️ DashboardViewModel: CACHED ItemList dates found:")
                for itemList in cachedItemLists {
                    let dateStr = DateFormatterHelper.formatDate(itemList.date)
                    print("   - \(itemList.itemListDescription ?? "No desc"): \(dateStr)")
                }
                
                await MainActor.run {
                    itemLists = cachedItemLists.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
                    calculateTotalSpent()
                    isLoading = false
                    print("✅ DashboardViewModel: UI updated with cached data")
                }
            } else {
                // 5. Load from database if not in cache
                print("🔄 DashboardViewModel: Cache miss, loading from database...")
                let groupItemLists = try await itemListService.getItemLists(for: group)
                let sortedItemLists = groupItemLists.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
                print("✅ DashboardViewModel: Loaded \(groupItemLists.count) ItemLists from database")
                let descriptions = groupItemLists.compactMap { $0.itemListDescription }
                print("📋 DashboardViewModel: Database ItemList descriptions: \(descriptions)")
                
                // 🔍 DEBUG: Print ALL dates from DATABASE ItemLists
                print("🗓️ DashboardViewModel: DATABASE ItemList dates found:")
                for itemList in groupItemLists {
                    let dateStr = DateFormatterHelper.formatDate(itemList.date)
                    print("   - \(itemList.itemListDescription ?? "No desc"): \(dateStr)")
                }
                
                // Cache the data
                cacheManager.cacheData(groupItemLists, for: cacheKey)
                print("✅ DashboardViewModel: ItemLists cached for future use")
                
                await MainActor.run {
                    itemLists = sortedItemLists
                    calculateTotalSpent()
                    isLoading = false
                    print("✅ DashboardViewModel: UI updated with database data")
                }
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
        print("➕ DashboardViewModel: Adding new ItemList to dashboard with cache optimization...")
        print("🔍 DashboardViewModel: New ItemList description: \(itemList.itemListDescription ?? "No description")")
        
        // Background validation
        guard isItemListInCurrentContext(itemList) else {
            print("⚠️ DashboardViewModel: ItemList doesn't belong to current context, skipping")
            return
        }
        
        // Get current state
        let (currentItemLists, groupId) = await MainActor.run { 
            (itemLists, currentGroup?.id?.uuidString)
        }
        
        // Check for duplicates
        if currentItemLists.contains(where: { $0.objectID == itemList.objectID }) {
            print("⚠️ DashboardViewModel: ItemList already exists in dashboard")
            return
        }
        
        // Calculate insert position
        let sortedItemLists = (currentItemLists + [itemList]).sorted { 
            ($0.date ?? Date()) > ($1.date ?? Date()) 
        }
        
        // Update cache
        if let groupId = groupId {
            let cacheKey = "dashboard_items_\(groupId)"
            cacheManager.cacheData(sortedItemLists, for: cacheKey)
            print("✅ DashboardViewModel: Cache updated with new ItemList")
        }
        
        // Update UI on main thread
        await MainActor.run {
            itemLists = sortedItemLists
            updateTotalSpentForItemList(itemList, operation: .add)
            
            print("✅ DashboardViewModel: ItemList added successfully. Total items: \(itemLists.count)")
            print("🔍 DashboardViewModel: Updated itemLists descriptions: \(itemLists.map { $0.itemListDescription ?? "No desc" })")
            
            // Force UI refresh
            objectWillChange.send()
        }
    }
    
    /// Remove ItemList from the dashboard using cache optimization
    func removeItemList(_ itemList: ItemList) async {
        print("➖ DashboardViewModel: Removing ItemList from dashboard with cache optimization...")
        
        // Get current state
        let (currentItemLists, groupId) = await MainActor.run { 
            (itemLists, currentGroup?.id?.uuidString)
        }
        
        guard let index = currentItemLists.firstIndex(where: { $0.objectID == itemList.objectID }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }
        
        // Create updated list
        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)
        
        // Update cache
        if let groupId = groupId {
            let cacheKey = "dashboard_items_\(groupId)"
            cacheManager.cacheData(updatedItemLists, for: cacheKey)
            print("✅ DashboardViewModel: Cache updated after removal")
        }
        
        // Update UI on main thread
        await MainActor.run {
            updateTotalSpentForItemList(itemList, operation: .remove)
            itemLists = updatedItemLists
            
            print("✅ DashboardViewModel: ItemList removed successfully. Total items: \(itemLists.count)")
            objectWillChange.send()
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
        let itemListTotal = itemsArray.reduce(0) { itemTotal, item in
            let amount = item.amount as Decimal? ?? 0
            let quantity = Decimal(item.quantity)
            let itemValue = NSDecimalNumber(decimal: amount * quantity).doubleValue
            return itemTotal + itemValue
        }
        
        switch operation {
        case .add:
            totalSpent += itemListTotal
        case .remove:
            totalSpent -= itemListTotal
        }
        
        // Ensure totalSpent never goes negative due to floating point precision
        totalSpent = max(0, totalSpent)
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
        totalSpent = itemLists.reduce(0) { total, itemList in
            let itemsArray = itemList.items?.allObjects as? [Item] ?? []
            let itemListTotal = itemsArray.reduce(0) { itemTotal, item in
                let amount = item.amount as Decimal? ?? 0
                let quantity = Decimal(item.quantity)
                let itemValue = NSDecimalNumber(decimal: amount * quantity).doubleValue
                return itemTotal + itemValue
            }
            return total + itemListTotal
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get formatted total spent string
    var formattedTotalSpent: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currentGroup?.currency ?? "EUR"
        formatter.locale = Locale(identifier: "es_ES") // Spanish locale for Euro formatting
        return formatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
    }
    
    /// Get recent ItemLists (last 10)
    var recentItemLists: [ItemList] {
        return Array(itemLists.prefix(10))
    }
    
    /// Get ItemLists from current month only
    var currentMonthItemLists: [ItemList] {
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = itemLists.filter { itemList in
            guard let itemListDate = itemList.date else { return false }
            return calendar.isDate(itemListDate, equalTo: now, toGranularity: .month)
        }
        
        print("🗓️ DashboardViewModel: Filtering ItemLists for current month")
        print("   - Total ItemLists: \(itemLists.count)")
        print("   - Current month ItemLists: \(filtered.count)")
        
        return filtered
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
        return itemsArray.reduce(0.0) { total, item in
            let amount = item.amount?.doubleValue ?? 0.0
            let quantity = Double(item.quantity)
            return total + (amount * quantity)
        }
    }
    
    /// Get formatted amount for an ItemList
    func getFormattedItemListTotal(_ itemList: ItemList) -> String {
        let total = getItemListTotal(itemList)
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