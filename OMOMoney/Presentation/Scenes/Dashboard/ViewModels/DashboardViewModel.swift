import Foundation
import SwiftUI

enum ItemListPaidStatus {
    case none       // 0 items, or all unpaid
    case partial    // some paid, some not
    case all        // all items paid
}


@MainActor

@Observable
class DashboardViewModel {
    private typealias ItemListData = (id: UUID, paidTotal: Double, unpaidTotal: Double, count: Int, paidStatus: ItemListPaidStatus)

    private struct CachedItemListData {
        let paidTotal: Double
        let unpaidTotal: Double
        let count: Int
        let paidStatus: ItemListPaidStatus
    }

    // MARK: - Published Properties
    var itemLists: [SDItemList] = [] {
        didSet {
            updateCurrentMonthCache()
        }
    }
    var currentMonthItemLists: [SDItemList] = []
    var totalSpent: Double = 0.0
    var todayTotal: Double = 0.0
    var currentMonthTotal: Double = 0.0
    var itemListTotals: [UUID: Double] = [:]
    var itemListUnpaidTotals: [UUID: Double] = [:]
    var itemListCounts: [UUID: Int] = [:]
    var itemListPaidStatus: [UUID: ItemListPaidStatus] = [:]
    var categories: [UUID: (name: String, color: String, icon: String)] = [:]
    var isLoading = false
    var isRefreshing = false
    var isChangingGroup = false
    var isDeletingGroup = false
    var errorMessage: String?
    var toast: ToastMessage?
    var currentGroup: SDGroup?
    var currentUser: SDUser?
    var availableGroups: [SDGroup] = []
    var showingSettings = false
    var showingFullMonth = false

    // MARK: - Filtered Lists

    var todayItemLists: [SDItemList] {
        itemLists.filter { Calendar.current.isDateInToday($0.date) }
    }

    var monthItemLists: [SDItemList] {
        itemLists.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var hasItemsOutsideToday: Bool {
        monthItemLists.count > todayItemLists.count
    }

    var todayRawTotal: Double {
        todayTotal
    }


    // MARK: - Use Cases
    private let fetchItemListsUseCase: FetchItemListsUseCase
    private let fetchItemsUseCase: FetchItemsUseCase
    private let deleteItemListUseCase: DeleteItemListUseCase
    private let getCurrentUserUseCase: GetCurrentUserUseCase
    private let fetchGroupsForUserUseCase: FetchGroupsForUserUseCase
    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let toggleAllItemsPaidInListUseCase: ToggleAllItemsPaidInListUseCase
    private let toggleItemPaidUseCase: ToggleItemPaidUseCase
    private let deleteGroupUseCase: DeleteGroupUseCase

    // MARK: - Cache
    private let cacheManager = CacheManager.shared
    private var paidToggleTasks: [UUID: Task<Void, Never>] = [:]

    // MARK: - Initialization
    init(
        fetchItemListsUseCase: FetchItemListsUseCase,
        fetchItemsUseCase: FetchItemsUseCase,
        deleteItemListUseCase: DeleteItemListUseCase,
        getCurrentUserUseCase: GetCurrentUserUseCase,
        fetchGroupsForUserUseCase: FetchGroupsForUserUseCase,
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        toggleAllItemsPaidInListUseCase: ToggleAllItemsPaidInListUseCase,
        toggleItemPaidUseCase: ToggleItemPaidUseCase,
        deleteGroupUseCase: DeleteGroupUseCase
    ) {
        self.fetchItemListsUseCase = fetchItemListsUseCase
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteItemListUseCase = deleteItemListUseCase
        self.getCurrentUserUseCase = getCurrentUserUseCase
        self.fetchGroupsForUserUseCase = fetchGroupsForUserUseCase
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.toggleAllItemsPaidInListUseCase = toggleAllItemsPaidInListUseCase
        self.toggleItemPaidUseCase = toggleItemPaidUseCase
        self.deleteGroupUseCase = deleteGroupUseCase
    }
    
    // MARK: - Public Methods
    
    func loadDashboardData() async {
        print("🔄 DashboardViewModel: loadDashboardData() starting...")
        
        print("🔄 DashboardViewModel: Setting isLoading = true")
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 DashboardViewModel: Getting current user...")
            guard let user = try await getCurrentUserUseCase.execute() else {
                print("❌ DashboardViewModel: No user found")
                errorMessage = "No user found. Please create a user first."
                isLoading = false
                return
            }
            print("✅ DashboardViewModel: Found user: \(user.name)")

            print("🔄 DashboardViewModel: Getting user groups...")
            let groups = try await fetchGroupsForUserUseCase.execute(userId: user.id)
            guard let firstGroup = groups.first else {
                print("❌ DashboardViewModel: No groups found")
                errorMessage = "No groups found. Please create a group first."
                isLoading = false
                return
            }
            print("✅ DashboardViewModel: Found \(groups.count) group(s), using: \(firstGroup.name)")

            print("🔄 DashboardViewModel: Getting ItemLists for group...")
            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: firstGroup.id)
            print("✅ DashboardViewModel: Found \(fetchedItemLists.count) ItemLists")

            print("🔄 DashboardViewModel: Loading categories...")
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: firstGroup.id)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories")

            print("🔄 DashboardViewModel: Updating UI with new data...")
            currentUser = user
            currentGroup = firstGroup
            availableGroups = groups
            itemLists = fetchedItemLists
            categories = categoriesDict

            await calculateTotalSpent()

            isLoading = false
            
        } catch {
            errorMessage = "Error loading dashboard data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func refreshData() async {
        print("🔄 DashboardViewModel: refreshData() - SMOOTH NATIVE REFRESH")
        
        isRefreshing = true
        
        do {
            guard let group = currentGroup else {
                print("⚠️ DashboardViewModel: No current group, skipping refresh")
                isRefreshing = false
                return
            }
            
            let groupId = group.id
            let currentItemLists = itemLists

            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)
            
            print("🔍 DashboardViewModel: Current count: \(currentItemLists.count), Fetched count: \(fetchedItemLists.count)")
            
            let cal = Calendar.current
            let sortedItemLists = fetchedItemLists.sorted {
                let d0 = cal.startOfDay(for: $0.date)
                let d1 = cal.startOfDay(for: $1.date)
                return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
            }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                itemLists = sortedItemLists
            }

            await calculateTotalSpent()

            print("✅ DashboardViewModel: UI updated with \(sortedItemLists.count) items, totals recalculated")
            isRefreshing = false
            print("✅ DashboardViewModel: Refresh completed smoothly")
            
        } catch {
            print("❌ DashboardViewModel: Error during refresh: \(error.localizedDescription)")
            isRefreshing = false
        }
    }

    func addExpense() {
        print("Add expense tapped - navigating to AddItemListView")
    }
    
    // MARK: - Group Management
    
    func changeGroup(to newGroup: SDGroup) async {
        guard newGroup.id != currentGroup?.id else {
            print("⚠️ DashboardViewModel: Grupo ya seleccionado, ignorando cambio")
            return
        }

        print("🔄 DashboardViewModel: Cambiando a grupo: \(newGroup.name)")

        isChangingGroup = true

        do {
            try? await Task.sleep(nanoseconds: 300_000_000)

            let groupId = newGroup.id
            let fetchedItemLists = try await fetchItemListsUseCase.execute(forGroupId: groupId)

            print("🔄 DashboardViewModel: Loading categories for new group...")
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var categoriesDict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories {
                categoriesDict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon)
            }
            print("✅ DashboardViewModel: Loaded \(categoriesDict.count) categories for new group")

            currentGroup = newGroup
            itemListTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListUnpaidTotals = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0.0) })
            itemListCounts = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, 0) })
            itemListPaidStatus = Dictionary(uniqueKeysWithValues: fetchedItemLists.map { ($0.id, ItemListPaidStatus.none) })
            itemLists = fetchedItemLists
            categories = categoriesDict

            await calculateTotalSpent()

            isChangingGroup = false
            print("✅ DashboardViewModel: Grupo cambiado exitosamente")
            print("📋 DashboardViewModel: Cargados \(fetchedItemLists.count) ItemLists")
        } catch {
            isChangingGroup = false
            print("❌ DashboardViewModel: Error cambiando grupo: \(error)")
        }
    }
    
    func refreshAvailableGroups() async {
        guard let user = currentUser else {
            print("⚠️ DashboardViewModel: No hay usuario actual, no se pueden recargar grupos")
            return
        }
        
        print("🔄 DashboardViewModel: Recargando grupos disponibles...")

        do {
            let userId = user.id
            let groups = try await fetchGroupsForUserUseCase.execute(userId: userId)

            availableGroups = groups
            print("✅ DashboardViewModel: Grupos recargados. Total: \(groups.count)")
        } catch {
            print("❌ DashboardViewModel: Error recargando grupos: \(error)")
        }
    }
    
    func addGroup(_ newGroup: SDGroup) {
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
    
    func removeGroup(_ group: SDGroup) {
        availableGroups.removeAll { $0.id == group.id }
    }

    func deleteGroup(_ group: SDGroup) async throws {
        withAnimation { availableGroups.removeAll { $0.id == group.id } }
        do {
            try await deleteGroupUseCase.execute(groupId: group.id)
        } catch {
            availableGroups.append(group)
            availableGroups.sort { $0.name < $1.name }
            throw error
        }
    }
    
    func openSettings() {
        showingSettings = true
    }

    func updateCurrentUser(_ user: SDUser) {
        currentUser = user
    }

    func refreshCategories() async {
        guard let groupId = currentGroup?.id else { return }
        do {
            let sdCategories = try await fetchCategoriesUseCase.execute(forGroupId: groupId)
            var dict: [UUID: (name: String, color: String, icon: String)] = [:]
            for cat in sdCategories { dict[cat.id] = (name: cat.name, color: cat.color, icon: cat.icon) }
            categories = dict
        } catch {}
    }

    func generateSeedDataDebug() {
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
                        itemListId: itemList.id,
                        isPaid: true
                    )
                }
            }

            print("✅ [SEED] 20 ItemLists created. Refreshing dashboard...")
            await loadDashboardData()

        } catch {
            print("❌ [SEED] Error generating seed data: \(error)")
        }
    }
    
    func addItemList(_ itemList: SDItemList) async {
        let itemListDesc = itemList.itemListDescription
        print("\n🟢 ============================================")
        print("📋 [ADD] Adding ItemList: '\(itemListDesc)'")
        print("🟢 ============================================")

        guard let currentGroupId = currentGroup?.id else {
            print("⚠️ [ADD] No current group selected - skipping")
            return
        }

        if itemList.group?.id != currentGroupId {
            print("⚠️ [ADD] ItemList belongs to different group")
            return
        }

        if itemLists.contains(where: { $0.id == itemList.id }) {
            print("⚠️ [ADD] ItemList already exists in dashboard")
            return
        }

        let cal = Calendar.current
        let sortedItemLists = (itemLists + [itemList]).sorted {
            let d0 = cal.startOfDay(for: $0.date)
            let d1 = cal.startOfDay(for: $1.date)
            return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
        }

        itemListTotals[itemList.id] = 0.0
        itemListUnpaidTotals[itemList.id] = 0.0
        itemListCounts[itemList.id] = 0
        itemListPaidStatus[itemList.id] = .none

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            itemLists = sortedItemLists
        }
        await calculateTotalSpent()

        print("✅ [ADD] ItemList added successfully to UI")
    }

    @MainActor
    func clearCache() async {
        cacheManager.clearAllCaches()
        print("🗂️ DashboardViewModel: All caches cleared")
    }
    
    func togglePaid(for itemList: SDItemList) {
        let itemCount = itemListCounts[itemList.id] ?? 0

        guard itemCount > 0 else {
            toast = ToastMessage("Registro vacío", type: .info)
            return
        }

        let previousStates = itemList.items.map { (id: $0.id, isPaid: $0.isPaid) }
        let currentStatus = itemListPaidStatus[itemList.id] ?? .none
        let newValue = currentStatus == .all ? false : true
        itemList.lastModifiedAt = Date()
        itemListPaidStatus[itemList.id] = newValue ? .all : .none
        itemList.items.forEach { $0.isPaid = newValue }

        if itemCount > 1 {
            toast = ToastMessage(
                newValue ? "Todo marcado como pagado" : "Todo marcado como pendiente",
                type: .info,
                actionTitle: "Deshacer"
            ) { [weak self] in
                Task { @MainActor in
                    await self?.undoTogglePaid(for: itemList, previousStates: previousStates)
                }
            }
        } else {
            toast = nil
        }

        paidToggleTasks[itemList.id] = Task {
            try? await toggleAllItemsPaidInListUseCase.execute(itemListId: itemList.id, isPaid: newValue)
            await calculateTotalSpent()
            paidToggleTasks[itemList.id] = nil
        }
    }

    private func undoTogglePaid(
        for itemList: SDItemList,
        previousStates: [(id: UUID, isPaid: Bool)]
    ) async {
        if let pendingTask = paidToggleTasks[itemList.id] {
            await pendingTask.value
        }

        for state in previousStates {
            itemList.items.first { $0.id == state.id }?.isPaid = state.isPaid
            try? await toggleItemPaidUseCase.execute(itemId: state.id, isPaid: state.isPaid)
        }
        itemList.lastModifiedAt = Date()
        await calculateTotalSpent()
        toast = ToastMessage("Cambio deshecho", type: .info)
    }

    func forceRefresh() async {
        await clearCache()
        await loadDashboardData()
        print("🔄 DashboardViewModel: Force refresh completed")
    }
    
    // MARK: - Private Methods

    func refreshTotals() async {
        await calculateTotalSpent()
    }

    private func calculateTotalSpent() async {
        let results = await withTaskGroup(of: ItemListData.self) { group in
            var items: [ItemListData] = []

            for itemList in itemLists {
                group.addTask {
                    return await self.getItemListData(itemList)
                }
            }

            for await result in group {
                items.append(result)
            }

            return items
        }

        let totals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidTotal) })
        let unpaidTotals = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.unpaidTotal) })
        let counts = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.count) })
        let paidStatuses = Dictionary(uniqueKeysWithValues: results.map { ($0.id, $0.paidStatus) })

        itemListTotals = totals
        itemListUnpaidTotals = unpaidTotals
        itemListCounts = counts
        itemListPaidStatus = paidStatuses
        todayTotal = todayItemLists.reduce(0.0) { $0 + (totals[$1.id] ?? 0) }
        currentMonthTotal = currentMonthItemLists.reduce(0.0) { $0 + (totals[$1.id] ?? 0) }

        let newTotal = totals.values.reduce(0.0) { total, itemListTotal in
            guard itemListTotal.isFinite else { return total }
            return total + itemListTotal
        }

        if newTotal.isFinite {
            totalSpent = max(0, newTotal)
        } else {
            totalSpent = 0.0
        }
    }
    
    // MARK: - Helper Methods

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

    func formattedPaid(for itemList: SDItemList) -> String {
        guard let total = itemListTotals[itemList.id] else { return "€0.00" }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "€0.00"
    }

    func formattedUnpaid(for itemList: SDItemList) -> String? {
        guard let status = itemListPaidStatus[itemList.id],
              status != .all,
              let unpaid = itemListUnpaidTotals[itemList.id],
              unpaid > 0 else { return nil }
        return makeCurrencyFormatter().string(from: NSNumber(value: unpaid))
    }

    func formattedTotal(for date: Date) -> String {
        let cal = Calendar.current
        let dayTotal = itemLists
            .filter { cal.isDate($0.date, inSameDayAs: date) }
            .reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        return makeCurrencyFormatter().string(from: NSNumber(value: dayTotal)) ?? "€0.00"
    }

    var formattedTodayTotal: String {
        makeCurrencyFormatter().string(from: NSNumber(value: todayTotal)) ?? "€0.00"
    }

    func formattedCachedMonthTotal() -> String {
        makeCurrencyFormatter().string(from: NSNumber(value: currentMonthTotal)) ?? "€0.00"
    }

    func formattedTotal(forMonth date: Date) -> String {
        let cal = Calendar.current
        let monthTotal = itemLists
            .filter { cal.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0.0) { $0 + (itemListTotals[$1.id] ?? 0) }
        return makeCurrencyFormatter().string(from: NSNumber(value: monthTotal)) ?? "€0.00"
    }

    var formattedTotalSpent: String {
        guard totalSpent.isFinite else {
            print("❌ DashboardViewModel: formattedTotalSpent called with NaN/Infinite value!")
            return "€0.00"
        }
        let formatter = makeCurrencyFormatter()
        return formatter.string(from: NSNumber(value: totalSpent)) ?? "€0.00"
    }
    
    var recentItemLists: [SDItemList] {
        return Array(itemLists.prefix(10))
    }
    
    private func updateCurrentMonthCache() {
        let calendar = Calendar.current
        let now = Date()

        let filtered = itemLists.filter { itemList in
            calendar.isDate(itemList.date, equalTo: now, toGranularity: .month)
        }

        let currentIds = Set(currentMonthItemLists.map { $0.id })
        let filteredIds = Set(filtered.map { $0.id })

        if currentIds != filteredIds {
            print("🗓️ DashboardViewModel: Updating current month cache")
            print("   - Total ItemLists: \(itemLists.count)")
            print("   - Current month ItemLists: \(filtered.count)")
            currentMonthItemLists = filtered
        }
    }
    
    private func getItemListData(_ itemList: SDItemList) async -> (id: UUID, paidTotal: Double, unpaidTotal: Double, count: Int, paidStatus: ItemListPaidStatus) {
        let cacheKey = itemListDataCacheKey(for: itemList)

        if let cached: CachedItemListData = cacheManager.getCachedCalculation(for: cacheKey) {
            return (itemList.id, cached.paidTotal, cached.unpaidTotal, cached.count, cached.paidStatus)
        }

        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let paidItems = items.filter { $0.isPaid }
            let unpaidItems = items.filter { !$0.isPaid }
            let paidTotal = paidItems.reduce(0.0) { acc, item in
                let value = item.totalAmount
                return value.isFinite ? acc + value : acc
            }
            let unpaidTotal = unpaidItems.reduce(0.0) { acc, item in
                let value = item.totalAmount
                return value.isFinite ? acc + value : acc
            }
            let totalUnits = items.reduce(0) { $0 + $1.quantity }
            let paidStatus: ItemListPaidStatus
            if items.isEmpty || paidItems.isEmpty {
                paidStatus = .none
            } else if paidItems.count == items.count {
                paidStatus = .all
            } else {
                paidStatus = .partial
            }
            let result = CachedItemListData(
                paidTotal: max(0, paidTotal.isFinite ? paidTotal : 0.0),
                unpaidTotal: max(0, unpaidTotal.isFinite ? unpaidTotal : 0.0),
                count: totalUnits,
                paidStatus: paidStatus
            )
            cacheManager.cacheCalculation(result, for: cacheKey)
            return (itemList.id, result.paidTotal, result.unpaidTotal, result.count, result.paidStatus)
        } catch {
            return (itemList.id, 0.0, 0.0, 0, .none)
        }
    }

    private func itemListDataCacheKey(for itemList: SDItemList) -> String {
        let versionDate = itemList.lastModifiedAt ?? itemList.createdAt
        return "dashboard_item_list_data_\(itemList.id.uuidString)_\(versionDate.timeIntervalSince1970)"
    }

    func getItemListTotal(_ itemList: SDItemList) async -> Double {
        do {
            let items = try await fetchItemsUseCase.execute(forItemListId: itemList.id)
            let total = items.reduce(0.0) { total, item in
                let value = item.totalAmount
                guard value.isFinite else { return total }
                return total + value
            }
            guard total.isFinite else { return 0.0 }
            return total
        } catch {
            return 0.0
        }
    }

    func getFormattedItemListTotal(_ itemList: SDItemList) async -> String {
        let total = await getItemListTotal(itemList)
        guard total.isFinite else { return "€0.00" }
        return makeCurrencyFormatter().string(from: NSNumber(value: total)) ?? "€0.00"
    }

    func deleteItemList(_ itemList: SDItemList) async {
        await removeItemList(itemList)
        do {
            try await deleteItemListUseCase.execute(id: itemList.id)
        } catch {
            await loadDashboardData()
        }
    }

    private func removeItemList(_ itemList: SDItemList) async {
        let currentItemLists = itemLists

        guard let index = currentItemLists.firstIndex(where: { $0.id == itemList.id }) else {
            print("⚠️ DashboardViewModel: ItemList not found in current list")
            return
        }

        var updatedItemLists = currentItemLists
        updatedItemLists.remove(at: index)

        withAnimation(.easeInOut(duration: 0.25)) {
            itemLists = updatedItemLists
        }

        await calculateTotalSpent()
    }

    func updateItemList(_ itemList: SDItemList) async {
        print("✏️ DashboardViewModel: Updating ItemList in UI cache")

        // Re-sort since date may have changed (SD* reference type, object is already mutated)
        let cal = Calendar.current
        itemLists = itemLists.sorted {
            let d0 = cal.startOfDay(for: $0.date)
            let d1 = cal.startOfDay(for: $1.date)
            return d0 == d1 ? $0.createdAt > $1.createdAt : d0 > d1
        }

        await calculateTotalSpent()
    }

    private func isItemListInCurrentContext(_ itemList: SDItemList) -> Bool {
        guard let currentGroup = currentGroup else { return false }
        return currentGroup.id == itemList.group?.id
    }

    func getCurrentMonthItemLists() -> [SDItemList] {
        let calendar = Calendar.current
        let now = Date()
        return itemLists.filter { itemList in
            calendar.isDate(itemList.date, equalTo: now, toGranularity: .month)
        }
    }
}

// MARK: - Supporting Types

private enum TotalSpentOperation {
    case add
    case remove
}
