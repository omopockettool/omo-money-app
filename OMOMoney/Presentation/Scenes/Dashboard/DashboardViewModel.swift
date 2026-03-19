//
//  DashboardViewModel.swift
//  OMOMoney
//
//  Created by System on 3/11/25.
//

import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    // ✅ Clean Architecture: Store Domain models, not Core Data entities
    @Published var itemLists: [ItemListDomain] = [] {
        didSet {
            // Update cached current month items whenever itemLists changes
            updateCurrentMonthCache()
        }
    }
    @Published var currentMonthItemLists: [ItemListDomain] = []  // ✅ Cached version
    @Published var totalSpent: Double = 0.0
    @Published var itemListTotals: [UUID: Double] = [:]  // ✅ Cache for individual ItemList totals
    @Published var itemListCounts: [UUID: Int] = [:]    // ✅ Cache for item counts per ItemList
    @Published var categories: [UUID: (name: String, color: String)] = [:]  // Category lookup for display
    @Published var isLoading = false
    @Published var isRefreshing = false  // ✅ Separate state for pull-to-refresh (doesn't affect other components)
    @Published var isChangingGroup = false  // ✅ Separate state for group switching (subtle loading)
    @Published var errorMessage: String?
    @Published var currentGroup: GroupDomain?  // ✅ Clean Architecture: Domain model, not Core Data entity
    @Published var currentUser: UserDomain?  // ✅ Clean Architecture: Domain model, not Core Data entity
    @Published var availableGroups: [GroupDomain] = []  // ✅ Clean Architecture: Domain models, not Core Data entities
    
    // MARK: - Use Cases
    private let fetchItemListsUseCase: FetchItemListsUseCase
    private let fetchItemsUseCase: FetchItemsUseCase
    private let deleteItemListUseCase: DeleteItemListUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase

    // MARK: - Cache
    // Note: Cache is managed by Service layer (ItemListService)
    // ViewModel only updates service cache for incremental changes
    private let cacheManager = CacheManager.shared

    // MARK: - Initialization
    init(
        fetchItemListsUseCase: FetchItemListsUseCase,
        fetchItemsUseCase: FetchItemsUseCase,
        deleteItemListUseCase: DeleteItemListUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase
    ) {
        self.fetchItemListsUseCase = fetchItemListsUseCase
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteItemListUseCase = deleteItemListUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
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
            // 1. Get current user using Use Case
            print("🔄 DashboardViewModel: Getting current user...")
            guard let userDomain = try await getCurrentUserUseCase.execute() else {
                print("❌ DashboardViewModel: No user found")
                await MainActor.run {
                    errorMessage = "No user found. Please create a user first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found user: \(userDomain.name)")

            // 2. Get user's groups using Use Case (✅ Domain models only!)
            print("🔄 DashboardViewModel: Getting user groups...")
            let groupDomains = try await fetchGroupsForUserUseCase.execute(userId: userDomain.id)
            guard let firstGroupDomain = groupDomains.first else {
                print("❌ DashboardViewModel: No groups found")
                await MainActor.run {
                    errorMessage = "No groups found. Please create a group first."
                    isLoading = false
                }
                return
            }
            print("✅ DashboardViewModel: Found \(groupDomains.count) group(s), using: \(firstGroupDomain.name)")

            // 3. Load ItemLists for the group using Use Case
            print("🔄 DashboardViewModel: Getting ItemLists for group...")
            let itemListDomains = try await fetchItemListsUseCase.execute(forGroupId: firstGroupDomain.id)
            print("✅ DashboardViewModel: Found \(itemListDomains.count) ItemLists")
            print("📋 DashboardViewModel: ItemList descriptions: \(itemListDomains.map { $0.itemListDescription })")

            // 4. ✅ Load categories for display using Use Case (Clean Architecture)
            print("🔄 DashboardViewModel: Loading categories...")
            let categoryDomains = try await fetchCategoriesUseCase.execute(forGroupId: firstGroupDomain.id)
            var categoriesDict: [UUID: (name: String, color: String)] = [:]
            for categoryDomain in categoryDomains {
                categoriesDict[categoryDomain.id] = (name: categoryDomain.name, color: categoryDomain.color)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories")

            // 🔍 DEBUG: Verify categoryId mapping
            print("🔍 DashboardViewModel: Verifying ItemList → Category mapping:")
            for itemList in itemListDomains.prefix(3) {
                if let categoryId = itemList.categoryId {
                    let categoryName = categoriesDict[categoryId]?.name ?? "NOT FOUND"
                    print("   ✅ ItemList '\(itemList.itemListDescription)' → CategoryId: \(categoryId.uuidString.prefix(8)) → '\(categoryName)'")
                } else {
                    print("   ⚠️ ItemList '\(itemList.itemListDescription)' → NO CATEGORY ID!")
                }
            }

            // 5. Update UI on main thread (✅ Domain models only!)
            await MainActor.run {
                print("🔄 DashboardViewModel: Updating UI with new data...")
                print("   - Current itemLists count before: \(itemLists.count)")
                print("   - New itemLists count: \(itemListDomains.count)")

                currentUser = userDomain  // ✅ Domain model
                currentGroup = firstGroupDomain  // ✅ Domain model
                availableGroups = groupDomains  // ✅ Domain models array
                itemLists = itemListDomains  // ✅ Domain models
                categories = categoriesDict  // ✅ Category lookup

                print("   - itemLists count after assignment: \(itemLists.count)")
                print("   - itemLists descriptions after: \(itemLists.map { $0.itemListDescription })")
            }

            // Calculate total spent (async, must be outside MainActor.run)
            await calculateTotalSpent()

            await MainActor.run {
                isLoading = false
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
            
            // Fetch latest data using Use Case
            print("🔍 DashboardViewModel: Fetching latest ItemLists...")
            let groupId = group.id  // ✅ GroupDomain.id is NOT optional
            // Get current state on main actor first (before async call)
            let currentItemLists = await MainActor.run { itemLists }

            // Execute use case to get Domain models
            let fetchedItemListDomains = try await fetchItemListsUseCase.execute(forGroupId: groupId)
            
            print("� DashboardViewModel: Current count: \(currentItemLists.count), Fetched count: \(fetchedItemListDomains.count)")
            
            // 🔥 BACKGROUND THREAD: Sort items (HEAVY)
            let sortedItemLists = fetchedItemListDomains.sorted {
                $0.date > $1.date
            }

            // ℹ️ NO CACHE UPDATE: Service layer already cached the fetched data
            print("💡 DashboardViewModel: Service layer manages cache (single source of truth)")

            // ⚡️ MAIN THREAD: ONLY UI update with animation
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    itemLists = sortedItemLists
                }
            }

            // ✅ ALWAYS recalculate totals on refresh - items inside ItemLists may have changed!
            // This fixes the bug where editing an item doesn't update the dashboard total
            print("🔄 DashboardViewModel: Recalculating all ItemList totals...")
            await calculateTotalSpent()

            await MainActor.run {
                print("✅ DashboardViewModel: UI updated with \(sortedItemLists.count) items, totals recalculated")
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

    /// Refresh ItemList objects' Core Data relationships
    /// ⚠️ DEPRECATED: Use refreshData() instead for Domain models
    /// Call this when navigating back to dashboard to get updated item totals
    @available(*, deprecated, message: "Use refreshData() instead for Domain models")
    func refreshItemListContexts() async {
        print("⚠️ DashboardViewModel: refreshItemListContexts() is deprecated, calling refreshData()...")
        await refreshData()
    }

    /// Add a new expense - triggers navigation to AddItemListView
    func addExpense() {
        // Navigation will be handled by the view using navigationPath
        print("Add expense tapped - navigating to AddItemListView")
    }
    
    // MARK: - Group Management
    
    /// Cambiar el grupo activo y recargar los ItemLists (✅ Clean Architecture: Domain model)
    func changeGroup(to newGroup: GroupDomain) async {
        guard newGroup.id != currentGroup?.id else {
            print("⚠️ DashboardViewModel: Grupo ya seleccionado, ignorando cambio")
            return
        }

        print("🔄 DashboardViewModel: Cambiando a grupo: \(newGroup.name)")

        await MainActor.run {
            isChangingGroup = true  // ✅ Usa loading sutil, no el splash
        }

        do {
            // ✅ Delay de 0.3 segundos para mostrar el spinner en acción
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 segundos

            // Load ItemLists using Use Case (Domain models)
            let groupId = newGroup.id  // ✅ GroupDomain.id is NOT optional
            let itemListDomains = try await fetchItemListsUseCase.execute(forGroupId: groupId)

            // ✅ CRITICAL FIX: Load categories for the new group using Use Case (Clean Architecture)
            print("🔄 DashboardViewModel: Loading categories for new group...")
            let categoryDomains = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var categoriesDict: [UUID: (name: String, color: String)] = [:]
            for categoryDomain in categoryDomains {
                categoriesDict[categoryDomain.id] = (name: categoryDomain.name, color: categoryDomain.color)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories for new group")

            await MainActor.run {
                currentGroup = newGroup  // ✅ Domain model
                itemLists = itemListDomains
                categories = categoriesDict  // ✅ FIX: Update categories when changing groups
            }

            // Calculate total spent (async, must be outside MainActor.run)
            await calculateTotalSpent()

            await MainActor.run {
                isChangingGroup = false
                print("✅ DashboardViewModel: Grupo cambiado exitosamente")
                print("📋 DashboardViewModel: Cargados \(itemListDomains.count) ItemLists")
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error al cambiar de grupo: \(error.localizedDescription)"
                isChangingGroup = false
            }
            print("❌ DashboardViewModel: Error cambiando grupo: \(error)")
        }
    }
    
    /// Recargar la lista de grupos disponibles (después de crear uno nuevo)
    func refreshAvailableGroups() async {
        guard let user = currentUser else {
            print("⚠️ DashboardViewModel: No hay usuario actual, no se pueden recargar grupos")
            return
        }
        
        print("🔄 DashboardViewModel: Recargando grupos disponibles...")

        do {
            let userId = user.id  // ✅ UserDomain.id is NOT optional

            let groupDomains = try await fetchGroupsForUserUseCase.execute(userId: userId)

            await MainActor.run {
                availableGroups = groupDomains  // ✅ Use Domain models
                print("✅ DashboardViewModel: Grupos recargados. Total: \(groupDomains.count)")
            }
        } catch {
            print("❌ DashboardViewModel: Error recargando grupos: \(error)")
        }
    }
    
    /// Agregar un grupo nuevo incrementalmente (sin query a BD) (✅ Clean Architecture: Domain model)
    func addGroup(_ newGroup: GroupDomain) {
        print("➕ [DashboardVM] addGroup() llamado")
        print("➕ [DashboardVM] Grupo nuevo: '\(newGroup.name)' (ID: \(newGroup.id.uuidString))")
        print("➕ [DashboardVM] availableGroups.count ANTES: \(availableGroups.count)")

        guard !availableGroups.contains(where: { $0.id == newGroup.id }) else {
            print("⚠️ [DashboardVM] Grupo ya existe en lista - SKIP")
            return
        }

        availableGroups.append(newGroup)
        print("✅ [DashboardVM] addGroup() completado")
    }
    
    /// Eliminar un grupo incrementalmente (✅ Clean Architecture: Domain model)
    func removeGroup(_ group: GroupDomain) {
        print("🗑️ [DashboardVM] removeGroup() llamado")
        print("🗑️ [DashboardVM] Grupo a eliminar: '\(group.name)' (ID: \(group.id.uuidString))")
        print("🗑️ [DashboardVM] availableGroups.count ANTES: \(availableGroups.count)")
        print("🗑️ [DashboardVM] availableGroups ANTES: \(availableGroups.map { ($0.name, $0.id.uuidString) })")
        print("🗑️ [DashboardVM] currentGroup: '\(currentGroup?.name ?? "nil")' (ID: \(currentGroup?.id.uuidString ?? "nil"))")
        print("🗑️ [DashboardVM] currentUser: '\(currentUser?.name ?? "nil")' (ID: \(currentUser?.id.uuidString ?? "nil"))")

        availableGroups.removeAll { $0.id == group.id }  // ✅ Compare by UUID, not objectID
        print("✅ [DashboardVM] removeGroup() completado")
    }
    
    /// Generate seed data for testing — creates 20 item lists with random items in current group
    func openSettings() {
        Task {
            await generateSeedData()
        }
    }

    private func generateSeedData() async {
        guard let group = currentGroup else {
            print("⚠️ [SEED] No current group selected")
            return
        }

        let container = AppDIContainer.shared
        let createItemListUseCase = container.makeCreateItemListUseCase()
        let createItemUseCase = container.makeCreateItemUseCase()
        let fetchPaymentMethodsUseCase = container.makeFetchPaymentMethodsUseCase()

        do {
            let categoryIds = Array(categories.keys)
            guard !categoryIds.isEmpty else {
                print("⚠️ [SEED] No categories available")
                return
            }

            let paymentMethods = try await fetchPaymentMethodsUseCase.executeActive(forGroupId: group.id)
            guard !paymentMethods.isEmpty else {
                print("⚠️ [SEED] No payment methods available")
                return
            }

            let descriptions = ["Supermercado", "Gasolina", "Restaurante", "Netflix", "Gym",
                                 "Farmacia", "Amazon", "Electricidad", "Agua", "Internet",
                                 "Ropa", "Café", "Taxi", "Cine", "Libro",
                                 "Dentista", "Peluquería", "Comida rápida", "Seguro", "Parking"]

            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let daysPassed = calendar.dateComponents([.day], from: startOfMonth, to: now).day ?? 0

            print("🌱 [SEED] Generating 20 ItemLists in group '\(group.name)'...")

            for i in 0..<20 {
                let dayOffset = Int.random(in: 0...max(0, daysPassed))
                let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) ?? now
                let description = descriptions[i % descriptions.count]
                let categoryId = categoryIds[Int.random(in: 0..<categoryIds.count)]
                let paymentMethodId = paymentMethods[Int.random(in: 0..<paymentMethods.count)].id
                let rawAmount = Double.random(in: 1.0...200.0)
                let amount = Decimal((rawAmount * 100).rounded() / 100)

                let itemList = try await createItemListUseCase.execute(
                    description: description,
                    date: date,
                    categoryId: categoryId,
                    paymentMethodId: paymentMethodId,
                    groupId: group.id
                )

                let itemSubDescriptions = ["Leche", "Huevos", "Pan", "Agua", "Refresco", "Yogur", "Mantequilla", "Queso", "Jamón", "Fruta"]
                let itemsToCreate = Int.random(in: 1...10)
                for j in 0..<itemsToCreate {
                    let itemAmount = Decimal((Double.random(in: 0.5...50.0) * 100).rounded() / 100)
                    let _ = try await createItemUseCase.execute(
                        description: itemSubDescriptions[j % itemSubDescriptions.count],
                        amount: itemAmount,
                        quantity: 1,
                        itemListId: itemList.id
                    )
                }
            }

            print("✅ [SEED] 20 ItemLists created. Refreshing dashboard...")
            await loadDashboardData()

        } catch {
            print("❌ [SEED] Error generating seed data: \(error)")
        }
    }
    
    /// Add ItemList from Domain model using Clean Architecture
    /// ✅ Works with Domain models only - no Core Data conversion needed!
    func addItemListFromDomain(_ itemListDomain: ItemListDomain) async {
        let itemListDesc = itemListDomain.itemListDescription
        print("\n🟢 ============================================")
        print("📋 [ADD-DOMAIN] Adding ItemList: '\(itemListDesc)'")
        print("🟢 ============================================")

        print("🔙 [CALLBACK] DashboardViewModel.addItemListFromDomain()")
        print("   📋 Received from: AddItemListView → DashboardView → DashboardViewModel")
        print("   📋 ItemListDomain Details:")
        print("      - ID: \(itemListDomain.id)")
        print("      - Description: \(itemListDomain.itemListDescription)")
        print("      - Category ID: \(itemListDomain.categoryId?.uuidString ?? "nil")")
        print("      - Group ID: \(itemListDomain.groupId?.uuidString ?? "nil")")

        // ✅ FIX: Check if ItemList belongs to the current dashboard group
        guard let currentGroupId = currentGroup?.id else {
            print("⚠️ [ADD-DOMAIN] No current group selected - skipping")
            return
        }

        if itemListDomain.groupId != currentGroupId {
            print("⚠️ [ADD-DOMAIN] ItemList belongs to different group")
            print("   - ItemList group: \(itemListDomain.groupId?.uuidString ?? "nil")")
            print("   - Current dashboard group: \(currentGroupId.uuidString)")
            print("   - Action: Skipping incremental update (ItemList saved to DB but not shown in current view)")
            return
        }

        print("   ✅ ItemList belongs to current group - proceeding with incremental update")
        print("   🔄 Performing incremental cache update (no DB query)")

        // Check if already exists (compare by ID)
        if itemLists.contains(where: { $0.id == itemListDomain.id }) {
            print("⚠️ [ADD-DOMAIN] ItemList already exists in dashboard")
            return
        }

        // Calculate insert position (sorted by date) - works with Domain models!
        let sortedItemLists = (itemLists + [itemListDomain]).sorted {
            $0.date > $1.date
        }

        print("📊 [ADD-DOMAIN] New count: \(sortedItemLists.count)")

        // Update UI (ViewModel is @MainActor)
        itemLists = sortedItemLists
        print("   ✅ ItemList added to local itemLists array")
        print("   🔄 Triggering didSet → updateCurrentMonthCache()")
        await calculateTotalSpent()

        print("✅ [ADD-DOMAIN] ItemList added successfully to UI")
        print("[TOTAL] [ADD-DOMAIN] New total spent: \(formattedTotalSpent)")
        print("🟢 [ADD-DOMAIN] Operation complete\n")
    }

    /// Add new ItemList to the dashboard using cache optimization
    /// Clear cache for current group
    @MainActor
    func clearCache() async {
        guard let group = currentGroup else { return }  // ✅ Direct access on MainActor
        let groupId = group.id.uuidString  // ✅ GroupDomain.id is NOT optional
        let cacheKey = "dashboard_items_\(groupId)"
        cacheManager.clearDataCache(for: cacheKey)
        print("🗂️ DashboardViewModel: Cache cleared for group \(groupId)")
    }
    
    /// Force refresh by clearing cache and reloading
    func forceRefresh() async {
        await clearCache()
        await loadDashboardData()
        print("🔄 DashboardViewModel: Force refresh completed")
    }
    
    // MARK: - Private Methods
    
    /// Update total spent for a specific ItemList (incremental calculation)
    
    /// Calculate total spent across all ItemLists (async, uses Domain models)
    /// ✅ Clean Architecture: Uses async getItemListTotal for Domain models
    /// ✅ Also populates itemListTotals cache for UI display
    private func calculateTotalSpent() async {
        // Calculate totals and counts concurrently for better performance
        typealias ItemListData = (id: UUID, total: Double, count: Int)
        let results = await withTaskGroup(of: ItemListData.self) { group in
            var items: [ItemListData] = []

            for itemListDomain in currentMonthItemLists {
                group.addTask {
                    let (total, count) = await self.getItemListTotalAndCount(itemListDomain)
                    return (itemListDomain.id, total, count)
                }
            }

            for await result in group {
                items.append(result)
            }

            return items
        }

        let totals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.total) })
        let counts = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.count) })

        await MainActor.run {
            itemListTotals = totals
            itemListCounts = counts
        }

        // Sum all totals
        let newTotal = totals.values.reduce(0.0) { total, itemListTotal in
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

    /// Returns a NumberFormatter using es_ES number formatting but with the native
    /// currency symbol (e.g. "$" for USD instead of "US$" from the Spanish locale).
    private func makeCurrencyFormatter() -> NumberFormatter {
        let code = currentGroup?.currency ?? "EUR"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = Locale(identifier: "es_ES")
        let sym = NumberFormatter()
        sym.numberStyle = .currency
        sym.currencyCode = code
        sym.locale = Locale(identifier: "en_US")
        formatter.currencySymbol = sym.currencySymbol
        return formatter
    }

    /// Get formatted total spent string
    var formattedTotalSpent: String {
        // Protect against NaN before formatting
        guard totalSpent.isFinite else {
            print("❌ DashboardViewModel: formattedTotalSpent called with NaN/Infinite value!")
            return "€0.00"
        }
        
        let formatter = makeCurrencyFormatter()
        let formattedValue = formatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
        
        // Debug: Verify the formatted string is valid
        if formattedValue.contains("�") || formattedValue.contains("NaN") {
            print("⚠️ DashboardViewModel: Formatted value contains invalid characters: \(formattedValue)")
        }
        
        return formattedValue
    }
    
    /// Get recent ItemLists (last 10)
    var recentItemLists: [ItemListDomain] {
        return Array(itemLists.prefix(10))
    }
    
    /// Update cached current month ItemLists
    /// ✅ Called automatically when itemLists changes (via didSet)
    /// Update cache of current month ItemLists (for performance optimization)
    /// ✅ Clean Architecture: Works with Domain models
    private func updateCurrentMonthCache() {
        let calendar = Calendar.current
        let now = Date()

        // Domain model date is NOT optional, simpler filtering!
        let filtered = itemLists.filter { itemListDomain in
            calendar.isDate(itemListDomain.date, equalTo: now, toGranularity: .month)
        }

        // Check if content changed by comparing IDs AND relevant fields
        // ID-only comparison misses renames/date/category changes on existing items
        let currentIds = Set(currentMonthItemLists.map { $0.id })
        let filteredIds = Set(filtered.map { $0.id })
        let idsChanged = currentIds != filteredIds
        let contentChanged = idsChanged || filtered.contains { newItem in
            guard let existing = currentMonthItemLists.first(where: { $0.id == newItem.id }) else { return false }
            return existing.itemListDescription != newItem.itemListDescription
                || existing.date != newItem.date
                || existing.categoryId != newItem.categoryId
                || existing.paymentMethodId != newItem.paymentMethodId
        }

        if contentChanged {
            print("🗓️ DashboardViewModel: Updating current month cache (content changed)")
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
    
    private func getItemListTotalAndCount(_ itemListDomain: ItemListDomain) async -> (Double, Int) {
        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemListDomain.id)
            let total = items.reduce(0.0) { acc, item in
                let value = Double(truncating: item.amount as NSNumber) * Double(item.quantity)
                return value.isFinite ? acc + value : acc
            }
            let totalUnits = items.reduce(0) { $0 + Int($1.quantity) }
            return (total.isFinite ? max(0, total) : 0.0, totalUnits)
        } catch {
            return (0.0, 0)
        }
    }

    /// ✅ Clean Architecture: Uses Use Case, no Core Data knowledge
    func getItemListTotal(_ itemListDomain: ItemListDomain) async -> Double {
        do {
            // Fetch items via Use Case (proper layering!)
            let items = try await fetchItemsUseCase.execute(forItemListId: itemListDomain.id)

            // Calculate total from Domain models
            let total = items.reduce(0.0) { total, item in
                let amount = Double(truncating: item.amount as NSNumber)
                let quantity = Double(item.quantity)
                let itemValue = amount * quantity

                // Detect NaN at item level
                guard itemValue.isFinite else {
                    print("❌ DashboardViewModel: getItemListTotal(Domain) - Invalid item value detected!")
                    print("   Item: \(item.itemDescription), Amount: \(amount), Quantity: \(quantity)")
                    return total
                }

                return total + itemValue
            }

            // Detect NaN at total level
            guard total.isFinite else {
                print("❌ DashboardViewModel: getItemListTotal(Domain) - Total is NaN for ItemList: \(itemListDomain.itemListDescription)")
                return 0.0
            }

            return total
        } catch {
            print("❌ DashboardViewModel: getItemListTotal(Domain) - Error fetching items: \(error.localizedDescription)")
            return 0.0
        }
    }

    /// Get formatted amount for an ItemListDomain (async, fetches items via Use Case)
    /// ✅ Clean Architecture: Uses Use Case, no Core Data knowledge
    func getFormattedItemListTotal(_ itemListDomain: ItemListDomain) async -> String {
        let total = await getItemListTotal(itemListDomain)

        // Extra protection
        guard total.isFinite else {
            print("❌ DashboardViewModel: getFormattedItemListTotal(Domain) - Attempted to format NaN!")
            return "€0.00"
        }

        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "€0.00"
    }

    /// Delete an ItemListDomain (Domain model version)
    /// ✅ Clean Architecture: Uses Use Case only, no Core Data knowledge
    func deleteItemListDomain(_ itemListDomain: ItemListDomain) async {
        print("🗑️ DashboardViewModel: deleteItemListDomain() called for: \(itemListDomain.itemListDescription)")

        do {
            // 1. Remove from UI immediately (optimistic update)
            print("⚡️ DashboardViewModel: Optimistic update - removing from UI")
            await removeItemListDomain(itemListDomain)

            // 2. Delete from persistence using Use Case
            print("🔄 DashboardViewModel: Deleting from persistence...")
            try await deleteItemListUseCase.execute(id: itemListDomain.id)
            print("✅ DashboardViewModel: ItemList deleted successfully")

        } catch {
            print("❌ DashboardViewModel: Error deleting ItemList: \(error.localizedDescription)")

            // Rollback UI change by reloading data
            await MainActor.run {
                errorMessage = "Error al eliminar el gasto: \(error.localizedDescription)"
            }

            // Reload to restore correct state
            print("🔄 DashboardViewModel: Rolling back - reloading from database")
            await loadDashboardData()
        }
    }

    /// Remove an ItemListDomain from the UI cache (Domain model version)
    /// ✅ Clean Architecture: Works with Domain models only
    private func removeItemListDomain(_ itemListDomain: ItemListDomain) async {
        print("➖ DashboardViewModel: Removing ItemListDomain from UI cache")
        print("🔍 DashboardViewModel: Removing: '\(itemListDomain.itemListDescription)'")

        // Get current state
        let currentItemLists = await MainActor.run { itemLists }

        print("📊 DashboardViewModel: Current itemLists count BEFORE remove: \(currentItemLists.count)")

        guard let index = currentItemLists.firstIndex(where: { $0.id == itemListDomain.id }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }

        print("🎯 DashboardViewModel: Found ItemList at index \(index)")

        // Create updated list
        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)

        print("📊 DashboardViewModel: New itemLists count AFTER remove: \(updatedItemLists.count)")

        // Update UI on main thread and recalculate total
        await MainActor.run {
            itemLists = updatedItemLists
        }

        // Recalculate total spent (following RULES: always recalculate)
        await calculateTotalSpent()
    }

    /// Update an ItemListDomain in the UI cache (Domain model version)
    /// ✅ Clean Architecture: Works with Domain models only
    func updateItemListDomain(_ itemListDomain: ItemListDomain) async {
        print("✏️ DashboardViewModel: Updating ItemListDomain in UI cache")
        print("🔍 DashboardViewModel: Updating: '\(itemListDomain.itemListDescription)'")

        // Get current state
        let currentItemLists = await MainActor.run { itemLists }

        guard let index = currentItemLists.firstIndex(where: { $0.id == itemListDomain.id }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }

        print("🎯 DashboardViewModel: Found ItemList at index \(index)")

        // Create updated list
        var updatedItemLists = currentItemLists
        updatedItemLists[index] = itemListDomain

        // Re-sort if dates changed
        updatedItemLists = updatedItemLists.sorted { $0.date > $1.date }

        print("📊 DashboardViewModel: ItemList updated")

        // Update UI on main thread and recalculate total
        await MainActor.run {
            itemLists = updatedItemLists
        }

        // Recalculate total spent (following RULES: always recalculate)
        await calculateTotalSpent()
    }

    /// Verify if an ItemListDomain belongs to the current dashboard context
    /// ✅ Clean Architecture: Works with Domain models only
    private func isItemListInCurrentContext(_ itemListDomain: ItemListDomain) -> Bool {
        // Check if ItemList belongs to current group
        guard let currentGroup = currentGroup else {
            return false
        }

        return currentGroup.id == itemListDomain.groupId  // ✅ id is NOT optional
    }

    /// Get current month ItemLists (Domain model version)
    /// ✅ Clean Architecture: Works with Domain models only
    func getCurrentMonthItemLists() -> [ItemListDomain] {
        let calendar = Calendar.current
        let now = Date()

        return itemLists.filter { itemListDomain in
            calendar.isDate(itemListDomain.date, equalTo: now, toGranularity: .month)
        }
    }
}

// MARK: - Supporting Types

private enum TotalSpentOperation {
    case add
    case remove
}